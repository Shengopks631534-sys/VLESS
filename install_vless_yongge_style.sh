#!/bin/bash

# === 勇哥风格 · 纯VLESS Reality 单协议版 ===
# 特点：随机端口 + 自动生成全部参数 + 一次性输出

set -e

clear

echo "========================================"
echo " VLESS Reality 一键安装（勇哥精简版）"
echo "========================================"

# root检查
[[ $EUID -ne 0 ]] && echo "请用 root 运行" && exit 1

# 随机端口（勇哥核心逻辑）
PORT=$(shuf -i 10000-65000 -n 1)

# 安装依赖
apt update -y
apt install -y curl wget unzip openssl

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

# 伪装域名（勇哥常用池）
DOMAINS=("www.cloudflare.com" "www.microsoft.com" "www.apple.com" "www.amazon.com")
SNI=${DOMAINS[$RANDOM % ${#DOMAINS[@]}]}

# 获取IP
IP=$(curl -s4 ip.sb || curl -s ifconfig.me)

# 写入配置
cat > /usr/local/etc/xray/config.json <<EOF
{
  "log": {"loglevel": "warning"},
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
          "dest": "$SNI:443",
          "xver": 0,
          "serverNames": ["$SNI"],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": ["$SHORT_ID"]
        }
      }
    }
  ],
  "outbounds": [
    {"protocol": "freedom"}
  ]
}
EOF

# 防火墙放行
if command -v ufw >/dev/null 2>&1; then
  ufw allow $PORT
fi

# 启动
systemctl daemon-reexec
systemctl restart xray
systemctl enable xray

# 输出（勇哥风格：一次性展示全部信息）

echo ""
echo "========================================"
echo " 🎉 部署完成"
echo "========================================"
echo ""
echo "IP: $IP"
echo "端口: $PORT"
echo "UUID: $UUID"
echo "SNI: $SNI"
echo "PublicKey: $PUBLIC_KEY"
echo "ShortID: $SHORT_ID"
echo ""
echo "-------- VLESS 链接 --------"
echo ""
echo "vless://$UUID@$IP:$PORT?encryption=none&security=reality&sni=$SNI&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&flow=xtls-rprx-vision#VLESS-YG"
echo ""
echo "========================================"
