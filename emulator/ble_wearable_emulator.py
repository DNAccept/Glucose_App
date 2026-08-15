#!/usr/bin/env python3
"""
BLE Wearable Emulator (Laptop -> Phone Over-The-Air Signal Generator)

This script turns your laptop's Bluetooth adapter into a simulated "Glucose Wearable"
peripheral that advertises the GATT service and streams real-time glucose & battery
data to the Glucose App running on your physical phone.

Usage:
    python emulator/ble_wearable_emulator.py

Requirements:
    pip install winsdk colorama
"""

import asyncio
import sys
import os
import threading
import time
import struct
import atexit
import signal
from typing import Optional, List

# Add parent directory to path so relative imports work
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from emulator.packet_codec import (
    SERVICE_UUID,
    READING_CHARACTERISTIC_UUID,
    SESSION_CHARACTERISTIC_UUID,
    BATTERY_SERVICE_UUID,
    BATTERY_LEVEL_CHARACTERISTIC_UUID,
    encode_reading,
    decode_reading,
    GlucoseClass,
    FLAG_NONE,
)
from emulator.scenarios import get_scenario, compute_daily_glucose

# Color formatting
try:
    from colorama import init, Fore, Style
    init(autoreset=True)
    GREEN = Fore.GREEN
    CYAN = Fore.CYAN
    YELLOW = Fore.YELLOW
    RED = Fore.RED
    MAGENTA = Fore.MAGENTA
    BOLD = Style.BRIGHT
    RESET = Style.RESET_ALL
except ImportError:
    GREEN = CYAN = YELLOW = RED = MAGENTA = BOLD = RESET = ""


class BleWearableEmulator:
    def __init__(self, device_name: str = "Glucose Wearable"):
        self.device_name = device_name
        self.battery_level = 85
        self.subscribed_clients = 0
        self.is_running = False
        self.auto_streaming = False
        self.total_readings_sent = 0
        self.last_reading = None
        self.connected_clients_info: List[str] = []
        # Unique session ID for this running instance
        self.session_id = (int(time.time()) ^ int.from_bytes(os.urandom(4), "little")) & 0xFFFFFFFF
        self.session_hex = f"{self.session_id:08X}"
        self._provider = None
        self._battery_provider = None
        self._publisher = None
        self._reading_char = None
        self._session_char = None
        self._battery_char = None
        self._winrt_available = False
        self._heartbeat_task = None

    async def initialize(self) -> bool:
        """Initializes the Windows WinRT BLE GATT Server and begins advertising."""
        try:
            import uuid
            import socket
            import winsdk.windows.devices.bluetooth.genericattributeprofile as gatt
            import winsdk.windows.devices.bluetooth as bt
            import winsdk.windows.storage.streams as streams

            self.hostname = socket.gethostname()

            print(f"\n{CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}")
            print(f"{CYAN}{BOLD}  Initializing Windows BLE GATT Server Provider...{RESET}")
            print(f"{CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}")

            # Check Bluetooth Adapter
            adapter = await bt.BluetoothAdapter.get_default_async()
            if adapter:
                print(f"  Bluetooth Adapter : {GREEN}Found ({adapter.device_id[:35]}...){RESET}")
                print(f"  Peripheral Role   : {GREEN if adapter.is_peripheral_role_supported else RED}{adapter.is_peripheral_role_supported}{RESET}")
                print(f"  PC Hostname       : {BOLD}{self.hostname}{RESET}")
                print(f"  Active Session ID : {MAGENTA}{BOLD}0x{self.session_hex}{RESET}")

            # 1. Primary Glucose GATT Service
            service_guid = uuid.UUID(SERVICE_UUID)
            result = await gatt.GattServiceProvider.create_async(service_guid)

            if int(result.error) != 0:
                print(f"{RED}[Error] Failed to create GATT service provider: {result.error}{RESET}")
                return False

            self._provider = result.service_provider
            service = self._provider.service

            # Glucose Reading Characteristic (Notify + Read)
            reading_guid = uuid.UUID(READING_CHARACTERISTIC_UUID)
            reading_params = gatt.GattLocalCharacteristicParameters()
            reading_params.characteristic_properties = (
                gatt.GattCharacteristicProperties.NOTIFY | gatt.GattCharacteristicProperties.READ
            )
            reading_params.user_description = "Glucose Reading (mg/dL + Class + Flags)"

            char_result = await service.create_characteristic_async(reading_guid, reading_params)
            if int(char_result.error) != 0:
                print(f"{RED}[Error] Failed to create Reading characteristic: {char_result.error}{RESET}")
                return False

            self._reading_char = char_result.characteristic

            # Session ID & Heartbeat Characteristic (Notify + Read)
            session_guid = uuid.UUID(SESSION_CHARACTERISTIC_UUID)
            session_params = gatt.GattLocalCharacteristicParameters()
            session_params.characteristic_properties = (
                gatt.GattCharacteristicProperties.NOTIFY | gatt.GattCharacteristicProperties.READ
            )
            session_params.user_description = f"Session ID (0x{self.session_hex}) & Heartbeat"

            s_char_result = await service.create_characteristic_async(session_guid, session_params)
            if int(s_char_result.error) == 0:
                self._session_char = s_char_result.characteristic
                self._session_char.add_read_requested(self._on_session_read_requested)

            # Subscribe to client connection / subscription events
            self._reading_char.add_subscribed_clients_changed(self._on_subscribers_changed)
            self._reading_char.add_read_requested(self._on_reading_read_requested)

            # Monitor Advertisement Status
            self._provider.add_advertisement_status_changed(self._on_adv_status_changed)

            # Start advertising Primary Service
            adv_params = gatt.GattServiceProviderAdvertisingParameters()
            adv_params.is_connectable = True
            adv_params.is_discoverable = True

            self._provider.start_advertising(adv_params)

            # 2. Battery GATT Service (Standard 0x180F / 0x2A19)
            try:
                battery_guid = uuid.UUID(BATTERY_SERVICE_UUID)
                b_result = await gatt.GattServiceProvider.create_async(battery_guid)
                if int(b_result.error) == 0:
                    self._battery_provider = b_result.service_provider
                    b_service = self._battery_provider.service
                    b_char_guid = uuid.UUID(BATTERY_LEVEL_CHARACTERISTIC_UUID)
                    b_params = gatt.GattLocalCharacteristicParameters()
                    b_params.characteristic_properties = (
                        gatt.GattCharacteristicProperties.NOTIFY | gatt.GattCharacteristicProperties.READ
                    )
                    b_params.user_description = "Battery Level"
                    b_char_result = await b_service.create_characteristic_async(b_char_guid, b_params)
                    if int(b_char_result.error) == 0:
                        self._battery_char = b_char_result.characteristic
                        self._battery_char.add_read_requested(self._on_battery_read_requested)
                        b_adv = gatt.GattServiceProviderAdvertisingParameters()
                        b_adv.is_connectable = True
                        b_adv.is_discoverable = True
                        self._battery_provider.start_advertising(b_adv)
            except Exception:
                pass

            self._winrt_available = True
            self.is_running = True

            # Start background heartbeat ticker (sends session ping every 1.5 seconds)
            self._heartbeat_task = asyncio.create_task(self._heartbeat_loop())

            print(f"\n{GREEN}{BOLD}✔ [BROADCASTING] Over-The-Air BLE Signal Active!{RESET}")
            print(f"  Target Device Name : {BOLD}{self.device_name}{RESET} (or PC Bluetooth Name: {BOLD}{self.hostname}{RESET})")
            print(f"  Session Identifier : {MAGENTA}{BOLD}0x{self.session_hex}{RESET}")
            print(f"  GATT Service UUID  : {CYAN}{SERVICE_UUID}{RESET}")
            print(f"  GATT Characteristic: {CYAN}{READING_CHARACTERISTIC_UUID}{RESET}")
            print(f"\n{YELLOW}📲 In the Glucose App on your phone: Tap 'Scan for device' -> Connect to '⭐ Glucose Wearable ({self.hostname})'{RESET}\n")
            return True

        except ImportError:
            print(f"{YELLOW}[Notice] 'winsdk' is not installed.{RESET}")
            print(f"To enable real over-the-air Bluetooth broadcasting from your laptop, run:")
            print(f"  {BOLD}pip install winsdk colorama{RESET}\n")
            print(f"{CYAN}Running in Interactive Protocol CLI mode (Packet Validation & Live Terminal Test).{RESET}")
            self.is_running = True
            return True
        except Exception as e:
            print(f"{YELLOW}[Warning] Native Windows BLE Peripheral advertising unavailable: {e}{RESET}")
            print(f"{CYAN}Running in interactive simulation mode.{RESET}")
            self.is_running = True
            return True

    def _on_adv_status_changed(self, sender, args):
        """Monitors Windows GATT advertisement status changes."""
        status_names = {0: "Created", 1: "Stopped", 2: "Started (Broadcasting)", 3: "Aborted"}
        name = status_names.get(args.status, f"Status-{args.status}")
        if args.status == 2:
            print(f"{GREEN}  [Radio Status] BLE Advertising ACTIVE & BROADCASTING over the air ({name}){RESET}\n{self.get_prompt()}", end="", flush=True)
        elif args.status in (1, 3):
            print(f"\n{RED}  [Radio Warning] BLE Advertising status changed to: {name} (Error: {args.error}){RESET}\n{self.get_prompt()}", end="", flush=True)

    def _on_reading_read_requested(self, sender, args):
        """Responds when the phone reads the glucose characteristic directly."""
        try:
            import winsdk.windows.storage.streams as streams
            deferral = args.get_deferral()
            request = args.get_request()
            if request:
                val = self.last_reading if self.last_reading is not None else 100.0
                packet = encode_reading(mg_dl=val)
                writer = streams.DataWriter()
                writer.write_bytes(bytes(packet))
                request.respond_with_value(writer.detach_buffer())
                now_str = time.strftime("%H:%M:%S")
                print(f"\n{CYAN}[{now_str}] 📲 Phone read current glucose reading ({val:.1f} mg/dL){RESET}\n{self.get_prompt()}", end="")
            deferral.complete()
        except Exception:
            pass

    def _on_session_read_requested(self, sender, args):
        """Responds when the phone reads the session ID characteristic."""
        try:
            import winsdk.windows.storage.streams as streams
            deferral = args.get_deferral()
            request = args.get_request()
            if request:
                writer = streams.DataWriter()
                packet = struct.pack("<IB", self.session_id, self.battery_level)
                writer.write_bytes(bytes(packet))
                request.respond_with_value(writer.detach_buffer())
            deferral.complete()
        except Exception:
            pass

    async def _heartbeat_loop(self):
        """Emits continuous session heartbeat pings every 1.5 seconds while alive."""
        while self.is_running:
            try:
                await asyncio.sleep(1.5)
                if not self.is_running:
                    break
                if self._winrt_available and self._session_char:
                    import winsdk.windows.storage.streams as streams
                    writer = streams.DataWriter()
                    packet = struct.pack("<IB", self.session_id, self.battery_level)
                    writer.write_bytes(bytes(packet))
                    buffer = writer.detach_buffer()
                    await self._session_char.notify_value_async(buffer)
            except Exception:
                pass

    def _on_battery_read_requested(self, sender, args):
        """Responds when the phone reads the battery level characteristic directly."""
        try:
            import winsdk.windows.storage.streams as streams
            deferral = args.get_deferral()
            request = args.get_request()
            if request:
                writer = streams.DataWriter()
                writer.write_byte(self.battery_level)
                request.respond_with_value(writer.detach_buffer())
                now_str = time.strftime("%H:%M:%S")
                print(f"\n{CYAN}[{now_str}] 📲 Phone read battery level ({self.battery_level}%){RESET}\n{self.get_prompt()}", end="")
            deferral.complete()
        except Exception:
            pass

    def _on_subscribers_changed(self, char, args):
        """Fires whenever a mobile device connects/subscribes or disconnects."""
        try:
            clients = list(char.subscribed_clients)
            new_count = len(clients)
            prev_count = self.subscribed_clients
            self.subscribed_clients = new_count
            now_str = time.strftime("%H:%M:%S")

            client_ids = []
            for c in clients:
                try:
                    if hasattr(c, "session") and hasattr(c.session, "device_id"):
                        client_ids.append(str(c.session.device_id.id))
                    else:
                        client_ids.append(f"ClientSession-{id(c)}")
                except Exception:
                    client_ids.append(f"BLE-Client-{len(client_ids)+1}")
            self.connected_clients_info = client_ids

            if new_count > prev_count:
                # Device Connected / Paired!
                print("\a", end="")  # System alert bell
                print(f"\n\n{GREEN}{BOLD}╔══════════════════════════════════════════════════════════════════════════════╗{RESET}")
                print(f"{GREEN}{BOLD}║  🟢 [BLE CONNECTED & PAIRED] MOBILE DEVICE SUCCESSFULLY CONNECTED!          ║{RESET}")
                print(f"{GREEN}{BOLD}╠══════════════════════════════════════════════════════════════════════════════╣{RESET}")
                print(f"{GREEN}║  Timestamp        : {now_str:<56} ║{RESET}")
                print(f"{GREEN}║  Active Clients   : {new_count:<56} ║{RESET}")
                for cid in client_ids:
                    display_id = (cid[:53] + "...") if len(cid) > 56 else cid
                    print(f"{GREEN}║  Device ID        : {display_id:<56} ║{RESET}")
                print(f"{GREEN}║  Subscribed To    : Glucose Characteristic (0000a001-...)              ║{RESET}")
                print(f"{GREEN}{BOLD}╠══════════════════════════════════════════════════════════════════════════════╣{RESET}")
                print(f"{GREEN}{BOLD}║  👉 Ready to stream data! Try typing:                                       ║{RESET}")
                print(f"{GREEN}{BOLD}║     • 'auto 2'  - to stream live glucose curves every 2 seconds             ║{RESET}")
                print(f"{GREEN}{BOLD}║     • 'regular' - to send normal sequence (95–115 mg/dL)                    ║{RESET}")
                print(f"{GREEN}{BOLD}║     • 'send 110'- to send custom value                                      ║{RESET}")
                print(f"{GREEN}{BOLD}║     • 'hypo'    - to trigger low glucose alert (<70 mg/dL)                  ║{RESET}")
                print(f"{GREEN}{BOLD}║     • 'hyper'   - to trigger high glucose spike (>180 mg/dL)                ║{RESET}")
                print(f"{GREEN}{BOLD}╚══════════════════════════════════════════════════════════════════════════════╝{RESET}\n")
                print(self.get_prompt(), end="", flush=True)

            elif new_count < prev_count:
                # Device Disconnected
                print(f"\n\n{YELLOW}{BOLD}╔══════════════════════════════════════════════════════════════════════════════╗{RESET}")
                print(f"{YELLOW}{BOLD}║  🟡 [BLE DISCONNECTED] Mobile device unsubscribed / disconnected.           ║{RESET}")
                print(f"{YELLOW}║  Timestamp        : {now_str:<56} ║{RESET}")
                print(f"{YELLOW}║  Remaining Clients: {new_count:<56} ║{RESET}")
                print(f"{YELLOW}{BOLD}╚══════════════════════════════════════════════════════════════════════════════╝{RESET}\n")
                print(self.get_prompt(), end="", flush=True)

        except Exception as e:
            print(f"\n{RED}[Error in connection callback: {e}]{RESET}\n{self.get_prompt()}", end="", flush=True)

    def get_prompt(self) -> str:
        """Returns dynamic prompt with live connection status."""
        if self.subscribed_clients > 0:
            badge = f"{GREEN}[PAIRED: {self.subscribed_clients} phone(s)]{RESET}"
        else:
            badge = f"{YELLOW}[WAITING FOR APP]{RESET}"
        return f"{badge} {BOLD}emulator > {RESET}"

    async def send_reading(
        self,
        mg_dl: float,
        glucose_class: Optional[int] = None,
        confidence: int = 95,
        flags: int = FLAG_NONE,
        note: str = "",
    ) -> bytes:
        """Encodes and transmits a glucose reading to connected phone."""
        packet_bytes = encode_reading(
            mg_dl=mg_dl,
            glucose_class=glucose_class,
            confidence=confidence,
            flags=flags,
        )

        decoded = decode_reading(packet_bytes)
        class_label = decoded["glucose_class_label"] if decoded else ""
        self.last_reading = mg_dl
        self.total_readings_sent += 1

        # Color coding based on value
        color = GREEN if 70.0 <= mg_dl <= 180.0 else (RED if mg_dl < 70.0 else YELLOW)
        flag_str = f" {MAGENTA}[Flags: 0x{flags:02X}]{RESET}" if flags != 0 else ""
        note_str = f" - {note}" if note else ""
        now_str = time.strftime("%H:%M:%S")

        print(
            f"  {color}-> [TX Reading {now_str}]{RESET} {BOLD}{mg_dl:5.1f} mg/dL{RESET} "
            f"[{color}{class_label}{RESET}, {confidence}% conf]{flag_str}{note_str}"
        )

        # Transmit via WinRT GATT Notify if active
        if self._winrt_available and self._reading_char:
            try:
                import winsdk.windows.storage.streams as streams
                writer = streams.DataWriter()
                writer.write_bytes(bytes(packet_bytes))
                buffer = writer.detach_buffer()
                await self._reading_char.notify_value_async(buffer)
            except Exception as e:
                print(f"    {YELLOW}(Notify error: {e}){RESET}")

        return packet_bytes

    async def send_battery(self, level: int):
        """Updates battery level and transmits to phone."""
        self.battery_level = max(0, min(100, level))
        now_str = time.strftime("%H:%M:%S")
        print(f"  {CYAN}-> [TX Battery {now_str}]{RESET} {self.battery_level}%")

        if self._winrt_available and self._battery_char:
            try:
                import winsdk.windows.storage.streams as streams
                writer = streams.DataWriter()
                writer.write_byte(self.battery_level)
                buffer = writer.detach_buffer()
                await self._battery_char.notify_value_async(buffer)
            except Exception as e:
                print(f"    {YELLOW}(Battery notify error: {e}){RESET}")

    def stop(self):
        """Stops BLE advertising, transmits session termination, and cleanly shuts down."""
        if not self.is_running:
            return
        self.is_running = False
        self.auto_streaming = False
        if self._heartbeat_task:
            self._heartbeat_task.cancel()

        # Transmit explicit Session End packet (session_id = 0)
        if self._winrt_available and self._session_char:
            try:
                import winsdk.windows.storage.streams as streams
                writer = streams.DataWriter()
                writer.write_bytes(b"\x00\x00\x00\x00\x00")
                self._session_char.notify_value_async(writer.detach_buffer())
            except Exception:
                pass

        if self._provider:
            try:
                self._provider.stop_advertising()
            except Exception:
                pass
        if self._battery_provider:
            try:
                self._battery_provider.stop_advertising()
            except Exception:
                pass

    async def play_scenario(self, name: str):
        """Executes a multi-step scenario sequence with realistic timing."""
        steps = get_scenario(name)
        if not steps:
            print(f"{RED}[Error] Unknown scenario '{name}'. Available: hypo, hyper, swings, flags, regular{RESET}")
            return

        print(f"\n{CYAN}{BOLD}>> Playing Scenario: '{name.upper()}' ({len(steps)} steps)...{RESET}")
        for i, step in enumerate(steps, start=1):
            if not self.is_running:
                break
            print(f"[{i}/{len(steps)}]", end="")
            await self.send_reading(
                mg_dl=step["mg_dl"],
                confidence=step.get("confidence", 95),
                flags=step.get("flags", FLAG_NONE),
                note=step.get("note", ""),
            )
            delay = step.get("delay", 1.5)
            await asyncio.sleep(delay)
        print(f"{GREEN}[OK] Scenario '{name}' complete.{RESET}\n")

    async def run_auto_stream(self, interval_seconds: float = 3.0):
        """Continuously streams realistic daily glucose curve."""
        print(f"\n{CYAN}{BOLD}>> Auto-streaming 24h synthetic curve every {interval_seconds}s (Press Ctrl+C to stop)...{RESET}")
        self.auto_streaming = True
        virtual_hour = 8.0  # Start at 8:00 AM breakfast

        while self.auto_streaming and self.is_running:
            mg_dl = compute_daily_glucose(virtual_hour)
            time_str = f"{int(virtual_hour):02d}:{int((virtual_hour % 1) * 60):02d}"
            await self.send_reading(
                mg_dl=mg_dl,
                confidence=95,
                note=f"Virtual Time {time_str}",
            )
            virtual_hour = (virtual_hour + 0.15) % 24.0  # Advance 9 minutes per tick
            await asyncio.sleep(interval_seconds)

    def stop(self):
        self.is_running = False
        self.auto_streaming = False
        if self._provider:
            try:
                self._provider.stop_advertising()
            except Exception:
                pass


def print_help():
    print(f"""
{CYAN}{BOLD}═══════════════════════════════════════════════════════════════════════════════{RESET}
{BOLD}             GLUCOSE WEARABLE BLE EMULATOR — COMMAND MENU{RESET}
{CYAN}{BOLD}═══════════════════════════════════════════════════════════════════════════════{RESET}
  {BOLD}send <mg_dl>{RESET}     - Send custom glucose reading (e.g. {GREEN}send 105.5{RESET}, {RED}send 58{RESET})
  {BOLD}hypo{RESET}             - Play Hypoglycemia Alert scenario (<70 mg/dL)
  {BOLD}hyper{RESET}            - Play Hyperglycemia Spike scenario (>180 mg/dL)
  {BOLD}swings{RESET}           - Play Rapid Swings scenario (Low/High transitions)
  {BOLD}flags{RESET}            - Play Signal Flags scenario (Motion / Skin Contact)
  {BOLD}regular{RESET}          - Play Regular Normal Use sequence (95–115 mg/dL)
  {BOLD}auto [seconds]{RESET}   - Stream continuous 24h curve (e.g. {CYAN}auto 2{RESET})
  {BOLD}battery <0-100>{RESET}  - Update battery level percentage (e.g. {CYAN}battery 45{RESET})
  {BOLD}status{RESET}           - Check BLE pairing details & subscriber status
  {BOLD}help{RESET}             - Show this help menu
  {BOLD}exit / quit{RESET}      - Stop emulator and exit
{CYAN}{BOLD}═══════════════════════════════════════════════════════════════════════════════{RESET}
""")


async def cli_loop(emulator: BleWearableEmulator):
    print_help()

    while emulator.is_running:
        try:
            loop = asyncio.get_event_loop()
            prompt = emulator.get_prompt()
            cmd_raw = await loop.run_in_executor(None, input, prompt)
            cmd = cmd_raw.strip().lower()

            if not cmd:
                continue

            parts = cmd.split()
            action = parts[0]

            if action in ("exit", "quit", "q"):
                print(f"{YELLOW}Shutting down emulator...{RESET}")
                emulator.stop()
                break

            elif action == "help":
                print_help()

            elif action == "status":
                status_color = GREEN if emulator.subscribed_clients > 0 else YELLOW
                status_text = f"PAIRED & CONNECTED ({emulator.subscribed_clients} phone(s))" if emulator.subscribed_clients > 0 else "WAITING (No phone paired yet)"
                print(f"\n{CYAN}{BOLD}─── Wearable Emulator Status ───────────────────────────────────────────{RESET}")
                print(f"  Device Name      : {BOLD}{emulator.device_name}{RESET}")
                print(f"  Pairing Status   : {status_color}{BOLD}{status_text}{RESET}")
                if emulator.connected_clients_info:
                    for i, cid in enumerate(emulator.connected_clients_info, 1):
                        print(f"  Client #{i} ID     : {cid}")
                print(f"  Battery Level    : {emulator.battery_level}%")
                print(f"  Total Sent (TX)  : {emulator.total_readings_sent} packet(s)")
                print(f"  Last Reading     : {f'{emulator.last_reading:.1f} mg/dL' if emulator.last_reading is not None else 'None'}")
                print(f"  WinRT Hardware   : {'Active (Broadcasting BLE GATT)' if emulator._winrt_available else 'CLI Simulation Mode'}")
                print(f"  Service UUID     : {SERVICE_UUID}")
                print(f"  Notify Char UUID : {READING_CHARACTERISTIC_UUID}")
                print(f"{CYAN}────────────────────────────────────────────────────────────────────────{RESET}\n")

            elif action == "hypo":
                await emulator.play_scenario("hypo")

            elif action == "hyper":
                await emulator.play_scenario("hyper")

            elif action == "swings":
                await emulator.play_scenario("swings")

            elif action == "flags":
                await emulator.play_scenario("flags")

            elif action == "regular":
                await emulator.play_scenario("regular")

            elif action == "send":
                if len(parts) < 2:
                    print(f"{RED}Usage: send <mg_dl> (e.g. send 115.0){RESET}")
                    continue
                try:
                    val = float(parts[1])
                    await emulator.send_reading(val, note="Manual CLI injection")
                except ValueError:
                    print(f"{RED}Invalid number: {parts[1]}{RESET}")

            elif action == "battery":
                if len(parts) < 2:
                    print(f"{RED}Usage: battery <0-100>{RESET}")
                    continue
                try:
                    level = int(parts[1])
                    await emulator.send_battery(level)
                except ValueError:
                    print(f"{RED}Invalid integer: {parts[1]}{RESET}")

            elif action == "auto":
                interval = 3.0
                if len(parts) >= 2:
                    try:
                        interval = float(parts[1])
                    except ValueError:
                        pass
                try:
                    await emulator.run_auto_stream(interval_seconds=interval)
                except (KeyboardInterrupt, asyncio.CancelledError):
                    emulator.auto_streaming = False
                    print(f"\n{YELLOW}Stopped auto-streaming.{RESET}")

            elif action in ("pair", "simulate-pair"):
                # Simulation toggle for testing
                emulator.subscribed_clients = 1 if emulator.subscribed_clients == 0 else 0
                state_desc = "PAIRED (Simulated Phone)" if emulator.subscribed_clients > 0 else "DISCONNECTED"
                print(f"{GREEN if emulator.subscribed_clients > 0 else YELLOW}[Simulator] Pairing toggled: {state_desc}{RESET}")

            else:
                print(f"{RED}Unknown command '{action}'. Type 'help' for menu.{RESET}")

        except (EOFError, KeyboardInterrupt):
            print(f"\n{YELLOW}Exiting...{RESET}")
            emulator.stop()
            break


async def main():
    emulator = BleWearableEmulator()
    atexit.register(emulator.stop)

    def _sig_handler(sig, frame):
        emulator.stop()
        sys.exit(0)

    signal.signal(signal.SIGINT, _sig_handler)
    signal.signal(signal.SIGTERM, _sig_handler)

    success = await emulator.initialize()
    if not success:
        print(f"{RED}Failed to initialize emulator.{RESET}")
        return

    try:
        await cli_loop(emulator)
    finally:
        emulator.stop()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except (KeyboardInterrupt, SystemExit):
        print("\nGoodbye!")

