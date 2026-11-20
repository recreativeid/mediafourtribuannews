const fs = require('fs')
const path = require('path')

const baseUrl = 'https://mediafourtribuannews.my.id'
const siteName = 'Media Four Tribuan News'

const seedDataPath = path.join(__dirname, '..', 'src', 'data', 'seedData.json')
const seedData = JSON.parse(fs.readFileSync(seedDataPath, 'utf8'))

const staticPages = [
  { path: '', changefreq: 'daily', priority: '1.0' },
  { path: 'indeks', changefreq: 'daily', priority: '0.9' },
  { path: 'redaksi', changefreq: 'weekly', priority: '0.8' },
  { path: 'kode-etik', changefreq: 'monthly', priority: '0.8' },
  { path: 'pedoman-media-siber', changefreq: 'monthly', priority: '0.8' },
  { path: 'privacy-policy', changefreq: 'monthly', priority: '0.7' },
  { path: 'kebijakan-privasi', changefreq: 'monthly', priority: '0.7' },
  { path: 'disclaimer', changefreq: 'monthly', priority: '0.7' },
  { path: 'dewan-pers', changefreq: 'monthly', priority: '0.7' },
  { path: 'tentang', changefreq: 'weekly', priority: '0.8' },
  { path: 'cari', changefreq: 'daily', priority: '0.7' }
]

const categories = seedData.categories || []
const articles = seedData.articles || []

const nowIso = new Date().toISOString()
const nowDateStr = nowIso.split('T')[0]

// -----------------------------------------------------------------------------
// 1. GENERATE ROBOTS.TXT
// -----------------------------------------------------------------------------
const robotsContent = `# ==============================================================================
# MEDIA FOUR TRIBUAN NEWS — PRODUCTION ROBOTS.TXT
# https://mediafourtribuannews.my.id
# ==============================================================================

User-agent: *
Allow: /
Disallow: /admin/
Disallow: /admin/*
Disallow: /api/

# Specialized Googlebot Crawlers
User-agent: Googlebot
Allow: /
Disallow: /admin/

User-agent: Googlebot-News
Allow: /

User-agent: Googlebot-Image
Allow: /uploads/
Allow: /images/

User-agent: Bingbot
Allow: /
Disallow: /admin/

# Sitemaps & Feeds
Sitemap: ${baseUrl}/sitemap.xml
Sitemap: ${baseUrl}/news-sitemap.xml
Sitemap: ${baseUrl}/rss.xml
`

// -----------------------------------------------------------------------------
// 2. GENERATE SITEMAP.XML
// -----------------------------------------------------------------------------
function escapeXml(unsafe) {
  if (!unsafe) return ''
  return String(unsafe)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;')
}

let sitemapXml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
`

// Static pages
for (const p of staticPages) {
  const loc = p.path ? `${baseUrl}/${p.path}` : `${baseUrl}/`
  sitemapXml += `  <url>
    <loc>${escapeXml(loc)}</loc>
    <lastmod>${nowDateStr}</lastmod>
    <changefreq>${p.changefreq}</changefreq>
    <priority>${p.priority}</priority>
  </url>
`
}

// Categories
for (const c of categories) {
  sitemapXml += `  <url>
    <loc>${escapeXml(`${baseUrl}/kategori/${c.slug}`)}</loc>
    <lastmod>${nowDateStr}</lastmod>
    <changefreq>daily</changefreq>
    <priority>0.8</priority>
  </url>
`
}

// Articles
for (const a of articles) {
  const modDate = (a.updated_at || a.published_at || nowIso).split('T')[0]
  sitemapXml += `  <url>
    <loc>${escapeXml(`${baseUrl}/berita/${a.slug}`)}</loc>
    <lastmod>${modDate}</lastmod>
    <changefreq>daily</changefreq>
    <priority>0.8</priority>
  </url>
`
}

sitemapXml += `</urlset>\n`

// -----------------------------------------------------------------------------
// 3. GENERATE NEWS-SITEMAP.XML (Google News Protocol)
// -----------------------------------------------------------------------------
let newsSitemapXml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:news="http://www.google.com/schemas/sitemap-news/0.9">
`

const recentArticles = [...articles].slice(0, 40)
for (const a of recentArticles) {
  const pubDate = a.published_at ? new Date(a.published_at).toISOString() : nowIso
  newsSitemapXml += `  <url>
    <loc>${escapeXml(`${baseUrl}/berita/${a.slug}`)}</loc>
    <news:news>
      <news:publication>
        <news:name>${escapeXml(siteName)}</news:name>
        <news:language>id</news:language>
      </news:publication>
      <news:publication_date>${pubDate}</news:publication_date>
      <news:title>${escapeXml(a.title)}</news:title>
    </news:news>
  </url>
`
}
newsSitemapXml += `</urlset>\n`

// -----------------------------------------------------------------------------
// 4. GENERATE RSS.XML (RSS 2.0 Feed)
// -----------------------------------------------------------------------------
let rssXml = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>${escapeXml(siteName)}</title>
    <link>${baseUrl}/</link>
    <description>${escapeXml(seedData.settings?.site_description || 'Portal Berita Nasional')}</description>
    <language>id-ID</language>
    <lastBuildDate>${new Date().toUTCString()}</lastBuildDate>
    <atom:link href="${baseUrl}/rss.xml" rel="self" type="application/rss+xml"/>
`

for (const a of recentArticles) {
  const pubDate = a.published_at ? new Date(a.published_at).toUTCString() : new Date().toUTCString()
  const articleUrl = `${baseUrl}/berita/${a.slug}`
  rssXml += `    <item>
      <title>${escapeXml(a.title)}</title>
      <link>${escapeXml(articleUrl)}</link>
      <guid isPermaLink="true">${escapeXml(articleUrl)}</guid>
      <description>${escapeXml(a.excerpt || a.title)}</description>
      <category>${escapeXml(a.category_name || 'Nasional')}</category>
      <author>${escapeXml(a.author_name || 'Redaksi MFTN')}</author>
      <pubDate>${pubDate}</pubDate>
    </item>
`
}
rssXml += `  </channel>
</rss>\n`

// -----------------------------------------------------------------------------
// OUTPUT TO DIRECTORIES
// -----------------------------------------------------------------------------
const targets = [
  path.join(__dirname, '..', 'public'),
  path.join(__dirname, '..', 'dist'),
  path.join(__dirname, '..', '..') // root project
]

for (const t of targets) {
  if (fs.existsSync(t)) {
    fs.writeFileSync(path.join(t, 'robots.txt'), robotsContent, 'utf8')
    fs.writeFileSync(path.join(t, 'sitemap.xml'), sitemapXml, 'utf8')
    fs.writeFileSync(path.join(t, 'news-sitemap.xml'), newsSitemapXml, 'utf8')
    fs.writeFileSync(path.join(t, 'rss.xml'), rssXml, 'utf8')
  }
}

console.log(`[SEO-Generator] Generated robots.txt, sitemap.xml (${staticPages.length + categories.length + articles.length} URLs), news-sitemap.xml, and rss.xml successfully!`)
