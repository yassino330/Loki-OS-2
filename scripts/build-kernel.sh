#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WORK_DIR:-$ROOT_DIR/.kernel-work}"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/out/kernel}"
KERNEL_BRANCH="${KERNEL_BRANCH:-linux-6.12.y}"
KERNEL_COMMIT="${KERNEL_COMMIT:-}"
JOBS="${JOBS:-2}"

mkdir -p "$WORK_DIR" "$OUTPUT_DIR"

if [[ ! -d "$WORK_DIR/linux/.git" ]]; then
  git init "$WORK_DIR/linux"
  git -C "$WORK_DIR/linux" remote add origin https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
fi

if [[ -n "$KERNEL_COMMIT" ]]; then
  if [[ ! "$KERNEL_COMMIT" =~ ^[0-9a-f]{40}$ ]]; then
    echo "KERNEL_COMMIT must be a full 40-character commit SHA" >&2
    exit 2
  fi
  git -C "$WORK_DIR/linux" fetch --depth 1 origin "$KERNEL_COMMIT"
  git -C "$WORK_DIR/linux" checkout --detach FETCH_HEAD
else
  git -C "$WORK_DIR/linux" fetch --depth 1 origin "$KERNEL_BRANCH"
  git -C "$WORK_DIR/linux" checkout --detach FETCH_HEAD
fi

cd "$WORK_DIR/linux"
ACTUAL_COMMIT="$(git rev-parse HEAD)"
if [[ -n "$KERNEL_COMMIT" && "$ACTUAL_COMMIT" != "$KERNEL_COMMIT" ]]; then
  echo "Fetched kernel revision does not match requested revision" >&2
  exit 3
fi

make x86_64_defconfig
scripts/kconfig/merge_config.sh -m .config "$ROOT_DIR/kernel/config.fragment"
make olddefconfig

KERNEL_RELEASE="$(make -s kernelrelease)"
echo "$KERNEL_RELEASE" > "$OUTPUT_DIR/kernel-release.txt"
printf '%s\\n' "$ACTUAL_COMMIT" > "$OUTPUT_DIR/source-commit.txt"

# Use ccache when available; plain GCC remains supported for local builds.
if command -v ccache >/dev/null 2>&1; then
  export CCACHE_DIR="${CCACHE_DIR:-$HOME/.cache/ccache}"
  mkdir -p "$CCACHE_DIR"
  ccache --max-size=2G
  COMPILER="ccache gcc"
else
  COMPILER="gcc"
fi

make -j"$JOBS" CC="$COMPILER" bzImage modules
make -j"$JOBS" CC="$COMPILER" modules_install INSTALL_MOD_PATH="$OUTPUT_DIR/modules-root"

install -D arch/x86/boot/bzImage "$OUTPUT_DIR/bzImage"
install -D System.map "$OUTPUT_DIR/System.map"
install -D .config "$OUTPUT_DIR/kernel.config"
printf '%s\\n' "$KERNEL_BRANCH" > "$OUTPUT_DIR/source-branch.txt"

tar -C "$OUTPUT_DIR/modules-root" -czf "$OUTPUT_DIR/modules.tar.gz" .
rm -rf "$OUTPUT_DIR/modules-root"

echo "Kernel build finished: $KERNEL_RELEASE ($ACTUAL_COMMIT)"
