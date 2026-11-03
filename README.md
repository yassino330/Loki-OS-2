# LokiOS

A Debian-based Linux desktop project with a minimalist Liquid Glass-inspired interface.

## Current status

The first Qt Quick desktop-shell scaffold is in place. A minimal x86_64 kernel build pipeline has also been added. The project is still not a bootable operating-system image: it does not yet include a root filesystem, init system, bootable ISO, or installer.

## Technology

- Debian 13 (planned userspace base)
- Upstream Linux 6.12.y kernel with a LokiOS configuration fragment
- Qt 6.5+ and Qt Quick / QML
- C++ application entry point
- CMake build system

## Build the kernel without using your PC storage

The repository includes a GitHub Actions workflow that compiles the kernel on a GitHub-hosted runner.

1. Open the **Actions** tab in this repository.
2. Select **Build LokiOS kernel**.
3. Press **Run workflow** and confirm.
4. When it finishes, open the run and download the `lokios-kernel-x86_64` artifact.

The artifact contains the kernel image, kernel configuration, System.map, and built modules. GitHub retains the artifact for 7 days.

The build starts from the upstream Linux `linux-6.12.y` stable branch and applies `kernel/config.fragment` on top of the x86_64 default configuration. This is a custom-configured upstream Linux kernel, not a kernel written from scratch. The kernel artifact alone cannot boot into a desktop; LokiOS still needs a root filesystem and init system.

To build locally on Linux instead, install the standard kernel build dependencies and run:

```bash
bash scripts/build-kernel.sh
```

## Build the desktop prototype

On a Debian-based development machine, install the Qt 6 development tools and QML modules, then run:

```bash
cmake -S . -B build
cmake --build build
./build/lokios
```

Package names vary by distribution. You need Qt 6 Quick development files and the Qt Quick Controls QML module.

## Roadmap

- [x] Initial Qt Quick shell scaffold
- [x] Minimal x86_64 kernel configuration and cloud build workflow
- [ ] Build and test the kernel artifact
- [ ] Build and test the shell on Debian
- [ ] Create a minimal root filesystem and init system
- [ ] Add working app launcher, settings, and file manager integration
- [ ] Add session and window-management integration
- [ ] Create a Debian-based live ISO
- [ ] Add installer, branding, and release documentation

## Project principle

LokiOS will be built in small, testable steps. Kernel compilation runs in GitHub Actions so local disk space is not needed for the kernel source tree or build output.
