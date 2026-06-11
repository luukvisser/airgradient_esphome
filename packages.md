# Packages

This repository uses ESPHome's
[packages](https://esphome.io/guides/configuration-types.html#packages) feature. Each
file under `packages/` is a self-contained unit of configuration. The device YAML
(`airgradient-one.yaml`) composes them via `!include`.

Most packages expose **substitutions** so you can override defaults in your device YAML
without editing the package itself.

---

## Board & hardware

### `airgradient_esp32-c3_board.yaml`

Sets the ESP32-C3 DevKit M1 board target with the ESP-IDF framework, and declares the
three hardware buses used by the AirGradient ONE:

| Bus    | Pins                   | Connected to         |
| ------ | ---------------------- | -------------------- |
| UART 0 | RX: GPIO0, TX: GPIO1   | SenseAir S8 (CO2)    |
| UART 1 | RX: GPIO20, TX: GPIO21 | PMS5003 (PM2.5)      |
| I2C    | SDA: GPIO7, SCL: GPIO6 | SHT40, SGP41, SH1106 |

### `watchdog.yaml`

Pulses a hardware watchdog pin every 2.5 minutes. If the pulse is missed for ~5 minutes
the watchdog IC resets the ESP. Installed on AirGradient ONE and Open Air.

### `diagnostic_esp32.yaml`

Exposes free heap memory, CPU temperature, and ESPHome loop time as diagnostic sensors.
Useful for monitoring resource pressure during development.

### `button_factory_reset.yaml`

Adds a button entity that erases all NVS/preferences storage and reboots. Use this if
you see persistent warnings about being unable to save preferences.

### `captive_portal.yaml`

Configures a fallback Wi-Fi AP with a captive portal so the device can be re-provisioned
without reflashing when Wi-Fi credentials change.

### `config_button.yaml`

Wires the physical button (GPIO9, strapping pin) to two actions:

- **Short press** — toggle temperature display between °C and °F.
- **Hold ≤ 5 s** — initiate SenseAir S8 CO2 manual baseline calibration (position the
  device outdoors or near an open window for 5+ minutes first).

---

## Sensors

### `sensor_pms5003.yaml`

Plantower PMS5003 particulate sensor (PM2.5, PM10, PM1.0, PM0.3 count).

The sensor is polled every 30 s (fan runs continuously) and PM readings are averaged and
published every 60 s via `throttle_average` filters. Stopping the fan between readings
causes unstable spin-up readings, so a sub-2-minute duty cycle is not used.

An EPA correction algorithm is applied. Per-device calibration controls are exposed:

```yaml
substitutions:
  pm_update_interval: "30s"
  pm_publish_interval: "60s"
```

A **Batch Preset** select lets you apply AirGradient's published batch-specific scaling
factors (post-2023-10-30 batches) without manual tuning. An **Intercept** number and
**Scaling Factor** number allow fully custom calibration.

Reports: PM2.5 (EPA-corrected), PM2.5 Raw, PM10, PM1.0, PM0.3 particle count, PM2.5 AQI.

### `sensor_pms5003t.yaml`

Plantower PMS5003T variant that adds temperature and humidity outputs alongside PM
measurements. Includes AirGradient's enclosure compensation for the Open Air housing.
Same 30 s / 60 s readout cadence and calibration controls as `sensor_pms5003.yaml`.

Used on the AirGradient Open Air in place of `sensor_pms5003.yaml` +
`sensor_sht40.yaml`.

### `sensor_s8.yaml`

SenseAir S8 NDIR CO2 sensor.

Reports CO2 concentration. Exposes controls for:

- **CO2 offset** — shift the reading by a known number of ppm (positive or negative):
  ```yaml
  substitutions:
    co2_offset: "0"
  ```
- **ABC interval** — Automatic Baseline Correction period (7, 14, 30, 90, or 180 days;
  default 14). The sensor re-zeros to the lowest reading seen each period, so a
  weekly/fortnightly cadence matches when a typical home sees fresh air. Use a longer
  interval (or the ABC on/off switch) for rooms that rarely reach outdoor CO2 levels.
- **Manual calibration button** — triggers a background calibration and logs the result
  70 s later.
- **ABC on/off switch** — disable ABC entirely if the device rarely sees
  outdoor-equivalent air.

### `sensor_sgp41.yaml`

Sensirion SGP41 MOX sensor. Reports VOC index (0–500) and NOx index (0–500) using
Sensirion's on-chip algorithm with temperature/humidity compensation from the SHT40.

The algorithm learning-time offsets are exposed as runtime selects (separate VOC and NOx
controls), configured in **days**: 0.5, 1, 7, 14, or 30 (default 1). Internally each
maps to Sensirion's `learning_time_offset_hours` (× 24; the algorithm forgets past
events after roughly twice the learning time). A longer value makes the index baseline
more stable but slower to adapt; a shorter value tracks daily changes more closely.

### `sensor_sht40.yaml`

Sensirion SHT40 temperature and humidity sensor (I2C address 0x44).

Raw readings are passed through independent linear correction filters. Per-axis
calibration controls are exposed to Home Assistant and the web UI:

| Control            | Default | Range        |
| ------------------ | ------- | ------------ |
| Temperature scale  | 1.0     | 0.5 – 2.0    |
| Temperature offset | 0.0 °C  | −10 – +10 °C |
| Humidity scale     | 1.0     | 0.5 – 2.0    |
| Humidity offset    | 0.0 %   | −20 – +20 %  |

Reset buttons restore each axis to factory defaults (scale 1.0, offset 0.0).

### `sensor_go_iaqs.yaml`

Calculates the GO IAQS Starter Score (Global Open Indoor Air Quality Score) entirely
on-device from PM2.5 and CO2 readings. Score runs 0–10 (10 = excellent, 0 = unhealthy).

Categories:

| Score | Category  |
| ----- | --------- |
| 8–10  | Good      |
| 4–7   | Moderate  |
| 0–3   | Unhealthy |

The score is the minimum of the per-pollutant subscores (PM2.5 and CO2), with a −1
synergetic deduction applied when the combined score is ≤ 7. Also emits a **GO IAQS
Summary** text sensor with the category string.

### `sensor_wifi.yaml`

Reports Wi-Fi signal strength (RSSI, dBm). Values are always negative; closer to zero
means stronger signal.

### `sensor_uptime.yaml`

Reports device uptime in seconds since last boot.

---

## Display

### `display_sh1106_multi_page.yaml`

SH1106 128×64 OLED display with nine independently switchable pages plus a boot page.
The active page is selected via the **Display Page** dropdown in Home Assistant or the
web UI:

| Option (name)           | Contents                                                                 |
| ----------------------- | ------------------------------------------------------------------------ |
| AirGradient Default ★   | Compact all-in-one: temp, humidity, CO2 (large), PM2.5 (large), VOC, NOx |
| Env Summary             | CO2 · PM2.5 · Temperature · Humidity                                     |
| VOC Summary             | CO2 · PM2.5 · VOC · NOx                                                  |
| CO2 & PM2.5             | CO2 and PM2.5 in large type                                              |
| Temp & Humidity         | Temperature and humidity in large type                                   |
| VOC & NOx               | VOC index and NOx in large type                                          |
| Combo                   | Temp, humidity, PM2.5, CO2, VOC, NOx, AQI                                |
| Large Numbers           | CO2, humidity, PM2.5, temp in the largest font (no units)                |
| Off                     | Display off                                                              |
| _(Boot — startup only)_ | Device name, MAC address, firmware version; auto-dismissed after 10 s    |

★ default on first boot

Additional controls:

- **Display Contrast %** slider (0–100) — dims the OLED backlight.
- **Temperature unit** — toggle between °C and °F (also controllable via the config
  button).

Uses six bitmap fonts (Open Sans regular + bold, sizes 10–34 pt).

---

## LED indicators

### `led.yaml`

Base package for the WS2812 RGB LED strip (11 LEDs, GPIO10). Must be included before any
`led_*.yaml` mode package.

Exposes:

- **LED Brightness %** slider (0–100) with gamma 2.0 perceptual correction.
- **LED Fade %** slider (0–100) — dims the outer LEDs of each segment relative to the
  centre, softening the bar edges.

### `led_combo.yaml`

Multi-mode indicator. Depends on `led.yaml`. Adds a **LED Mode** selector with eleven
options (default: **CO2 Bar**):

| Mode                 | Behaviour                                                                  |
| -------------------- | -------------------------------------------------------------------------- |
| **5CO2+5PM2.5+1VOC** | LEDs 0–4: CO₂ · LEDs 5–9: PM2.5 · LED 10: VOC                              |
| **5CO2+5PM2.5**      | LEDs 0–4: CO₂ · LEDs 5–9: PM2.5 · LED 10: off                              |
| **5CO2+3PM25+1VOC**  | LEDs 0–4: CO₂ · LEDs 5–7: PM2.5 · LED 9: VOC                               |
| **CO2**              | All 11 LEDs: CO₂                                                           |
| **PM2.5**            | All 11 LEDs: PM2.5                                                         |
| **VOC**              | All 11 LEDs: VOC index                                                     |
| **CO2 Bar** ★        | Bar fills right→left; 1 LED < 600 ppm → 11 at ≥ 1 500 ppm (100 ppm/LED)    |
| **PM2.5 Bar**        | Bar fills right→left; 1 LED < 2.5 µg/m³ → 11 at ≥ 25 µg/m³ (2.5 µg/m³/LED) |
| **GO IAQS**          | Bar fills right→left from score 0–10; LED 10 always off                    |
| **Test**             | All 11 LEDs white at full brightness                                       |
| **Off**              | Strip off                                                                  |

★ default on first boot

Color thresholds are configurable via substitutions:

```yaml
substitutions:
  co2_green: "600"
  co2_yellow: "900"
  co2_orange: "1000"
  co2_red: "1200"
  co2_purple: "1500"
  pm_2_5_green: "5"
  pm_2_5_yellow: "15"
  pm_2_5_orange: "25"
  pm_2_5_red: "35"
  pm_2_5_purple: "55"
  # Bar-specific PM2.5 thresholds (compressed to 0–25 µg/m³ range):
  pm_2_5_bar_green: "0"
  pm_2_5_bar_yellow: "5"
  pm_2_5_bar_orange: "10"
  pm_2_5_bar_red: "15"
  pm_2_5_bar_purple: "25"
  voc_green: "175"
  voc_yellow: "225"
  voc_orange: "300"
  voc_red: "375"
  voc_purple: "475"
```

---

## Integrations

### `airgradient_api_esp32-c3.yaml`

Uploads sensor readings to the
[AirGradient Dashboard](https://app.airgradient.com/dashboard) every 1 minute via HTTPS.
A boot POST is sent on startup.

Includes an **Upload to AirGradient Dashboard** toggle switch so data upload can be
disabled without reflashing.

Requires the device's MAC-based serial number to be registered in the AirGradient
account.
