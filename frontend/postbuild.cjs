const fs = require('fs')
const path = require('path')

const distDir = path.join(__dirname, 'dist')
const indexHtml = path.join(distDir, 'index.html')

if (!fs.existsSync(indexHtml)) {
  console.error('dist/index.html not found!')
  process.exit(1)
}

const routes = [
  'admin',
  'admin/login',
  'admin/berita',
  'admin/kategori',
  'admin/video',
  'admin/komentar',
  'admin/iklan',
  'admin/redaksi',
  'admin/pengguna',
  'admin/akun',
  'admin/pengaturan',
  'kategori',
  'berita',
  'cari',
  'tentang',
]

// 1. Copy to 404.html
fs.copyFileSync(indexHtml, path.join(distDir, '404.html'))

// 2. Create .nojekyll
fs.writeFileSync(path.join(distDir, '.nojekyll'), '', 'utf8')

// 3. Create static directories and index.html for each route
for (const r of routes) {
  const targetDir = path.join(distDir, r)
  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true })
  }
  fs.copyFileSync(indexHtml, path.join(targetDir, 'index.html'))
}

console.log(`[postbuild] Generated static fallbacks for ${routes.length} SPA routes + 404.html + .nojekyll`)
