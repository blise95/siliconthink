/** /my_html 共享逻辑：WebDAV PUT/DELETE + manifest + 下载二维码 */

const BASE = '/my_html'
const FILES_BASE = `${BASE}/f`
/** 列表清单放在管理面（需口令），不放在公开的 /f/ 下 */
const MANIFEST_URL = `${BASE}/manifest.json`
const MAX_BYTES = 2 * 1024 * 1024

export function publicOrigin() {
  return window.location.origin
}

export function filePublicUrl(id) {
  return `${publicOrigin()}${FILES_BASE}/${id}.html`
}

export function filePath(id) {
  return `${FILES_BASE}/${id}.html`
}

function randomId() {
  const t = new Date()
  const stamp = [
    t.getFullYear(),
    String(t.getMonth() + 1).padStart(2, '0'),
    String(t.getDate()).padStart(2, '0'),
    '-',
    String(t.getHours()).padStart(2, '0'),
    String(t.getMinutes()).padStart(2, '0'),
    String(t.getSeconds()).padStart(2, '0'),
  ].join('')
  const rand = Math.random().toString(36).slice(2, 8)
  return `${stamp}-${rand}`
}

async function davFetch(url, options = {}) {
  const res = await fetch(url, {
    credentials: 'include',
    ...options,
  })
  if (res.status === 401) {
    throw new Error('未通过口令验证，请刷新页面后输入 binge / 口令')
  }
  return res
}

export async function loadManifest() {
  const res = await davFetch(MANIFEST_URL, { cache: 'no-store' })
  if (res.status === 404) return { items: [] }
  if (!res.ok) throw new Error(`读取列表失败 (${res.status})`)
  const data = await res.json()
  return { items: Array.isArray(data.items) ? data.items : [] }
}

async function saveManifest(manifest) {
  const body = JSON.stringify(manifest, null, 2)
  const res = await davFetch(MANIFEST_URL, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body,
  })
  if (!res.ok && res.status !== 201 && res.status !== 204) {
    throw new Error(`更新列表失败 (${res.status})`)
  }
}

/**
 * @param {File} file
 * @returns {Promise<{ id: string, name: string, url: string, uploadedAt: string }>}
 */
export async function uploadHtmlFile(file) {
  if (!file) throw new Error('请选择文件')
  const name = file.name || 'untitled.html'
  if (!/\.html?$/i.test(name)) throw new Error('只支持 .html / .htm 文件')
  if (file.size > MAX_BYTES) throw new Error('文件不能超过 2MB')

  const id = randomId()
  const html = await file.text()
  const putRes = await davFetch(filePath(id), {
    method: 'PUT',
    headers: { 'Content-Type': 'text/html; charset=utf-8' },
    body: html,
  })
  if (!putRes.ok && putRes.status !== 201 && putRes.status !== 204) {
    throw new Error(`上传失败 (${putRes.status})，请确认 Nginx 已开启 WebDAV`)
  }

  const item = {
    id,
    name,
    url: filePublicUrl(id),
    uploadedAt: new Date().toISOString(),
  }

  const manifest = await loadManifest()
  manifest.items = [item, ...manifest.items.filter((x) => x.id !== id)]
  await saveManifest(manifest)
  return item
}

export async function deleteItem(id) {
  const delRes = await davFetch(filePath(id), { method: 'DELETE' })
  if (!delRes.ok && delRes.status !== 204 && delRes.status !== 404) {
    throw new Error(`删除文件失败 (${delRes.status})`)
  }
  const manifest = await loadManifest()
  manifest.items = manifest.items.filter((x) => x.id !== id)
  await saveManifest(manifest)
}

export function formatTime(iso) {
  if (!iso) return ''
  try {
    return new Date(iso).toLocaleString('zh-CN', { hour12: false })
  } catch {
    return iso
  }
}

/** 从 canvas 下载二维码 PNG */
export function downloadQrFromCanvas(canvas, filename = 'qrcode.png') {
  if (!canvas) throw new Error('没有可下载的二维码')
  const url = canvas.toDataURL('image/png')
  const a = document.createElement('a')
  a.href = url
  a.download = filename.replace(/[^\w.\u4e00-\u9fa5-]+/g, '_')
  document.body.appendChild(a)
  a.click()
  a.remove()
}

export function qrFilename(item) {
  const base = (item?.name || item?.id || 'page').replace(/\.html?$/i, '')
  return `qr-${base}.png`
}
