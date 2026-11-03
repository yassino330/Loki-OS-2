# LokiOS

A lightweight Linux desktop project with a minimalist Liquid Glass-inspired interface.

## Current build target

The GitHub Actions pipeline builds a Debian 13 (Trixie) live ISO using a custom-configured upstream Linux 6.12.y kernel and the LokiOS Qt Quick shell.

The graphical image is a development preview, not a production-ready distribution. Hardware coverage, graphics acceleration, installer, power management, and broad application support still need testing and work.

## Build without using your PC storage

GitHub Actions builds the kernel and assembles the ISO on a hosted runner.

1. Open the [Actions page](https://github.com/yassino330/Loki-OS-2/actions).
2. Select **Build LokiOS image** and open the latest run.
3. Wait for all build steps to finish successfully.
4. Download **lokios-graphical-iso-x86_64** from the run's Artifacts section.

The resulting ISO is named `LokiOS-graphical-x86_64.iso`. GitHub retains it for 14 days.

## What the image contains

- Custom-configured Linux 6.12.y kernel and matching modules
- Debian Trixie minimal live userspace with live-boot
- GRUB boot menu and SquashFS compressed root filesystem
- Xorg, LightDM, Openbox and NetworkManager
- Qt 6 Quick / QML runtime
- LokiOS shell, launched as the live desktop session

The kernel is based on upstream Linux; LokiOS does not claim to have a kernel written from scratch.

## Local development

On Debian or Ubuntu, install Qt 6 Quick development packages, CMake and Ninja, then run:

```bash
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
./build/lokios
```

To assemble the full ISO locally, install the host packages used in `.github/workflows/build-kernel.yml` and run:

```bash
bash scripts/build-kernel.sh
sudo bash scripts/build-image.sh
```

## Roadmap

- [x] Initial Qt Quick shell scaffold
- [x] Minimal x86_64 kernel configuration and cloud build pipeline
- [x] Debian live root filesystem and graphical session integration
- [ ] Confirm successful cloud build and boot-test the ISO
- [ ] Improve desktop shell with functional launcher, files and settings apps
- [ ] Add hardware-specific drivers, power management and networking tests
- [ ] Add installer and release documentation

## Project principle

Keep the local machine free of large build dependencies. GitHub Actions performs kernel compilation and ISO assembly in the cloud.
