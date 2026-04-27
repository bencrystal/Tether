# Tether

> Your phone. Your limits. Your accountability.

Tether is a wearable behavior-modification device paired with a mobile app that delivers a mild electric stimulus when you exceed your self-set social media screen time limits. Built for people who are serious about digital wellness and want real consequences — not just a notification you can swipe away.

---

## How It Works

1. **Set your limits** — Define daily time budgets per app (Instagram, TikTok, X, etc.) in the Tether mobile app.
2. **Wear the device** — The Tether collar/wristband pairs via Bluetooth to your phone.
3. **Hit your limit** — When you exceed a time budget, the device delivers a brief, safe electric pulse.
4. **Stay in control** — All thresholds, intensity levels, and schedules are user-configured.

---

## Components

| Component | Description |
|---|---|
| `firmware/` | Embedded C/C++ firmware for the Tether hardware (nRF52840-based) |
| `mobile/` | React Native mobile app (iOS + Android) |
| `hardware/` | Schematics, PCB layout, BOM |
| `docs/` | Product specs, safety guidelines, API docs |

---

## Hardware

- **MCU**: Nordic nRF52840 (Bluetooth LE)
- **Stimulus**: TENS-based pulse circuit, medically safe ranges
- **Power**: 400 mAh LiPo, USB-C charging
- **Connectivity**: BLE 5.0
- **Form factor**: Adjustable collar + wristband variants

---

## Safety

- All stimulus levels are within TENS therapy safe ranges (< 80mA, < 500V peak)
- Emergency stop: double-tap the device or tap "Stop" in-app
- Intensity levels 1–5 (default: 1)
- Automatic shutoff after 3 pulses without app confirmation
- Not intended for medical use

---

## Getting Started

### Firmware
```bash
cd firmware
# Requires nRF Connect SDK
west build -b nrf52840dk_nrf52840
west flash
```

### Mobile App
```bash
cd mobile
npm install
npx expo start
```

---

## Roadmap

- [ ] BLE pairing + screen time sync (iOS Screen Time API, Android Digital Wellbeing)
- [ ] Per-app time budgets
- [ ] Stimulus delivery + intensity control
- [ ] Streak/reward system
- [ ] Multi-device support (collar + wristband)
- [ ] Companion web dashboard

---

## License

MIT
