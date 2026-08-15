"""
Glucose BLE Packet Codec for the Wearable Emulator.
Matches BleContract and GlucoseReadingCodec from the Flutter app.
"""

import struct
from typing import Optional, Tuple, Dict, Any

# UUID Constants from BleContract
SERVICE_UUID = "0000a000-0000-1000-8000-00805f9b34fb"
READING_CHARACTERISTIC_UUID = "0000a001-0000-1000-8000-00805f9b34fb"
SESSION_CHARACTERISTIC_UUID = "0000a002-0000-1000-8000-00805f9b34fb"
BATTERY_SERVICE_UUID = "0000180f-0000-1000-8000-00805f9b34fb"
BATTERY_LEVEL_CHARACTERISTIC_UUID = "00002a19-0000-1000-8000-00805f9b34fb"

# Sensor Health Flag Bitmasks (Byte 4 of Extended Payload)
FLAG_NONE = 0x00
FLAG_MOTION_ARTIFACT = 0x01
FLAG_POOR_SKIN_CONTACT = 0x02
FLAG_LOW_BATTERY = 0x04
FLAG_SENSOR_FAULT = 0x08

# Model Origin Identifiers (Byte 5 of Extended Payload)
MODEL_ON_DEVICE = 0x00
MODEL_PHONE_BACKGROUND = 0x01

# Thresholds in mg/dL
LOW_CUTOFF_MGDL = 70.0
HIGH_CUTOFF_MGDL = 180.0


class GlucoseClass:
    LOW = 0
    NORMAL = 1
    HIGH = 2

    @staticmethod
    def from_mgdl(mg_dl: float) -> int:
        if mg_dl < LOW_CUTOFF_MGDL:
            return GlucoseClass.LOW
        elif mg_dl > HIGH_CUTOFF_MGDL:
            return GlucoseClass.HIGH
        return GlucoseClass.NORMAL

    @staticmethod
    def label(class_val: int) -> str:
        return {
            GlucoseClass.LOW: "LOW (<70)",
            GlucoseClass.NORMAL: "NORMAL (70-180)",
            GlucoseClass.HIGH: "HIGH (>180)",
        }.get(class_val, "UNKNOWN")


def encode_reading(
    mg_dl: float,
    glucose_class: Optional[int] = None,
    confidence: int = 95,
    flags: int = FLAG_NONE,
    model_origin: int = MODEL_ON_DEVICE,
    sequence_number: Optional[int] = None,
    extended: bool = False,
) -> bytes:
    """
    Encodes a glucose reading into BLE notification bytes.
    - Standard 4-byte format: [class (1B), confidence (1B), tenths_mg_dl (2B uint16 LE)]
    - Extended 8-byte format: [class, confidence, tenths_mg_dl, flags, model_origin, seq_uint16 LE]
    """
    if glucose_class is None:
        glucose_class = GlucoseClass.from_mgdl(mg_dl)

    tenths = int(round(mg_dl * 10.0)) & 0xFFFF
    confidence_clamped = max(0, min(100, confidence))

    if extended or flags != FLAG_NONE or model_origin != MODEL_ON_DEVICE or sequence_number is not None:
        seq = (sequence_number or 0) & 0xFFFF
        return struct.pack("<BBHBBH", glucose_class, confidence_clamped, tenths, flags, model_origin, seq)
    else:
        return struct.pack("<BBH", glucose_class, confidence_clamped, tenths)


def decode_reading(payload: bytes) -> Optional[Dict[str, Any]]:
    """
    Decodes raw BLE notification bytes into a dictionary.
    """
    if not payload or len(payload) < 4:
        return None

    class_val, confidence, tenths = struct.unpack("<BBH", payload[:4])
    mg_dl = tenths / 10.0

    flags = FLAG_NONE
    model_origin = MODEL_ON_DEVICE
    seq = None

    if len(payload) >= 8:
        flags, model_origin, seq = struct.unpack("<BBH", payload[4:8])

    return {
        "mg_dl": mg_dl,
        "glucose_class": class_val,
        "glucose_class_label": GlucoseClass.label(class_val),
        "confidence": confidence,
        "flags": flags,
        "has_motion_artifact": bool(flags & FLAG_MOTION_ARTIFACT),
        "has_poor_contact": bool(flags & FLAG_POOR_SKIN_CONTACT),
        "has_low_battery": bool(flags & FLAG_LOW_BATTERY),
        "has_sensor_fault": bool(flags & FLAG_SENSOR_FAULT),
        "model_origin": model_origin,
        "sequence_number": seq,
    }
