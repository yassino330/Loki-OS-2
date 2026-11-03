# LokiOS architecture

## Non-negotiable product boundary

The Linux kernel is the only upstream operating-system component. LokiOS owns everything in userspace: PID 1, initramfs, service supervision, device management policy, login/session, desktop, shell, settings, installer, package/update system, and branding.

Third-party application software (for example Chromium) may be bundled as applications, but it must not become the operating-system foundation or dictate the user experience.

## Migration strategy

The existing Debian-based ISO is retained only as a clearly labelled prototype and recovery reference. Do not silently relabel it as the target OS.

The replacement is built in layers:

1. **Boot contract:** upstream kernel + LokiOS-built initramfs, with LokiOS PID 1.
2. **Base userspace:** LokiOS-owned init, service supervisor, device setup, mount handling, logging, networking integration, and recovery shell.
3. **Installer environment:** bootable full-screen LokiOS setup application; language, keyboard, network, storage, install progress, reboot.
4. **Installed system:** atomic deployment of the LokiOS system image, bootloader setup, recovery entry, first-run wizard.
5. **Desktop:** LokiOS session compositor/shell, panel, launcher, settings, notifications, file manager and terminal.
6. **Applications:** Chromium and curated modern apps installed as applications, isolated from core OS where practical.

## Kernel cache

CI may reuse a kernel build only when the kernel source revision, configuration, toolchain identity, and build recipe match. A cache miss must build the kernel. Never substitute an arbitrary stale kernel cache.

## Acceptance gates

- Build the initramfs reproducibly.
- Boot under QEMU with serial console and graphical display.
- Verify PID 1, mounts, networking, shutdown/reboot and recovery.
- Run installer against a disposable virtual disk.
- Verify installed system boots independently of installation media.
- Verify graphical session and preinstalled Chromium.
- Publish ISO only after all gates pass.

## Current status

The current image pipeline is a Debian-based prototype. The target architecture above is not yet implemented. This document defines the engineering boundary; it is not a claim that the replacement OS already exists.
