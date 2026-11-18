const API_BASE = '/api'
export const SESSION_DURATION_MS = 20 * 60 * 1000 // 20 menit

export function getToken() {
  return localStorage.getItem('mftn_token') || ''
}

export function setToken(token) {
  if (token) localStorage.setItem('mftn_token', token)
  else localStorage.removeItem('mftn_token')
}

export function getSessionExpiresAt() {
  const raw = Number(localStorage.getItem('mftn_expires_at') || 0)
  return Number.isFinite(raw) ? raw : 0
}

export function setSessionExpiresAt(expiresAtMs) {
  if (expiresAtMs) localStorage.setItem('mftn_expires_at', String(expiresAtMs))
  else localStorage.removeItem('mftn_expires_at')
}

export function isSessionExpired() {
  const token = getToken()
  if (!token) return true
  const exp = getSessionExpiresAt()
  if (!exp) return true
  return Date.now() >= exp
}

export function clearAuthStorage() {
  setToken('')
  setSessionExpiresAt(0)
  localStorage.removeItem('mftn_user')
}

export async function apiRequest(path, options = {}) {
  const headers = { ...(options.headers || {}) }
  const token = getToken()
  if (token) {
    headers.Authorization = `Bearer ${token}`
  }
  const isFormData = options.body instanceof FormData
  if (!isFormData && options.body && !headers['Content-Type']) {
    headers['Content-Type'] = 'application/json'
  }

  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers,
    body: isFormData ? options.body : options.body ? JSON.stringify(options.body) : undefined,
  })

  const data = await res.json().catch(() => ({}))
  if (!res.ok) {
    if (res.status === 401 && (path.startsWith('/admin') || path === '/auth/me')) {
      clearAuthStorage()
      if (window.location.pathname.startsWith('/admin') && window.location.pathname !== '/admin/login') {
        window.location.href = '/admin/login?expired=1'
      }
    }
    throw new Error(data.error || `Request gagal (${res.status})`)
  }
  return data
}

export const api = {
  get: (path) => apiRequest(path, { method: 'GET' }),
  post: (path, body) => apiRequest(path, { method: 'POST', body }),
  put: (path, body) => apiRequest(path, { method: 'PUT', body }),
  del: (path) => apiRequest(path, { method: 'DELETE' }),
  upload: (file) => {
    const fd = new FormData()
    fd.append('file', file)
    return apiRequest('/admin/upload', { method: 'POST', body: fd })
  },
}

export function resolveImg(src) {
  if (!src) return '/images/logo-mftn.jpg'
  if (src.startsWith('http://') || src.startsWith('https://') || src.startsWith('/')) {
    return src
  }
  return `/${src}`
}

export function formatDateID(dateStr, withTime = false) {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  if (Number.isNaN(d.getTime())) return dateStr
  const opts = {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  }
  if (withTime) {
    opts.hour = '2-digit'
    opts.minute = '2-digit'
  }
  const formatted = new Intl.DateTimeFormat('id-ID', opts).format(d)
  return withTime ? `${formatted} WIB` : formatted
}

export function timeAgoID(dateStr) {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  const diff = Math.floor((Date.now() - d.getTime()) / 1000)
  if (diff < 60) return 'Baru saja'
  if (diff < 3600) return `${Math.floor(diff / 60)} menit lalu`
  if (diff < 86400) return `${Math.floor(diff / 3600)} jam lalu`
  if (diff < 604800) return `${Math.floor(diff / 86400)} hari lalu`
  return new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'short', year: 'numeric' }).format(d)
}

export function formatNumber(n) {
  return new Intl.NumberFormat('id-ID').format(Number(n || 0))
}
