// =====================================================
// Tether Firmware — XIAO nRF52840 (Prototype v1)
// =====================================================
// BLE peripheral that receives command bytes and blinks
// the onboard LED in warn/zap patterns.
//
// Commands (write 1 byte to command characteristic):
//   0x00 = LED off
//   0x01 = Warn: 3x slow blink (500ms on / 500ms off)
//   0x02 = Zap:  10x fast blink (80ms on / 80ms off)
//
// Test with LightBlue app before building iOS app.
// =====================================================

#include <Arduino.h>
#include <bluefruit.h>

// ── BLE UUIDs ────────────────────────────────────────
#define TETHER_SERVICE_UUID   "12345678-1234-1234-1234-123456789ABC" 
#define COMMAND_CHAR_UUID     "12345678-1234-1234-1234-123456789ABD"

// ── LED ──────────────────────────────────────────────
// XIAO nRF52840 onboard LEDs are active LOW
#define LED_PIN       LED_BUILTIN

// ── Command bytes ────────────────────────────────────
#define CMD_OFF   0x00
#define CMD_WARN  0x01
#define CMD_ZAP   0x02

// ── Blink state machine ─────────────────────────────
enum BlinkState { IDLE, BLINK_ON, BLINK_OFF };

BlinkState blinkState       = IDLE;
int        blinkCount       = 0;
int        blinksRemaining  = 0;
uint16_t   blinkOnMs        = 0;
uint16_t   blinkOffMs       = 0;
unsigned long blinkTimer    = 0;

// ── BLE objects ─────────────────────────────────────
BLEService        tetherService(TETHER_SERVICE_UUID);
BLECharacteristic commandChar(COMMAND_CHAR_UUID);

// ── BLE callbacks ───────────────────────────────────
void onConnect(uint16_t conn_handle) {
  Serial.println("[BLE] Connected");
}

void onDisconnect(uint16_t conn_handle, uint8_t reason) {
  Serial.print("[BLE] Disconnected, reason: 0x");
  Serial.println(reason, HEX);
  Serial.println("[BLE] Advertising...");
}

void onCommandWrite(uint16_t conn_handle, BLECharacteristic* chr,
                    uint8_t* data, uint16_t len) {
  if (len < 1) return;
  uint8_t cmd = data[0];

  Serial.print("[CMD] Received: 0x");
  Serial.println(cmd, HEX);

  switch (cmd) {
    case CMD_WARN:
      startBlink(3, 500, 500);
      break;
    case CMD_ZAP:
      startBlink(10, 80, 80);
      break;
    case CMD_OFF:
    default:
      stopBlink();
      break;
  }
}

// ── Blink control ───────────────────────────────────
void startBlink(int count, uint16_t onMs, uint16_t offMs) {
  blinksRemaining = count;
  blinkOnMs       = onMs;
  blinkOffMs      = offMs;
  blinkState      = BLINK_ON;
  blinkTimer      = millis();
  ledOn();
  Serial.print("[LED] Blink pattern: ");
  Serial.print(count);
  Serial.print("x (");
  Serial.print(onMs);
  Serial.print("/");
  Serial.print(offMs);
  Serial.println("ms)");
}

void stopBlink() {
  blinkState      = IDLE;
  blinksRemaining = 0;
  ledOff();
}

void ledOn() {
  digitalWrite(LED_PIN, LOW);   // active LOW on XIAO
}

void ledOff() {
  digitalWrite(LED_PIN, HIGH);  // active LOW on XIAO
}

// ── Setup ───────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  delay(500);  // let serial settle
  Serial.println("=== Tether v1 ===");

  // LED
  pinMode(LED_PIN, OUTPUT);
  ledOff();

  // BLE init
  Bluefruit.begin();
  Bluefruit.setName("Tether");
  Bluefruit.setTxPower(0);
  Bluefruit.Periph.setConnectCallback(onConnect);
  Bluefruit.Periph.setDisconnectCallback(onDisconnect);

  // Service
  tetherService.begin();

  // Command characteristic: write-only, 1 byte
  commandChar.setProperties(CHR_PROPS_WRITE | CHR_PROPS_WRITE_WO_RESP);
  commandChar.setPermission(SECMODE_OPEN, SECMODE_OPEN);
  commandChar.setFixedLen(1);
  commandChar.setWriteCallback(onCommandWrite);
  commandChar.begin();

  // Advertising
  Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
  Bluefruit.Advertising.addService(tetherService);
  Bluefruit.ScanResponse.addName();
  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.setInterval(32, 244);  // fast then slow (20ms / 152.5ms)
  Bluefruit.Advertising.setFastTimeout(30);     // 30s of fast advertising
  Bluefruit.Advertising.start(0);               // advertise forever

  Serial.println("[BLE] Advertising as 'Tether'...");

  // Startup blink to confirm flash worked
  startBlink(2, 200, 200);
}

// ── Loop ────────────────────────────────────────────
void loop() {
  if (blinkState == IDLE) return;

  unsigned long now = millis();

  if (blinkState == BLINK_ON && (now - blinkTimer >= blinkOnMs)) {
    ledOff();
    blinkTimer = now;
    blinksRemaining--;
    if (blinksRemaining <= 0) {
      blinkState = IDLE;
      Serial.println("[LED] Pattern done");
    } else {
      blinkState = BLINK_OFF;
    }
  }

  if (blinkState == BLINK_OFF && (now - blinkTimer >= blinkOffMs)) {
    ledOn();
    blinkTimer = now;
    blinkState = BLINK_ON;
  }
}
