# LokiOS

LokiOS is an independent operating-system project. Its requirement is that the **Linux kernel is the only upstream operating-system component**. The boot experience, userspace, init/service manager, desktop, login, installer, settings, system utilities, and branding are LokiOS-owned.

## Current repository status — honest snapshot

The current ISO pipeline is still a prototype. It uses a Debian Trixie root filesystem, Debian packages, live-boot, GRUB, Xorg, LightDM, Openbox, and a Qt Quick desktop shell. It is **not yet compliant** with the LokiOS-only-userspace requirement. The current installer also copies that prototype root filesystem to disk; it is not the requested Windows-style installation wizard.

The current ISO is an engineering prototype, not the finished LokiOS operating system. Do not describe it as a fully custom OS or as boot-tested on hardware.

## Target architecture

- Upstream Linux kernel and hardware drivers.
- LokiOS-owned boot splash and boot flow.
- LokiOS userspace, core utilities, init/service manager, and system configuration.
- LokiOS login/session manager and desktop shell.
- LokiOS graphical full-screen installer with language, keyboard, network, disk selection, progress, and restart stages.
- LokiOS settings, file manager, terminal, app launcher, notifications, and system tools.
- LokiOS branding throughout; no distro greeter, installer, desktop, or branding.

## Build pipeline

The current GitHub Actions pipeline builds a development ISO using the prototype implementation. It does not yet produce the target architecture above. The transition requires replacing the Debian root filesystem and its package/service assumptions, then validating the resulting ISO in a virtual machine before calling it usable.

## Kernel

The kernel is based on upstream Linux. LokiOS does not claim to have written its own kernel. Driver and hardware support must be tested on target machines.
