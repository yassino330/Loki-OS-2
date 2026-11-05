# LokiOS

LokiOS is an independent Linux-based desktop operating-system project. It uses the upstream Linux kernel and may use a proven init/service manager such as systemd; LokiOS focuses its custom engineering on the desktop experience, installer, system integration, branding, and applications.

## Current repository status

The current ISO pipeline builds a Debian Trixie-based live system with a LokiOS Qt desktop shell, Chromium, a hardware-compatibility kernel alongside the LokiOS upstream kernel, and an experimental UEFI installer. It currently relies on Debian packages, systemd, live-boot, GRUB, Xorg, LightDM, and Openbox. It is **not yet a fully independent distribution or validated for general physical-hardware installation**.

CI now checks the desktop as the unprivileged `loki` user and runs a UEFI QEMU boot test that checks LightDM autologin, the LokiOS process, the X display socket, and input-device nodes. These are useful automated checks, but they do not prove compatibility with every physical laptop or validate a full disk installation.

## Project priorities

- Polish the LokiOS desktop shell, keyboard-driven app launcher, dock, quick settings, and settings experience.
- Build a proper full-screen, Windows-style installer with language, keyboard, network, disk selection, progress, and restart stages.
- Keep destructive disk operations explicit and guarded.
- Include VMware open-vm-tools, desktop integration, and the VMware Xorg video driver.
- Provide a guarded MBR-to-GPT conversion utility for supported disk layouts.
- Improve boot branding, reliability, and hardware compatibility.
- Keep Chromium preinstalled and available from the desktop.
- Replace prototype components selectively when LokiOS-owned alternatives provide a real benefit. A custom init is **not a requirement**; systemd is acceptable.

## Build and beta publishing

GitHub Actions builds the development ISO from the pinned upstream Linux kernel source and the current live-image recipe. Each successful build uploads the ISO and its SHA-256 checksum as the `lokios-graphical-iso-x86_64` artifact.

To publish a beta, create and push a version tag such as `v0.1.0-beta.1`. The workflow builds the image, verifies the ISO, calculates its checksum, and creates a GitHub Release with both files attached. A release is published only if the build succeeds. See [Beta release notes](docs/BETA-RELEASE.md).

## Safety

Treat the ISO as a development preview. Test it in a virtual machine first. Do not install it on a disk containing important data until the installer has been tested against disposable virtual disks and the installed system has been verified to boot.
