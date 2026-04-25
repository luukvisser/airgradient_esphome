# Packages

This repository uses ESPHome's [packages](https://esphome.io/guides/configuration-types.html#packages) feature. Each file under `packages/` is a self-contained unit of configuration. The device YAML (`airgradient-one.yaml`) composes them via `!include`.

Most packages expose **substitutions** so you can override defaults in your device YAML without editing the package itself.

---

## Board & hardware

### `airgradient_esp32-c3_board.yaml`

Sets the ESP32-C3 DevKit M1 board target with the ESP-IDF framework, and declares the three hardware buses used by the AirGradient ONE:

| Bus | Pins | Connected to |
|-----|------|-------------|
| UART 0 | RX: GPIO0, TX: GPIO1 | SenseAir S8 (CO2) |
| UART 1 | RX: GPIO20, TX: GPIO21 | PMS5003 (PM2.5) |
| I2C | SDA: GPIO7, SCL: GPIO6 | SHT40, SGP41, SH1106 |

### `watchdog.yaml`

Pulses a hardware watchdog pin every 2.5 minutes. If the pulse is missed for ~5 minutes the watchdog IC resets the ESP. Installed on AirGradient ONE and Open Air.

### `diagnostic_esp32.yaml`

Exposes free heap memory, CPU temperature, and ESPHome loop time as diagnostic sensors. Useful for monitoring resource pressure during development.

### `button_factory_reset.yaml`

Adds a button entity that erases all NVS/preferences storage and reboots. Use this if you see persistent warnings about being unable to save preferences.

### `captive_portal.yaml`

Configures a fallback Wi-Fi AP with a captive portal so the device can be re-provisioned without reflashing when Wi-Fi credentials change.

### `config_button.yaml`

Wires the physical button (GPIO9, strapping pin) to two actions:

- **Short press** — toggle temperature display between °C and °F.
- **Hold ≤ 5 s** — initiate SenseAir S8 CO2 manual baseline calibration (position the device outdoors or near an open window for 5+ minutes first).

### `switch_safe_mode.yaml`

Adds a switch that reboots the device into safe mode, which disables most components to allow OTA flashing when a misbehaving component or low-memory condition is blocking normal OTA.

---

## Sensors

### `sensor_pms5003_extended_life.yaml`

Plantower PMS5003 particulate sensor (PM2.5, PM10, PM1.0).

By default the sensor wakes every 2 minutes to take a reading, extending its rated lifespan. The update interval is configurable:

```yaml
substitutions:
  pm_update_interval: "2min"
```

An EPA correction algorithm is applied. Per-device calibration offsets can be set:

```yaml
substitutions:
  pm_2_5_scaling_factor: '1'   # multiplicative correction
  pm_2_5_intercept: '0'        # additive correction (µg/m³)
```

Reports: PM2.5, PM10, PM1.0, PM0.3 particle count.

### `sensor_pms5003t_extended_life.yaml`

Plantower PMS5003T variant that adds temperature and humidity outputs alongside PM measurements. Includes AirGradient's enclosure compensation for the Open Air housing. Same extended duty-cycle and calibration substitutions as `sensor_pms5003_extended_life.yaml`.

### `sensor_s8.yaml`

SenseAir S8 NDIR CO2 sensor.

Reports CO2 concentration. Exposes controls for:

- **CO2 offset** — shift the reading by a known number of ppm (positive or negative):
  ```yaml
  substitutions:
    co2_offset: '0'
  ```
- **ABC interval** — Automatic Baseline Correction period (1, 8, 30, or 90 days; default 8).
- **Manual calibration button** — triggers a background calibration and logs the result 70 s later.
- **ABC on/off switch** — disable ABC entirely if the device rarely sees outdoor-equivalent air.

### `sensor_sgp41.yaml`

Sensirion SGP41 MOX sensor. Reports VOC index (0–500) and NOx index (0–500) using Sensirion's on-chip algorithm with temperature/humidity compensation from the SHT40.

The algorithm learning time offsets are configurable:

```yaml
substitutions:
  # Suggested values: 12, 60, 120, 360, 720 (range: 1–1000 hours)
  voc_learning_time_offset_hours: '12'
  nox_learning_time_offset_hours: '12'
```

### `sensor_sht40.yaml`

Sensirion SHT40 temperature and humidity sensor (I2C address 0x44).

Raw readings are passed through independent linear correction filters. Per-axis calibration controls are exposed to Home Assistant and the web UI:

| Control | Default | Range |
|---------|---------|-------|
| Temperature scale | 1.0 | 0.5 – 2.0 |
| Temperature offset | 0.0 °C | −10 – +10 °C |
| Humidity scale | 1.0 | 0.5 – 2.0 |
| Humidity offset | 0.0 % | −20 – +20 % |

Reset buttons restore each axis to factory defaults (scale 1.0, offset 0.0).

### `sensor_nowcast_aqi.yaml`

Calculates US EPA AQI and NowCast AQI entirely on-device, using a 24-hour rolling window of PM2.5 readings and the 2024 EPA breakpoints. Also emits an AQI category string (Good, Moderate, …, Hazardous). Contributed by [@Ex-Nerd](https://github.com/Ex-Nerd).

### `sensor_wifi.yaml`

Reports Wi-Fi signal strength (RSSI, dBm). Values are always negative; closer to zero means stronger signal.

### `sensor_uptime.yaml`

Reports device uptime in seconds since last boot.

---

## Display

### `display_sh1106_multi_page.yaml`

SH1106 128×64 OLED display with ten independently switchable pages. Each page is toggled by a Home Assistant switch (or the web UI):

| Switch | Page contents |
|--------|--------------|
| Default | Compact layout: temp, humidity, CO2, PM2.5, TVOC, NOx |
| Summary 1 | CO2 · PM2.5 · Temperature · Humidity |
| Summary 2 | CO2 · PM2.5 · VOC · NOx |
| Air Quality | CO2 + PM2.5 in large type |
| Temp & Hum | Temperature + humidity in large type |
| VOC | VOC index + NOx in large type |
| Combo | Mixed full-screen layout |
| Huge (no units) | Four readings in the largest available font |
| Boot | Device MAC address + config version |
| Blank | Display off |

Additional controls:

- **Display Contrast %** slider (0–100) — dims the OLED backlight.
- **Temperature unit** — toggle between °C and °F (also controllable via the config button).

Uses six bitmap fonts (Open Sans regular + bold, sizes 10–34 pt).

---

## LED indicators

### `led.yaml`

Base package for the WS2812 RGB LED strip (11 LEDs, GPIO10). Must be included before any `led_*.yaml` mode package.

Exposes:

- **LED Brightness %** slider (0–100) with gamma 2.0 perceptual correction.
- **LED Fade %** slider (0–100) — dims the outer LEDs of each segment relative to the centre, softening the bar edges.

### `led_combo.yaml`

Multi-mode indicator. Depends on `led.yaml`. Adds a **LED Mode** selector with six options:

| Mode | Behaviour |
|------|-----------|
| **Combo** | LEDs 0–4: CO2 · LEDs 5–9: PM2.5 · LED 10: VOC |
| **CO2** | All 11 LEDs: CO2 |
| **PM2.5** | All 11 LEDs: PM2.5 |
| **VOC** | All 11 LEDs: VOC index |
| **Test** | All LEDs white at full brightness |
| **Off** | All LEDs off |

Color thresholds are configurable via substitutions (defaults follow ASHRAE/WHO/Sensirion guidelines — see `README.md`):

```yaml
substitutions:
  co2_green: '600'
  co2_yellow: '900'
  co2_orange: '1000'
  co2_red: '1200'
  co2_purple: '1500'
  pm_2_5_green: '5'
  pm_2_5_yellow: '15'
  pm_2_5_orange: '25'
  pm_2_5_red: '35'
  pm_2_5_purple: '55'
  voc_green: '100'
  voc_yellow: '200'
  voc_orange: '300'
  voc_red: '400'
  voc_purple: '500'
```

### `led_co2.yaml`

All 11 LEDs reflect CO2 level only (legacy single-sensor mode).

Threshold substitutions:

```yaml
substitutions:
  co2_green: '600'
  co2_yellow: '900'
  co2_orange: '1000'
  co2_red: '1200'
  co2_purple: '1500'
```

### `led_pm25.yaml`

All 11 LEDs reflect PM2.5 level only.

Threshold substitutions:

```yaml
substitutions:
  pm_2_5_green: '5'
  pm_2_5_yellow: '15'
  pm_2_5_orange: '25'
  pm_2_5_red: '35'
  pm_2_5_purple: '55'
```

### `led_tvoc.yaml`

All 11 LEDs reflect VOC index, using a blue-to-purple color scale.

Threshold substitutions:

```yaml
substitutions:
  voc_blue: '50'
  voc_green: '100'
  voc_yellow: '200'
  voc_orange: '300'
  voc_red: '400'
  voc_purple: '500'
```

---

## Integrations

### `airgradient_api_esp32-c3.yaml`

Uploads sensor readings to the [AirGradient Dashboard](https://app.airgradient.com/dashboard) every 2.5 minutes via HTTPS. A boot POST is sent on startup.

Includes a **Send to AirGradient** toggle switch so data upload can be disabled without reflashing.

Requires the device's MAC-based serial number to be registered in the AirGradient account.
