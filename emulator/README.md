# Glucose Wearable BLE Peripheral Emulator

Turn your laptop into a real Bluetooth Low Energy (BLE) peripheral that broadcasts GATT signals to the Glucose App running on your physical mobile device (Android or iOS).

---

## 1. Quick Setup

Ensure you have Python 3.10+ installed on your laptop:

```bash
# 1. Navigate to the project directory
cd Glucose_App

# 2. Install dependencies (WinRT BLE + colored terminal output)
pip install -r emulator/requirements.txt
```

---

## 2. Running the Emulator

Run the emulator script from your terminal:

```bash
python emulator/ble_wearable_emulator.py
```

When started, your laptop will advertise:
- **Device Name:** `Glucose Wearable`
- **Service UUID:** `0000a000-0000-1000-8000-00805f9b34fb`
- **Notify Characteristic:** `0000a001-0000-1000-8000-00805f9b34fb`

---

## 3. Connecting From Your Phone

1. **Launch the Glucose App on your phone.**
2. Go to **Settings**, toggle **Use BLE simulator** to **OFF** (to enable real Bluetooth hardware).
3. Open the **Device** tab and tap **Scan**.
4. You will see **Glucose Wearable** (your laptop). Tap **Connect**.
5. Switch to the **Now** or **History** tab.

---

## 4. Interactive CLI Commands

Type any of the following commands in the emulator terminal on your laptop to send live data to your phone:

| Command | Action |
|---|---|
| `hypo` | Streams rapid descent into hypoglycemia (<70 mg/dL), triggering a low-glucose push alert on your phone. |
| `hyper` | Streams postprandial glucose spike (>180 mg/dL), triggering a high-glucose push alert. |
| `swings` | Streams rapid oscillations between low, normal, and high states. |
| `flags` | Transmits motion artifact and poor skin contact sensor health flags. |
| `regular` | Streams a sequence of steady normal-range readings (95–114 mg/dL). |
| `send <mg_dl>` | Sends an exact custom reading instantly (e.g., `send 64.5` or `send 220`). |
| `auto [seconds]` | Automatically streams the continuous 24-hour daily curve every N seconds (e.g. `auto 2`). |
| `battery <0-100>` | Changes and transmits the wearable battery level percentage (e.g., `battery 42`). |
| `status` | Checks active client subscriptions and connection state. |
| `help` | Displays the interactive menu. |
| `exit` | Stops the emulator and disconnects. |
