#!/bin/bash

set -e

CONFIG="/usr/local/etc/xray/config.json"
INFO="/root/vless_info.txt"

show_info() {
    if [ -f "$INFO" ]; then
        echo "===== 当前节点信息 ====="
        cat $INFO
    else
        echo "未找到节点，请先安装"
    fi
}

if [ "$1" == "info" ]; then
    show_info
    exit 0
fi

echo "=== VLESS Reality 安装（勇哥纯净版） ==="

[[ $EUID -ne 0 ]] && echo "请用 root 运行" && exit 1

# 随机端口
PORT=$(shuf -i 10000-65000 -n 1)

apt update -y
apt install -y curl unzip openssl

# 安装 xray
bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh)

# UUID
UUID=$(cat /proc/sys/kernel/random/uuid)

# 密钥
KEY=$(xray x25519)
PRI=$(echo "$KEY" | grep Private | awk '{print $3}')
PUB=$(echo "$KEY" | grep Public | awk '{print $3}')

# short id
SID=$(openssl rand -hex 4)

# 固定 Apple
SNI="www.apple.com"

# IP
IP=$(curl -s4 ip.sb || curl -s ifconfig.me)

# 写配置
cat > $CONFIG <<EOF
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "vless",
    "settings": {
      "clients": [{
        "id": "$UUID",
        "flow": "xtls-rprx-vision"
      }],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "dest": "$SNI:443",
        "serverNames": ["$SNI"],
        "privateKey": "$PRI",
        "shortIds": ["$SID"]
      }
    }
  }],
  "outbounds": [{"protocol": "freedom"}]
}
EOF

# 防火墙
ufw allow $PORT 2>/dev/null || true

# 启动
systemctl restart xray
systemctl enable xray

# 链接
LINK="vless://$UUID@$IP:$PORT?encryption=none&security=reality&sni=$SNI&fp=chrome&pbk=$PUB&sid=$SID&type=tcp&flow=xtls-rprx-vision#VLESS"

# 保存
cat > $INFO <<EOF
IP: $IP
端口: $PORT
UUID: $UUID
SNI: $SNI
PublicKey: $PUB
ShortID: $SID

$LINK
EOF

# 输出

echo ""
echo "===== 部署完成 ====="
cat $INFO

echo ""
echo "👉 查询命令: bash install_vless_yongge_pure.sh info"
