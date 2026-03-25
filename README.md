# VLESS 配置（通用模板）

本仓库用于存储标准 VLESS 节点信息（参考 sing-box / xray reality 通用写法）。

---

## 一键导入链接（示例）

```
vless://UUID@your_ip:443?encryption=none&security=reality&sni=www.cloudflare.com&fp=chrome&pbk=PUBLIC_KEY&sid=SHORT_ID&type=tcp&flow=xtls-rprx-vision#VLESS-Node
```

---

## 参数说明

- UUID：用户唯一标识
- IP：服务器地址
- 端口：默认 443
- security：reality（推荐）
- sni：伪装域名（建议大厂域名）
- pbk：Reality 公钥
- sid：Short ID
- flow：xtls-rprx-vision

---

## 服务端 config.json 示例（Reality）

```json
{
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "UUID",
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
          "privateKey": "PRIVATE_KEY",
          "shortIds": [
            "SHORT_ID"
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
```

---

## 使用说明

1. 替换 UUID / IP / KEY 等参数
2. 启动 xray
3. 将 vless 链接导入客户端（v2rayN / Clash Meta / sing-box）

---

## 说明

该模板参考 yongge 五合一脚本精简，仅保留 VLESS Reality 高稳定方案。
