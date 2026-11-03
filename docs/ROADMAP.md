# LokiOS engineering roadmap

- [ ] Replace distro rootfs/debootstrap with a LokiOS-built root filesystem.
- [ ] Build a minimal LokiOS initramfs and PID 1.
- [ ] Add supervised service lifecycle, logging, mount setup and shutdown.
- [ ] Add hardware discovery and networking integration.
- [ ] Build a LokiOS graphical installer with destructive-disk safeguards.
- [ ] Define a reproducible installed-system image format and rollback/recovery.
- [ ] Implement a LokiOS graphical session and core desktop applications.
- [ ] Bundle Chromium as an application.
- [ ] Add automated QEMU boot/install/first-boot tests.
- [ ] Remove legacy Debian prototype path only after replacement passes all acceptance gates.

Do not mark a stage complete until its automated test passes.
