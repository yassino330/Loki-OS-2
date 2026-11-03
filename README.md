# LokiOS

A Debian-based Linux desktop project with a minimalist Liquid Glass-inspired interface.

## Current status

The first Qt Quick desktop-shell scaffold is in place. It contains a translucent top bar, a reusable glass panel, and a floating dock. This is an early shell prototype, not yet a bootable operating-system image.

## Technology

- Debian 13 (planned base)
- Qt 6.5+ and Qt Quick / QML
- C++ application entry point
- CMake build system

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
- [ ] Build and test the shell on Debian
- [ ] Add working app launcher, settings, and file manager integration
- [ ] Add session and window-management integration
- [ ] Create a Debian-based live ISO
- [ ] Add installer, branding, and release documentation

## Project principle

LokiOS will be built in small, testable steps. The desktop shell is the first layer; bootable ISO and installer work comes later.
