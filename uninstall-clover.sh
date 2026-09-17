#!/bin/bash
# ============================================================
# ROG Ally 双系统引导 - Clover 卸载脚本
# 功能:
#   1. 删除 NVRAM 中的 "Clover - GUI Boot Manager" 启动项
#   2. 从 BootOrder 中移除 Clover, 恢复其他引导顺序
#   3. 删除 ESP 上的 /EFI/clover/ 目录(含驱动/主题/bootmanager)
#   4. 清理可能的 bootmanager systemd 服务
#   5. 可选: 卸载 /boot/efi bind 挂载(如由安装脚本创建)
#
# 用法:
#   sudo ./uninstall-clover.sh
#   或     ./uninstall-clover.sh   (自动用 sudo 重跑)
# ============================================================

set -e

CLOVER_LABEL="Clover - GUI Boot Manager"
CLOVER_DIR="/boot/EFI/clover"

# --- 0. 确保 root ---
if [ "$EUID" -ne 0 ]; then
    echo "[提示] 需要 root, 使用 sudo 重新运行..."
    exec sudo bash "$0"
fi

echo "=== ROG Ally 双系统 Clover 卸载程序 ==="

# --- 1. 删除 Clover EFI 启动项 ---
echo ""
echo "[Step 1/5] 检查 NVRAM 中的 Clover 启动项..."
BOOTNUM=$(efibootmgr 2>/dev/null | grep -i "$CLOVER_LABEL" | colrm 9 | colrm 1 4)
if [ -n "$BOOTNUM" ]; then
    echo "  找到 Clover 启动项: $BOOTNUM, 正在删除..."
    efibootmgr -b "$BOOTNUM" -B >/dev/null 2>&1
    echo "  已删除 NVRAM 启动项 $BOOTNUM"
else
    echo "  未找到 Clover 启动项, 跳过"
fi

# --- 2. 从 BootOrder 中移除 Clover 残留编号 ---
echo ""
echo "[Step 2/5] 修复 BootOrder (移除 Clover)..."
CURRENT_ORDER=$(efibootmgr 2>/dev/null | grep "^BootOrder:" | awk '{print $2}')
if [ -n "$CURRENT_ORDER" ]; then
    # 动态找出所有指向 clover 的编号并剔除
    CLEAN=""
    for entry in $(echo "$CURRENT_ORDER" | tr ',' ' '); do
        target=$(efibootmgr 2>/dev/null | grep "^Boot${entry}" | grep -ci "$CLOVER_LABEL" || true)
        if [ "$target" -eq 0 ]; then
            [ -n "$CLEAN" ] && CLEAN="$CLEAN,"
            CLEAN="$CLEAN$entry"
        fi
    done
    if [ -n "$CLEAN" ] && [ "$CLEAN" != "$CURRENT_ORDER" ]; then
        efibootmgr -o "$CLEAN" >/dev/null 2>&1
        echo "  BootOrder 已更新: $CURRENT_ORDER  ->  $CLEAN"
    else
        echo "  BootOrder 无 Clover, 无需修改: $CURRENT_ORDER"
    fi
fi

# --- 3. 删除 ESP 上的 Clover 目录 ---
echo ""
echo "[Step 3/5] 删除 ESP 上的 Clover 目录..."
if [ -d "$CLOVER_DIR" ]; then
    rm -rf "$CLOVER_DIR"
    echo "  已删除 $CLOVER_DIR"
else
    echo "  未找到 $CLOVER_DIR, 跳过"
fi

# --- 4. 清理 bootmanager systemd 服务 ---
echo ""
echo "[Step 4/5] 清理 bootmanager 相关 systemd 服务..."
if [ -f /etc/systemd/system/clover-bootmanager.service ]; then
    systemctl disable clover-bootmanager.service >/dev/null 2>&1 || true
    rm -f /etc/systemd/system/clover-bootmanager.service
    systemctl daemon-reload 2>/dev/null || true
    echo "  已删除 clover-bootmanager.service"
else
    echo "  未发现相关服务, 跳过"
fi

# --- 5. 清理 /boot/efi bind 挂载(如存在且来自 /boot) ---
echo ""
echo "[Step 5/5] 检查 /boot/efi bind 残留..."
if findmnt /boot/efi >/dev/null 2>&1; then
    SRC=$(findmnt -n -o SOURCE /boot/efi)
    if [ "$SRC" = "/boot" ]; then
        umount /boot/efi 2>/dev/null && echo "  已卸载 /boot/efi bind 挂载" || echo "  [警告] 卸载失败"
    else
        echo "  /boot/efi 来自 $SRC, 未由本脚本创建, 保留"
    fi
else
    echo "  无 bind 挂载, 跳过"
fi

echo ""
echo "============================================"
echo " 卸载完成! 验证:"
echo "   efibootmgr 版本信息如下:"
efibootmgr 2>/dev/null | grep -iE "BootOrder|Clover" || true
echo "   ESP 上的 clover 残留:"
ls -d /boot/EFI/clover 2>/dev/null && echo "   [残留!]" || echo "   已清除, 无残留"
echo "============================================"