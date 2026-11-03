# LokiOS

LokiOS is an independent Linux-based desktop operating-system project. It uses the upstream Linux kernel and may use a proven init/service manager such as systemd; LokiOS focuses its custom engineering on the desktop experience, installer, system integration, branding, and applications.

## Current repository status

The current ISO pipeline builds a Debian Trixie-based live prototype with a LokiOS Qt desktop shell, Chromium, and a graphical disk-installation front end. It currently relies on Debian packages, systemd, live-boot, GRUB, Xorg, LightDM, and Openbox. It is a working build artifact, **not yet a fully independent distribution or a hardware-validated installer**.

The latest successful CI build produced the `lokios-graphical-iso-x86_64` artifact. A successful build confirms the ISO was generated; it does not prove it boots correctly on every computer or that installation is safe for daily use.

## Project priorities

- Polish the LokiOS desktop shell, app launcher, dock, quick settings, and settings experience.
- Build a proper full-screen, Windows-style installer with language, keyboard, network, disk selection, progress, and restart stages.
- Keep destructive disk operations explicit and guarded.
- Improve boot branding, reliability, and hardware compatibility.
- Keep Chromium preinstalled and available from the desktop.
- Replace prototype components selectively when LokiOS-owned alternatives provide a real benefit. A custom init is **not a requirement**; systemd is acceptable.

## Build

GitHub Actions builds the development ISO from the pinned upstream Linux kernel source and the current live-image recipe. Download the `lokios-graphical-iso-x86_64` artifact from the Actions run.

## Safety

Treat the ISO as a development preview. Test it in a virtual machine first. Do not install it on a disk containing important data until the installer has been tested against disposable virtual disks and the installed system has been verified to boot.
