#!/usr/bin/env bash
set -Eeuo pipefail

ISO="${1:-out/LokiOS-graphical-x86_64.iso}"
LOG="${2:-out/qemu-uefi-boot.log}"
[[ -s "$ISO" ]] || { echo "ISO not found: $ISO" >&2; exit 2; }
command -v qemu-system-x86_64 >/dev/null || { echo "qemu-system-x86_64 is required." >&2; exit 2; }
command -v qemu-img >/dev/null || { echo "qemu-img is required." >&2; exit 2; }

OVMF_CODE=""
for candidate in \
  /usr/share/OVMF/OVMF_CODE_4M.fd \
  /usr/share/OVMF/OVMF_CODE.fd \
  /usr/share/edk2/x64/OVMF_CODE.fd; do
  if [[ -s "$candidate" ]]; then OVMF_CODE="$candidate"; break; fi
done
[[ -n "$OVMF_CODE" ]] || { echo "OVMF UEFI firmware was not found." >&2; exit 2; }
OVMF_VARS="${OVMF_CODE/OVMF_CODE/OVMF_VARS}"
[[ -s "$OVMF_VARS" ]] || { echo "Matching OVMF variables template was not found: $OVMF_VARS" >&2; exit 2; }

mkdir -p "$(dirname "$LOG")"
TMP_DIR="$(mktemp -d)"
QGA_SOCKET="$TMP_DIR/qga.sock"
SERIAL_LOG="$TMP_DIR/serial.log"
MONITOR_SOCKET="$TMP_DIR/monitor.sock"
DISK="$TMP_DIR/throwaway.qcow2"
cp "$OVMF_VARS" "$TMP_DIR/OVMF_VARS.fd"
qemu-img create -q -f qcow2 "$DISK" 16G

ACCEL=tcg
if [[ -r /dev/kvm && -w /dev/kvm ]]; then ACCEL=kvm; fi
echo "Booting LokiOS ISO with UEFI/QEMU (accel=$ACCEL)." | tee "$LOG"

qemu-system-x86_64 \
  -machine "q35,accel=$ACCEL" -cpu max -m 4096 -smp 2 \
  -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE" \
  -drive "if=pflash,format=raw,file=$TMP_DIR/OVMF_VARS.fd" \
  -drive "file=$DISK,if=virtio,format=qcow2" \
  -cdrom "$ISO" -boot order=d \
  -device qemu-xhci -device usb-kbd -device usb-tablet \
  -device virtio-serial-pci \
  -chardev "socket,id=qga,path=$QGA_SOCKET,server=on,wait=off" \
  -device virtserialport,chardev=qga,name=org.qemu.guest_agent.0 \
  -vga std -display none -serial "file:$SERIAL_LOG" \
  -monitor "unix:$MONITOR_SOCKET,server=on,wait=off" -no-reboot -no-shutdown \
  >"$TMP_DIR/qemu.stderr" 2>&1 &
QEMU_PID=$!

cleanup() {
  kill "$QEMU_PID" 2>/dev/null || true
  wait "$QEMU_PID" 2>/dev/null || true
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

set +e
python3 - "$QGA_SOCKET" "$QEMU_PID" <<'PY' | tee -a "$LOG"
import base64
import json
import os
import socket
import sys
import time

path, qemu_pid = sys.argv[1], int(sys.argv[2])
next_id = 1

def connect_agent(deadline):
    while time.monotonic() < deadline:
        try:
            os.kill(qemu_pid, 0)
        except ProcessLookupError:
            raise RuntimeError("QEMU exited before the guest agent connected")
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.settimeout(240)
        try:
            sock.connect(path)
            return sock
        except OSError:
            sock.close()
            time.sleep(1)
    raise TimeoutError("QEMU guest agent did not connect; LokiOS may not have booted")

def call(sock, stream, command, arguments=None):
    global next_id
    request_id = next_id
    next_id += 1
    message = {"execute": command, "id": request_id}
    if arguments is not None:
        message["arguments"] = arguments
    stream.write((json.dumps(message) + "\n").encode())
    while True:
        raw = stream.readline()
        if not raw:
            raise ConnectionError("QEMU guest-agent socket closed")
        reply = json.loads(raw.decode())
        if reply.get("id") != request_id:
            continue
        if "error" in reply:
            raise RuntimeError(f"{command}: {reply['error']}")
        return reply.get("return")

sock = connect_agent(time.monotonic() + 240)
try:
    stream = sock.makefile("rwb", buffering=0)
    call(sock, stream, "guest-sync", {"id": 90210})
    call(sock, stream, "guest-ping")

    check = r"""
set -eu
for n in $(seq 1 100); do
  if systemctl is-active --quiet lightdm \
    && pgrep -u loki -x lokios >/dev/null \
    && test -S /tmp/.X11-unix/X0 \
    && id -nG loki | tr ' ' '\n' | grep -qx input \
    && find /dev/input -maxdepth 1 -name 'event*' -print -quit | grep -q .; then
      echo LOKIOS_UEFI_DESKTOP_AND_INPUT_READY
      exit 0
  fi
  sleep 1
done
echo "LightDM: $(systemctl is-active lightdm || true)"
echo "LokiOS process:"
pgrep -a -u loki lokios || true
echo "Input devices:"
find /dev/input -maxdepth 2 -ls 2>/dev/null || true
exit 1
"""
    started = call(sock, stream, "guest-exec", {
        "path": "/bin/bash",
        "arg": ["-lc", check],
        "capture-output": True
    })
    pid = started["pid"]
    deadline = time.monotonic() + 115
    while time.monotonic() < deadline:
        status = call(sock, stream, "guest-exec-status", {"pid": pid})
        if status.get("exited"):
            stdout = base64.b64decode(status.get("out-data", "")).decode(errors="replace")
            stderr = base64.b64decode(status.get("err-data", "")).decode(errors="replace")
            if stdout:
                print(stdout, end="")
            if stderr:
                print(stderr, end="", file=sys.stderr)
            if status.get("exitcode") != 0:
                raise RuntimeError(f"Live desktop/input check failed (exit {status.get('exitcode')})")
            print("PASS: UEFI boot, LightDM autologin, LokiOS desktop process, X display and input devices.")
            break
        time.sleep(2)
    else:
        raise TimeoutError("LokiOS did not reach its graphical desktop/input-ready state within the test window")

    # Read input events from all Linux event devices. The host injects a real
    # A key press through QEMU's monitor; success requires an EV_KEY value=1.
    key_check = r"""
set -eu
DIR=/tmp/lokios-keyboard-test
mkdir -p "$DIR"
rm -f "$DIR"/*.log
found=0
for dev in /dev/input/event*; do
  [ -c "$dev" ] || continue
  evtest "$dev" > "$DIR/$(basename "$dev").log" 2>&1 &
  found=1
done
[ "$found" -eq 1 ] || { echo "No input event devices available"; exit 2; }
sleep 10
pkill -x evtest || true
sleep 1
if grep -Eq 'type 1 \(EV_KEY\), code 30 \(KEY_A\), value 1' "$DIR"/*.log; then
  echo LOKIOS_KEYBOARD_KEY_A_RECEIVED
  exit 0
fi
echo "No KEY_A press event was received. evtest output follows:"
cat "$DIR"/*.log || true
exit 1
"""
    key_started = call(sock, stream, "guest-exec", {
        "path": "/bin/bash",
        "arg": ["-lc", key_check],
        "capture-output": True
    })
    monitor = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    monitor.settimeout(2)
    monitor.connect(os.path.join(os.path.dirname(path), "monitor.sock"))
    try:
        try:
            monitor.recv(4096)
        except socket.timeout:
            pass
        time.sleep(2)
        monitor.sendall(b"sendkey a\n")
    finally:
        monitor.close()

    key_pid = key_started["pid"]
    key_deadline = time.monotonic() + 20
    while time.monotonic() < key_deadline:
        key_status = call(sock, stream, "guest-exec-status", {"pid": key_pid})
        if key_status.get("exited"):
            key_stdout = base64.b64decode(key_status.get("out-data", "")).decode(errors="replace")
            key_stderr = base64.b64decode(key_status.get("err-data", "")).decode(errors="replace")
            if key_stdout:
                print(key_stdout, end="")
            if key_stderr:
                print(key_stderr, end="", file=sys.stderr)
            if key_status.get("exitcode") != 0:
                raise RuntimeError(f"Keyboard event test failed (exit {key_status.get('exitcode')})")
            break
        time.sleep(1)
    else:
        raise TimeoutError("Keyboard event test did not complete")
finally:
    sock.close()
PY
RESULT=$?
set -e
if [[ $RESULT -ne 0 ]]; then
  echo "UEFI QEMU boot test failed." | tee -a "$LOG"
  if [[ -s "$SERIAL_LOG" ]]; then tail -n 120 "$SERIAL_LOG" | tee -a "$LOG"; fi
  if [[ -s "$TMP_DIR/qemu.stderr" ]]; then tail -n 80 "$TMP_DIR/qemu.stderr" | tee -a "$LOG"; fi
  exit "$RESULT"
fi
echo "UEFI QEMU boot test passed." | tee -a "$LOG"
