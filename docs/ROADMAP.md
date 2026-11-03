# LokiOS engineering roadmap

- [ ] Polish the LokiOS desktop shell, app launcher, dock, quick settings, and settings.
- [ ] Build a guided full-screen installer with language, keyboard, network, disk, progress, and restart stages.
- [ ] Harden partitioning and bootloader setup with explicit destructive-operation safeguards.
- [ ] Test the live ISO in QEMU and fix boot/session issues.
- [ ] Test Chromium launch and core desktop workflows.
- [ ] Test installation against disposable virtual disks and verify first boot.
- [ ] Improve boot splash, login/session experience, and hardware compatibility.
- [ ] Gradually replace prototype components when custom LokiOS alternatives are ready and beneficial.

A custom init is not a project requirement. Using systemd is acceptable. Do not call the OS release-ready until boot, desktop, installation, and first-boot acceptance tests pass.
