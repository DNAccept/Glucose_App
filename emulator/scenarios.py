"""
Predefined Scenario Sequences for the Wearable Emulator.
"""

import math
import time
from typing import List, Dict, Any
from .packet_codec import (
    FLAG_NONE,
    FLAG_MOTION_ARTIFACT,
    FLAG_POOR_SKIN_CONTACT,
    FLAG_LOW_BATTERY,
    FLAG_SENSOR_FAULT,
    MODEL_ON_DEVICE,
    MODEL_PHONE_BACKGROUND,
)


def get_scenario(name: str) -> List[Dict[str, Any]]:
    """Returns a list of step dictionaries for the specified scenario."""
    scenarios = {
        "hypo": [
            {"mg_dl": 90.0, "confidence": 92, "delay": 1.5, "note": "Baseline normal (90 mg/dL)"},
            {"mg_dl": 78.0, "confidence": 90, "delay": 1.5, "note": "Dropping towards threshold (78 mg/dL)"},
            {"mg_dl": 68.0, "confidence": 92, "delay": 1.5, "note": "HYPOGLYCEMIA ENTRY (68 mg/dL) -> triggers low alert"},
            {"mg_dl": 58.0, "confidence": 95, "delay": 1.5, "note": "Deeper hypo (58 mg/dL)"},
            {"mg_dl": 52.0, "confidence": 96, "delay": 1.5, "note": "Nadir (52 mg/dL)"},
            {"mg_dl": 65.0, "confidence": 92, "delay": 1.5, "note": "Recovering (65 mg/dL)"},
            {"mg_dl": 75.0, "confidence": 90, "delay": 1.5, "note": "Recovery to normal (75 mg/dL)"},
        ],
        "hyper": [
            {"mg_dl": 120.0, "confidence": 94, "delay": 1.5, "note": "Pre-meal baseline (120 mg/dL)"},
            {"mg_dl": 155.0, "confidence": 92, "delay": 1.5, "note": "Postprandial rise (155 mg/dL)"},
            {"mg_dl": 185.0, "confidence": 93, "delay": 1.5, "note": "HYPERGLYCEMIA ENTRY (185 mg/dL) -> triggers high alert"},
            {"mg_dl": 220.0, "confidence": 96, "delay": 1.5, "note": "Peak spike (220 mg/dL)"},
            {"mg_dl": 245.0, "confidence": 97, "delay": 1.5, "note": "Extended high (245 mg/dL)"},
            {"mg_dl": 175.0, "confidence": 91, "delay": 1.5, "note": "Recovery below 180 mg/dL (175 mg/dL)"},
        ],
        "swings": [
            {"mg_dl": 100.0, "confidence": 92, "delay": 1.2, "note": "Normal baseline (100 mg/dL)"},
            {"mg_dl": 62.0, "confidence": 90, "delay": 1.2, "note": "Low transition #1 (62 mg/dL)"},
            {"mg_dl": 110.0, "confidence": 92, "delay": 1.2, "note": "Rebound to normal (110 mg/dL)"},
            {"mg_dl": 195.0, "confidence": 93, "delay": 1.2, "note": "High transition #1 (195 mg/dL)"},
            {"mg_dl": 105.0, "confidence": 91, "delay": 1.2, "note": "Normal range (105 mg/dL)"},
            {"mg_dl": 58.0, "confidence": 89, "delay": 1.2, "note": "Low transition #2 (58 mg/dL)"},
        ],
        "flags": [
            {
                "mg_dl": 102.0,
                "confidence": 95,
                "flags": FLAG_MOTION_ARTIFACT,
                "delay": 1.5,
                "note": "Flag: Motion Artifact detected",
            },
            {
                "mg_dl": 105.0,
                "confidence": 60,
                "flags": FLAG_POOR_SKIN_CONTACT,
                "delay": 1.5,
                "note": "Flag: Poor Skin Contact detected",
            },
            {
                "mg_dl": 108.0,
                "confidence": 50,
                "flags": FLAG_LOW_BATTERY | FLAG_MOTION_ARTIFACT,
                "delay": 1.5,
                "note": "Flags: Low Battery + Motion Artifact",
            },
            {
                "mg_dl": 104.0,
                "confidence": 95,
                "flags": FLAG_NONE,
                "delay": 1.5,
                "note": "Flags cleared -> Sensor health OK",
            },
        ],
        "regular": [
            {"mg_dl": 95.0, "confidence": 95, "delay": 1.0, "note": "Steady state 1 (95 mg/dL)"},
            {"mg_dl": 98.2, "confidence": 94, "delay": 1.0, "note": "Steady state 2 (98 mg/dL)"},
            {"mg_dl": 102.5, "confidence": 96, "delay": 1.0, "note": "Steady state 3 (102 mg/dL)"},
            {"mg_dl": 106.0, "confidence": 95, "delay": 1.0, "note": "Steady state 4 (106 mg/dL)"},
            {"mg_dl": 110.4, "confidence": 94, "delay": 1.0, "note": "Steady state 5 (110 mg/dL)"},
            {"mg_dl": 114.0, "confidence": 93, "delay": 1.0, "note": "Steady state 6 (114 mg/dL)"},
            {"mg_dl": 108.0, "confidence": 95, "delay": 1.0, "note": "Steady state 7 (108 mg/dL)"},
            {"mg_dl": 96.5, "confidence": 95, "delay": 1.0, "note": "Steady state 8 (96 mg/dL)"},
        ],
    }
    return scenarios.get(name.lower(), [])


def compute_daily_glucose(hour_float: float) -> float:
    """Mathematical continuous 24-hour glucose curve matching the app's mockup."""
    h = hour_float % 24.0
    g = 110.0
    g += 78.0 * math.exp(-((h - 7.5) ** 2) / 1.1)  # breakfast
    g += 88.0 * math.exp(-((h - 13.0) ** 2) / 1.4)  # lunch
    g += 82.0 * math.exp(-((h - 19.5) ** 2) / 1.6)  # dinner
    if h < 5.5:
        g -= 28.0 * math.exp(-((h - 3.2) ** 2) / 2.2)  # overnight dip
    g += 7.0 * math.sin(h * 1.7)
    return max(52.0, min(255.0, g))
