#!/usr/bin/env bash
# 将线上旧路径 silliconthink → siliconthink（一次性迁移）
# 用法: sudo bash deploy/rename-from-silliconthink.sh
set -euo pipefail

OLD_APP=/opt/silliconthink
NEW_APP=/opt/siliconthink
OLD_WEB=/var/www/silliconthink
NEW_WEB=/var/www/siliconthink
OLD_JAR=/opt/silliconthink-runtime
NEW_JAR=/opt/siliconthink-runtime
OLD_CONF=/etc/silliconthink
NEW_CONF=/etc/siliconthink
OLD_LOG=/var/log/silliconthink
NEW_LOG=/var/log/siliconthink
OLD_SVC=silliconthink-backend
NEW_SVC=siliconthink-backend
OLD_NGINX=silliconthink
NEW_NGINX=siliconthink

echo "==> 停止旧后端服务（若存在）..."
systemctl stop "$OLD_SVC" 2>/dev/null || true
systemctl stop "$NEW_SVC" 2>/dev/null || true

echo "==> 迁移目录..."
[[ -d "$OLD_APP" && ! -d "$NEW_APP" ]] && mv "$OLD_APP" "$NEW_APP"
[[ -d "$OLD_WEB" && ! -d "$NEW_WEB" ]] && mv "$OLD_WEB" "$NEW_WEB"
[[ -d "$OLD_JAR" && ! -d "$NEW_JAR" ]] && mv "$OLD_JAR" "$NEW_JAR"
[[ -d "$OLD_CONF" && ! -d "$NEW_CONF" ]] && mv "$OLD_CONF" "$NEW_CONF"
[[ -d "$OLD_LOG" && ! -d "$NEW_LOG" ]] && mv "$OLD_LOG" "$NEW_LOG"

echo "==> 更新 backend.env 中的 DB_NAME（若仍为旧库名）..."
ENV_FILE="$NEW_CONF/backend.env"
if [[ -f "$ENV_FILE" ]]; then
  sed -i 's/DB_NAME=silliconthink/DB_NAME=siliconthink/g' "$ENV_FILE"
  sed -i 's/DB_USERNAME=silliconthink/DB_USERNAME=siliconthink/g' "$ENV_FILE"
fi

echo "==> MySQL 库名若仍为 silliconthink，请手动执行："
echo "    mysqldump -uroot -p silliconthink | mysql -uroot -p siliconthink"

echo "==> 安装新 systemd 单元..."
if [[ -f "$NEW_APP/backend/deploy/siliconthink-backend.service" ]]; then
  cp "$NEW_APP/backend/deploy/siliconthink-backend.service" "/etc/systemd/system/${NEW_SVC}.service"
  systemctl daemon-reload
  systemctl disable "$OLD_SVC" 2>/dev/null || true
  systemctl enable "$NEW_SVC"
fi

echo "==> 更新 Nginx 站点..."
if [[ -f /etc/nginx/sites-available/$OLD_NGINX ]]; then
  sed -i "s|/var/www/silliconthink|/var/www/siliconthink|g" "/etc/nginx/sites-available/$OLD_NGINX"
  mv "/etc/nginx/sites-available/$OLD_NGINX" "/etc/nginx/sites-available/$NEW_NGINX"
  rm -f "/etc/nginx/sites-enabled/$OLD_NGINX"
  ln -sf "/etc/nginx/sites-available/$NEW_NGINX" "/etc/nginx/sites-enabled/$NEW_NGINX"
  nginx -t && systemctl reload nginx
fi

systemctl restart "$NEW_SVC"
echo "完成。在 $NEW_APP 执行 git pull && sudo bash deploy/update.sh"
