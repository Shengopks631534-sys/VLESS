#!/bin/bash

set -e

echo "=== VLESS Reality 单节点 · 稳定版 ==="

# root 检查
if [ "$EUID" -ne 0 ]; then
  echo "请用 root 运行"
  exit 1
fi

# 检测端口占用
if ss -lntp | grep -q ":443"; then
  echo "端口443被占用，自动切换到8443"
  PORT=8443
else
  PORT=443
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

# 获取公网IP（更稳）
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

# 防火墙放行
if command -v ufw >/dev/null 2>&1; then
  ufw allow $PORT
fi

# 启动服务
systemctl daemon-reexec
systemctl restart xray
systemctl enable xray

# 输出

echo ""
echo "=== 🎉 部署完成 ==="
echo ""
echo "服务器IP: $IP"
echo "端口: $PORT"
echo ""
echo "VLESS Reality 链接："
echo ""
echo "vless://$UUID@$IP:$PORT?encryption=none&security=reality&sni=www.cloudflare.com&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&flow=xtls-rprx-vision#VLESS-Pro"
echo ""
echo "提示：复制上面链接导入客户端即可使用"
