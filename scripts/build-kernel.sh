#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WORK_DIR:-$ROOT_DIR/.kernel-work}"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/out/kernel}"
KERNEL_BRANCH="${KERNEL_BRANCH:-linux-6.12.y}"
JOBS="${JOBS:-2}"

mkdir -p "$WORK_DIR" "$OUTPUT_DIR"

if [[ ! -d "$WORK_DIR/linux/.git" ]]; then
  git clone --depth 1 --branch "$KERNEL_BRANCH" \
    https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git \
    "$WORK_DIR/linux"
else
  git -C "$WORK_DIR/linux" fetch --depth 1 origin "$KERNEL_BRANCH"
  git -C "$WORK_DIR/linux" checkout -B "$KERNEL_BRANCH" FETCH_HEAD
fi

cd "$WORK_DIR/linux"
make x86_64_defconfig
"$ROOT_DIR/scripts/config" --file .config --enable CONFIG_EFI_STUB
"$ROOT_DIR/scripts/config" --file .config --enable CONFIG_BLK_DEV_INITRD
"$ROOT_DIR/scripts/config" --file .config --enable CONFIG_DEVTMPFS
"$ROOT_DIR/scripts/config" --file .config --enable CONFIG_DEVTMPFS_MOUNT
"$ROOT_DIR/scripts/config" --file .config --enable CONFIG_EXT4_FS
"$ROOT_DIR/scripts/config" --file .config --enable CONFIG_VFAT_FS
"$ROOT_DIR/scripts/config" --file .config --enable CONFIG_VIRTIO
"$ROOT_DIR/scripts/config" --file .config --enable CONFIG_VIRTIO_PCI
"$ROOT_DIR/scripts/config" --file .config --enable CONFIG_VIRTIO_BLK
"$ROOT_DIR/scripts/config" --file .config --enable CONFIG_VIRTIO_NET
"$ROOT_DIR/scripts/config" --file .config --enable CONFIG_DRM_SIMPLEDRM
make olddefconfig

make -j"$JOBS" bzImage modules
make -j"$JOBS" modules_install INSTALL_MOD_PATH="$OUTPUT_DIR/modules-root"

install -D arch/x86/boot/bzImage "$OUTPUT_DIR/bzImage"
install -D System.map "$OUTPUT_DIR/System.map"
install -D .config "$OUTPUT_DIR/kernel.config"
printf '%s\n' "$KERNEL_BRANCH" > "$OUTPUT_DIR/source-branch.txt"

tar -C "$OUTPUT_DIR/modules-root" -czf "$OUTPUT_DIR/modules.tar.gz" .
rm -rf "$OUTPUT_DIR/modules-root"

echo "Kernel build finished. Artifacts are in: $OUTPUT_DIR"
