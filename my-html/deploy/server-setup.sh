#!/usr/bin/env bash
# 首次部署 /my_html（WebDAV + Basic Auth）
# 用法: sudo bash my-html/deploy/server-setup.sh
set -euo pipefail

WEB_ROOT="${WEB_ROOT:-/var/www/my-html}"
HTPASSWD_FILE="${HTPASSWD_FILE:-/etc/nginx/.htpasswd-my-html}"
AUTH_USER="${AUTH_USER:-binge}"
AUTH_PASS="${AUTH_PASS:-520binge}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "请使用 sudo 运行"
  exit 1
fi

echo "==> 安装目录 $WEB_ROOT"
mkdir -p "$WEB_ROOT/f"
rsync -a --exclude 'f/*.html' --exclude 'deploy' "$SRC_DIR/" "$WEB_ROOT/"
if [[ ! -f "$WEB_ROOT/manifest.json" ]]; then
  printf '%s\n' '{"items":[]}' > "$WEB_ROOT/manifest.json"
fi
# 旧版曾把清单放在 f/ 下，迁移到管理面
if [[ -f "$WEB_ROOT/f/manifest.json" && ! -s "$WEB_ROOT/manifest.json" ]]; then
  mv "$WEB_ROOT/f/manifest.json" "$WEB_ROOT/manifest.json"
elif [[ -f "$WEB_ROOT/f/manifest.json" ]]; then
  rm -f "$WEB_ROOT/f/manifest.json"
fi
chown -R www-data:www-data "$WEB_ROOT"
chmod -R u+rwX,g+rwX,o+rX "$WEB_ROOT"
# WebDAV 写入：f/ 与根目录 manifest
chmod 775 "$WEB_ROOT" "$WEB_ROOT/f"

echo "==> 生成口令文件 $HTPASSWD_FILE （用户 $AUTH_USER）"
if command -v htpasswd >/dev/null 2>&1; then
  htpasswd -bBc "$HTPASSWD_FILE" "$AUTH_USER" "$AUTH_PASS"
else
  HASH="$(openssl passwd -apr1 "$AUTH_PASS")"
  printf '%s:%s\n' "$AUTH_USER" "$HASH" > "$HTPASSWD_FILE"
fi
chmod 640 "$HTPASSWD_FILE"
chown root:www-data "$HTPASSWD_FILE"

echo "==> 请将下列片段合并进 Nginx 站点（location / 之前）:"
echo "    $SRC_DIR/deploy/nginx.snippet.conf"
echo "然后执行: nginx -t && systemctl reload nginx"
echo
echo "访问: https://www.siliconthink.top/my_html/"
echo "账号: $AUTH_USER / （已设固定口令）"
