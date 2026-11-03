# LokiOS architecture

## Product direction

LokiOS uses the upstream Linux kernel. It does **not** require a custom init or PID 1; a mature service manager such as systemd is acceptable. Custom engineering is focused on the LokiOS desktop experience, installer, system integration, settings, utilities, and branding.

Third-party components may be used where they are practical foundations or applications. The goal is a coherent LokiOS product, not rewriting every mature system component without a user benefit.

## Current prototype

The current image uses Debian Trixie as its root filesystem, systemd, live-boot, GRUB, Xorg, LightDM, Openbox, and a Qt Quick LokiOS desktop shell. Chromium is installed in the image. The installer is a graphical front end to a disk installation script.

This prototype is not yet a polished release. In particular, the installer must be validated against disposable virtual disks, and the installed system must be tested independently of the live ISO.

## Priorities

1. Improve the desktop shell and make launcher/settings controls functional.
2. Replace the installer front end with a guided, full-screen setup wizard.
3. Harden partitioning, bootloader installation, failure recovery, and progress reporting.
4. Improve boot splash, login/session presentation, and hardware support.
5. Test boot, live session, installation, first boot, networking, and Chromium in QEMU before recommending real hardware.

## Kernel cache

CI may reuse a kernel build only when the exact upstream source revision, configuration, and build recipe match. A cache miss must build that exact source revision.

## Acceptance gates

- CI produces a non-empty ISO and uploads it as an artifact.
- ISO boots in QEMU to the live desktop.
- Chromium launches successfully.
- Installer is tested only against disposable virtual disks until destructive operations are validated.
- Installed system boots independently of installation media.

## Current status

The repository currently produces a Debian-based development ISO. The successful CI artifact proves image generation, not complete hardware compatibility or production readiness.
