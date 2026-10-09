#!/usr/bin/env python3
"""Drive the Hyprland desktop and the ArchEclipse shell from the 8BitDo gamepad.

Left stick = mouse, right stick = scroll, A/X = left/right click, B = Esc (hold: close window), Y = launcher,
d-pad = focus, LB/RB = workspace, LT/RT = mouse back/forward, Start = overview, Select = control panel, L3 = fullscreen, R3 = screenshot, Mode = turn this on/off.
Stays out of the way while a Steam game is focused (steam_app_*): the pad is only read, never grabbed.
"""
import json
import os
import subprocess
import sys
import time

from evdev import InputDevice, UInput, ecodes as e, list_devices

PAD = "8BitDo Ultimate 2C Wireless Controller"  # shortcut: one pad by name; a second pad needs a list here
QS = ["qs", "-p", os.path.expanduser("~/.config/quickshell/archeclipse"), "ipc", "call", "bar"]
TICK = 0.012  # s between pointer updates
SPEED = 1100.0  # px/s at full deflection
SCROLL = 7.0  # wheel notches/s at full deflection
DEAD = 0.18
HOLD = 0.7  # s: B tapped = Esc, B held this long = close the window


def stick(raw, lo=-32768, hi=32767):
    """-1..1 with a dead zone, squared so small pushes stay precise."""
    v = (raw - (lo + hi) / 2) / ((hi - lo) / 2)
    if abs(v) < DEAD:
        return 0.0
    v = (abs(v) - DEAD) / (1 - DEAD)
    return v * v * (1 if raw >= 0 else -1)


def hypr(expr):
    subprocess.Popen(["hyprctl", "dispatch", expr], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def shell(fn, *args):
    subprocess.Popen(QS + [fn, *args], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


CLICK = {e.BTN_A: e.BTN_LEFT, e.BTN_X: e.BTN_RIGHT, e.ABS_Z: e.BTN_SIDE, e.ABS_RZ: e.BTN_EXTRA}  # triggers: mouse back/forward buttons
ACTION = {
    e.BTN_Y: lambda ui: shell("toggleSearch"),
    e.BTN_TL: lambda ui: hypr('hl.dsp.focus({ workspace = "e-1" })'),
    e.BTN_TR: lambda ui: hypr('hl.dsp.focus({ workspace = "e+1" })'),
    e.BTN_START: lambda ui: shell("toggleOverview"),
    e.BTN_SELECT: lambda ui: shell("toggleControl"),
    e.BTN_THUMBL: lambda ui: hypr('hl.dsp.window.fullscreen({ action = "toggle" })'),
    e.BTN_THUMBR: lambda ui: subprocess.Popen([os.path.expanduser("~/.config/hypr/scripts/screenshot.sh"), "--now"]),
}
DPAD = {(e.ABS_HAT0X, -1): "left", (e.ABS_HAT0X, 1): "right", (e.ABS_HAT0Y, -1): "up", (e.ABS_HAT0Y, 1): "down"}


def tap(ui, key):
    ui.write(e.EV_KEY, key, 1)
    ui.write(e.EV_KEY, key, 0)
    ui.syn()


class Focus:
    """Is the desktop (not a game) what the pad should drive? Cached: this is asked on every event."""

    def __init__(self):
        self.at, self.ok = 0.0, True

    def desktop(self):
        if time.monotonic() - self.at > 0.4:
            self.at = time.monotonic()
            try:
                w = json.loads(subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True, timeout=1).stdout or "{}")
            except (subprocess.SubprocessError, ValueError):
                w = {}
            self.ok = not str(w.get("class", "")).startswith("steam_app_")  # shortcut: only Steam games; a non-Steam fullscreen game would also need this
        return self.ok


def run(pad):
    ui = UInput({e.EV_KEY: [e.BTN_LEFT, e.BTN_RIGHT, e.BTN_SIDE, e.BTN_EXTRA, e.KEY_ESC], e.EV_REL: [e.REL_X, e.REL_Y, e.REL_WHEEL_HI_RES, e.REL_WHEEL]}, name="gamepad-desktop")
    focus, on = Focus(), True
    ax = {e.ABS_X: 0.0, e.ABS_Y: 0.0, e.ABS_RY: 0.0}
    held = set()
    b_down = 0.0
    frac = [0.0, 0.0, 0.0]
    last = time.monotonic()
    try:
        while True:
            try:
                events = list(pad.read())
            except BlockingIOError:
                events = []
            for ev in events:
                if ev.type == e.EV_KEY and ev.code == e.BTN_MODE and ev.value == 1:
                    on = not on
                    subprocess.Popen(["notify-send", "-t", "1500", "Gamepad", "desktop control " + ("on" if on else "off")])
                elif ev.type == e.EV_ABS and ev.code in ax:
                    ax[ev.code] = stick(ev.value)
                elif not (on and focus.desktop()):
                    continue
                elif ev.type == e.EV_ABS and ev.code in (e.ABS_Z, e.ABS_RZ):  # analog 0-255: press past half, let go below a quarter
                    down = ev.value > 128 or (ev.code in held and ev.value > 64)
                    if down != (ev.code in held):
                        ui.write(e.EV_KEY, CLICK[ev.code], int(down))
                        ui.syn()
                        (held.add if down else held.discard)(ev.code)
                elif ev.type == e.EV_KEY and ev.code in CLICK:
                    ui.write(e.EV_KEY, CLICK[ev.code], ev.value)
                    ui.syn()
                    (held.add if ev.value else held.discard)(ev.code)
                elif ev.type == e.EV_KEY and ev.code == e.BTN_B:
                    if ev.value == 1:
                        b_down = time.monotonic()
                    elif b_down:
                        if time.monotonic() - b_down < HOLD:
                            tap(ui, e.KEY_ESC)
                        else:
                            hypr("hl.dsp.window.close()")
                        b_down = 0.0
                elif ev.type == e.EV_KEY and ev.value == 1 and ev.code in ACTION:
                    ACTION[ev.code](ui)
                elif ev.type == e.EV_ABS and (ev.code, ev.value) in DPAD:
                    hypr('hl.dsp.focus({ direction = "%s" })' % DPAD[(ev.code, ev.value)])
            now = time.monotonic()
            dt, last = now - last, now
            if on and focus.desktop() and (ax[e.ABS_X] or ax[e.ABS_Y] or ax[e.ABS_RY]):
                for i, (code, v, k) in enumerate(((e.REL_X, ax[e.ABS_X], SPEED), (e.REL_Y, ax[e.ABS_Y], SPEED), (e.REL_WHEEL, -ax[e.ABS_RY], SCROLL))):
                    frac[i] += v * k * dt
                    step = int(frac[i])
                    frac[i] -= step
                    if step:
                        ui.write(e.EV_REL, code, step)
                ui.syn()
            elif held and not (on and focus.desktop()):  # focus moved to a game mid-click: let go
                for code in list(held):
                    ui.write(e.EV_KEY, CLICK[code], 0)
                    held.discard(code)
                ui.syn()
            time.sleep(TICK)
    finally:
        ui.close()


def main():
    while True:
        pads = [d for d in map(InputDevice, list_devices()) if d.name == PAD]
        if not pads:
            time.sleep(3)  # asleep or unplugged: look again
            continue
        pad = pads[0]
        os.set_blocking(pad.fd, False)
        try:
            run(pad)
        except OSError:
            time.sleep(1)  # pad vanished mid-read


def selftest():
    assert stick(0) == 0.0 and stick(-32768) == -1.0 and stick(32767) == 1.0
    assert 0 < stick(32767 // 2) < 0.5  # squared: half push is well under half speed
    assert stick(2000) == 0.0  # inside the dead zone
    print("selftest ok")


if __name__ == "__main__":
    selftest() if "--selftest" in sys.argv else main()
