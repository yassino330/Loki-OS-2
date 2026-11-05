# MBR to GPT conversion

LokiOS includes `/usr/local/sbin/lokios-mbr2gpt` for guarded conversion of supported MBR disks.

**This is not a universal one-click conversion.** The current utility refuses mounted disks, extended/logical MBR layouts, and unusual partition counts. It saves partition-table backups under `/root/lokios-partition-backups` before conversion. It does not format filesystems, resize partitions, install an EFI bootloader, or make an existing operating system boot in UEFI mode.

1. Back up important files first.
2. Boot from a different disk/live USB; do not convert the disk currently running LokiOS.
3. Check the target with `lsblk -f` and ensure it is the correct disk.
4. Run `sudo /usr/local/sbin/lokios-mbr2gpt /dev/sdX` to display the exact confirmation command.
5. Re-run with the printed confirmation. Do not interrupt the conversion.
6. Verify that the operating system has a valid EFI System Partition and UEFI bootloader before switching firmware to UEFI-only mode.

Test with a disposable virtual disk first. Keep a separate full-disk backup; no partition-table conversion is risk-free.
