#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/out}"
ROOTFS="$OUTPUT_DIR/rootfs"
ISO_ROOT="$OUTPUT_DIR/iso-root"
KERNEL_DIR="$OUTPUT_DIR/kernel"
KERNEL_RELEASE="$(cat "$KERNEL_DIR/kernel-release.txt")"
ARCHIVE_MIRROR="${DEBIAN_MIRROR:-http://deb.debian.org/debian}"

if [[ $EUID -ne 0 ]]; then
  echo "Run this script as root (the GitHub workflow uses sudo)." >&2
  exit 1
fi
for tool in debootstrap mksquashfs grub-mkrescue; do
  command -v "$tool" >/dev/null || { echo "Missing required tool: $tool" >&2; exit 1; }
done
[[ -s "$KERNEL_DIR/bzImage" ]] || { echo "Kernel image is missing." >&2; exit 1; }
[[ -s "$KERNEL_DIR/modules.tar.gz" ]] || { echo "Kernel modules archive is missing." >&2; exit 1; }
[[ -s "$KERNEL_DIR/kernel-release.txt" ]] || { echo "Kernel release metadata is missing." >&2; exit 1; }

rm -rf "$ROOTFS" "$ISO_ROOT"
mkdir -p "$ROOTFS" "$ISO_ROOT/live" "$ISO_ROOT/boot/grub"

echo "Creating minimal Debian Trixie root filesystem..."
debootstrap --merged-usr --arch=amd64 --variant=minbase --include=apt,ca-certificates,locales trixie "$ROOTFS" "$ARCHIVE_MIRROR"

# Enable Debian's firmware component so real machines can load vendor firmware.
cat > "$ROOTFS/etc/apt/sources.list" <<SOURCES
deb $ARCHIVE_MIRROR trixie main contrib non-free non-free-firmware
deb $ARCHIVE_MIRROR trixie-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
SOURCES

cp /etc/resolv.conf "$ROOTFS/etc/resolv.conf"
mkdir -p "$ROOTFS/usr/src/lokios"
cp "$ROOT_DIR/CMakeLists.txt" "$ROOTFS/usr/src/lokios/"
cp -a "$ROOT_DIR/src" "$ROOTFS/usr/src/lokios/"

tar -xzf "$KERNEL_DIR/modules.tar.gz" -C "$ROOTFS"

cat > "$ROOTFS/etc/hostname" <<'HOST'
lokios
HOST
cat > "$ROOTFS/etc/hosts" <<'HOSTS'
127.0.0.1 localhost
127.0.1.1 lokios
HOSTS

mount --bind /dev "$ROOTFS/dev"
mount --bind /dev/pts "$ROOTFS/dev/pts"
mount -t proc proc "$ROOTFS/proc"
mount -t sysfs sysfs "$ROOTFS/sys"
mount --bind /run "$ROOTFS/run"
cleanup() {
  umount -lf "$ROOTFS/run" 2>/dev/null || true
  umount -lf "$ROOTFS/sys" 2>/dev/null || true
  umount -lf "$ROOTFS/proc" 2>/dev/null || true
  umount -lf "$ROOTFS/dev/pts" 2>/dev/null || true
  umount -lf "$ROOTFS/dev" 2>/dev/null || true
}
trap cleanup EXIT

chroot "$ROOTFS" apt-get update
# Trixie requires merged-/usr. Install the migration package explicitly before
# systemd so the /bin, /sbin and /lib symlinks exist in the target rootfs.
chroot "$ROOTFS" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends usrmerge
for path in bin sbin lib; do
  [[ -L "$ROOTFS/$path" ]] || { echo "Expected merged-/usr symlink missing: /$path" >&2; exit 1; }
done
chroot "$ROOTFS" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  systemd-sysv initramfs-tools live-boot live-config lightdm lightdm-gtk-greeter \
  xserver-xorg-core xserver-xorg-input-libinput xserver-xorg-video-fbdev \
  openbox dbus-x11 network-manager sudo locales pcmanfm xterm lxappearance \
  libgl1-mesa-dri \
  firmware-iwlwifi firmware-realtek firmware-atheros firmware-brcm80211 \
  firmware-mediatek intel-microcode amd64-microcode \
  fonts-dejavu-core x11-xserver-utils \
  parted dosfstools grub-efi-amd64 grub2-common efibootmgr \
  qt6-qpa-plugins qml6-module-qtquick qml6-module-qtquick-controls \
  qml6-module-qtquick-window qml6-module-qtquick-templates \
  cmake ninja-build g++ qt6-base-dev qt6-declarative-dev qt6-declarative-dev-tools

echo "Building LokiOS Qt desktop shell inside the target root filesystem..."
chroot "$ROOTFS" cmake -S /usr/src/lokios -B /tmp/lokios-build -G Ninja -DCMAKE_BUILD_TYPE=Release
chroot "$ROOTFS" cmake --build /tmp/lokios-build --parallel 2
install -D -m 0755 "$ROOTFS/tmp/lokios-build/lokios" "$ROOTFS/usr/local/bin/lokios"
install -D -m 0755 "$ROOT_DIR/scripts/lokios-install" "$ROOTFS/usr/local/sbin/lokios-install"
rm -rf "$ROOTFS/usr/src/lokios" "$ROOTFS/tmp/lokios-build"

# Create the live account explicitly; do not depend on live-config defaults.
chroot "$ROOTFS" useradd --create-home --shell /bin/bash --groups audio,video,plugdev,netdev,sudo loki
echo 'loki:lokios' | chroot "$ROOTFS" chpasswd
chroot "$ROOTFS" passwd -l root

mkdir -p "$ROOTFS/usr/local/bin" "$ROOTFS/usr/share/xsessions" "$ROOTFS/etc/lightdm/lightdm.conf.d"
cat > "$ROOTFS/usr/local/bin/lokios-session" <<'SESSION'
#!/bin/sh
export XDG_SESSION_TYPE=x11
export QT_QPA_PLATFORM=xcb
openbox-session &
exec /usr/local/bin/lokios
SESSION
chmod 0755 "$ROOTFS/usr/local/bin/lokios-session"

cat > "$ROOTFS/usr/share/xsessions/lokios.desktop" <<'DESKTOP'
[Desktop Entry]
Name=LokiOS
Comment=LokiOS Liquid Glass desktop
Exec=/usr/local/bin/lokios-session
Type=Application
DESKTOP

cat > "$ROOTFS/etc/lightdm/lightdm.conf.d/50-lokios.conf" <<'LIGHTDM'
[Seat:*]
autologin-user=loki
autologin-user-timeout=0
user-session=lokios
greeter-session=lightdm-gtk-greeter
LIGHTDM

cat > "$ROOTFS/etc/initramfs-tools/modules" <<'MODULES'
# Built-in live filesystem support is configured in the kernel; force-load
# storage drivers so the live medium is discoverable on different hardware.
usb-storage
sd_mod
ahci
nvme
MODULES

# Keep the live image compact: omit documentation, man pages and package caches.
cat > "$ROOTFS/etc/dpkg/dpkg.cfg.d/01-lokios-small-image" <<'DPKG'
path-exclude=/usr/share/doc/*
path-include=/usr/share/doc/*/copyright
path-exclude=/usr/share/man/*
path-exclude=/usr/share/info/*
path-exclude=/usr/share/locale/*
path-include=/usr/share/locale/en*
DPKG

# Retain Qt runtime modules; remove only build dependencies.
chroot "$ROOTFS" env DEBIAN_FRONTEND=noninteractive apt-get purge -y \
  cmake ninja-build g++ qt6-base-dev qt6-declarative-dev qt6-declarative-dev-tools
chroot "$ROOTFS" apt-get autoremove -y
chroot "$ROOTFS" apt-get clean
rm -rf "$ROOTFS/var/lib/apt/lists/"*

# Include modules needed to mount the compressed live root early.
chroot "$ROOTFS" update-initramfs -c -k "$KERNEL_RELEASE"
install -m 0644 "$KERNEL_DIR/bzImage" "$ISO_ROOT/live/vmlinuz"
install -m 0644 "$ROOTFS/boot/initrd.img-$KERNEL_RELEASE" "$ISO_ROOT/live/initrd.img"

echo "Compressing the trimmed Debian userspace with high-ratio XZ..."
du -sh "$ROOTFS"
mksquashfs "$ROOTFS" "$ISO_ROOT/live/filesystem.squashfs" -comp xz -Xdict-size 100% -b 1M -noappend

cat > "$ISO_ROOT/boot/grub/grub.cfg" <<'GRUB'
set timeout=5
set default=0

menuentry "LokiOS — Graphical Live Desktop" {
    linux /live/vmlinuz boot=live components quiet splash hostname=lokios
    initrd /live/initrd.img
}
GRUB

grub-mkrescue -o "$OUTPUT_DIR/LokiOS-graphical-x86_64.iso" "$ISO_ROOT"
test -s "$OUTPUT_DIR/LokiOS-graphical-x86_64.iso"
echo "Created $OUTPUT_DIR/LokiOS-graphical-x86_64.iso"
