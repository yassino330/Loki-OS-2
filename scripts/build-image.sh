#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/out}"
KERNEL_IMAGE="$OUTPUT_DIR/kernel/bzImage"
ROOTFS="$OUTPUT_DIR/rootfs"
ISO_ROOT="$OUTPUT_DIR/iso-root"
INITRD="$OUTPUT_DIR/initramfs.cpio.gz"

if [[ ! -s "$KERNEL_IMAGE" ]]; then
  echo "Missing kernel image: $KERNEL_IMAGE" >&2
  exit 1
fi
if ! command -v busybox >/dev/null 2>&1; then
  echo "busybox is required (install busybox-static)" >&2
  exit 1
fi
if ! command -v grub-mkrescue >/dev/null 2>&1; then
  echo "grub-mkrescue is required (install grub-pc-bin, grub-common, xorriso)" >&2
  exit 1
fi

rm -rf "$ROOTFS" "$ISO_ROOT"
mkdir -p "$ROOTFS"/{bin,sbin,etc,proc,sys,dev,root,tmp}
chmod 1777 "$ROOTFS/tmp"
install -m 0755 "$(command -v busybox)" "$ROOTFS/bin/busybox"
chroot "$ROOTFS" /bin/busybox --install -s /bin

cat > "$ROOTFS/init" <<'INIT'
#!/bin/sh
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
mount -t proc proc /proc
mount -t sysfs sysfs /sys
echo
echo "===================================="
echo "          Welcome to LokiOS"
echo "   Minimal Linux recovery environment"
echo "===================================="
echo
echo "This is the first bootable LokiOS base."
echo "Type 'poweroff -f' to shut down."
exec /bin/sh
INIT
chmod 0755 "$ROOTFS/init"

(
  cd "$ROOTFS"
  find . -print0 | cpio --null -ov --format=newc 2>/dev/null | gzip -9
) > "$INITRD"

mkdir -p "$ISO_ROOT/boot/grub"
install -m 0644 "$KERNEL_IMAGE" "$ISO_ROOT/boot/vmlinuz"
install -m 0644 "$INITRD" "$ISO_ROOT/boot/initramfs.cpio.gz"

cat > "$ISO_ROOT/boot/grub/grub.cfg" <<'GRUB'
set timeout=5
set default=0

menuentry "LokiOS (minimal x86_64)" {
    linux /boot/vmlinuz console=tty0 console=ttyS0,115200n8
    initrd /boot/initramfs.cpio.gz
}
GRUB

grub-mkrescue -o "$OUTPUT_DIR/LokiOS-minimal-x86_64.iso" "$ISO_ROOT"
echo "Created $OUTPUT_DIR/LokiOS-minimal-x86_64.iso"
