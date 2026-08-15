"""
Self-test to verify that the Python emulator's packet codec matches the Flutter app's codec.
"""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from emulator.packet_codec import (
    encode_reading,
    decode_reading,
    GlucoseClass,
    FLAG_MOTION_ARTIFACT,
    FLAG_LOW_BATTERY,
    MODEL_PHONE_BACKGROUND,
)
from emulator.scenarios import get_scenario, compute_daily_glucose


def test_standard_packet():
    # 132.5 mg/dL -> 1325 tenths -> normal class (1)
    data = encode_reading(132.5, confidence=87)
    assert len(data) == 4, f"Expected 4 bytes, got {len(data)}"
    decoded = decode_reading(data)
    assert decoded is not None
    assert abs(decoded["mg_dl"] - 132.5) < 0.01, f"Decoded mg_dl: {decoded['mg_dl']}"
    assert decoded["glucose_class"] == GlucoseClass.NORMAL
    assert decoded["confidence"] == 87
    print("[PASS] Standard 4-byte packet encode/decode passed.")


def test_extended_packet():
    # 64.2 mg/dL -> low class (0) with flags and model origin
    data = encode_reading(
        mg_dl=64.2,
        confidence=88,
        flags=FLAG_MOTION_ARTIFACT | FLAG_LOW_BATTERY,
        model_origin=MODEL_PHONE_BACKGROUND,
        sequence_number=420,
        extended=True,
    )
    assert len(data) == 8, f"Expected 8 bytes, got {len(data)}"
    decoded = decode_reading(data)
    assert decoded is not None
    assert abs(decoded["mg_dl"] - 64.2) < 0.01
    assert decoded["glucose_class"] == GlucoseClass.LOW
    assert decoded["confidence"] == 88
    assert decoded["has_motion_artifact"] is True
    assert decoded["has_low_battery"] is True
    assert decoded["has_poor_contact"] is False
    assert decoded["model_origin"] == MODEL_PHONE_BACKGROUND
    assert decoded["sequence_number"] == 420
    print("[PASS] Extended 8-byte packet encode/decode passed.")


def test_scenarios():
    for name in ["hypo", "hyper", "swings", "flags", "regular"]:
        steps = get_scenario(name)
        assert len(steps) > 0, f"Scenario {name} is empty"
    print("[PASS] All predefined scenarios loaded successfully.")


def test_curve():
    val_8am = compute_daily_glucose(8.0)
    assert 50.0 <= val_8am <= 260.0
    print("[PASS] Synthetic mathematical glucose curve validated.")


if __name__ == "__main__":
    test_standard_packet()
    test_extended_packet()
    test_scenarios()
    test_curve()
    print("\nAll Python emulator verification tests passed successfully!")
