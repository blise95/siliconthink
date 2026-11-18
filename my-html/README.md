# /my_html — HTML 上传与二维码（独立小站）

给女朋友用的独立工具：**上传 HTML → 生成访问二维码 → 列表管理 / 随时下载二维码**。  
与 Silicon Think 博客/登录 **完全解耦**，不经过 Spring Boot / Vue SPA。

## 访问地址

| 路径 | 说明 | 口令 |
|------|------|------|
| `https://www.siliconthink.top/my_html/` | 上传 + 出码 | 需要 |
| `https://www.siliconthink.top/my_html/list.html` | 已上传列表 | 需要 |
| `https://www.siliconthink.top/my_html/f/{id}.html` | 静态 HTML 本体（扫码直达） | **不需要** |

管理口令（用户名 / 密码）：

```text
binge / 520binge
```

## 行为说明

- **扫码 / 直接打开 `/my_html/f/...html`**：公开，免登录、免口令  
- **上传、列表、删除、下载二维码入口**：需口令（管理面）  
- **随时下载二维码**：上传成功页、列表页「下载二维码」均可保存 PNG  

## 技术要点

- **上传**：浏览器 `PUT` → Nginx WebDAV  
- **列表**：`/my_html/manifest.json`（在管理面，需口令；不放在公开的 `/f/`）  
- **二维码**：前端生成；内容为公开 HTML 链接  

## 服务器首次部署

```bash
sudo bash my-html/deploy/server-setup.sh
```

将 `my-html/deploy/nginx.snippet.conf` 合并进站点配置（写在 SPA `location /` **之前**），再：

```bash
sudo nginx -t && sudo systemctl reload nginx
```

确认带 WebDAV：`nginx -V 2>&1 | grep http_dav_module`

## 日常更新静态页

```bash
rsync -avz \
  --exclude 'f/*.html' \
  --exclude 'manifest.json' \
  --exclude 'deploy' \
  my-html/ root@YOUR_SERVER:/var/www/my-html/
```
