# ROG Ally CachyOS + Windows 双启动（Clover）

适用于 ROG Ally（RC71L）的 CachyOS 与 Windows 双启动 Clover 引导安装包。Clover 菜单支持使用摇杆或 D-pad 选择系统，并按 A 确认。

## 安装

1. 将 ESP 分区挂载到 `/boot`：

   ```bash
   sudo mount /dev/nvme0n1p1 /boot
   ```

2. 进入本仓库目录并运行安装脚本：

   ```bash
   cd Clover-dualboot
   sudo ./install-clover-dualboot.sh
   ```

3. 重启设备，在 Clover 图形菜单中选择 CachyOS 或 Windows。

## 卸载

若不再需要 Clover，请在 ESP 已挂载到 `/boot` 的情况下运行：

```bash
sudo ./uninstall-clover.sh
```

该脚本会移除 Clover 的 UEFI 启动项、从引导顺序中清除 Clover，并删除 ESP 上的 `/EFI/clover` 文件。

## 注意事项

- 脚本默认使用 ESP 分区 `/dev/nvme0n1p1`，且挂载点为 `/boot`。请先确认这与您的分区布局相符。
- 安装和卸载都会改动 UEFI NVRAM 引导项及 ESP 内容；建议先备份重要数据和当前引导配置。

- 
README_en

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
