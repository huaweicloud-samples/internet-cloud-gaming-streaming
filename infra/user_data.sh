#!/bin/bash
# ============================================================================
# Ubuntu GPU 云游戏实例首启动引导（cloud-init 执行）
# ----------------------------------------------------------------------------
# 本脚本用于 Ubuntu GPU 云游戏实例的首启动引导。
# 关键配置说明：
#   - 运行在华为云官方 GRID 公共镜像（Ubuntu + NVIDIA GRID 图形驱动预装）上，
#     驱动由镜像预装，无需手动安装。
#   - 使用 Steam(Linux) + Proton 兼容层运行游戏；
#     使用 Sunshine(GameStream 主机) + Moonlight(客户端) 提供
#     低延迟 GPU 硬件编码串流（NVIDIA NVENC）。
#   - 不安装与 cloud-init 初始化无关的附加组件。
# ============================================================================

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
LOG=/var/log/cloud-gaming-bootstrap.log
exec > >(tee -a "$LOG") 2>&1

MARKER=/var/lib/cloud-gaming/.bootstrap_done
if [ -f "$MARKER" ]; then
  echo "已初始化，跳过引导。"
  exit 0
fi
mkdir -p /var/lib/cloud-gaming

echo "==> [1/5] 安装桌面与远程组件（XFCE + LightDM 自动登录 + xrdp）"
apt-get update -y
apt-get install -y --no-install-recommends \
  xubuntu-desktop lightdm xrdp xinit \
  curl wget gnupg software-properties-common

# LightDM 自动登录默认用户 ubuntu（华为云 Ubuntu 镜像默认账号）
mkdir -p /etc/lightdm
if [ -f /etc/lightdm/lightdm.conf ]; then
  sed -i 's/^#\?autologin-user=.*/autologin-user=ubuntu/' /etc/lightdm/lightdm.conf
  grep -q '^autologin-user=' /etc/lightdm/lightdm.conf || \
    echo -e "[Seat:*]\nautologin-user=ubuntu\nautologin-user-timeout=0" >> /etc/lightdm/lightdm.conf
else
  echo -e "[Seat:*]\nautologin-user=ubuntu\nautologin-user-timeout=0" > /etc/lightdm/lightdm.conf
fi
systemctl enable lightdm

echo "==> [2/5] 配置 NVIDIA 虚拟显示（GRID 镜像已含驱动）"
# GRID 驱动支持在无物理显示器时启动虚拟显示；放开空初始配置以允许 X 启动
nvidia-xconfig --enable-all-gpus --allow-empty-initial-configuration || true

echo "==> [3/5] 安装 Steam（Linux 版，游戏经 Proton 兼容层运行）"
cd /tmp
if ! command -v steam >/dev/null 2>&1; then
  wget -q https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb -O steam.deb || \
    curl -fsSL -o steam.deb https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb
  dpkg -i steam.deb || apt-get -f install -y
fi
chown -R ubuntu:ubuntu /home/ubuntu 2>/dev/null || true

echo "==> [4/5] 安装 Sunshine（GameStream 主机，Moonlight 客户端接入）"
add-apt-repository -y ppa:lizardbyte/stable
apt-get update -y
apt-get install -y sunshine
mkdir -p /etc/sunshine
cat > /etc/sunshine/sunshine.conf <<'EOF'
display = ":0"
min_log_level = info
EOF
# Sunshine 需在图形会话内捕获显示；将其加入开机自启并允许 ubuntu 用户访问 GPU
usermod -aG video ubuntu || true
systemctl enable sunshine
# 桌面自启 sunshine（确保捕获自动登录后的 X:0 会话）
mkdir -p /home/ubuntu/.config/autostart
cat > /home/ubuntu/.config/autostart/sunshine.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Sunshine
Exec=/usr/bin/sunshine
X-GNOME-Autostart-enabled=true
EOF
chown -R ubuntu:ubuntu /home/ubuntu/.config

echo "==> [5/5] 重启显示管理器以应用虚拟显示与自动登录"
systemctl restart lightdm || true

touch "$MARKER"
echo "==> 引导完成。等待 LightDM 拉起 X(:0) 与 Sunshine 后，即可用 Moonlight 连接（默认端口 47984-48010）。"
echo "    首次配对：浏览器打开 https://<EIP>:47990 设置 Sunshine 账号密码 / PIN，再用 Moonlight 添加 <EIP>。"
