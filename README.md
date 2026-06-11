# AirGradient ESPHome firmware

[![Validate configs](https://github.com/luukvisser/airgradient_esphome/actions/workflows/validate.yml/badge.svg)](https://github.com/luukvisser/airgradient_esphome/actions/workflows/validate.yml)
[![Build firmware](https://github.com/luukvisser/airgradient_esphome/actions/workflows/build-firmware.yml/badge.svg)](https://github.com/luukvisser/airgradient_esphome/actions/workflows/build-firmware.yml)
[![Pre-commit](https://github.com/luukvisser/airgradient_esphome/actions/workflows/pre-commit.yml/badge.svg)](https://github.com/luukvisser/airgradient_esphome/actions/workflows/pre-commit.yml)
[![GitHub release](https://img.shields.io/github/v/release/luukvisser/airgradient_esphome)](https://github.com/luukvisser/airgradient_esphome/releases/latest)
[![Made for ESPHome](https://img.shields.io/badge/Made_for-ESPHome-blue?logo=esphome)](https://esphome.io/guides/made_for_esphome/)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-green.svg)](LICENSE.txt)

ESPHome firmware for **AirGradient** air-quality monitors (ESP32-C3), built on top of
[MallocArray/airgradient_esphome](https://github.com/MallocArray/airgradient_esphome).
Designed to meet the [Made for ESPHome](https://esphome.io/guides/made_for_esphome/)
program requirements.

---

## Install firmware

Flash directly from the browser — no ESPHome or Python installation required:

**<https://luukvisser.github.io/airgradient_esphome/>**

Open the link in Chrome or Edge, plug in your device via USB, and click **Install**. See
[docs/firmware.md](docs/firmware.md) for full instructions and OTA update details.

---

## Documentation

| Topic                      | File                                 |
| -------------------------- | ------------------------------------ |
| Installing firmware        | [docs/firmware.md](docs/firmware.md) |
| LED indicator — all modes  | [docs/led.md](docs/led.md)           |
| Display — all pages        | [docs/display.md](docs/display.md)   |
| Contributing & development | [CONTRIBUTING.md](CONTRIBUTING.md)   |
| Package reference          | [packages.md](packages.md)           |

---

## Supported devices

Every device is declared in [`devices.yaml`](devices.yaml):

- **AirGradient ONE** (`airgradient-one`) — ESP32-C3 indoor monitor (I-9PSL): PM2.5,
  CO₂, VOC/NOx, temperature/humidity, OLED display, RGB LED strip
- **AirGradient Open Air** (`airgradient-open-air`) — ESP32-C3 outdoor monitor (O-1PST):
  PM2.5, CO₂, VOC/NOx, temperature/humidity (via PMS5003T)

---

## Notable changes from upstream

- **LED**: `led_co2` replaced by `led_combo` — eleven selectable modes, health-based
  thresholds, perceptual brightness correction, LED fade effect. See
  [docs/led.md](docs/led.md).
- **Display**: multi-page OLED with nine selectable pages plus a boot page. See
  [docs/display.md](docs/display.md).
- **CI/CD**: full automated release pipeline — `validate.yml`, `build-firmware.yml`,
  `devices.yaml` registry, OTA via `update.http_request`. See
  [CONTRIBUTING.md](CONTRIBUTING.md).
- **Scope**: D1 Mini / ESP8266 support removed; targets ESP32-C3 only.
- **Identity**: `name_add_mac_suffix: true`; project name `luukvisser.airgradient-one`.

---

## Made for ESPHome compliance

| Requirement               | Where it's satisfied                               |
| ------------------------- | -------------------------------------------------- |
| ESP32 / supported variant | Set per device in its `packages/` board file       |
| `project` identification  | `esphome.project` in each device's YAML            |
| Open-source configuration | this repository                                    |
| User-applied updates      | `update.http_request` → per-device `manifest.json` |
| Wi-Fi provisioning (BLE)  | `esp32_improv`                                     |
| Wi-Fi provisioning (USB)  | `improv_serial`                                    |
| Fallback Wi-Fi AP         | `wifi.ap` + `captive_portal`                       |
| Dashboard adoption        | `dashboard_import.package_import_url`              |
| No secrets / static IPs   | credential fields are commented out                |
| IDs on components         | every top-level component has an explicit `id:`    |
