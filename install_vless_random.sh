#!/bin/bash

set -e

echo "=== VLESS Reality 单节点（勇哥风格·随机端口） ==="

# root 检查
if [ "$EUID" -ne 0 ]; then
  echo "请用 root 运行"
  exit 1
fi

# 随机端口（20000-60000）
PORT=$(shuf -i 20000-60000 -n 1)

# 安装依赖
apt update -y
apt install -y curl unzip openssl

# 安装 Xray
bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh)

# UUID
UUID=$(cat /proc/sys/kernel/random/uuid)

# Reality 密钥
KEY_PAIR=$(xray x25519)
PRIVATE_KEY=$(echo "$KEY_PAIR" | grep "Private key" | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEY_PAIR" | grep "Public key" | awk '{print $3}')

# short id
SHORT_ID=$(openssl rand -hex 4)

# IP
IP=$(curl -s4 ip.sb || curl -s ifconfig.me)

# 写入配置
cat > /usr/local/etc/xray/config.json <<EOF
{
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.cloudflare.com:443",
          "xver": 0,
          "serverNames": [
            "www.cloudflare.com"
          ],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [
            "$SHORT_ID"
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

# 防火墙
if command -v ufw >/dev/null 2>&1; then
  ufw allow $PORT
fi

# 启动
systemctl daemon-reexec
systemctl restart xray
systemctl enable xray

# 输出

echo ""
echo "=== 🎉 安装完成（随机端口版） ==="
echo ""
echo "端口: $PORT"
echo ""
echo "vless://$UUID@$IP:$PORT?encryption=none&security=reality&sni=www.cloudflare.com&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&flow=xtls-rprx-vision#VLESS-Random"
echo ""
