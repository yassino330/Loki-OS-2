# LokiOS

A Debian 13 (Trixie) live Linux desktop prototype with a minimalist Liquid Glass-inspired Qt Quick shell.

## Build status

GitHub Actions builds an upstream Linux 6.12.y kernel with LokiOS configuration and assembles a Debian live ISO. The image is a development preview, not a production-ready distribution. It still requires successful cloud build validation and boot testing on real and virtual hardware.

## Cloud build

1. Open [GitHub Actions](https://github.com/yassino330/Loki-OS-2/actions).
2. Select **Build LokiOS image** and open the latest run.
3. Wait for all steps to pass.
4. Download the `lokios-graphical-iso-x86_64` artifact.

The output is `LokiOS-graphical-x86_64.iso`, retained by GitHub for 14 days.

## Included

- Upstream Linux 6.12.y with EFI, live filesystem, USB, NVMe, SATA, virtio and common PC driver configuration
- Intel, AMD and Nouveau graphics modules; common Wi-Fi and Ethernet driver families
- Debian Trixie live root filesystem, live-boot, GRUB and Zstandard SquashFS
- Xorg, LightDM, Openbox, NetworkManager and firmware packages
- Qt 6 Quick shell with launcher panels and basic app launching

The kernel is based on upstream Linux; LokiOS does not claim to have a kernel written from scratch. Driver availability varies by hardware and firmware.

## Live account

The image creates an auto-login desktop account named `loki`. It currently uses a temporary development password, `lokios`; change it before distributing the image.

## Roadmap

- [x] Qt Quick desktop scaffold and dock
- [x] Cloud kernel and ISO build pipeline
- [x] Broader graphics, network, storage and USB kernel configuration
- [x] Explicit live desktop user and firmware repository setup
- [ ] Verify successful build and boot-test ISO
- [x] Initial UEFI disk installer with explicit disk-erasure confirmation\n- [ ] Real settings app, power management and hardware testing
