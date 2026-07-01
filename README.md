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

## Feature comparison

An extensive comparison of every configurable feature, sensor, and toggle across the
three firmwares an AirGradient ONE / Open Air owner is likely to choose between. The
columns are pinned to specific released versions so it is clear what is being compared:

| Column                  | Project                                                                               | Version compared                                         |
| ----------------------- | ------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| **AirGradient (stock)** | [airgradienthq/arduino](https://github.com/airgradienthq/arduino)                     | `3.6.x` (stable `3.6.2`; IAQS/SPS30 pre-releases 3.6.6)  |
| **MallocArray**         | [MallocArray/airgradient_esphome](https://github.com/MallocArray/airgradient_esphome) | `5.3.7`                                                  |
| **This repo**           | [luukvisser/airgradient_esphome](https://github.com/luukvisser/airgradient_esphome)   | `airgradient-one/v1.4.16`, `airgradient-open-air/v1.0.1` |

**Legend for how a setting is changed:**

- ✅ **Runtime** — live control exposed in Home Assistant **and** the ESPHome web server
  (switch / select / number / button). No rebuild, no reflash.
- ⚙️ **Compile-time** — a YAML substitution only. Changing it means editing the config
  and reflashing/OTA.
- 📱 **App / cloud** — set in the AirGradient mobile app, stored on the AirGradient
  server, and pulled by the device on its periodic `GET /config` poll.
- 🔧 **Local REST** — settable on-device via the firmware's `PUT /config` HTTP endpoint
  (no cloud round-trip).
- ❌ — not available. ➖ — not applicable.

> The AirGradient (stock) column reflects settings the firmware reads from the
> AirGradient server config document (the JSON returned by
> `GET https://hw.airgradient.com/sensors/airgradient:<serial>/one/config`, mirrored by
> the local `GET/PUT /config` endpoint). Most stock settings are therefore both 📱 and
> 🔧. MallocArray runtime exposure varies by which optional package you include; cells
> reflect the default device configs shipped in that repo.

### At a glance: compile-time (MallocArray) → runtime (this repo)

The single biggest difference between MallocArray and this repo is **where** you change
a setting. MallocArray exposes many knobs only as YAML substitutions (⚙️) — changing one
means editing the config and **rebuilding + reflashing/OTA**. This repo promotes those
same knobs to live entities (✅) you can change from Home Assistant or the web server
**with no rebuild**. The settings that move from compile-time to runtime:

| Setting                            | MallocArray (compile-time ⚙️)                      | This repo (runtime ✅)                          |
| ---------------------------------- | -------------------------------------------------- | ----------------------------------------------- |
| LED indicator mode                 | ⚙️ fixed by which `led_*.yaml` package you include | ✅ **LED Mode** select — 11 modes, live         |
| CO₂ offset (ppm)                   | ⚙️ `co2_offset` substitution                       | ✅ **CO₂ Offset** number                        |
| CO₂ ABC interval (days)            | ⚙️/❌ fixed default (only on/off exposed)          | ✅ **ABC Interval** select (7/14/30/90/180)     |
| PM2.5 batch / SLR correction       | ⚙️ `pm_2_5_scaling_factor` / `pm_2_5_intercept`    | ✅ **Batch Preset** select                      |
| PM2.5 custom intercept / scaling   | ⚙️ substitutions                                   | ✅ **Intercept** + **Scaling Factor** numbers   |
| VOC learning-time offset           | ⚙️ `voc_learning_time_offset_hours`                | ✅ **VOC Learning Offset** select (days)        |
| NOx learning-time offset           | ⚙️ `nox_learning_time_offset_hours`                | ✅ **NOx Learning Offset** select (days)        |
| Temperature / humidity calibration | ⚙️/fixed (compensation baked in)                   | ✅ per-axis **scale + offset** numbers + resets |
| Display page                       | ⚙️ single- vs multi-page package (auto-rotates)    | ✅ **Display Page** dropdown (9 pages)          |

Everything below repeats these in context alongside the stock-firmware equivalents.

### Supported devices & build

| Device / build option                       | AirGradient (stock) | MallocArray                      | This repo |
| ------------------------------------------- | ------------------- | -------------------------------- | --------- |
| AirGradient ONE — I-9PSL (indoor, ESP32-C3) | ✅                  | ✅                               | ✅        |
| Open Air — O-1PST (outdoor, ESP32-C3)       | ✅                  | ✅                               | ✅        |
| Open Air — O-1PPT (dual PMS5003T)           | ✅                  | ✅ dual-PMS package              | ❌        |
| Open Air Max — O-M-1PPST (SPS30)            | ✅ (3.6.5+)         | ❌                               | ❌        |
| DIY Pro (indoor kit, D1 Mini / Lolin C3)    | ✅ legacy           | ✅ board package                 | ❌        |
| DIY Basic (ESP8266)                         | ✅ legacy           | ✅ `airgradient-basic`           | ❌        |
| Framework                                   | Arduino             | ESP-IDF (C3) / Arduino (ESP8266) | ESP-IDF   |
| CPU clock reduction (80 MHz)                | ❌                  | ⚙️ `cpu_clock_speed_80_mhz`      | ❌        |
| Hardware watchdog                           | ✅                  | ✅                               | ✅        |

### Connectivity & integrations

| Feature                                   | AirGradient (stock)          | MallocArray                             | This repo                               |
| ----------------------------------------- | ---------------------------- | --------------------------------------- | --------------------------------------- |
| AirGradient Dashboard upload              | 📱🔧 `postDataToAirGradient` | ✅ switch                               | ✅ switch                               |
| Home Assistant native API                 | ❌                           | ✅                                      | ✅                                      |
| ESPHome web server                        | ❌                           | ✅ (v2)                                 | ✅ (v3)                                 |
| Read all values over HTTP (REST)          | ✅ `/measures/current`       | ✅ web-server REST (`GET /sensor/<id>`) | ✅ web-server REST (`GET /sensor/<id>`) |
| Control entities over HTTP (REST)         | ✅ `PUT /config`             | ✅ web-server REST (`POST`)             | ✅ web-server REST (`POST`)             |
| AirGradient `/config` schema (read/write) | ✅ built-in                  | ❌ (ESPHome entities instead)           | ❌ (ESPHome entities instead)           |
| MQTT                                      | 📱🔧 `mqttBrokerUrl`         | ❌                                      | ❌                                      |
| Custom server / HTTP domain               | 📱🔧 `httpDomain`            | ❌                                      | ⚙️ URL pinned                           |
| Offline mode                              | 📱🔧 `offlineMode`           | ➖ local                                | ➖ local                                |
| Config source (`local`/`cloud`/`both`)    | 📱🔧 `configurationControl`  | ➖ local                                | ➖ local                                |

### Provisioning & updates

| Feature                                 | AirGradient (stock)         | MallocArray                   | This repo                            |
| --------------------------------------- | --------------------------- | ----------------------------- | ------------------------------------ |
| Wi-Fi AP fallback + captive portal      | ✅                          | ✅                            | ✅                                   |
| Improv BLE provisioning                 | ❌                          | ❌                            | ✅ `esp32_improv`                    |
| Improv Serial provisioning              | ❌                          | ❌                            | ✅ `improv_serial`                   |
| OTA firmware update                     | 📱 cloud OTA                | ✅ ESPHome                    | ✅ `http_request` manifest + ESPHome |
| Automatic new-firmware check            | ✅ polls AirGradient server | ❌ manual (ESPHome dashboard) | ✅ polls manifest every 6 h          |
| Dashboard adoption (`dashboard_import`) | ➖                          | ✅                            | ✅                                   |
| Factory reset                           | 🔧 config / hold            | ✅ button                     | ✅ button                            |
| Safe-mode switch                        | ❌                          | ✅ switch                     | ❌                                   |

### Sensors reported

| Feature                              | AirGradient (stock)    | MallocArray             | This repo              |
| ------------------------------------ | ---------------------- | ----------------------- | ---------------------- |
| PM2.5 / PM10 / PM1.0                 | ✅                     | ✅                      | ✅                     |
| PM2.5 reading precision              | rounded to whole µg/m³ | rounded to whole µg/m³  | ✅ decimal (x.x µg/m³) |
| PM0.3 particle count                 | ✅                     | ✅                      | ✅                     |
| CO₂ (SenseAir S8)                    | ✅                     | ✅                      | ✅                     |
| Temperature & humidity               | ✅                     | ✅                      | ✅                     |
| VOC index / NOx index (SGP41)        | ✅                     | ✅                      | ✅                     |
| PM2.5 AQI (US)                       | 📱 `pmStandard=us-aqi` | ⚙️ `sensor_nowcast_aqi` | ✅ PM2.5 AQI sensor    |
| NowCast AQI                          | ❌                     | ⚙️ `sensor_nowcast_aqi` | ❌                     |
| GO IAQS score (on-device)            | ✅ (3.6.6+)            | ❌                      | ✅ score + summary     |
| Wi-Fi RSSI                           | ✅                     | ✅                      | ✅                     |
| Uptime                               | ✅ boot count          | ✅                      | ✅                     |
| Diagnostics (heap / CPU temp / loop) | limited                | ✅ `diagnostic_esp32`   | ✅ `diagnostic_esp32`  |

### Calibration & correction

| Feature                                   | AirGradient (stock)                    | MallocArray                                   | This repo                                                                |
| ----------------------------------------- | -------------------------------------- | --------------------------------------------- | ------------------------------------------------------------------------ |
| PM measurement standard (µg/m³ vs US AQI) | 📱🔧 `pmStandard`                      | ➖                                            | ➖                                                                       |
| PM2.5 EPA 2021 correction                 | 📱🔧 `corrections.pm02=epa_2021`       | ✅ applied                                    | ✅ applied                                                               |
| PM2.5 batch-specific (SLR) correction     | 📱🔧 `corrections.pm02=slr_*`          | ⚙️ scaling/intercept substitution             | ✅ select: None / 6 presets (`PMS5003_20231030` … `_20250530`); def None |
| PM2.5 custom scaling factor               | 📱🔧 `corrections.pm02.slr`            | ⚙️ substitution                               | ✅ number ×100: 0.001–200, def 100 (= 1.0×)                              |
| PM2.5 custom intercept                    | 📱🔧 `corrections.pm02.slr`            | ⚙️ substitution                               | ✅ number: −10 … 10, def 0                                               |
| PM update / publish interval              | ⚙️ (fixed)                             | ⚙️ `pm_update_interval` (+ extended-life pkg) | ⚙️ `pm_update_interval` 30 s / `pm_publish_interval` 60 s                |
| CO₂ manual calibration (400 ppm)          | 📱🔧 `co2CalibrationRequested`         | ✅ button                                     | ✅ button                                                                |
| CO₂ ABC enable / disable                  | 🔧 (via `abcDays`)                     | ✅ switch                                     | ✅ switch (def on)                                                       |
| CO₂ ABC interval                          | 📱🔧 `abcDays` (0–200, def 8)          | ❌ fixed default                              | ✅ select: 7 / 14 / 30 / 90 / 180 days, def 14                           |
| CO₂ offset (ppm)                          | ❌                                     | ⚙️ `co2_offset`                               | ✅ number: −400 … 400, def 22                                            |
| Temp scale / offset                       | 📱🔧 `corrections.atmp`                | ⚙️ (outdoor compensation applied)             | ✅ scale 0.5–2.0 def 1.0 · offset −10 … 10 °C def 0                      |
| Humidity scale / offset                   | 📱🔧 `corrections.rhum`                | ⚙️ (outdoor compensation applied)             | ✅ scale 0.5–2.0 def 1.0 · offset −20 … 20 % def 0                       |
| Temp/humidity reset to defaults           | ➖                                     | ❌                                            | ✅ reset buttons                                                         |
| Show compensated vs raw on device         | 📱🔧 `monitorDisplayCompensatedValues` | ➖ (both published)                           | ➖ (both published)                                                      |
| VOC learning-time offset                  | 📱🔧 `tvocLearningOffset` (0–720 h)    | ⚙️ `voc_learning_time_offset_hours`           | ✅ select: 0.5 / 1 / 7 / 14 / 30 days, def 1                             |
| NOx learning-time offset                  | 📱🔧 `noxLearningOffset` (0–720 h)     | ⚙️ `nox_learning_time_offset_hours`           | ✅ select: 0.5 / 1 / 7 / 14 / 30 days, def 1                             |

### LED bar

| Feature                                  | AirGradient (stock)                              | MallocArray                                    | This repo                                                                       |
| ---------------------------------------- | ------------------------------------------------ | ---------------------------------------------- | ------------------------------------------------------------------------------- |
| LED bar on / off                         | 📱🔧 `ledBarMode=off`                            | ✅ toggle                                      | ✅ **Off** mode                                                                 |
| LED brightness                           | 📱🔧 `ledBarBrightness` (0–100)                  | ✅ slider                                      | ✅ slider 0–100 %, def 35                                                       |
| Perceptual (gamma) brightness correction | ❌                                               | ❌                                             | ✅                                                                              |
| Edge-fade / bar softening                | ❌                                               | ✅ fade                                        | ✅ **LED Fade %** 0–100, def 15                                                 |
| Mode selectable **at runtime**           | 📱🔧 `ledBarMode`                                | ❌ fixed by which `led_*` package              | ✅ **LED Mode** select (11), def CO₂ Bar                                        |
| CO₂ mode                                 | 📱 `co2`                                         | ⚙️ `led_co2.yaml`                              | ✅                                                                              |
| PM2.5 mode                               | 📱 `pm`                                          | ⚙️ `led_pm25.yaml`                             | ✅                                                                              |
| VOC mode                                 | ❌                                               | ⚙️ `led_tvoc.yaml`                             | ✅                                                                              |
| Combo (CO₂+PM2.5+VOC) modes              | ❌                                               | ⚙️ `led_combo.yaml` (one layout)               | ✅ several layouts                                                              |
| Graduated single-metric bar (fill)       | ❌                                               | ❌                                             | ✅ CO₂ Bar / PM2.5 Bar                                                          |
| Half-lit LED for sub-step resolution     | ❌                                               | ❌                                             | ✅ CO₂ Bar / PM2.5 Bar                                                          |
| GO IAQS LED mode                         | 📱 `iaqs` (3.6.6+)                               | ❌                                             | ✅                                                                              |
| LED test sequence                        | 📱🔧 `ledBarTestRequested`                       | ❌                                             | ✅ **Test** mode                                                                |
| Color thresholds                         | ❌ fixed                                         | ⚙️ substitutions                               | ⚙️ substitutions                                                                |
| LED refresh cadence                      | firmware loop — repainted each measurement cycle | repainted on every sensor publish (`on_value`) | fixed **5 s tick, synced with the display** + instant repaint on control change |

#### LED bar scale & colours

The three firmwares treat the bar very differently:

- **AirGradient (stock)** — the bar **fills** LED-by-LED and snaps through five discrete
  colour bands.
- **MallocArray** — **all LEDs are always lit**; the whole bar shifts colour along a
  continuous gradient (there is no fill), with very loose default thresholds.
- **This repo** — the bar **fills** (with half-LED sub-steps in the Bar modes) along a
  continuous, tight health-based gradient.

**Value at which the bar is fully lit / reaches its top (purple) colour:**

| Metric | AirGradient (stock)                      | MallocArray                            | This repo                                     |
| ------ | ---------------------------------------- | -------------------------------------- | --------------------------------------------- |
| CO₂    | fills; fully lit in top band ≳ 2000 ppm  | always all lit — purple at ≥ 4000 ppm  | all 11 lit at **≥ 1500 ppm** (100 ppm/LED)    |
| PM2.5  | fills; fully lit in top band ≳ 125 µg/m³ | always all lit — purple at ≥ 201 µg/m³ | all 11 lit at **≥ 25 µg/m³** (~2.3 µg/m³/LED) |

**CO₂ colour scale (ppm):**

| Colour      | AirGradient (stock) | MallocArray | This repo |
| ----------- | ------------------- | ----------- | --------- |
| 🟢 Green ≤  | 800                 | 400         | 600       |
| 🟡 Yellow ≤ | 1000                | 1000        | 900       |
| 🟠 Orange ≤ | 1500                | —           | 1000      |
| 🔴 Red ≤    | 2000                | 2000        | 1200      |
| 🟣 Purple ≥ | 2000                | 4000        | 1500      |

**PM2.5 colour scale (µg/m³):**

| Colour      | AirGradient (stock) | MallocArray | This repo (solid / Bar) |
| ----------- | ------------------- | ----------- | ----------------------- |
| 🟢 Green ≤  | 9                   | 0           | 5 / 0                   |
| 🟡 Yellow ≤ | 35                  | 11          | 15 / 5                  |
| 🟠 Orange ≤ | 55                  | —           | 25 / 10                 |
| 🔴 Red ≤    | 125                 | 56          | 35 / 15                 |
| 🟣 Purple ≥ | 125                 | 201         | 55 / 25                 |

> Net effect: MallocArray's defaults only turn the bar red/purple in genuinely extreme
> air (CO₂ 2000–4000 ppm), stock AirGradient reaches red around 1750–2000 ppm, while
> this repo hits purple by 1500 ppm — so on the same air this repo shows the most
> conservative (reddest) colour and MallocArray the most relaxed. AirGradient stock uses
> fixed bands; both ESPHome firmwares interpolate continuously, and this repo's
> thresholds are tunable via substitutions. Stock AirGradient figures are read from the
> firmware source and are approximate discrete bands.

### Display

| Feature                            | AirGradient (stock)                                 | MallocArray                                                        | This repo                                                                                                           |
| ---------------------------------- | --------------------------------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------- |
| OLED display                       | ✅                                                  | ✅                                                                 | ✅                                                                                                                  |
| Brightness / contrast              | 📱🔧 `displayBrightness` (0–100)                    | ✅ contrast slider                                                 | ✅ **Display Contrast %** 0–100, def 35                                                                             |
| Page selectable **at runtime**     | ❌ auto-cycle                                       | ⚙️ single vs multi-page pkg                                        | ✅ **Display Page** dropdown, def AirGradient Default                                                               |
| Number of pages                    | fixed set                                           | up to 7 (multi-page pkg)                                           | 9 pages + boot page                                                                                                 |
| Display refresh cadence            | firmware loop; auto-cycles screens (~5 s)           | ~1 s auto-refresh + **auto-rotates** pages every 5 s (`show_next`) | `update_interval: never` — redrawn on the shared **5 s tick**, selected page only (no rotation) + instant on change |
| Blank / off page (manual)          | 📱🔧 only `displayBrightness=0` (no blank page)     | ✅ selectable **blank** page                                       | ✅ dedicated **Off** page (fills screen black)                                                                      |
| Automatic display off (e.g. night) | 📱 cloud schedule — **online / server-driven only** | ✅ local — Home Assistant automation / ESPHome `time`              | ✅ local — Home Assistant automation / ESPHome `time`                                                               |
| Boot / splash page                 | ✅                                                  | limited                                                            | ✅ (name, MAC, firmware)                                                                                            |
| Temperature unit °C / °F           | 📱🔧 `temperatureUnit` + button                     | ✅ button + runtime                                                | ✅ select °C / °F + button, def °C                                                                                  |

> **Blank vs off, and auto-off.** Stock AirGradient has no dedicated blank/off page —
> the screen is only "hidden" by pushing `displayBrightness` to 0, and any _automatic_
> switch-off (e.g. dimming overnight) is scheduled in the cloud and therefore works
> **only while the monitor is online and talking to the AirGradient server**.
> MallocArray exposes a selectable blank page and this repo adds a dedicated **Off**
> page (it fills the panel black); in both ESPHome firmwares the display runs entirely
> **locally**, so auto-off is driven by a Home Assistant automation or an on-device
> ESPHome `time` schedule with no cloud dependency.

### Physical button

| Feature                       | AirGradient (stock) | MallocArray | This repo |
| ----------------------------- | ------------------- | ----------- | --------- |
| Short press → toggle °C / °F  | ✅                  | ✅          | ✅        |
| Hold → CO₂ manual calibration | ✅                  | ✅          | ✅        |

> **Where the versions diverge in one line:** stock AirGradient centralises
> configuration in the app/cloud (with a local REST mirror) but exposes no Home
> Assistant/web-server controls; MallocArray moves configuration into ESPHome but leaves
> many knobs (LED mode, thresholds, CO₂ offset, learning offsets) as compile-time
> substitutions; this repo promotes those same knobs to **runtime** Home Assistant / web
> UI controls and adds an 11-mode LED selector, a 9-page display selector, and per-axis
> temperature/humidity calibration.

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
