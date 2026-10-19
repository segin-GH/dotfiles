#!/usr/bin/env python3
# status.py - i3bar status wrapper around i3status.
# Preserves the mouse/keyboard battery segment and makes the wireless
# segment clickable: left-clicking it opens the dmenu Wi-Fi menu.

import json
import os
import subprocess
import sys
import threading
import time

CACHE = "/tmp/.bt_batt_cache"
SCRIPTS = os.path.dirname(os.path.abspath(__file__))
WIFI_MENU = os.path.join(SCRIPTS, "wifi_menu.sh")


def _pct(device):
    try:
        out = subprocess.run(
            ["upower", "-i", device],
            capture_output=True, text=True, timeout=5,
        ).stdout
    except Exception:
        return "?"
    for line in out.splitlines():
        line = line.strip()
        if line.startswith("percentage:"):
            return line.split()[1].rstrip("%")
    return "?"


def get_batt():
    try:
        fresh = time.time() - os.path.getmtime(CACHE) < 60
    except OSError:
        fresh = False
    if not fresh:
        m = _pct("/org/freedesktop/UPower/devices/battery_hidpp_battery_0")
        k = _pct("/org/freedesktop/UPower/devices/keyboard_dev_CA_D7_58_04_03_34")
        try:
            with open(CACHE, "w") as f:
                f.write("m:{}% k:{}%".format(m, k))
        except OSError:
            pass
    try:
        with open(CACHE) as f:
            return f.read()
    except OSError:
        return ""


def handle_clicks():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("name") == "wireless" and ev.get("button") == 1:
            try:
                subprocess.Popen([WIFI_MENU])
            except OSError:
                pass


def main():
    threading.Thread(target=handle_clicks, daemon=True).start()

    proc = subprocess.Popen(["i3status"], stdout=subprocess.PIPE, text=True)
    first = True
    for raw in proc.stdout:
        line = raw.rstrip("\n")
        if line == '{"version":1}' or line in ("[", "[]"):
            print(line, flush=True)
            continue

        data = line[1:] if line.startswith(",") else line
        if data.startswith("["):
            try:
                blocks = json.loads(data)
            except ValueError:
                print(line, flush=True)
                continue
            blocks.insert(0, {
                "name": "bt_batt",
                "full_text": get_batt(),
                "markup": "none",
            })
            prefix = "" if first else ","
            first = False
            print(prefix + json.dumps(blocks, separators=(",", ":")), flush=True)
        else:
            print(line, flush=True)


if __name__ == "__main__":
    main()
