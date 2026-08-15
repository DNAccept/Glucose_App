# App Response Simulation — Test Plan

**Goal:** Build BLE device-simulation scripts to test app functionality and response across regular-use and extreme/edge-case scenarios, decoupling app testing from hardware readiness.

---

## 1. Lock Down the Packet Contract

Before writing any simulator, nail down the exact structure of a BLE packet from the device:

- Glucose estimate
- Model confidence score
- Sensor-health flags (motion artifact, poor skin contact, low battery)
- Timestamp
- Which model produced the reading (on-device vs. eventually phone-side)

Everything downstream depends on this being stable and documented — ideally as a shared schema file (JSON schema or a Dart class) that both you and the simulator use.

---

## 2. Build a Case Library, Not One-Off Scripts

Define each test scenario as a data fixture (JSON/YAML) rather than hardcoding it into a script — a sequence of packets with timestamps and the expected app behavior for that sequence.

**Why:** trivial to add new edge cases later without touching simulator code, and it doubles as living documentation of what the app is supposed to do in each situation.

---

## 3. Choose Two Levels of Simulation

1. **In-process mock (build first):** a function that injects fake packets directly into the app's data-processing layer, bypassing BLE entirely. Fast to iterate on — this is what you'll use daily.
2. **Real BLE peripheral emulator (build later):** a script (e.g. Python using a BLE peripheral library on a laptop/Pi) that actually advertises and sends GATT data, for realistic end-to-end runs closer to launch.

Start with the in-process mock — it unblocks most of your testing immediately.

**Decision needed:** Is your Flutter app's BLE data-handling logic already isolated behind an interface/service class you could inject fake data into directly, or is BLE reading tangled into the UI code? This determines whether the in-process mock is a quick win or needs a small refactor first.

---

## 4. Enumerate the Case Categories

| Category | Example cases |
|---|---|
| **Regular use** | Stable connection, periodic normal-range readings, both models agreeing |
| **Extreme / clinical** | Simulated hypoglycemia, hyperglycemia, rapid swings between readings |
| **Confidence / quality** | Low-confidence inference, device model vs. phone-background model disagreeing, corrupted or missing packet |
| **Connectivity** | Mid-reading disconnect, reconnect, wake/sleep handoff between device and phone models |
| **Signal integrity** | Motion-artifact flag set, poor skin contact, low battery warning from device |
| **Timing** | Burst of packets, delayed packets, out-of-order arrival |

---

## 5. Define Expected Behavior Per Case

For every fixture, write down what "pass" looks like:

- Correct value displayed
- Alert triggered (and which one)
- Background model goes to sleep / wakes at the right moment
- App degrades gracefully on bad data instead of crashing

Without this, the simulator just generates traffic — it doesn't actually test anything.

---

## 6. Automate Execution and Capture Results

Write a runner that loops through the case library, injects each fixture, and checks app state/logs against the expected behavior recorded in step 5.

UI-triggered cases (haptic, visual alerts) may need a manual check pass initially, since asserting on UI state automatically is more work — flag those separately rather than blocking the whole harness on it.

---

## 7. Sequencing (2–3 Week Window)

**Priority 1 (do first):**
- Packet contract definition
- In-process mock
- Regular-use and extreme-case fixtures

This unblocks app testing immediately while hardware work continues in parallel.

**Priority 2 (after core logic is verified):**
- Full BLE peripheral emulator
- Timing and connectivity edge cases
