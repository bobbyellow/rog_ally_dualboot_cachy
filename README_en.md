# ROG Ally CachyOS + Windows Dual Boot (Clover)

A Clover bootloader installer for dual booting CachyOS and Windows on ROG Ally (RC71L). The Clover menu allows selecting the system using the joystick or D-pad, and confirming with the A button.

## Installation

1. Mount the ESP partition to `/boot`:

   ```bash
   sudo mount /dev/nvme0n1p1 /boot
   ```

2. Enter the repository directory and run the install script:

   ```bash
   cd Clover-dualboot
   sudo ./install-clover-dualboot.sh
   ```

3. Reboot the device and select CachyOS or Windows from the Clover graphical menu.

## Uninstall

If Clover is no longer needed, run the following while the ESP is mounted to `/boot`:

```bash
sudo ./uninstall-clover.sh
```

This script removes the Clover UEFI boot entry, clears Clover from the boot order, and deletes the `/EFI/clover` files on the ESP.

## Notes

- The scripts default to the ESP partition `/dev/nvme0n1p1` mounted at `/boot`. Please verify this matches your partition layout first.
- Both installation and uninstallation modify UEFI NVRAM boot entries and ESP contents; it is recommended to back up important data and the current boot configuration first.