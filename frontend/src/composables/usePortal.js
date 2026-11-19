import { reactive, computed } from 'vue'
import {
  api,
  getToken,
  setToken,
  setSessionExpiresAt,
  isSessionExpired,
  clearAuthStorage,
  SESSION_DURATION_MS,
} from '../api/client'

const savedBookmarks = (() => {
  try {
    return JSON.parse(localStorage.getItem('mftn_bookmarks') || '[]')
  } catch {
    return []
  }
})()

const savedUser = (() => {
  try {
    if (isSessionExpired()) {
      clearAuthStorage()
      return null
    }
    return JSON.parse(localStorage.getItem('mftn_user') || 'null')
  } catch {
    return null
  }
})()

export const portalState = reactive({
  settings: {
    site_title: 'Media Four Tribuan News',
    site_subtitle: 'NASIONAL',
    site_tagline: 'Aktual • Terpercaya • Independen',
    site_description: 'Portal Berita Nasional Media Four Tribuan News — Aktual, Terpercaya, Independen.',
    company_name: 'PT Media Four Tribuan Nusantara',
    hotline_phone: '0812-3456-7890',
    whatsapp_number: '6281234567890',
    redaksi_email: 'redaksi@mediafourtribuannews.id',
    office_address: 'Gedung Graha Tribuan Pers Lt. 3, Jl. Merdeka Nasional No. 44, Jakarta Pusat',
    facebook_url: 'https://facebook.com',
    instagram_url: 'https://instagram.com',
    twitter_url: 'https://x.com',
    youtube_url: 'https://youtube.com',
  },
  categories: [],
  ads: [],
  bookmarks: savedBookmarks,
  user: savedUser,
  bootstrapped: false,

  // Global UI drawers/modals
  drawerOpen: false,
  searchOpen: false,
  bookmarksOpen: false,
  videoModal: null,
  photoModal: null,
  toast: null,
})

export function showToast(message, type = 'success') {
  portalState.toast = { message, type, id: Date.now() }
  setTimeout(() => {
    if (portalState.toast && portalState.toast.message === message) {
      portalState.toast = null
    }
  }, 3400)
}

export async function bootstrapPortal(force = false) {
  if (portalState.bootstrapped && !force) return
  try {
    const [setRes, catRes, adRes] = await Promise.all([
      api.get('/settings').catch(() => null),
      api.get('/categories').catch(() => null),
      api.get('/ads').catch(() => null),
    ])
    if (setRes?.data) {
      Object.assign(portalState.settings, setRes.data)
    }
    if (catRes?.data) {
      portalState.categories = catRes.data
    }
    if (adRes?.data) {
      portalState.ads = adRes.data
    }
    portalState.bootstrapped = true
  } catch (e) {
    console.error('Bootstrap error:', e)
  }
}

export async function refreshAds() {
  try {
    const res = await api.get('/ads')
    if (res?.data) {
      portalState.ads = res.data
    }
  } catch (e) {
    console.warn('Refresh ads error:', e)
  }
}

export function isBookmarked(slug) {
  return portalState.bookmarks.some((b) => b.slug === slug)
}

export function toggleBookmark(article) {
  const idx = portalState.bookmarks.findIndex((b) => b.slug === article.slug)
  if (idx >= 0) {
    portalState.bookmarks.splice(idx, 1)
    showToast('Dihapus dari daftar simpan', 'info')
  } else {
    portalState.bookmarks.unshift({
      id: article.id,
      slug: article.slug,
      title: article.title,
      thumbnail: article.thumbnail,
      category_name: article.category_name,
      published_at: article.published_at,
      read_time: article.read_time,
    })
    showToast('Berita disimpan untuk dibaca nanti')
  }
  localStorage.setItem('mftn_bookmarks', JSON.stringify(portalState.bookmarks))
}

export function clearBookmarks() {
  portalState.bookmarks.splice(0)
  localStorage.setItem('mftn_bookmarks', '[]')
}

export const isAuthenticated = computed(() => Boolean(getToken() && portalState.user && !isSessionExpired()))

export async function loginAdmin(usernameOrEmail, password) {
  const res = await api.post('/auth/login', {
    username: usernameOrEmail,
    email: usernameOrEmail,
    password,
  })
  const durationMs = res.expires_in ? Number(res.expires_in) * 1000 : SESSION_DURATION_MS
  setToken(res.token)
  setSessionExpiresAt(Date.now() + durationMs)
  portalState.user = res.user
  localStorage.setItem('mftn_user', JSON.stringify(res.user))
  return res.user
}

export async function updateAdminAccount(payload) {
  const res = await api.put('/auth/account', payload)
  if (res.token) {
    const durationMs = res.expires_in ? Number(res.expires_in) * 1000 : SESSION_DURATION_MS
    setToken(res.token)
    setSessionExpiresAt(Date.now() + durationMs)
  }
  if (res.user) {
    portalState.user = res.user
    localStorage.setItem('mftn_user', JSON.stringify(res.user))
  }
  return res
}

export function logoutAdmin() {
  clearAuthStorage()
  portalState.user = null
}
