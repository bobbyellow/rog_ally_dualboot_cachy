#!/bin/bash
# ============================================================
# ROG Ally (RC71L) 双系统引导 - Clover 5160 一键部署脚本
# CachyOS + Windows 双系统, 手柄(摇杆/D-pad)可控制 Clover 菜单
#
# 用法:
#   chmod +x install-clover-dualboot.sh
#   ./install-clover-dualboot.sh
#
# 素材来源: 工作目录下 efi-clover/ (已验证可用)
# ============================================================

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/efi-clover"
ESP_DEV="/dev/nvme0n1p1"
ESP_MOUNT="/boot"
CLOVER_DEST="$ESP_MOUNT/EFI/clover"
BOOTMANAGER_DEST="$ESP_MOUNT/EFI/clover/clover-bootmanager"

echo "=== ROG Ally 双系统 Clover 安装程序 ==="

# --- 0. 检查素材 ---
[ -f "$SRC_DIR/cloverx64.efi" ] || { echo "[错误] 素材缺失: $SRC_DIR/cloverx64.efi"; exit 1; }
[ -f "$SRC_DIR/drivers/uefi/UsbXbox360Dxe.efi" ] || { echo "[错误] 驱动缺失: UsbXbox360Dxe.efi"; exit 1; }
[ -f "$SRC_DIR/config.plist" ] || { echo "[错误] 配置缺失: config.plist"; exit 1; }
echo "[OK] 素材完整"

# --- 1. 确认 root ---
if [ "$EUID" -ne 0 ]; then
    echo "[提示] 需要 root, 使用 sudo 重新运行..."
    exec sudo bash "$0"
fi

# --- 2. 检查 ESP 是否挂载 ---
if ! mountpoint -q "$ESP_MOUNT"; then
    echo "[错误] ESP 未挂载到 $ESP_MOUNT (需要 vfat 分区)"
    echo "        请先挂载: mount $ESP_DEV $ESP_MOUNT"
    exit 1
fi
echo "[OK] ESP 已挂载"

# --- 3. 可选: /boot/efi bind (LGC/旧脚本路径兼容, 非必须) ---
if [ ! -e "$ESP_MOUNT/efi" ]; then
    mkdir -p "$ESP_MOUNT/efi"
    mount --bind "$ESP_MOUNT" "$ESP_MOUNT/efi" 2>/dev/null && echo "[OK] /boot/efi bind 已建立"
fi

# --- 4. 部署 Clover 文件 ---
rm -rf "$CLOVER_DEST"
mkdir -p "$CLOVER_DEST"
cp -r "$SRC_DIR/." "$CLOVER_DEST/" 2>/dev/null
if [ -f "$CLOVER_DEST/cloverx64.efi" ] && \
   [ -f "$CLOVER_DEST/drivers/uefi/UsbXbox360Dxe.efi" ] && \
   [ -f "$CLOVER_DEST/config.plist" ]; then
    echo "[OK] Clover 文件已复制到 $CLOVER_DEST"
else
    echo "[错误] Clover 复制不完整, 关键文件缺失"
    ls -la "$CLOVER_DEST"
    exit 1
fi

# --- 5. 部署 bootmanager 工具 ---
cp "$SRC_DIR/clover-bootmanager.sh" "$BOOTMANAGER_DEST.sh" 2>/dev/null || true
cp "$SRC_DIR/clover-bootmanager.service" "$BOOTMANAGER_DEST.service" 2>/dev/null || true
echo "[OK] bootmanager 工具已复制"

# --- 6. 添加 Clover EFI 启动项 ---
if ! efibootmgr | grep -qi "Clover"; then
    efibootmgr -c -d /dev/nvme0n1 -p 1 -L "Clover - GUI Boot Manager" \
        -l "\EFI\clover\cloverx64.efi" >/dev/null 2>&1
    if efibootmgr | grep -qi "Clover"; then
        echo "[OK] Clover EFI 启动项已添加"
    else
        echo "[错误] Clover 启动项添加失败"
        exit 1
    fi
else
    echo "[OK] Clover EFI 启动项已存在"
fi

# --- 7. 把 Clover 设为首位 ---
CLOVER_NUM=$(efibootmgr | grep -i Clover | colrm 9 | colrm 1 4)
CURRENT_ORDER=$(efibootmgr | grep "^BootOrder:" | awk '{print $2}')
# 移除已有的 Clover
CLEANED=$(echo "$CURRENT_ORDER" | tr ',' '\n' | grep -v "^$CLOVER_NUM$" | paste -sd,)
NEW_ORDER="$CLOVER_NUM,$CLEANED"
efibootmgr -o "$NEW_ORDER" >/dev/null 2>&1
echo "[OK] Clover 已设为第一优先引导"
echo "    BootOrder = $NEW_ORDER"

# --- 8. 完成 ---
echo ""
echo "============================================"
echo " 部署完成! 请重启验证."
echo " 重启后进入 Clover 图形菜单:"
echo "   CachyOS = Linux 系统"
echo "   Windows = Windows 系统"
echo " 用手柄摇杆/D-pad 选择, 按 A 确认"
echo "============================================"