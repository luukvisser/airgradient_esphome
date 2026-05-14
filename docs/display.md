# Display pages

The `display_sh1106_multi_page` package drives an SH1106 128×64 OLED. Nine pages are
selectable via the **Display Page** dropdown in Home Assistant or the web UI, plus a
boot page shown automatically at startup.

## Pages

| Page (option name)      | Contents                                                                 |
| ----------------------- | ------------------------------------------------------------------------ |
| AirGradient Default ★   | Compact all-in-one: temp, humidity, CO2 (large), PM2.5 (large), VOC, NOx |
| Env Summary             | CO2 · PM2.5 · Temperature · Humidity                                     |
| VOC Summary             | CO2 · PM2.5 · VOC · NOx                                                  |
| CO2 & PM2.5             | CO2 and PM2.5 in large type                                              |
| Temp & Humidity         | Temperature and humidity in large type                                   |
| VOC & NOx               | VOC index and NOx in large type                                          |
| Combo                   | Temp, humidity, PM2.5, CO2, VOC, NOx, AQI                                |
| Large Numbers           | CO2, humidity, PM2.5, temp in the largest font (no units)                |
| Off                     | Turns the display off                                                    |
| _(Boot — startup only)_ | Device name, MAC address, firmware version; auto-dismissed after 10 s    |

★ default on first boot

## Controls

- **Display Page** — dropdown selector in Home Assistant / web UI.
- **Display Contrast %** — slider (0–100) for screen brightness.
- **Display Temperature Unit** — °C or °F; applied to all pages that show temperature.
