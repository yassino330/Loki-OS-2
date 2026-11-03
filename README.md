# LokiOS

A Linux desktop project with a minimalist Liquid Glass-inspired interface.

## Current status

The repository contains an early Qt Quick desktop-shell scaffold and a GitHub Actions pipeline intended to build a minimal x86_64 bootable ISO. The first ISO is a text-mode BusyBox recovery environment, not the finished graphical desktop. It is a bootable foundation for bringing up the kernel and userspace.

## Technology

- Upstream Linux 6.12.y kernel with a LokiOS configuration fragment
- Minimal static BusyBox userspace and init script
- GRUB 2 bootloader
- Qt 6.5+ and Qt Quick / QML desktop shell (prototype; not yet integrated into the boot image)

## Build without using your PC storage

GitHub Actions compiles the kernel and assembles the bootable ISO on a GitHub-hosted runner.

1. Open the [Actions page](https://github.com/yassino330/Loki-OS-2/actions).
2. Select **Build LokiOS image**.
3. Open the latest run.
4. When it succeeds, download the `lokios-bootable-iso-x86_64` artifact from the run's Artifacts section.

The ISO is named `LokiOS-minimal-x86_64.iso`. The artifact is retained for 14 days.

The kernel build starts from the upstream Linux `linux-6.12.y` stable branch and applies `kernel/config.fragment` on top of x86_64_defconfig. This is a custom-configured upstream Linux kernel, not a kernel written from scratch.

## Build locally on Linux

Install the kernel build dependencies, BusyBox static, cpio, GRUB utilities and xorriso, then run:

```bash
bash scripts/build-kernel.sh
bash scripts/build-image.sh
```

The output ISO is written to `out/LokiOS-minimal-x86_64.iso`.

## Desktop shell prototype

The Qt Quick shell source is under `src/`. It is not yet included in the minimal ISO. On a Debian-based development machine with Qt 6 Quick development files and the Qt Quick Controls QML module installed, build it with:

```bash
cmake -S . -B build
cmake --build build
./build/lokios
```

## Roadmap

- [x] Initial Qt Quick shell scaffold
- [x] Minimal x86_64 kernel configuration
- [x] GitHub Actions kernel and ISO build pipeline
- [x] Minimal BusyBox root filesystem and GRUB boot image assembly
- [ ] Confirm successful cloud build and boot test
- [ ] Integrate Qt desktop shell into the bootable userspace
- [ ] Add graphics session, window manager, app launcher, settings and file manager
- [ ] Add installer, hardware support and release documentation

## Project principle

Build and test each layer separately. GitHub Actions handles the large kernel compilation so local disk space is not needed for the kernel source tree or build output.
