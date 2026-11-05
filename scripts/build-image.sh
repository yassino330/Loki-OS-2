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
  systemd-sysv initramfs-tools live-boot live-config plymouth plymouth-themes lightdm lightdm-gtk-greeter \
  evtest \
  linux-image-amd64 \
  xserver-xorg xserver-xorg-input-libinput xserver-xorg-input-evdev xserver-xorg-video-fbdev \
  openbox dbus-x11 network-manager network-manager-gnome procps sudo locales pcmanfm xterm xfce4-terminal \
  lxappearance mousepad pavucontrol pipewire-audio wireplumber bluez blueman \
  xfce4-power-manager xfce4-taskmanager xfce4-screenshooter polkitd mate-polkit \
  libgl1-mesa-dri \
  firmware-iwlwifi firmware-realtek firmware-atheros firmware-brcm80211 \
  firmware-mediatek intel-microcode amd64-microcode \
  fonts-dejavu-core fonts-liberation2 fonts-noto-core fonts-noto-color-emoji x11-xserver-utils chromium \
  parted gdisk dosfstools grub-efi-amd64 grub2-common efibootmgr \
  open-vm-tools open-vm-tools-desktop xserver-xorg-video-vmware \
  qt6-qpa-plugins qml6-module-qtquick qml6-module-qtquick-controls \
  qml6-module-qtquick-window qml6-module-qtquick-templates \
  cmake ninja-build g++ qt6-base-dev qt6-declarative-dev qt6-declarative-dev-tools \
  keyboard-configuration console-setup xkb-data xvfb xauth

echo "Building LokiOS Qt desktop shell inside the target root filesystem..."
chroot "$ROOTFS" cmake -S /usr/src/lokios -B /tmp/lokios-build -G Ninja -DCMAKE_BUILD_TYPE=Release
chroot "$ROOTFS" cmake --build /tmp/lokios-build --parallel 2
install -D -m 0755 "$ROOTFS/tmp/lokios-build/lokios" "$ROOTFS/usr/local/bin/lokios"
install -D -m 0755 "$ROOT_DIR/scripts/lokios-install" "$ROOTFS/usr/local/sbin/lokios-install"
install -D -m 0755 "$ROOT_DIR/scripts/lokios-mbr2gpt" "$ROOTFS/usr/local/sbin/lokios-mbr2gpt"
rm -rf "$ROOTFS/usr/src/lokios" "$ROOTFS/tmp/lokios-build"


# Create the live account explicitly; do not depend on live-config defaults.
chroot "$ROOTFS" useradd --create-home --shell /bin/bash --groups audio,video,input,plugdev,netdev,sudo loki
chroot "$ROOTFS" passwd -d loki
chroot "$ROOTFS" passwd -l root

# Run the QML launch test as the real, unprivileged desktop account.
chroot "$ROOTFS" install -d -o loki -g loki -m 0700 /tmp/lokios-test-runtime
echo "Smoke-testing LokiOS as the live user under Xvfb..."
set +e
chroot "$ROOTFS" runuser -u loki -- env HOME=/home/loki XDG_RUNTIME_DIR=/tmp/lokios-test-runtime \
  xvfb-run -a timeout --signal=TERM --kill-after=2s 12s /usr/local/bin/lokios \
  > "$OUTPUT_DIR/lokios-ui-smoke.log" 2>&1
UI_STATUS=$?
set -e
if [[ $UI_STATUS -ne 124 && $UI_STATUS -ne 137 ]]; then
  echo "LokiOS desktop did not remain running as loki (exit $UI_STATUS)." >&2
  cat "$OUTPUT_DIR/lokios-ui-smoke.log" >&2
  exit 1
fi
if grep -Eiq 'QQmlApplicationEngine failed to load component|module .* is not installed|Type .* unavailable|Could not load the Qt platform plugin|Cannot assign to non-existent property' "$OUTPUT_DIR/lokios-ui-smoke.log"; then
  echo "LokiOS desktop reported a QML or Qt runtime error." >&2
  cat "$OUTPUT_DIR/lokios-ui-smoke.log" >&2
  exit 1
fi

# Passwordless local desktop: LightDM logs the live user in automatically, and
# administrative actions launched from the desktop do not prompt for a password.
install -d -m 0750 "$ROOTFS/etc/sudoers.d"
printf '%s\n' 'loki ALL=(root) NOPASSWD: /usr/local/sbin/lokios-install, /usr/local/sbin/lokios-mbr2gpt' > "$ROOTFS/etc/sudoers.d/lokios-loki"
chmod 0440 "$ROOTFS/etc/sudoers.d/lokios-loki"
chroot "$ROOTFS" visudo -cf /etc/sudoers

mkdir -p "$ROOTFS/usr/local/bin" "$ROOTFS/usr/share/xsessions" "$ROOTFS/etc/lightdm/lightdm.conf.d"
cat > "$ROOTFS/usr/local/bin/lokios-session" <<'SESSION'
#!/bin/sh
export XDG_SESSION_TYPE=x11
export QT_QPA_PLATFORM=xcb
openbox-session &
nm-applet --indicator >/dev/null 2>&1 &
blueman-applet >/dev/null 2>&1 &
xfce4-power-manager >/dev/null 2>&1 &
exec /usr/local/bin/lokios
SESSION
chmod 0755 "$ROOTFS/usr/local/bin/lokios-session"

# Make Xorg's keyboard path explicit and install a predictable base keymap.
mkdir -p "$ROOTFS/etc/X11/xorg.conf.d"
cat > "$ROOTFS/etc/X11/xorg.conf.d/40-lokios-input.conf" <<'XORG'
Section "InputClass"
    Identifier "LokiOS keyboard"
    MatchIsKeyboard "on"
    Driver "libinput"
    Option "XkbLayout" "us"
EndSection

Section "InputClass"
    Identifier "LokiOS pointer"
    MatchIsPointer "on"
    Driver "libinput"
EndSection
XORG

cat > "$ROOTFS/usr/share/xsessions/lokios.desktop" <<'DESKTOP'
[Desktop Entry]
Name=LokiOS
Comment=LokiOS Liquid Glass desktop
Exec=/usr/local/bin/lokios-session
Type=Application
DESKTOP

# Put the seat policy in LightDM's primary config so it wins over any
# distro drop-in that might otherwise leave the Debian greeter on screen.
cat > "$ROOTFS/etc/lightdm/lightdm.conf" <<'LIGHTDM'
[LightDM]
start-default-seat=true

[Seat:*]
autologin-user=loki
autologin-user-timeout=0
autologin-session=lokios
user-session=lokios
allow-guest=false
greeter-hide-users=true
LIGHTDM
rm -f "$ROOTFS/etc/lightdm/lightdm.conf.d/50-lokios.conf"
# Fail the image build if the image would fall back to a username/password prompt.
chroot "$ROOTFS" lightdm --show-config > "$OUTPUT_DIR/lightdm-effective.conf" 2>&1
grep -Eq 'autologin-user[[:space:]]*=[[:space:]]*loki' "$OUTPUT_DIR/lightdm-effective.conf" || {
  echo "LightDM autologin for the loki account is not active." >&2
  cat "$OUTPUT_DIR/lightdm-effective.conf" >&2
  exit 1
}
test -x "$ROOTFS/usr/local/bin/lokios-session"
test -f "$ROOTFS/usr/share/xsessions/lokios.desktop"
grep -q '^loki:[^:]*:[0-9][0-9]*:[0-9][0-9]*:' "$ROOTFS/etc/passwd"

cat > "$ROOTFS/etc/initramfs-tools/modules" <<'MODULES'
# Include the keyboard modules in the initramfs so they are loaded before
# LightDM starts, even when udev coldplug is delayed on unusual hardware.
usbhid
hid_generic
xhci_pci
xhci_hcd
i2c_hid
i2c_hid_acpi
atkbd
serio_raw
virtio_input
usb-storage
sd_mod
ahci
nvme
MODULES

# Use Debian's polished spinner Plymouth theme during kernel/initramfs startup.
# Make the graphical desktop the real boot target and explicitly enable its display manager.
chroot "$ROOTFS" systemctl set-default graphical.target
chroot "$ROOTFS" systemctl enable lightdm
chroot "$ROOTFS" systemctl is-enabled lightdm >/dev/null
chroot "$ROOTFS" systemctl enable NetworkManager
chroot "$ROOTFS" systemctl enable bluetooth
chroot "$ROOTFS" systemctl enable vmtoolsd.service

# Only QEMU guests run this serial health check. It confirms the real LightDM
# desktop and waits for an injected keyboard event; physical PCs skip it.
install -D -m 0755 "$ROOT_DIR/scripts/lokios-vm-health" "$ROOTFS/usr/local/sbin/lokios-vm-health"
cat > "$ROOTFS/etc/systemd/system/lokios-vm-health.service" <<'VMHEALTH'
[Unit]
Description=LokiOS virtual-machine desktop and keyboard validation
ConditionVirtualization=vm
After=lightdm.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/lokios-vm-health
TimeoutStartSec=300

[Install]
WantedBy=graphical.target
VMHEALTH
chroot "$ROOTFS" systemctl enable lokios-vm-health.service
chroot "$ROOTFS" plymouth-set-default-theme spinner
mkdir -p "$ROOTFS/etc/plymouth"
cat > "$ROOTFS/etc/plymouth/plymouthd.conf" <<'PLYMOUTH'
[Daemon]
Theme=spinner
ShowDelay=0
DeviceTimeout=8
PLYMOUTH

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
  cmake ninja-build g++ qt6-base-dev qt6-declarative-dev qt6-declarative-dev-tools xvfb xauth
chroot "$ROOTFS" apt-get autoremove -y
chroot "$ROOTFS" apt-get clean
rm -rf "$ROOTFS/var/lib/apt/lists/"*

# Build and package the LokiOS upstream kernel.
chroot "$ROOTFS" update-initramfs -c -k "$KERNEL_RELEASE"
install -m 0644 "$KERNEL_DIR/bzImage" "$ISO_ROOT/live/vmlinuz-$KERNEL_RELEASE"
install -m 0644 "$ROOTFS/boot/initrd.img-$KERNEL_RELEASE" "$ISO_ROOT/live/initrd.img-$KERNEL_RELEASE"

# Ship Debian's hardware-compatibility kernel as a fallback for laptops and
# devices that need drivers outside the compact upstream LokiOS config.
COMPAT_KERNEL="$(find "$ROOTFS/boot" -maxdepth 1 -type f -name 'vmlinuz-*' | sort -V | tail -n1)"
[[ -s "$COMPAT_KERNEL" ]] || { echo "Compatibility kernel was not installed." >&2; exit 1; }
COMPAT_KERNEL_RELEASE="${COMPAT_KERNEL##*/vmlinuz-}"
[[ "$COMPAT_KERNEL_RELEASE" != "$KERNEL_RELEASE" ]] || { echo "Compatibility kernel matches the LokiOS kernel unexpectedly." >&2; exit 1; }
[[ -s "$ROOTFS/boot/initrd.img-$COMPAT_KERNEL_RELEASE" ]] || { echo "Compatibility kernel initramfs is missing." >&2; exit 1; }
chroot "$ROOTFS" update-initramfs -u -k "$COMPAT_KERNEL_RELEASE"
install -m 0644 "$COMPAT_KERNEL" "$ISO_ROOT/live/vmlinuz-$COMPAT_KERNEL_RELEASE"
install -m 0644 "$ROOTFS/boot/initrd.img-$COMPAT_KERNEL_RELEASE" "$ISO_ROOT/live/initrd.img-$COMPAT_KERNEL_RELEASE"

# Never package the host's live pseudo-filesystems into the SquashFS image.
# Unmount in reverse order before measuring or compressing the target root.
cleanup
trap - EXIT

echo "Compressing the trimmed Debian userspace with high-ratio XZ..."
du -shx "$ROOTFS"
mksquashfs "$ROOTFS" "$ISO_ROOT/live/filesystem.squashfs" -comp xz -Xdict-size 100% -b 1M -noappend

cat > "$ISO_ROOT/boot/grub/grub.cfg" <<GRUB
set timeout=4
set default=0

menuentry "LokiOS — Recommended hardware compatibility" {
    linux /live/vmlinuz-$COMPAT_KERNEL_RELEASE boot=live components quiet splash hostname=lokios
    initrd /live/initrd.img-$COMPAT_KERNEL_RELEASE
}

menuentry "LokiOS — Upstream Loki kernel" {
    linux /live/vmlinuz-$KERNEL_RELEASE boot=live components quiet splash hostname=lokios
    initrd /live/initrd.img-$KERNEL_RELEASE
}
GRUB
grub-mkrescue -o "$OUTPUT_DIR/LokiOS-graphical-x86_64.iso" "$ISO_ROOT"
test -s "$OUTPUT_DIR/LokiOS-graphical-x86_64.iso"
echo "Created $OUTPUT_DIR/LokiOS-graphical-x86_64.iso"
