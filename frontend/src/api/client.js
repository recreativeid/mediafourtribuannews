import seedData from '../data/seedData.json'
import { defaultPages } from '../data/pagesData.js'
import { getSupabaseClient, getSupabaseConfig } from './supabase'

export const SESSION_DURATION_MS = 20 * 60 * 1000 // 20 menit

const STORE_KEY = 'mftn_live_store_v2'
const OLD_STORE_KEY = 'mftn_live_store_v1'

// Konversi otomatis file gambar apa pun (JPG, PNG, WebP, GIF, BMP) menjadi format SVG vector
export async function convertImageFileToSvg(file) {
  if (!file) return null

  // Jika sudah SVG
  if (file.type === 'image/svg+xml' || file.name?.toLowerCase().endsWith('.svg')) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.onload = () => {
        const text = String(reader.result)
        const svgBlob = new Blob([text], { type: 'image/svg+xml' })
        const svgFile = new File([svgBlob], file.name || 'image.svg', { type: 'image/svg+xml' })
        const dataUrl = text.startsWith('data:') ? text : `data:image/svg+xml;charset=utf-8,${encodeURIComponent(text)}`
        resolve({
          file: svgFile,
          blob: svgBlob,
          svgContent: text,
          dataUrl,
        })
      }
      reader.onerror = () => reject(new Error('Gagal membaca file SVG'))
      reader.readAsText(file)
    })
  }

  // Jika gambar raster (JPG, PNG, WebP, dll.), konversi presisi ke SVG W3C
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = (e) => {
      const rawDataUrl = e.target.result
      const img = new Image()
      img.onload = () => {
        const width = img.naturalWidth || img.width || 1200
        const height = img.naturalHeight || img.height || 800

        let finalWidth = width
        let finalHeight = height
        const maxDim = 1600
        if (finalWidth > maxDim) {
          finalHeight = Math.round((finalHeight * maxDim) / finalWidth)
          finalWidth = maxDim
        }

        const canvas = document.createElement('canvas')
        canvas.width = finalWidth
        canvas.height = finalHeight
        const ctx = canvas.getContext('2d')
        ctx.drawImage(img, 0, 0, finalWidth, finalHeight)

        let optimizedData = ''
        try {
          optimizedData = canvas.toDataURL('image/webp', 0.88)
        } catch (err) {}
        if (!optimizedData || !optimizedData.startsWith('data:image/webp')) {
          optimizedData = canvas.toDataURL('image/jpeg', 0.88)
        }

        // SVG wrapper W3C standard
        const svgContent = `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 ${finalWidth} ${finalHeight}" width="${finalWidth}" height="${finalHeight}">
  <image width="${finalWidth}" height="${finalHeight}" xlink:href="${optimizedData}" href="${optimizedData}"/>
</svg>`

        const baseName = (file.name ? file.name.replace(/\.[^.]+$/, '') : 'image') + '.svg'
        const svgBlob = new Blob([svgContent], { type: 'image/svg+xml' })
        const svgFile = new File([svgBlob], baseName, { type: 'image/svg+xml' })
        const svgDataUrl = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svgContent)}`

        resolve({
          file: svgFile,
          blob: svgBlob,
          svgContent,
          dataUrl: svgDataUrl,
        })
      }
      img.onerror = () => reject(new Error('Gagal memproses gambar untuk konversi SVG'))
      img.src = rawDataUrl
    }
    reader.onerror = () => reject(new Error('Gagal membaca file gambar'))
    reader.readAsDataURL(file)
  })
}

// Inisialisasi local store dengan fallback data awal
function loadLocalStore() {
  try {
    const raw = localStorage.getItem(STORE_KEY)
    if (raw) {
      const parsed = JSON.parse(raw)
      if (parsed.categories) {
        if (!parsed.pages || !parsed.pages.length) {
          parsed.pages = JSON.parse(JSON.stringify(defaultPages))
        }
        if (!parsed.articles) parsed.articles = []
        return parsed
      }
    } else {
      // Migrasi dari v1 jika ada: pertahankan akun/pengaturan tetapi bersihkan artikel lama sesuai permintaan pengguna
      const oldRaw = localStorage.getItem(OLD_STORE_KEY)
      if (oldRaw) {
        try {
          const oldParsed = JSON.parse(oldRaw)
          localStorage.removeItem(OLD_STORE_KEY)
          const migrated = {
            settings: { ...(seedData.settings || {}), ...(oldParsed.settings || {}) },
            categories: [...(oldParsed.categories?.length ? oldParsed.categories : seedData.categories || [])],
            articles: [], // Dikosongkan khusus postingan berita agar pelanggan upload dari awal
            videos: [...(oldParsed.videos?.length ? oldParsed.videos : seedData.videos || [])],
            comments: [],
            editorial_team: [...(oldParsed.editorial_team?.length ? oldParsed.editorial_team : seedData.editorial_team || [])],
            pages: oldParsed.pages?.length ? oldParsed.pages : JSON.parse(JSON.stringify(defaultPages)),
            ads: [...(oldParsed.ads?.length ? oldParsed.ads : seedData.ads || [])],
            users: [...(oldParsed.users?.length ? oldParsed.users : seedData.users || [])],
            next_ids: { ...(oldParsed.next_ids || {}), articles: 1, comments: 1 },
          }
          saveLocalStore(migrated)
          return migrated
        } catch (e) {
          localStorage.removeItem(OLD_STORE_KEY)
        }
      }
    }
  } catch (e) {
    console.warn('Failed to parse local store:', e)
  }
  // Default dari seedData (artikel kosong)
  const initial = {
    settings: { ...(seedData.settings || {}) },
    categories: [...(seedData.categories || [])],
    articles: [],
    videos: [...(seedData.videos || [])],
    comments: [],
    editorial_team: [...(seedData.editorial_team || [])],
    pages: JSON.parse(JSON.stringify(defaultPages)),
    ads: [...(seedData.ads || [])],
    users: [...(seedData.users || [])],
    next_ids: { ...(seedData.next_ids || {}), articles: 1, comments: 1 },
  }
  saveLocalStore(initial)
  return initial
}

export function saveLocalStore(store) {
  try {
    localStorage.setItem(STORE_KEY, JSON.stringify(store))
  } catch (e) {
    console.warn('Failed to save local store:', e)
  }
}

export function getLocalStore() {
  return loadLocalStore()
}

// Token & Session Management
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

// Core API Gateway: Supabase first with local store fallback
export const api = {
  async get(path) {
    const supabase = getSupabaseClient()

    // 1. /settings
    if (path === '/settings' || path === '/admin/settings') {
      if (supabase) {
        try {
          const { data, error } = await supabase.from('settings').select('key, value')
          if (!error && data?.length) {
            const map = {}
            data.forEach((r) => (map[r.key] = r.value))
            return { data: map }
          }
        } catch (e) {
          console.warn('[Supabase] Settings fetch fallback:', e)
        }
      }
      const store = getLocalStore()
      return { data: store.settings }
    }

    // 2. /categories or /admin/categories
    if (path === '/categories' || path === '/admin/categories') {
      if (supabase) {
        try {
          const { data, error } = await supabase.from('categories').select('*').order('sort_order', { ascending: true })
          if (!error && data?.length) return { data }
        } catch (e) {
          console.warn('[Supabase] Categories fetch fallback:', e)
        }
      }
      const store = getLocalStore()
      return { data: store.categories }
    }

    // 3. /articles query or /admin/articles
    if (path.startsWith('/articles') || path.startsWith('/admin/articles')) {
      const urlObj = new URL(path, 'http://dummy.local')
      const p = urlObj.pathname
      const params = urlObj.searchParams

      // Single article by slug: /articles/:slug
      const singleMatch = p.match(/^\/articles\/([^/]+)$/)
      if (singleMatch && singleMatch[1] !== 'search') {
        const slug = decodeURIComponent(singleMatch[1])
        if (supabase) {
          try {
            const { data, error } = await supabase.from('articles').select('*').eq('slug', slug).single()
            if (!error && data) {
              return {
                data,
                article: data,
                related: [],
                comments: [],
              }
            }
          } catch (e) {
            console.warn('[Supabase] Single article fallback:', e)
          }
        }
        const store = getLocalStore()
        const found = store.articles.find((a) => a.slug === slug || String(a.id) === slug)
        if (!found) throw new Error('Berita tidak ditemukan')

        // Increment views count
        found.views = (found.views || 0) + 1
        saveLocalStore(store)

        // Related articles in same category
        const related = (store.articles || [])
          .filter((a) => (a.category_id === found.category_id || a.category_slug === found.category_slug) && a.id !== found.id)
          .slice(0, 4)

        // Comments for this article
        const comments = (store.comments || []).filter(
          (c) => (c.article_slug === slug || c.article_id === found.id) && c.is_approved
        )

        return {
          data: found,
          article: found,
          related,
          comments,
        }
      }

      // Comments for article: /articles/:slug/comments
      const commentsMatch = p.match(/^\/articles\/([^/]+)\/comments$/)
      if (commentsMatch) {
        const slug = decodeURIComponent(commentsMatch[1])
        if (supabase) {
          try {
            const { data, error } = await supabase
              .from('comments')
              .select('*')
              .eq('article_slug', slug)
              .eq('is_approved', true)
              .order('created_at', { ascending: false })
            if (!error && data) return { data }
          } catch (e) {
            console.warn('[Supabase] Comments fetch fallback:', e)
          }
        }
        const store = getLocalStore()
        const filtered = store.comments.filter((c) => c.article_slug === slug && c.is_approved)
        return { data: filtered }
      }

      // List articles with filters
      if (supabase && !p.startsWith('/admin')) {
        try {
          let query = supabase.from('articles').select('*').eq('status', 'published')
          if (params.get('category')) {
            query = query.eq('category_slug', params.get('category'))
          }
          if (params.get('headline') === 'true') {
            query = query.eq('is_headline', true)
          }
          if (params.get('featured') === 'true') {
            query = query.eq('is_featured', true)
          }
          if (params.get('popular') === 'true') {
            query = query.order('views', { ascending: false })
          } else {
            query = query.order('published_at', { ascending: false })
          }
          if (params.get('limit')) {
            query = query.limit(Number(params.get('limit')))
          }
          const { data, error } = await query
          if (!error && data) return { data }
        } catch (e) {
          console.warn('[Supabase] Articles list fallback:', e)
        }
      }

      // Local store query
      const store = getLocalStore()
      let list = [...store.articles]

      if (params.get('category')) {
        const cSlug = params.get('category')
        list = list.filter((a) => a.category_slug === cSlug || String(a.category_id) === cSlug)
      }
      if (params.get('q')) {
        const q = params.get('q').toLowerCase()
        list = list.filter(
          (a) =>
            a.title?.toLowerCase().includes(q) ||
            a.excerpt?.toLowerCase().includes(q) ||
            a.content?.toLowerCase().includes(q)
        )
      }
      if (params.get('headline') === 'true') {
        list = list.filter((a) => a.is_headline)
      }
      if (params.get('featured') === 'true') {
        list = list.filter((a) => a.is_featured)
      }
      if (params.get('popular') === 'true') {
        list.sort((a, b) => (b.views || 0) - (a.views || 0))
      } else {
        list.sort((a, b) => new Date(b.published_at || 0) - new Date(a.published_at || 0))
      }
      if (params.get('limit')) {
        list = list.slice(0, Number(params.get('limit')))
      }

      return { data: list }
    }

    // 4. /videos or /admin/videos
    if (path.startsWith('/videos') || path.startsWith('/admin/videos')) {
      if (supabase) {
        try {
          const { data, error } = await supabase.from('videos').select('*').order('created_at', { ascending: false })
          if (!error && data?.length) return { data }
        } catch (e) {
          console.warn('[Supabase] Videos fetch fallback:', e)
        }
      }
      const store = getLocalStore()
      return { data: store.videos }
    }

    // 5. /ads or /admin/ads
    if (path.startsWith('/ads') || path.startsWith('/admin/ads')) {
      if (supabase) {
        try {
          const { data, error } = await supabase.from('ads').select('*').order('id', { ascending: true })
          if (!error && data?.length) return { data }
        } catch (e) {
          console.warn('[Supabase] Ads fetch fallback:', e)
        }
      }
      const store = getLocalStore()
      return { data: store.ads }
    }

    // 6. /editorial or /admin/editorial or /redaksi or /admin/redaksi
    if (
      path.startsWith('/editorial') ||
      path.startsWith('/admin/editorial') ||
      path.startsWith('/redaksi') ||
      path.startsWith('/admin/redaksi')
    ) {
      if (supabase) {
        try {
          const { data, error } = await supabase.from('editorial_team').select('*').order('sort_order', { ascending: true })
          if (!error && data?.length) return { data }
        } catch (e) {
          console.warn('[Supabase] Editorial fetch fallback:', e)
        }
      }
      const store = getLocalStore()
      return { data: store.editorial_team }
    }

    // 6b. /pages or /admin/pages
    if (path.startsWith('/pages') || path.startsWith('/admin/pages')) {
      const store = getLocalStore()
      store.pages = store.pages || JSON.parse(JSON.stringify(defaultPages))
      const match = path.match(/^\/(?:admin\/)?pages\/([a-zA-Z0-9_-]+)$/)
      if (match) {
        const p = store.pages.find((pg) => pg.slug === match[1])
        return { data: p || null }
      }
      return { data: store.pages }
    }

    // 7. /admin/comments
    if (path.startsWith('/admin/comments')) {
      const store = getLocalStore()
      let commentsList = []
      if (supabase) {
        try {
          const { data, error } = await supabase.from('comments').select('*').order('created_at', { ascending: false })
          if (!error && data?.length) commentsList = data
        } catch (e) {
          console.warn('[Supabase] Admin comments fallback:', e)
        }
      }
      if (!commentsList.length) {
        commentsList = store.comments || []
      }

      // Enrich comments with article data
      const enriched = commentsList.map((cm) => {
        let art = null
        if (cm.article_slug) {
          art = store.articles.find((a) => a.slug === cm.article_slug)
        }
        if (!art && cm.article_id) {
          art = store.articles.find((a) => String(a.id) === String(cm.article_id))
        }
        return {
          ...cm,
          article_title: cm.article_title || art?.title || (cm.article_id ? `Artikel #${cm.article_id}` : 'Artikel Redaksi'),
          article_slug: cm.article_slug || art?.slug || '',
          article_thumbnail: cm.article_thumbnail || art?.thumbnail || '',
          article_category: cm.article_category || art?.category_name || '',
          comment: cm.comment || cm.content || '',
        }
      })
      return { data: enriched }
    }

    // 8. /admin/users
    if (path.startsWith('/admin/users')) {
      if (supabase) {
        try {
          const { data, error } = await supabase.from('admin_users').select('id, name, email, role, status, avatar, bio, last_login')
          if (!error && data?.length) return { data }
        } catch (e) {
          console.warn('[Supabase] Admin users fallback:', e)
        }
      }
      const store = getLocalStore()
      return { data: store.users }
    }

    // 9. /admin/stats
    if (path.startsWith('/admin/stats')) {
      const store = getLocalStore()
      const totalArticles = store.articles.length
      const totalViews = store.articles.reduce((acc, cur) => acc + (cur.views || 0), 0)
      const totalComments = store.comments.length
      const totalCategories = store.categories.length
      return {
        data: {
          articles: totalArticles,
          views: totalViews,
          comments: totalComments,
          categories: totalCategories,
          recent_articles: store.articles.slice(0, 5),
          top_articles: [...store.articles].sort((a, b) => (b.views || 0) - (a.views || 0)).slice(0, 5),
        },
      }
    }

    // Default fallback
    return { data: null }
  },

  async post(path, body) {
    const supabase = getSupabaseClient()
    const store = getLocalStore()

    // 1. Auth Login: /auth/login
    if (path === '/auth/login') {
      const ident = (body?.username || body?.email || '').trim().toLowerCase()
      const password = body?.password || ''
      if (!ident || !password) {
        throw new Error('Username/email dan kata sandi wajib diisi')
      }

      // Check against stored users (supports username 'admin', email, or name)
      const user = store.users.find((u) => {
        const uEmail = (u.email || '').toLowerCase()
        const uName = (u.name || '').toLowerCase()
        return (
          uEmail === ident ||
          uName === ident ||
          (ident === 'admin' && (u.role === 'Administrator' || uEmail.startsWith('admin'))) ||
          (ident === 'editor' && (u.role === 'Editor' || uEmail.startsWith('redaksi'))) ||
          (ident === 'reporter' && (u.role === 'Reporter' || uEmail.startsWith('reporter')))
        )
      })

      if (!user) {
        throw new Error('Kredensial tidak valid: Akun tidak ditemukan')
      }

      // Password check (supports plain text update or default admin123)
      const isDefault = password === 'admin123'
      const isCustomMatch = user.plain_password && user.plain_password === password
      if (!isDefault && !isCustomMatch) {
        throw new Error('Kredensial tidak valid: Kata sandi salah')
      }

      user.last_login = new Date().toISOString()
      saveLocalStore(store)

      const token = 'mftn_' + Math.random().toString(36).substring(2) + Date.now().toString(36)
      return {
        token,
        expires_in: 20 * 60, // 20 menit
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          avatar: user.avatar,
        },
      }
    }

    // 2. Submit Comments: /articles/:slug/comments
    const commentsMatch = path.match(/^\/articles\/([^/]+)\/comments$/)
    if (commentsMatch) {
      const slug = decodeURIComponent(commentsMatch[1])
      const article = store.articles.find((a) => a.slug === slug)
      const nextId = (store.next_ids.comments = (store.next_ids.comments || 0) + 1)
      const commentText = body.comment || body.content || ''
      const newComment = {
        id: nextId,
        article_id: article ? article.id : (body.article_id || 1),
        article_slug: slug,
        article_title: article ? article.title : (body.article_title || 'Artikel Terkait'),
        article_category: article ? article.category_name : '',
        article_thumbnail: article ? article.thumbnail : '',
        name: body.name || 'Pembaca',
        email: body.email || '',
        comment: commentText,
        content: commentText,
        status: 'approved',
        is_approved: true,
        created_at: new Date().toISOString(),
      }
      store.comments.unshift(newComment)
      saveLocalStore(store)

      if (supabase) {
        try {
          await supabase.from('comments').insert([newComment])
        } catch (e) {
          console.warn('[Supabase] Comment insert failed:', e)
        }
      }
      return { data: newComment, message: 'Komentar berhasil dikirim' }
    }

    // 3. Admin Articles: /admin/articles
    if (path === '/admin/articles') {
      const nextId = (store.next_ids.articles = (store.next_ids.articles || 0) + 1)
      const selectedCat = store.categories.find((c) => c.id === Number(body.category_id)) || {}
      const slug =
        body.slug ||
        (body.title || '')
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, '-')
          .replace(/(^-|-$)/g, '') +
          '-' +
          Date.now()
      const newArticle = {
        id: nextId,
        title: body.title,
        slug,
        excerpt: body.excerpt || '',
        content: body.content || '',
        thumbnail: body.thumbnail || '/images/logo-mftn.jpg',
        category_id: body.category_id || selectedCat.id || 1,
        category_name: body.category_name || selectedCat.name || 'Nasional',
        category_slug: body.category_slug || selectedCat.slug || 'nasional',
        author_name: body.author_name || 'Redaksi MFTN',
        author_role: body.author_role || 'Redaksi',
        status: body.status || 'published',
        is_headline: Boolean(body.is_headline),
        is_featured: Boolean(body.is_featured),
        is_popular: Boolean(body.is_popular),
        is_breaking: Boolean(body.is_breaking),
        views: 0,
        read_time: body.read_time || '3 mnt',
        tags: Array.isArray(body.tags)
          ? body.tags
          : typeof body.tags === 'string'
          ? body.tags.split(',').map((t) => t.trim()).filter(Boolean)
          : [],
        published_at: new Date().toISOString(),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      }
      store.articles.unshift(newArticle)
      saveLocalStore(store)

      if (supabase) {
        try {
          await supabase.from('articles').insert([newArticle])
        } catch (e) {
          console.warn('[Supabase] Article insert failed:', e)
        }
      }
      return { data: newArticle, article: newArticle, message: 'Berita berhasil diterbitkan' }
    }

    // 4. Admin Categories: /admin/categories
    if (path === '/admin/categories') {
      const nextId = (store.next_ids.categories = (store.next_ids.categories || 0) + 1)
      const slug =
        body.slug ||
        (body.name || '')
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, '-')
          .replace(/(^-|-$)/g, '')
      const newCat = {
        id: nextId,
        name: body.name,
        slug,
        description: body.description || '',
        color: body.color || '#0B2563',
        icon: body.icon || 'newspaper',
        sort_order: body.sort_order || store.categories.length + 1,
      }
      store.categories.push(newCat)
      saveLocalStore(store)

      if (supabase) {
        try {
          await supabase.from('categories').insert([newCat])
        } catch (e) {
          console.warn('[Supabase] Category insert failed:', e)
        }
      }
      return { data: newCat, message: 'Kategori berhasil ditambahkan' }
    }

    // 5. Admin Videos: /admin/videos
    if (path === '/admin/videos') {
      const nextId = (store.next_ids.videos = (store.next_ids.videos || 0) + 1)
      const newVideo = {
        id: nextId,
        title: body.title,
        slug: body.slug || 'video-' + nextId,
        youtube_id: body.youtube_id,
        duration: body.duration || '05:00',
        thumbnail: body.thumbnail || '',
        category_name: body.category_name || 'Nasional',
        views: 0,
      }
      store.videos.unshift(newVideo)
      saveLocalStore(store)
      if (supabase) {
        try {
          await supabase.from('videos').insert([newVideo])
        } catch (e) {}
      }
      return { data: newVideo, message: 'Video berhasil ditambahkan' }
    }

    // 6. Admin Ads: /admin/ads
    if (path === '/admin/ads') {
      const nextId = (store.next_ids.ads = (store.next_ids.ads || 0) + 1)
      const newAd = {
        id: nextId,
        title: body.title,
        position: body.position || 'home_leaderboard',
        type: body.type || 'banner',
        image_url: body.image_url || '',
        target_url: body.target_url || '',
        is_active: body.is_active !== undefined ? Boolean(body.is_active) : true,
      }
      store.ads.push(newAd)
      saveLocalStore(store)
      if (supabase) {
        try {
          await supabase.from('ads').insert([newAd])
        } catch (e) {}
      }
      return { data: newAd, message: 'Iklan berhasil ditambahkan' }
    }

    // 7. Admin Editorial: /admin/editorial or /admin/redaksi
    if (path === '/admin/editorial' || path === '/admin/redaksi') {
      const nextId = (store.next_ids.editorial_team = (store.next_ids.editorial_team || 0) + 1)
      const newMember = {
        id: nextId,
        name: body.name,
        role: body.role,
        bio: body.bio || '',
        avatar: body.avatar || '',
        sort_order: body.sort_order || store.editorial_team.length + 1,
      }
      store.editorial_team.push(newMember)
      saveLocalStore(store)
      if (supabase) {
        try {
          await supabase.from('editorial_team').insert([newMember])
        } catch (e) {}
      }
      return { data: newMember, message: 'Anggota redaksi berhasil ditambahkan' }
    }

    // 8. Admin Users: /admin/users
    if (path === '/admin/users') {
      const nextId = (store.next_ids.users = (store.next_ids.users || 0) + 1)
      const newUser = {
        id: nextId,
        name: body.name,
        email: body.email,
        role: body.role || 'Reporter',
        status: 'active',
        avatar: body.avatar || '/images/logo-mftn.jpg',
        plain_password: body.password || 'admin123',
      }
      store.users.push(newUser)
      saveLocalStore(store)
      return { data: newUser, message: 'Pengguna berhasil ditambahkan' }
    }

    // 9. Admin Upload: /admin/upload
    if (path === '/admin/upload') {
      const rawFile = body instanceof FormData ? body.get('file') : null
      if (!rawFile) throw new Error('File tidak ditemukan')

      // Otomatis ubah gambar apa pun menjadi SVG
      let svgResult = null
      try {
        svgResult = await convertImageFileToSvg(rawFile)
      } catch (err) {
        console.warn('Gagal konversi ke SVG, memakai file asli:', err)
      }

      const fileToUpload = svgResult?.file || rawFile
      const fallbackUrl = svgResult?.dataUrl

      if (supabase) {
        try {
          const fileName = `${Date.now()}_${Math.random().toString(36).slice(2)}.svg`
          const { error: uploadError } = await supabase.storage
            .from('mftn-uploads')
            .upload(fileName, fileToUpload, {
              contentType: 'image/svg+xml',
              upsert: true,
            })
          if (!uploadError) {
            const { data } = supabase.storage.from('mftn-uploads').getPublicUrl(fileName)
            if (data?.publicUrl) {
              return { url: data.publicUrl }
            }
          }
        } catch (e) {
          console.warn('[Supabase] Storage upload fallback to SVG data url:', e)
        }
      }

      if (fallbackUrl) {
        return { url: fallbackUrl }
      }

      return new Promise((resolve, reject) => {
        const reader = new FileReader()
        reader.onload = () => resolve({ url: reader.result })
        reader.onerror = () => reject(new Error('Gagal membaca file gambar'))
        reader.readAsDataURL(fileToUpload)
      })
    }

    // 10. Admin Pages Create: /admin/pages
    if (path === '/admin/pages') {
      store.pages = store.pages || JSON.parse(JSON.stringify(defaultPages))
      const slug = body.slug || (body.title || 'halaman-baru').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '')
      const newPage = {
        id: Date.now(),
        slug,
        title: body.title || 'Halaman Baru',
        short_title: body.short_title || body.title || 'Halaman',
        subtitle: body.subtitle || '',
        summary: body.summary || '',
        content: body.content || '',
        status: body.status || 'published',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        ...body,
      }
      store.pages.push(newPage)
      saveLocalStore(store)
      return { data: newPage, message: 'Halaman statis berhasil ditambahkan' }
    }

    return { data: null }
  },

  async put(path, body) {
    const supabase = getSupabaseClient()
    const store = getLocalStore()

    // 1. Update Account: /auth/account
    if (path === '/auth/account') {
      const user = store.users[0]
      if (!user) throw new Error('Pengguna tidak ditemukan')

      if (body.new_password) {
        const curPass = body.current_password
        const isDefault = curPass === 'admin123'
        const isCustomMatch = user.plain_password && user.plain_password === curPass
        if (!isDefault && !isCustomMatch) {
          throw new Error('Kata sandi saat ini tidak sesuai')
        }
        user.plain_password = body.new_password
      }

      if (body.name) user.name = body.name
      if (body.email) user.email = body.email.trim().toLowerCase()
      if (body.avatar) user.avatar = body.avatar
      if (body.bio !== undefined) user.bio = body.bio
      user.updated_at = new Date().toISOString()

      saveLocalStore(store)

      const token = 'mftn_' + Math.random().toString(36).substring(2) + Date.now().toString(36)
      return {
        message: 'Akun berhasil diperbarui',
        token,
        expires_in: 20 * 60,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          avatar: user.avatar,
        },
      }
    }

    // 2. Update Settings: /admin/settings
    if (path === '/admin/settings') {
      Object.assign(store.settings, body)
      saveLocalStore(store)

      if (supabase) {
        try {
          const rows = Object.entries(body).map(([key, value]) => ({ key, value: String(value) }))
          await supabase.from('settings').upsert(rows)
        } catch (e) {}
      }
      return { data: store.settings, message: 'Pengaturan berhasil disimpan' }
    }

    // 3. Update Articles: /admin/articles/:id
    const artMatch = path.match(/^\/admin\/articles\/(\d+)$/)
    if (artMatch) {
      const id = Number(artMatch[1])
      const idx = store.articles.findIndex((a) => a.id === id)
      if (idx === -1) throw new Error('Berita tidak ditemukan')
      const selectedCat = store.categories.find((c) => c.id === Number(body.category_id)) || {}
      store.articles[idx] = {
        ...store.articles[idx],
        ...body,
        category_name: body.category_name || selectedCat.name || store.articles[idx].category_name,
        category_slug: body.category_slug || selectedCat.slug || store.articles[idx].category_slug,
        tags: Array.isArray(body.tags)
          ? body.tags
          : typeof body.tags === 'string'
          ? body.tags.split(',').map((t) => t.trim()).filter(Boolean)
          : store.articles[idx].tags,
        updated_at: new Date().toISOString(),
      }
      saveLocalStore(store)

      if (supabase) {
        try {
          await supabase.from('articles').update(body).eq('id', id)
        } catch (e) {}
      }
      return { data: store.articles[idx], article: store.articles[idx], message: 'Berita berhasil diperbarui' }
    }

    // 4. Update Categories: /admin/categories/:id
    const catMatch = path.match(/^\/admin\/categories\/(\d+)$/)
    if (catMatch) {
      const id = Number(catMatch[1])
      const idx = store.categories.findIndex((c) => c.id === id)
      if (idx === -1) throw new Error('Kategori tidak ditemukan')
      store.categories[idx] = { ...store.categories[idx], ...body }
      saveLocalStore(store)

      if (supabase) {
        try {
          await supabase.from('categories').update(body).eq('id', id)
        } catch (e) {}
      }
      return { data: store.categories[idx], message: 'Kategori berhasil diperbarui' }
    }

    // 5. Update Videos: /admin/videos/:id
    const vidMatch = path.match(/^\/admin\/videos\/(\d+)$/)
    if (vidMatch) {
      const id = Number(vidMatch[1])
      const idx = store.videos.findIndex((v) => v.id === id)
      if (idx === -1) throw new Error('Video tidak ditemukan')
      store.videos[idx] = { ...store.videos[idx], ...body }
      saveLocalStore(store)
      if (supabase) {
        try {
          await supabase.from('videos').update(body).eq('id', id)
        } catch (e) {}
      }
      return { data: store.videos[idx], message: 'Video berhasil diperbarui' }
    }

    // 6. Update Ads: /admin/ads/:id
    const adMatch = path.match(/^\/admin\/ads\/(\d+)$/)
    if (adMatch) {
      const id = Number(adMatch[1])
      const idx = store.ads.findIndex((a) => a.id === id)
      if (idx === -1) throw new Error('Iklan tidak ditemukan')
      store.ads[idx] = { ...store.ads[idx], ...body }
      saveLocalStore(store)
      if (supabase) {
        try {
          await supabase.from('ads').update(body).eq('id', id)
        } catch (e) {}
      }
      return { data: store.ads[idx], message: 'Iklan berhasil diperbarui' }
    }

    // 7. Update Editorial: /admin/editorial/:id or /admin/redaksi/:id
    const editMatch = path.match(/^\/admin\/(?:editorial|redaksi)\/(\d+)$/)
    if (editMatch) {
      const id = Number(editMatch[1])
      const idx = store.editorial_team.findIndex((e) => e.id === id)
      if (idx === -1) throw new Error('Anggota redaksi tidak ditemukan')
      store.editorial_team[idx] = { ...store.editorial_team[idx], ...body }
      saveLocalStore(store)
      if (supabase) {
        try {
          await supabase.from('editorial_team').update(body).eq('id', id)
        } catch (e) {}
      }
      return { data: store.editorial_team[idx], message: 'Anggota redaksi diperbarui' }
    }

    // 7b. Update Pages: /admin/pages/:slug
    const pageMatch = path.match(/^\/admin\/pages\/([a-zA-Z0-9_-]+)$/)
    if (pageMatch) {
      const slug = pageMatch[1]
      store.pages = store.pages || JSON.parse(JSON.stringify(defaultPages))
      const idx = store.pages.findIndex((p) => p.slug === slug)
      if (idx !== -1) {
        store.pages[idx] = { ...store.pages[idx], ...body, updated_at: new Date().toISOString() }
      } else {
        store.pages.push({ ...body, slug, updated_at: new Date().toISOString() })
      }
      saveLocalStore(store)
      return { data: store.pages.find((p) => p.slug === slug), message: 'Halaman statis berhasil diperbarui' }
    }

    // 8. Update Comments (Approve/Reject): /admin/comments/:id or /admin/comments/:id/status
    const comMatch = path.match(/^\/admin\/comments\/(\d+)(?:\/status)?$/)
    if (comMatch) {
      const id = Number(comMatch[1])
      const idx = store.comments.findIndex((c) => c.id === id)
      if (idx === -1) throw new Error('Komentar tidak ditemukan')
      const newStatus = body.status || store.comments[idx].status || 'approved'
      store.comments[idx] = {
        ...store.comments[idx],
        ...body,
        status: newStatus,
        is_approved: newStatus === 'approved',
      }
      saveLocalStore(store)
      if (supabase) {
        try {
          await supabase
            .from('comments')
            .update({ status: newStatus, is_approved: newStatus === 'approved' })
            .eq('id', id)
        } catch (e) {}
      }
      return { data: store.comments[idx], message: 'Status komentar diperbarui' }
    }

    return { data: null }
  },

  async del(path) {
    const supabase = getSupabaseClient()
    const store = getLocalStore()

    // 1. Delete Articles: /admin/articles/:id
    const artMatch = path.match(/^\/admin\/articles\/(\d+)$/)
    if (artMatch) {
      const id = Number(artMatch[1])
      store.articles = store.articles.filter((a) => a.id !== id)
      saveLocalStore(store)
      if (supabase) {
        try {
          await supabase.from('articles').delete().eq('id', id)
        } catch (e) {}
      }
      return { message: 'Berita berhasil dihapus' }
    }

    // 2. Delete Categories: /admin/categories/:id
    const catMatch = path.match(/^\/admin\/categories\/(\d+)$/)
    if (catMatch) {
      const id = Number(catMatch[1])
      store.categories = store.categories.filter((c) => c.id !== id)
      saveLocalStore(store)
      if (supabase) {
        try {
          await supabase.from('categories').delete().eq('id', id)
        } catch (e) {}
      }
      return { message: 'Kategori berhasil dihapus' }
    }

    // 3. Delete Videos: /admin/videos/:id
    const vidMatch = path.match(/^\/admin\/videos\/(\d+)$/)
    if (vidMatch) {
      const id = Number(vidMatch[1])
      store.videos = store.videos.filter((v) => v.id !== id)
      saveLocalStore(store)
      if (supabase) {
        try {
          await supabase.from('videos').delete().eq('id', id)
        } catch (e) {}
      }
      return { message: 'Video berhasil dihapus' }
    }

    // 4. Delete Ads: /admin/ads/:id
    const adMatch = path.match(/^\/admin\/ads\/(\d+)$/)
    if (adMatch) {
      const id = Number(adMatch[1])
      store.ads = store.ads.filter((a) => a.id !== id)
      saveLocalStore(store)
      if (supabase) {
        try {
          await supabase.from('ads').delete().eq('id', id)
        } catch (e) {}
      }
      return { message: 'Iklan berhasil dihapus' }
    }

    // 5. Delete Editorial: /admin/editorial/:id or /admin/redaksi/:id
    const editMatch = path.match(/^\/admin\/(?:editorial|redaksi)\/(\d+)$/)
    if (editMatch) {
      const id = Number(editMatch[1])
      store.editorial_team = store.editorial_team.filter((e) => e.id !== id)
      saveLocalStore(store)
      if (supabase) {
        try {
          await supabase.from('editorial_team').delete().eq('id', id)
        } catch (e) {}
      }
      return { message: 'Anggota redaksi dihapus' }
    }

    // 6. Delete Comments: /admin/comments/:id
    const comMatch = path.match(/^\/admin\/comments\/(\d+)$/)
    if (comMatch) {
      const id = Number(comMatch[1])
      store.comments = store.comments.filter((c) => c.id !== id)
      saveLocalStore(store)
      if (supabase) {
        try {
          await supabase.from('comments').delete().eq('id', id)
        } catch (e) {}
      }
      return { message: 'Komentar berhasil dihapus' }
    }

    // 7. Delete Pages: /admin/pages/:slug
    const pageMatch = path.match(/^\/admin\/pages\/([a-zA-Z0-9_-]+)$/)
    if (pageMatch) {
      const slug = pageMatch[1]
      store.pages = store.pages || JSON.parse(JSON.stringify(defaultPages))
      store.pages = store.pages.filter((p) => p.slug !== slug)
      saveLocalStore(store)
      return { message: 'Halaman berhasil dihapus' }
    }

    return { message: 'Operasi selesai' }
  },

  upload(file) {
    const fd = new FormData()
    fd.append('file', file)
    return this.post('/admin/upload', fd)
  },
}

// Image Resolver with BASE_URL support for GitHub Pages
export function resolveImg(src) {
  const base = import.meta.env.BASE_URL || '/'
  const cleanBase = base.endsWith('/') ? base : base + '/'

  if (!src) {
    return cleanBase + 'images/logo-mftn.jpg'
  }
  if (src.startsWith('http://') || src.startsWith('https://') || src.startsWith('data:')) {
    return src
  }
  const cleanSrc = src.startsWith('/') ? src.slice(1) : src
  return cleanBase + cleanSrc
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
