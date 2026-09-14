# ESP32-C3 Super Mini - Glucose Wearable Firmware & Inference Simulator

This firmware turns your **ESP32-C3 Super Mini** development board into a standalone wearable prototype that pairs over-the-air with the **Glucose App** running on your Android/iOS phone.

---

## 🛠 Features

1. **BLE GATT Server**:
   - Primary Service UUID: `0000a000-0000-1000-8000-00805f9b34fb`
   - Reading Characteristic: `0000a001-0000-1000-8000-00805f9b34fb` (Notify + Read)
   - Session ID & Heartbeat: `0000a002-0000-1000-8000-00805f9b34fb` (Notify + Read)
   - Standard Battery Service: `0x180F` / `0x2A19` (Notify + Read)
2. **Realistic Physiological Inference Simulation**:
   - Random-walk physiological drift engine (Gaussian noise + trend drift) generating realistic **Normal** (70–180 mg/dL), **Hypoglycemic** (<70 mg/dL), and **Hyperglycemic** (>180 mg/dL) excursions.
   - Dynamic ML confidence estimation (88%–98%).
3. **Multi-Screen OLED Display (SSD1306 128x64 or 128x32)**:
   - **Waiting for Pair**: Animated radar bar, device name (`Glucose Wearable`), session ID, and battery.
   - **Pair Successful & Live Broadcast**: Real-time glucose reading in large font, classification badge (`[LOW]`, `[NORMAL]`, `[HIGH]`), live sparkline trend graph, packet counter, and rate-of-change indicator (`RISE ^`, `FALL v`, `STEADY -`).
   - **Disconnected**: Automatic return to broadcast mode.
4. **Serial Diagnostics**:
   - Detailed live logging at 115200 baud.

---

## 🔌 Hardware Wiring (ESP32-C3 Super Mini)

| OLED Pin (SSD1306) | ESP32-C3 Super Mini Pin | Notes |
| :--- | :--- | :--- |
| **VCC** | **3.3V** | Power (3.3V) |
| **GND** | **GND** | Ground |
| **SDA** | **GPIO 8** (or GPIO 4) | I2C Data (`I2C_SDA_PIN`) |
| **SCL** | **GPIO 9** (or GPIO 5) | I2C Clock (`I2C_SCL_PIN`) |

> *Note: If your board uses GPIO 4 & 5 for I2C, change `#define I2C_SDA_PIN 4` and `#define I2C_SCL_PIN 5` at the top of the code.*

---

## 📦 Arduino IDE Setup

1. **Install ESP32 Board Support**:
   - In Arduino IDE, go to **File** -> **Preferences** -> **Additional Board Manager URLs**:
     ```
     https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
     ```
   - Go to **Tools** -> **Board** -> **Boards Manager** -> Search for **`esp32` by Espressif** -> Click **Install**.

2. **Select Board**:
   - **Tools** -> **Board** -> **ESP32C3 Dev Module** (or **ESP32-C3**).
   - **USB CDC On Boot**: `Enabled`
   - **Flash Size**: `4MB`
   - **Upload Speed**: `921600` (or `460800`)

3. **Install Required Libraries**:
   - In Arduino IDE, open **Sketch** -> **Include Library** -> **Manage Libraries...**:
     - Search **`Adafruit SSD1306`** -> Click **Install All** (this also installs `Adafruit GFX Library`).

4. **Upload & Run**:
   - Open [`arduino.txt`](file:///c:/Glucose_App/arduino.txt) or [`firmware/esp32_c3_glucose_wearable/esp32_c3_glucose_wearable.ino`](file:///c:/Glucose_App/firmware/esp32_c3_glucose_wearable/esp32_c3_glucose_wearable.ino).
   - Select your COM port under **Tools** -> **Port**.
   - Click **Upload**.
   - Open **Serial Monitor** at **115200 baud**.

---

## 📱 Testing with the Flutter App

1. Power on the ESP32-C3 board (OLED displays `"READY TO PAIR"`).
2. On your phone, open the **Glucose App** -> Go to **Device** tab.
3. Tap **Scan for device**.
4. Select **`⭐ Glucose Wearable`** -> Tap **Connect**.
5. The ESP32 OLED display switches to **PAIRED** and streams real-time glucose values to the phone's **Now Screen** and **History Screen**.
