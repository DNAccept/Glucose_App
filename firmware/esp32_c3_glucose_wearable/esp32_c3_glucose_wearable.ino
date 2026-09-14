/*
 * =====================================================================================
 *  ESP32-C3 Super Mini - Glucose Wearable BLE Firmware & Inference Simulator
 * =====================================================================================
 *  Features:
 *    - Full BLE GATT Server matching the Flutter Glucose Monitor App
 *    - Real-time physiological Glucose Random-Walk Drift Simulation (Highs, Lows, Normals)
 *    - Unique Session ID Protocol (0x0000A002) with 1.5s live Heartbeat
 *    - Clean Connection/Disconnection callbacks with auto-readvertise
 *    - I2C OLED Display Support (SSD1306 128x64 or 128x32) + Serial Monitor diagnostics
 *    - Multi-screen states:
 *        1) WAITING FOR PAIR (animated radar & device info)
 *        2) PAIR SUCCESSFUL (connected mobile device name/ID)
 *        3) LIVE INFERENCE BROADCAST (mg/dL, class, confidence, packet counter, graph)
 *        4) DISCONNECTED (instant status alert & restart advertising)
 *
 *  Hardware Pinout (ESP32-C3 Super Mini):
 *    - I2C SDA -> GPIO 8 (or GPIO 4)
 *    - I2C SCL -> GPIO 9 (or GPIO 5)
 *    - OLED VCC -> 3.3V
 *    - OLED GND -> GND
 *    - Onboard Blue LED -> GPIO 8 (Active LOW on most C3 Super Mini boards)
 *
 *  Required Arduino Libraries:
 *    - ESP32 BLE Arduino (Built into ESP32 Board package by Espressif)
 *    - Adafruit SSD1306 (Install via Arduino Library Manager)
 *    - Adafruit GFX Library (Install via Arduino Library Manager)
 * =====================================================================================
 */

#include <Arduino.h>
#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// =====================================================================================
//  PIN & HARDWARE CONFIGURATION
// =====================================================================================
#define I2C_SDA_PIN          8     // Change to 4 if your board uses GPIO 4
#define I2C_SCL_PIN          9     // Change to 5 if your board uses GPIO 5
#define ONBOARD_LED_PIN      8     // Built-in LED on ESP32-C3 Super Mini (Active LOW)

#define SCREEN_WIDTH         128   // OLED display width in pixels
#define SCREEN_HEIGHT        64    // OLED display height (use 32 if you have 128x32)
#define OLED_RESET           -1    // Reset pin # (or -1 if sharing Arduino reset pin)
#define SCREEN_I2C_ADDRESS   0x3C  // Common I2C addresses: 0x3C or 0x3D

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
bool hasDisplay = false;

// =====================================================================================
//  BLE GATT UUID CONTRACT (Matching Flutter App & BleContract)
// =====================================================================================
#define DEVICE_NAME                  "Glucose Wearable"
#define SERVICE_UUID                 "0000a000-0000-1000-8000-00805f9b34fb"
#define READING_CHARACTERISTIC_UUID   "0000a001-0000-1000-8000-00805f9b34fb"
#define SESSION_CHARACTERISTIC_UUID   "0000a002-0000-1000-8000-00805f9b34fb"
#define BATTERY_SERVICE_UUID         "0000180f-0000-1000-8000-00805f9b34fb"
#define BATTERY_LEVEL_CHAR_UUID      "00002a19-0000-1000-8000-00805f9b34fb"

// Glucose Thresholds (mg/dL)
#define LOW_THRESHOLD_MGDL   70.0f
#define HIGH_THRESHOLD_MGDL  180.0f

// Sensor Health & Model Origin Flags
#define FLAG_NONE            0x00
#define MODEL_ON_DEVICE      0x00

// =====================================================================================
//  GLOBAL STATE
// =====================================================================================
BLEServer* pServer = nullptr;
BLECharacteristic* pReadingChar = nullptr;
BLECharacteristic* pSessionChar = nullptr;
BLECharacteristic* pBatteryChar = nullptr;

bool deviceConnected = false;
bool oldDeviceConnected = false;
String connectedClientAddress = "";
uint32_t activeSessionId = 0;
uint16_t packetSequence = 0;
uint8_t batteryLevel = 94;

// Physiological Random Walk State
float currentGlucose = 115.0f;       // Starting glucose mg/dL (Normal)
float driftVelocity = 0.0f;          // Rate of change (mg/dL per step)
int trendDirection = 0;              // -1: descending, 0: stable, 1: ascending
unsigned long targetTrendDuration = 0;
unsigned long lastTrendChangeTime = 0;

// Timing Timers
unsigned long lastInferenceTime = 0;
unsigned long lastHeartbeatTime = 0;
unsigned long lastScreenUpdateTime = 0;
const unsigned long INFERENCE_INTERVAL_MS = 2500;  // Send new reading every 2.5s
const unsigned long HEARTBEAT_INTERVAL_MS = 1500;  // Send session heartbeat every 1.5s
const unsigned long SCREEN_INTERVAL_MS    = 100;   // Refresh UI at 10 FPS

// Historical data points for mini sparkline on OLED (last 16 readings)
#define HISTORY_LEN 16
float glucoseHistory[HISTORY_LEN];
int historyIndex = 0;

// =====================================================================================
//  BLE SERVER CALLBACKS (Connection Lifecycle Management)
// =====================================================================================
class ServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        deviceConnected = true;
        Serial.println();
        Serial.println("==================================================");
        Serial.println(" [BLE] PHONE CONNECTED & PAIRED!");
        Serial.printf (" [BLE] Active Session : 0x%08X\n", activeSessionId);
        Serial.println("==================================================");
    }

    void onDisconnect(BLEServer* pServer) {
        deviceConnected = false;
        Serial.println();
        Serial.println(" [BLE] Mobile device disconnected. Resuming advertisement...");
    }
};

// =====================================================================================
//  BLE CHARACTERISTIC CALLBACKS (Direct GATT Reads by Phone)
// =====================================================================================
class ReadingCharCallbacks : public BLECharacteristicCallbacks {
    void onRead(BLECharacteristic* pCharacteristic) {
        uint8_t payload[8];
        buildReadingPacket(currentGlucose, 95, packetSequence, payload);
        pCharacteristic->setValue(payload, 8);
        Serial.printf(" [GATT Read] Phone read glucose characteristic: %.1f mg/dL\n", currentGlucose);
    }
};

class SessionCharCallbacks : public BLECharacteristicCallbacks {
    void onRead(BLECharacteristic* pCharacteristic) {
        uint8_t sessionPayload[5];
        sessionPayload[0] = activeSessionId & 0xFF;
        sessionPayload[1] = (activeSessionId >> 8) & 0xFF;
        sessionPayload[2] = (activeSessionId >> 16) & 0xFF;
        sessionPayload[3] = (activeSessionId >> 24) & 0xFF;
        sessionPayload[4] = batteryLevel;
        pCharacteristic->setValue(sessionPayload, 5);
        Serial.printf(" [GATT Read] Phone read Session ID: 0x%08X (Batt: %d%%)\n", activeSessionId, batteryLevel);
    }
};

// =====================================================================================
//  PACKET ENCODING (Matches Flutter BleContract & GlucoseReadingCodec)
// =====================================================================================
// Extended 8-byte format:
//   byte 0     : class      (0 = LOW, 1 = NORMAL, 2 = HIGH)
//   byte 1     : confidence (0 - 100)
//   bytes 2..3 : uint16 LE tenths of mg/dL (e.g. 1150 = 115.0 mg/dL)
//   byte 4     : sensor health flags (0x00)
//   byte 5     : model origin (0x00 = On-Device Edge ML)
//   bytes 6..7 : uint16 LE sequence number
void buildReadingPacket(float mgDl, uint8_t confidence, uint16_t seq, uint8_t* outBytes) {
    uint8_t glucoseClass;
    if (mgDl < LOW_THRESHOLD_MGDL) {
        glucoseClass = 0; // LOW
    } else if (mgDl > HIGH_THRESHOLD_MGDL) {
        glucoseClass = 2; // HIGH
    } else {
        glucoseClass = 1; // NORMAL
    }

    uint16_t tenths = (uint16_t)round(mgDl * 10.0f);
    if (confidence > 100) confidence = 100;

    outBytes[0] = glucoseClass;
    outBytes[1] = confidence;
    outBytes[2] = tenths & 0xFF;
    outBytes[3] = (tenths >> 8) & 0xFF;
    outBytes[4] = FLAG_NONE;
    outBytes[5] = MODEL_ON_DEVICE;
    outBytes[6] = seq & 0xFF;
    outBytes[7] = (seq >> 8) & 0xFF;
}

// =====================================================================================
//  REALISTIC PHYSIOLOGICAL GLUCOSE RANDOM-WALK ENGINE
// =====================================================================================
void updatePhysiologicalSimulation() {
    unsigned long now = millis();

    // Change physiological drift trend periodically (every 15 to 30 seconds)
    if (now - lastTrendChangeTime > targetTrendDuration) {
        lastTrendChangeTime = now;
        targetTrendDuration = random(12000, 28000); // 12-28 seconds per trend regime

        int dice = random(0, 100);
        if (currentGlucose > 210.0f) {
            // High -> Tendency to descend back to normal
            trendDirection = -1;
            driftVelocity = -((float)random(15, 35) / 10.0f); // -1.5 to -3.5 mg/dL per step
        } else if (currentGlucose < 65.0f) {
            // Hypo -> Tendency to recover upwards
            trendDirection = 1;
            driftVelocity = ((float)random(15, 35) / 10.0f);  // +1.5 to +3.5 mg/dL per step
        } else if (dice < 25) {
            // 25% chance: Trigger a dip towards Hypoglycemia (< 70)
            trendDirection = -1;
            driftVelocity = -((float)random(18, 38) / 10.0f);
        } else if (dice < 50) {
            // 25% chance: Trigger a post-meal rise towards Hyperglycemia (> 180)
            trendDirection = 1;
            driftVelocity = ((float)random(20, 42) / 10.0f);
        } else {
            // 50% chance: Gentle normal baseline fluctuation
            trendDirection = (random(0, 2) == 0) ? -1 : 1;
            driftVelocity = ((float)random(3, 12) / 10.0f) * trendDirection;
        }
    }

    // Add Gaussian-like micro-fluctuation noise (+/- 0.8 mg/dL)
    float microNoise = ((float)random(-8, 9) / 10.0f);
    currentGlucose += (driftVelocity * 0.7f) + microNoise;

    // Hard physiological clamping (45 mg/dL to 320 mg/dL)
    if (currentGlucose < 45.0f) currentGlucose = 45.0f;
    if (currentGlucose > 320.0f) currentGlucose = 320.0f;

    // Store in historical buffer for sparkline graph
    glucoseHistory[historyIndex] = currentGlucose;
    historyIndex = (historyIndex + 1) % HISTORY_LEN;
}

// =====================================================================================
//  OLED DISPLAY RENDERING (Rich Multi-State Interface)
// =====================================================================================
void drawWaitingForPairScreen() {
    display.clearDisplay();

    // Top Header Bar
    display.fillRect(0, 0, 128, 12, SSD1306_WHITE);
    display.setTextColor(SSD1306_BLACK);
    display.setTextSize(1);
    display.setCursor(4, 2);
    display.print("GLUCOSE WEARABLE");

    // Battery Icon / Percentage
    display.setCursor(96, 2);
    display.printf("%d%%", batteryLevel);

    // Body
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 18);
    display.print("Status: ");
    display.println("READY TO PAIR");

    display.setCursor(0, 30);
    display.printf("Session: 0x%08X\n", activeSessionId);

    // Animated Radar Scanning Bar
    int animPhase = (millis() / 200) % 16;
    display.drawRect(0, 44, 128, 7, SSD1306_WHITE);
    display.fillRect(animPhase * 8, 45, 8, 5, SSD1306_WHITE);

    display.setCursor(6, 55);
    display.print("Open Glucose App...");
    display.display();
}

void drawLiveInferenceScreen() {
    display.clearDisplay();

    // Top Status Header Bar
    display.fillRect(0, 0, 128, 11, SSD1306_WHITE);
    display.setTextColor(SSD1306_BLACK);
    display.setTextSize(1);
    display.setCursor(2, 2);
    display.print("PAIRED");

    display.setCursor(44, 2);
    display.printf("0x%04X", (uint16_t)(activeSessionId & 0xFFFF));

    display.setCursor(96, 2);
    display.printf("%d%%", batteryLevel);

    // Large Glucose Value Display
    display.setTextColor(SSD1306_WHITE);
    display.setTextSize(2);
    display.setCursor(2, 16);
    display.printf("%.1f", currentGlucose);

    display.setTextSize(1);
    display.setCursor(68, 16);
    display.print("mg/dL");

    // Class Badge Box & Label
    const char* classLabel;
    int badgeWidth = 48;
    if (currentGlucose < LOW_THRESHOLD_MGDL) {
        classLabel = "LOW";
        badgeWidth = 32;
    } else if (currentGlucose > HIGH_THRESHOLD_MGDL) {
        classLabel = "HIGH";
        badgeWidth = 36;
    } else {
        classLabel = "NORMAL";
        badgeWidth = 46;
    }

    display.drawRoundRect(68, 26, badgeWidth, 11, 2, SSD1306_WHITE);
    display.setCursor(72, 28);
    display.print(classLabel);

    // Mini Sparkline Graph (Bottom Left)
    int graphX = 0;
    int graphY = 48;
    int graphW = 60;
    int graphH = 15;
    display.drawRect(graphX, graphY, graphW, graphH, SSD1306_WHITE);
    for (int i = 0; i < HISTORY_LEN - 1; i++) {
        int idx1 = (historyIndex + i) % HISTORY_LEN;
        int idx2 = (historyIndex + i + 1) % HISTORY_LEN;
        float v1 = glucoseHistory[idx1];
        float v2 = glucoseHistory[idx2];
        if (v1 > 0 && v2 > 0) {
            int y1 = graphY + graphH - (int)map(constrain((int)v1, 40, 250), 40, 250, 2, graphH - 2);
            int y2 = graphY + graphH - (int)map(constrain((int)v2, 40, 250), 40, 250, 2, graphH - 2);
            int x1 = graphX + (i * (graphW - 2) / (HISTORY_LEN - 1));
            int x2 = graphX + ((i + 1) * (graphW - 2) / (HISTORY_LEN - 1));
            display.drawLine(x1, y1, x2, y2, SSD1306_WHITE);
        }
    }

    // Packet counter & Trend indicator (Bottom Right)
    display.setCursor(68, 44);
    display.printf("TX: #%d", packetSequence);

    display.setCursor(68, 55);
    display.printf("Trend: %s", driftVelocity > 0.5f ? "RISE ^" : (driftVelocity < -0.5f ? "FALL v" : "STEADY -"));

    display.display();
}

void updateOLED() {
    if (!hasDisplay) return;

    if (deviceConnected) {
        drawLiveInferenceScreen();
    } else {
        drawWaitingForPairScreen();
    }
}

// =====================================================================================
//  SETUP INITIALIZATION
// =====================================================================================
void setup() {
    Serial.begin(115200);
    delay(500);

    Serial.println("\n==================================================");
    Serial.println(" ESP32-C3 Glucose Wearable BLE Simulator");
    Serial.println("==================================================");

    // Setup Onboard LED
    pinMode(ONBOARD_LED_PIN, OUTPUT);
    digitalWrite(ONBOARD_LED_PIN, HIGH); // Off initially

    // Initialize I2C and OLED Display
    Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
    if (display.begin(SSD1306_SWITCHCAPVCC, SCREEN_I2C_ADDRESS)) {
        hasDisplay = true;
        display.clearDisplay();
        display.setTextColor(SSD1306_WHITE);
        display.setTextSize(1);
        display.setCursor(10, 20);
        display.println("ESP32-C3 Glucose");
        display.setCursor(10, 35);
        display.println("Initializing BLE...");
        display.display();
        Serial.println(" [OLED] Display initialized successfully.");
    } else {
        Serial.println(" [OLED] No SSD1306 display detected. Continuing in Serial-only mode.");
    }

    // Initialize historical readings buffer
    for (int i = 0; i < HISTORY_LEN; i++) glucoseHistory[i] = currentGlucose;

    // Generate Unique Cryptographic Session ID
    activeSessionId = esp_random();
    Serial.printf(" [Session] Generated Session ID: 0x%08X\n", activeSessionId);

    // Initialize ESP32 BLE Stack
    BLEDevice::init(DEVICE_NAME);
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    // 1. Create Primary Glucose GATT Service
    BLEService* pGlucoseService = pServer->createService(SERVICE_UUID);

    // Glucose Reading Characteristic (Notify + Read)
    pReadingChar = pGlucoseService->createCharacteristic(
        READING_CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_READ |
        BLECharacteristic::PROPERTY_NOTIFY
    );
    pReadingChar->addDescriptor(new BLE2902());
    pReadingChar->setCallbacks(new ReadingCharCallbacks());

    // Session ID & Heartbeat Characteristic (Notify + Read)
    pSessionChar = pGlucoseService->createCharacteristic(
        SESSION_CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_READ |
        BLECharacteristic::PROPERTY_NOTIFY
    );
    pSessionChar->addDescriptor(new BLE2902());
    pSessionChar->setCallbacks(new SessionCharCallbacks());

    // Set initial session payload
    uint8_t initSession[5] = {
        (uint8_t)(activeSessionId & 0xFF),
        (uint8_t)((activeSessionId >> 8) & 0xFF),
        (uint8_t)((activeSessionId >> 16) & 0xFF),
        (uint8_t)((activeSessionId >> 24) & 0xFF),
        batteryLevel
    };
    pSessionChar->setValue(initSession, 5);

    pGlucoseService->start();

    // 2. Create Standard Battery GATT Service (0x180F)
    BLEService* pBatteryService = pServer->createService(BATTERY_SERVICE_UUID);
    pBatteryChar = pBatteryService->createCharacteristic(
        BATTERY_LEVEL_CHAR_UUID,
        BLECharacteristic::PROPERTY_READ |
        BLECharacteristic::PROPERTY_NOTIFY
    );
    pBatteryChar->addDescriptor(new BLE2902());
    pBatteryChar->setValue(&batteryLevel, 1);
    pBatteryService->start();

    // Start BLE Advertising
    BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->addServiceUUID(BATTERY_SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);  // Helper for iPhone/Android connection stability
    pAdvertising->setMinPreferred(0x12);
    BLEDevice::startAdvertising();

    Serial.println(" [BLE] GATT Server active & broadcasting over-the-air!");
    Serial.printf (" [BLE] Device Name       : %s\n", DEVICE_NAME);
    Serial.printf (" [BLE] Primary Service   : %s\n", SERVICE_UUID);
    Serial.println(" [BLE] Waiting for Mobile App to connect...\n");
}

// =====================================================================================
//  MAIN LOOP
// =====================================================================================
void loop() {
    unsigned long now = millis();

    // Handle Connection State Transitions
    if (deviceConnected && !oldDeviceConnected) {
        // Just connected
        oldDeviceConnected = true;
        digitalWrite(ONBOARD_LED_PIN, LOW); // Turn on LED (active low)
    }

    if (!deviceConnected && oldDeviceConnected) {
        // Just disconnected -> delay and re-advertise
        delay(300);
        pServer->startAdvertising();
        Serial.println(" [BLE] Re-opened advertisement for next connection.");
        oldDeviceConnected = false;
        digitalWrite(ONBOARD_LED_PIN, HIGH); // Turn off LED
    }

    // When connected to the phone, stream simulated inference readings & heartbeats
    if (deviceConnected) {
        // 1. Send Simulated Glucose Inference Reading every 2.5s
        if (now - lastInferenceTime >= INFERENCE_INTERVAL_MS) {
            lastInferenceTime = now;
            packetSequence++;

            // Run Random Walk Engine
            updatePhysiologicalSimulation();

            // Build 8-Byte Extended Payload
            uint8_t payload[8];
            uint8_t confidence = random(88, 98);
            buildReadingPacket(currentGlucose, confidence, packetSequence, payload);

            // Transmit BLE Notification to App
            pReadingChar->setValue(payload, 8);
            pReadingChar->notify();

            const char* classStr = (currentGlucose < LOW_THRESHOLD_MGDL) ? "LOW" : 
                                   (currentGlucose > HIGH_THRESHOLD_MGDL) ? "HIGH" : "NORMAL";

            Serial.printf(" -> [TX #%04d] %5.1f mg/dL [%-6s] (Conf: %d%%) | Trend: %+.1f mg/dL\n",
                          packetSequence, currentGlucose, classStr, confidence, driftVelocity);
        }

        // 2. Send 1.5s Session Heartbeat (resets App's real-time watchdog)
        if (now - lastHeartbeatTime >= HEARTBEAT_INTERVAL_MS) {
            lastHeartbeatTime = now;

            uint8_t heartbeatPayload[5] = {
                (uint8_t)(activeSessionId & 0xFF),
                (uint8_t)((activeSessionId >> 8) & 0xFF),
                (uint8_t)((activeSessionId >> 16) & 0xFF),
                (uint8_t)((activeSessionId >> 24) & 0xFF),
                batteryLevel
            };
            pSessionChar->setValue(heartbeatPayload, 5);
            pSessionChar->notify();
        }
    }

    // Refresh OLED Display Screen at 10 FPS
    if (now - lastScreenUpdateTime >= SCREEN_INTERVAL_MS) {
        lastScreenUpdateTime = now;
        updateOLED();
    }

    delay(10);
}
