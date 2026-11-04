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
QMP_SOCKET="$TMP_DIR/qmp.sock"
SERIAL_LOG="$TMP_DIR/serial.log"
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
  -vga std -display none -serial "file:$SERIAL_LOG" \
  -qmp "unix:$QMP_SOCKET,server=on,wait=off" \
  -no-reboot -no-shutdown >"$TMP_DIR/qemu.stderr" 2>&1 &
QEMU_PID=$!

cleanup() {
  kill "$QEMU_PID" 2>/dev/null || true
  wait "$QEMU_PID" 2>/dev/null || true
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

set +e
python3 - "$SERIAL_LOG" "$QMP_SOCKET" "$QEMU_PID" <<'PY' | tee -a "$LOG"
import json
import os
import socket
import sys
import time

serial_path, monitor_path = sys.argv[1], sys.argv[2]
qemu_pid = int(sys.argv[3])

def serial_text():
    try:
        with open(serial_path, "r", encoding="utf-8", errors="replace") as handle:
            return handle.read()
    except FileNotFoundError:
        return ""

def ensure_qemu_alive():
    try:
        os.kill(qemu_pid, 0)
    except ProcessLookupError:
        raise RuntimeError("QEMU exited before the LokiOS health checks completed")

def wait_for(marker, failure_marker, seconds, description):
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        ensure_qemu_alive()
        output = serial_text()
        if failure_marker and failure_marker in output:
            raise RuntimeError(f"{description} failed. Serial output:\n{output[-9000:]}")
        if marker in output:
            print(f"PASS: {description}")
            return output
        time.sleep(1)
    output = serial_text()
    raise TimeoutError(f"Timed out waiting for {description}. Serial output:\n{output[-9000:]}")

# This marker is emitted only after systemd has started LightDM, the LokiOS
# process is running, X is available, and the live user has input-device access.
wait_for("LOKIOS_VM_TEST:DESKTOP_READY",
         "LOKIOS_VM_TEST:DESKTOP_FAIL",
         300, "UEFI boot, LightDM autologin and LokiOS desktop")

# The guest health service has now started evtest on all input event nodes.
wait_for("LOKIOS_VM_TEST:KEYBOARD_LISTENING",
         "LOKIOS_VM_TEST:NO_INPUT_EVENTS",
         20, "keyboard event listener")

# Use QMP input-send-event so the virtual key reaches the guest explicitly.
qmp = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
qmp.settimeout(10)
qmp.connect(monitor_path)
stream = qmp.makefile("rwb", buffering=0)
try:
    greeting = json.loads(stream.readline().decode())
    if "QMP" not in greeting:
        raise RuntimeError(f"Unexpected QMP greeting: {greeting}")

    def qmp_call(request_id, command, arguments=None):
        request = {"execute": command, "id": request_id}
        if arguments is not None:
            request["arguments"] = arguments
        stream.write((json.dumps(request) + "\r\n").encode())
        while True:
            raw = stream.readline()
            if not raw:
                raise ConnectionError("QMP socket closed")
            reply = json.loads(raw.decode())
            if reply.get("id") != request_id:
                continue
            if "error" in reply:
                raise RuntimeError(f"QMP {command} failed: {reply['error']}")
            return reply.get("return")

    qmp_call("capabilities", "qmp_capabilities")
    event_down = {"events": [{"type": "key", "data": {
        "down": True, "key": {"type": "qcode", "data": "a"}
    }}]}
    event_up = {"events": [{"type": "key", "data": {
        "down": False, "key": {"type": "qcode", "data": "a"}
    }}]}
    qmp_call("key-down", "input-send-event", event_down)
    time.sleep(0.6)
    qmp_call("key-up", "input-send-event", event_up)
finally:
    stream.close()
    qmp.close()

wait_for("LOKIOS_VM_TEST:KEYBOARD_KEY_A_RECEIVED",
         "LOKIOS_VM_TEST:KEYBOARD_KEY_A_MISSING",
         45, "real keyboard A key-down event")
print("PASS: LokiOS UEFI live desktop and USB keyboard input.")
PY
RESULT=$?
set -e
if [[ $RESULT -ne 0 ]]; then
  echo "UEFI QEMU boot/input test failed." | tee -a "$LOG"
  if [[ -s "$SERIAL_LOG" ]]; then tail -n 180 "$SERIAL_LOG" | tee -a "$LOG"; fi
  if [[ -s "$TMP_DIR/qemu.stderr" ]]; then tail -n 80 "$TMP_DIR/qemu.stderr" | tee -a "$LOG"; fi
  exit "$RESULT"
fi
echo "UEFI QEMU boot and keyboard test passed." | tee -a "$LOG"
