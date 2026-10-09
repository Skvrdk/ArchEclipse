#!/usr/bin/env python3
"""Window drag helper for windeco. stdin: "start ADDR WINX WINY" / "stop". stdout: "ADDR X Y" for every new position.
Reads the pointer and moves the window through Hyprland's socket (no process spawn per move), so window and title strip stay together."""
import glob
import os
import select
import socket
import sys
import time

SOCK = glob.glob(os.environ["XDG_RUNTIME_DIR"] + "/hypr/*/.socket.sock")[0]


def cmd(c):
    s = socket.socket(socket.AF_UNIX)
    s.connect(SOCK)
    s.send(c.encode())
    r = s.recv(4096).decode()
    s.close()
    return r


def cursor():
    x, y = cmd("cursorpos").split(",")
    return int(x), int(y)


def selftest():
    x, y = cursor()
    assert isinstance(x, int) and isinstance(y, int)
    print("selftest ok")


def main():
    drag = None  # (addr, win_x, win_y, ptr_x, ptr_y, last)
    while True:
        r, _, _ = select.select([sys.stdin], [], [], 0.008 if drag else None)
        if r:
            line = sys.stdin.readline()
            if not line:
                return
            parts = line.split()
            if parts[0] == "start":
                px, py = cursor()
                drag = (parts[1], int(parts[2]), int(parts[3]), px, py, None)
            elif parts[0] == "stop":
                drag = None
        if drag:
            addr, wx, wy, px, py, last = drag
            cx, cy = cursor()
            pos = (wx + cx - px, wy + cy - py)
            if pos != last:
                cmd('/dispatch hl.dsp.window.move({ x = %d, y = %d, window = "address:%s" })' % (pos[0], pos[1], addr))
                print("%s %d %d" % (addr, pos[0], pos[1]), flush=True)
                drag = (addr, wx, wy, px, py, pos)


if __name__ == "__main__":
    selftest() if "--selftest" in sys.argv else main()
