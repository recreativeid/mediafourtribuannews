import { createClient } from '@supabase/supabase-js'

const STORAGE_URL_KEY = 'mftn_supabase_url'
const STORAGE_ANON_KEY = 'mftn_supabase_anon_key'

// Default fallback env vars (can be set during build or runtime)
const ENV_URL = import.meta.env.VITE_SUPABASE_URL || ''
const ENV_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || ''

let cachedClient = null

export function getSupabaseConfig() {
  const url = localStorage.getItem(STORAGE_URL_KEY) || ENV_URL || ''
  const key = localStorage.getItem(STORAGE_ANON_KEY) || ENV_KEY || ''
  return {
    url: url.trim(),
    key: key.trim(),
    isConfigured: Boolean(url.trim() && key.trim()),
  }
}

export function setSupabaseConfig(url, key) {
  if (url && key) {
    localStorage.setItem(STORAGE_URL_KEY, url.trim())
    localStorage.setItem(STORAGE_ANON_KEY, key.trim())
  } else {
    localStorage.removeItem(STORAGE_URL_KEY)
    localStorage.removeItem(STORAGE_ANON_KEY)
  }
  cachedClient = null
}

export function getSupabaseClient() {
  const { url, key, isConfigured } = getSupabaseConfig()
  if (!isConfigured) return null
  if (cachedClient) return cachedClient

  try {
    cachedClient = createClient(url, key, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
      },
    })
    return cachedClient
  } catch (err) {
    console.warn('[Supabase] Failed to initialize client:', err)
    return null
  }
}

export async function testSupabaseConnection(urlInput, keyInput) {
  const url = (urlInput || getSupabaseConfig().url || '').trim()
  const key = (keyInput || getSupabaseConfig().key || '').trim()
  if (!url || !key) {
    return { ok: false, error: 'URL dan Anon Key Supabase harus diisi' }
  }

  try {
    const testClient = createClient(url, key)
    const { data, error } = await testClient.from('categories').select('id, name').limit(1)
    if (error) {
      return { ok: false, error: error.message || 'Koneksi gagal ke Supabase' }
    }
    return { ok: true, data }
  } catch (err) {
    return { ok: false, error: err?.message || 'Gagal menghubungi server Supabase' }
  }
}

export async function syncAllToSupabase(localData) {
  const client = getSupabaseClient()
  if (!client) throw new Error('Supabase belum terkonfigurasi')

  const results = {
    categories: 0,
    articles: 0,
    videos: 0,
    editorial_team: 0,
    ads: 0,
    settings: 0,
  }

  // 1. Categories
  if (localData.categories?.length) {
    const rows = localData.categories.map((c) => ({
      id: c.id,
      name: c.name,
      slug: c.slug,
      description: c.description || '',
      color: c.color || '#0B2563',
      icon: c.icon || 'newspaper',
      sort_order: c.sort_order || 0,
    }))
    const { error } = await client.from('categories').upsert(rows, { onConflict: 'id' })
    if (error) throw new Error('Gagal sync categories: ' + error.message)
    results.categories = rows.length
  }

  // 2. Settings
  if (localData.settings) {
    const rows = Object.entries(localData.settings).map(([k, v]) => ({
      key: k,
      value: String(v),
    }))
    const { error } = await client.from('settings').upsert(rows, { onConflict: 'key' })
    if (error) throw new Error('Gagal sync settings: ' + error.message)
    results.settings = rows.length
  }

  // 3. Articles
  if (localData.articles?.length) {
    const rows = localData.articles.map((a) => ({
      id: a.id,
      title: a.title,
      slug: a.slug,
      excerpt: a.excerpt || '',
      content: a.content || '',
      thumbnail: a.thumbnail || '',
      category_id: a.category_id || 1,
      category_name: a.category_name || 'Nasional',
      category_slug: a.category_slug || 'nasional',
      author_name: a.author_name || 'Redaksi MFTN',
      author_role: a.author_role || 'Redaksi',
      status: a.status || 'published',
      is_headline: Boolean(a.is_headline),
      is_featured: Boolean(a.is_featured),
      is_popular: Boolean(a.is_popular),
      is_breaking: Boolean(a.is_breaking),
      views: a.views || 0,
      read_time: a.read_time || '3 mnt',
      tags: a.tags || [],
      published_at: a.published_at || new Date().toISOString(),
    }))
    // Upsert in batches of 20 to avoid payload size limits
    for (let i = 0; i < rows.length; i += 20) {
      const batch = rows.slice(i, i + 20)
      const { error } = await client.from('articles').upsert(batch, { onConflict: 'id' })
      if (error) throw new Error('Gagal sync articles batch ' + i + ': ' + error.message)
    }
    results.articles = rows.length
  }

  // 4. Videos
  if (localData.videos?.length) {
    const rows = localData.videos.map((v) => ({
      id: v.id,
      title: v.title,
      slug: v.slug,
      youtube_id: v.youtube_id,
      duration: v.duration || '05:00',
      thumbnail: v.thumbnail || '',
      category_name: v.category_name || 'Nasional',
      views: v.views || 0,
    }))
    const { error } = await client.from('videos').upsert(rows, { onConflict: 'id' })
    if (error) throw new Error('Gagal sync videos: ' + error.message)
    results.videos = rows.length
  }

  // 5. Editorial
  if (localData.editorial_team?.length) {
    const rows = localData.editorial_team.map((e) => ({
      id: e.id,
      name: e.name,
      role: e.role,
      bio: e.bio || '',
      avatar: e.avatar || '',
      sort_order: e.sort_order || 0,
    }))
    const { error } = await client.from('editorial_team').upsert(rows, { onConflict: 'id' })
    if (error) throw new Error('Gagal sync editorial: ' + error.message)
    results.editorial_team = rows.length
  }

  // 6. Ads
  if (localData.ads?.length) {
    const rows = localData.ads.map((ad) => ({
      id: ad.id,
      title: ad.title,
      position: ad.position,
      type: ad.type || 'banner',
      image_url: ad.image_url || '',
      target_url: ad.target_url || '',
      is_active: Boolean(ad.is_active),
    }))
    const { error } = await client.from('ads').upsert(rows, { onConflict: 'id' })
    if (error) throw new Error('Gagal sync ads: ' + error.message)
    results.ads = rows.length
  }

  return results
}
