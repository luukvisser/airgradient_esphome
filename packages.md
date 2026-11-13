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

### `security.yaml`

Security and recovery baseline shared by every device:

- `safe_mode: num_attempts: 5` (ESPHome's default is 10), so a bad update falls back to
  the recovery firmware after 5 failed boots instead of 10.
- **Verified HTTPS** (`verify_ssl: true`) against
  [`certs/ca_bundle.pem`](packages/certs/ca_bundle.pem) only: AirGradient's private root
  CA for `hw.airgradient.com` (the same root AirGradient's own firmware pins) and the
  public roots GitHub Pages uses or may move to, for the update manifest and firmware.
  ESPHome has a single `http_request` component, so one trust list serves both hosts.
  `scripts/check_ca_bundle.sh` checks that both hosts still chain to the bundle and that
  no root expires within a year; CI runs it when the bundle changes and every week.

### `update_check_interval.yaml`

Adds an **Update Check Interval** select that sets how often the device checks GitHub
Pages for new firmware: Off, every 6 hours, every 24 hours (default) or weekly. The
choice is restored after a reboot. Manual checks always work: the update entity in Home
Assistant, the **Firmware Update Check** button, or double-clicking the config button.
Requires an `update:` component with id `firmware_update` in the device YAML.

### `switch_network_services.yaml`

Adds config switches to turn off network services that are not needed once the device is
adopted in Home Assistant, reducing attack surface and network noise:

| Switch           | When off                                                                   |
| ---------------- | -------------------------------------------------------------------------- |
| Web Server       | Stops the HTTP listener on port 80. Turning it back on is always allowed.  |
| Bluetooth        | Stops the BLE stack (Improv Wi-Fi provisioning); Wi-Fi gets the radio.     |
| Fallback Hotspot | No access point + captive portal when Wi-Fi is lost; keeps retrying Wi-Fi. |

All switches default to on and keep their state across reboots. The native API is never
affected, so the services can always be re-enabled from Home Assistant.

- **Only changeable while Home Assistant is connected.** A device used without Home
  Assistant cannot lock itself out, and nobody can flip them through the open web page.
  While Home Assistant is connected the web page can still change them, so turn the web
  server off for full protection. Turning the web server back **on** is always allowed.
  A refused change is logged as a warning; the web page may keep showing the toggle in
  the position you clicked until you reload it.
- **Tip: turn Bluetooth off once the device is set up.** While Bluetooth is on, Wi-Fi
  and Bluetooth share the radio in time slices. After a Bluetooth toggle the Wi-Fi power
  save mode is re-applied (requires [`wifi_power_save.yaml`](#wifi_power_saveyaml)).
- **Fallback Hotspot:** first-time setup (no Wi-Fi configured) always gets the hotspot.
  Turning it off does not stop a hotspot that is already running; it closes once Wi-Fi
  reconnects. While the hotspot is active, the captive portal reopens port 80 regardless
  of the Web Server switch. Turning the switch back on restores the hotspot delay from
  the device YAML's `fallback_ap_timeout_ms` substitution (90 s), the same value
  `wifi: ap: ap_timeout:` uses.

### `wifi_power_save.yaml`

Adds a **Wi-Fi Power Save** select for the radio's power saving: **Off (full power)**,
the default and the most reliable for Home Assistant, the web page and cloud uploads;
**Light**; or **High** (lower power, slower to receive). It applies immediately, is
restored after a reboot and can be changed without Home Assistant. The device YAML's
`wifi: power_save_mode: none` is only the default before the select is restored.

While Bluetooth is on, Wi-Fi and Bluetooth share the radio in time slices, so even "Off"
is not fully awake. The hidden diagnostic sensor **Wi-Fi Power Save (actual)** shows the
mode the radio reports (enable it in Home Assistant to see it); a failure to apply the
mode is logged as an `esp_wifi_set_ps failed` warning. Requires a `wifi:` component with
id `wifi_client`.

### `config_button.yaml`

Wires the physical button (GPIO9, strapping pin) to three gestures:

- **Hold 1–5 s, then release** — initiate SenseAir S8 CO2 manual baseline calibration
  (position the device outdoors or near an open window for 5+ minutes first).
- **Hold ~8 s** — factory reset (wipes preferences and restarts); a warning is logged at
  2 s so the hold can be released to cancel.
- **Double-click** — check for a firmware update and install it if a newer version is
  available (downloads, flashes, and reboots; a no-op when already up to date). Uses the
  `firmware_update` component from the device YAML.

A short single tap performs no action. The temperature display unit (°C / °F) is changed
with the **Display Temperature Unit** select in Home Assistant / the web UI, not the
button.

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

- **CO2 offset** — ppm added to every reading (default +27 for new devices). The S8's
  calibration target is a fixed 400 ppm, while outdoor air is now about 425–430 ppm.
- **Pressure compensation** — local air pressure in hPa. The S8 reads 1.6 % high per kPa
  above 101.3 kPa and does not correct for it. Only the part of the reading above 400
  ppm is scaled, because ABC and background calibration already pin fresh air to 400 ppm
  at the local pressure. The default 1013.25 hPa leaves readings unchanged. The value is
  not stored on the device, so push it from Home Assistant.

  Use **station pressure** (what a sensor in the room measures, e.g. an Aqara T1 or a
  BME280), not the sea-level-adjusted pressure most weather integrations report. Replace
  both entity IDs with your own; the second one depends on the device's friendly name:

  ```yaml
  automation:
    - alias: "Push pressure to AirGradient CO2 compensation"
      triggers:
        - trigger: state
          entity_id: sensor.aqara_t1_pressure
        - trigger: homeassistant
          event: start
        - trigger: state # the device restarted and lost the value
          entity_id: number.ag_one_senseair_s8_co2_pressure_compensation
          from: unavailable
      conditions:
        - condition: template # skip 'unavailable'/'unknown' and out-of-range values
          value_template: >
            {{ states('sensor.aqara_t1_pressure') | is_number and
               800 <= states('sensor.aqara_t1_pressure') | float <= 1100 }}
      actions:
        - action: number.set_value
          target:
            entity_id: number.ag_one_senseair_s8_co2_pressure_compensation
          data:
            value: "{{ states('sensor.aqara_t1_pressure') | float | round(1) }}"
  ```

- **ABC interval** — Automatic Baseline Correction period (7, 14, 30, 90, or 180 days;
  default 14). Each period the sensor nudges its **lowest** reading towards 400 ppm, by
  at most about 30–50 ppm. Pick a period in which the room is properly aired out at
  least once; otherwise ABC slowly drags all readings too low.
- **ABC on/off switch** — disable ABC entirely if the device rarely sees
  outdoor-equivalent air. The interval and switch are written to the sensor at boot and
  on change, and only when the sensor holds a different value. A failed write is retried
  once after 5 s.
- **ABC Period (Sensor)** — diagnostic showing the period actually stored in the S8
  (e.g. `14 days`, `Paused`, or `No response`), read back after every change and once a
  day. If it differs from the ABC interval / switch, the sensor did not accept the
  change; toggling the setting or rebooting retries it.
- **Manual calibration button** — sets the current reading to 400 ppm in one step. Put
  the device in steady fresh air for 5+ minutes first. The result appears 70 s later in
  **Calibration Result**: `OK`, `Skipped by sensor` (the S8 refuses when the CO2 level
  is still changing) or `No response`.

### `sensor_sgp41.yaml`

Sensirion SGP41 MOX sensor. Reports VOC index (0–500) and NOx index (0–500) using
Sensirion's on-chip algorithm with temperature/humidity compensation from the SHT40.

The algorithm learning-time offsets are exposed as selects (separate VOC and NOx
controls), configured in **days**: 0.5, 1, 7, 14, or 30 (default 1). Internally each
maps to Sensirion's `learning_time_offset_hours` (× 24; the algorithm forgets past
events after roughly twice the learning time). A longer value makes the index baseline
more stable but slower to adapt; a shorter value tracks daily changes more closely. A
change takes effect at the **next restart**: the sensor only loads its tuning during
start-up. All other tuning parameters are Sensirion's defaults.

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

SH1106 128×64 OLED display with ten independently switchable pages plus a boot page. The
active page is selected via the **Display Page** dropdown in Home Assistant or the web
UI:

| Option (name)               | Contents                                                                                         |
| --------------------------- | ------------------------------------------------------------------------------------------------ |
| AirGradient Default ★       | Compact all-in-one: temp, humidity, CO2 (large), PM2.5 (large), VOC, NOx                         |
| AirGradient Default (Clock) | Same as AirGradient Default, but a clock replaces humidity (top-right) and humidity replaces NOx |
| Env Summary                 | CO2 · PM2.5 · Temperature · Humidity                                                             |
| VOC Summary                 | CO2 · PM2.5 · VOC · NOx                                                                          |
| CO2 & PM2.5                 | CO2 and PM2.5 in large type                                                                      |
| Temp & Humidity             | Temperature and humidity in large type                                                           |
| VOC & NOx                   | VOC index and NOx in large type                                                                  |
| Combo                       | Temp, humidity, PM2.5, CO2, VOC, NOx, AQI                                                        |
| Large Numbers               | CO2, humidity, PM2.5, temp in the largest font (no units)                                        |
| Off                         | Display off                                                                                      |
| _(Boot — startup only)_     | Device name, MAC address, firmware version; auto-dismissed after 10 s                            |

★ default on first boot

Additional controls:

- **Display Contrast %** slider (0–100) — dims the OLED backlight.
- **Temperature unit** — toggle between °C and °F (also controllable via the config
  button).

The **AirGradient Default (Clock)** option renders the same page as **AirGradient
Default** with two cells swapped, driven by the `clock_option`, `clock_format`,
`clock_time_id` and `humidity_label` substitutions at the top of the package. It needs a
time source — see [`time_homeassistant.yaml`](#time_homeassistantyaml) — and shows
`--:--` until the first sync.

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
  # PM2.5 thresholds (compressed to 0–25 µg/m³ range; shared by every PM2.5 view):
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

It also adds a **left LED notification override** — a Home-Assistant-controllable
overlay that lights the leftmost LED (index 0) on top of any mode while it is switched
on:

- **Left LED Notification** switch — ON lights LED 0, OFF returns it to normal (HA calls
  `switch.turn_on` / `switch.turn_off`). No timer; restored after a reboot (default
  off).
- **Left LED Notification Color** light — color-wheel picker, default white (hue only).
- **Left LED Notification Brightness %** number — 0–100 %, default 100 %, decoupled from
  **LED Brightness %** so the overlay can be full brightness on a dimmed bar.
- **Left LED Notification Follow LED Brightness** switch — when on, the overlay tracks
  the bar's **LED Brightness %** instead of the slider (default off). Overlay is a no-op
  while **LED Mode** is Off.

---

## Integrations

### `airgradient_api_esp32-c3.yaml`

Uploads sensor readings to the
[AirGradient Dashboard](https://app.airgradient.com/dashboard) every 1 minute via HTTPS.
A boot POST is sent on startup.

### `time_homeassistant.yaml`

Time source (`id: ha_time`) for the on-screen clock, using the native ESPHome API. Once
the device is adopted into Home Assistant it receives both the current time and HA's
configured timezone automatically, so there is no device-side timezone setting. Only
needed by devices that use the **AirGradient Default (Clock)** display page — included
by `airgradient-one.yaml`, not by the display-less Open Air.

Includes an **Upload to AirGradient Dashboard** toggle switch so data upload can be
disabled without reflashing.

Requires the device's MAC-based serial number to be registered in the AirGradient
account.
