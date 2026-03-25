#!/bin/bash

echo "=== VLESS Reality 一键安装（极简版） ==="

# root 检查
if [ "$EUID" -ne 0 ]; then
  echo "请用 root 运行"
  exit
fi

# 安装依赖
apt update -y
apt install -y curl unzip openssl

# 安装 Xray
bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh)

# 生成 UUID
UUID=$(cat /proc/sys/kernel/random/uuid)

# 生成 Reality 密钥
KEY_PAIR=$(xray x25519)
PRIVATE_KEY=$(echo "$KEY_PAIR" | grep "Private key" | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEY_PAIR" | grep "Public key" | awk '{print $3}')

# short id
SHORT_ID=$(openssl rand -hex 4)

# 获取 IP
IP=$(curl -s ifconfig.me)

# 写入配置
cat > /usr/local/etc/xray/config.json <<EOF
{
  "inbounds": [
    {
      "port": 443,
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

# 启动
systemctl restart xray
systemctl enable xray

# 输出

echo ""
echo "=== 安装完成 ==="
echo ""
echo "VLESS Reality 链接："
echo ""
echo "vless://$UUID@$IP:443?encryption=none&security=reality&sni=www.cloudflare.com&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&flow=xtls-rprx-vision#VLESS-Reality"
echo ""
