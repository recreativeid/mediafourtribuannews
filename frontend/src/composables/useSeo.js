import { resolveImg } from '../api/client'

const BASE_URL = 'https://mediafourtribuannews.my.id'
const DEFAULT_TITLE = 'Media Four Tribuan News — Portal Berita Nasional Aktual, Terpercaya & Independen'
const DEFAULT_DESC = 'Portal Berita Nasional Media Four Tribuan News menyajikan jurnalisme terverifikasi, independen, dan berimbang seputar berita nasional, daerah, politik, hukum, dan kemitraan publikasi TNI-Polri.'
const DEFAULT_IMAGE = `${BASE_URL}/images/logo-mftn.jpg`

function getOrCreateMeta(attrName, attrVal, isProperty = false) {
  const selector = isProperty ? `meta[property="${attrVal}"]` : `meta[${attrName}="${attrVal}"]`
  let el = document.querySelector(selector)
  if (!el) {
    el = document.createElement('meta')
    if (isProperty) el.setAttribute('property', attrVal)
    else el.setAttribute(attrName, attrVal)
    document.head.appendChild(el)
  }
  return el
}

export function setPageSeo({
  title,
  description,
  keywords,
  image,
  url,
  type = 'website',
  article = null,
}) {
  const fullTitle = title ? `${title} — Media Four Tribuan News` : DEFAULT_TITLE
  const fullDesc = description || DEFAULT_DESC
  const fullUrl = url ? (url.startsWith('http') ? url : `${BASE_URL}${url}`) : BASE_URL
  const fullImg = image ? (image.startsWith('http') ? image : `${BASE_URL}${resolveImg(image)}`) : DEFAULT_IMAGE

  // 1. Document Title
  document.title = fullTitle

  // 2. Canonical
  let canonicalEl = document.querySelector('link[rel="canonical"]')
  if (!canonicalEl) {
    canonicalEl = document.createElement('link')
    canonicalEl.setAttribute('rel', 'canonical')
    document.head.appendChild(canonicalEl)
  }
  canonicalEl.setAttribute('href', fullUrl)

  // 3. Description & Keywords
  getOrCreateMeta('name', 'description').setAttribute('content', fullDesc)
  if (keywords) {
    getOrCreateMeta('name', 'keywords').setAttribute('content', keywords)
  }

  // 4. OpenGraph
  getOrCreateMeta('name', 'og:title', true).setAttribute('content', fullTitle)
  getOrCreateMeta('name', 'og:description', true).setAttribute('content', fullDesc)
  getOrCreateMeta('name', 'og:url', true).setAttribute('content', fullUrl)
  getOrCreateMeta('name', 'og:type', true).setAttribute('content', type)
  getOrCreateMeta('name', 'og:image', true).setAttribute('content', fullImg)

  // 5. Twitter
  getOrCreateMeta('name', 'twitter:title').setAttribute('content', fullTitle)
  getOrCreateMeta('name', 'twitter:description').setAttribute('content', fullDesc)
  getOrCreateMeta('name', 'twitter:image').setAttribute('content', fullImg)

  // 6. Article JSON-LD Schema
  let ldEl = document.getElementById('article-seo-schema')
  if (article) {
    if (!ldEl) {
      ldEl = document.createElement('script')
      ldEl.id = 'article-seo-schema'
      ldEl.type = 'application/ld+json'
      document.head.appendChild(ldEl)
    }

    const schemaObj = {
      '@context': 'https://schema.org',
      '@type': 'NewsArticle',
      mainEntityOfPage: {
        '@type': 'WebPage',
        '@id': fullUrl,
      },
      headline: article.title,
      description: article.excerpt || fullDesc,
      image: [fullImg],
      datePublished: article.published_at || new Date().toISOString(),
      dateModified: article.updated_at || article.published_at || new Date().toISOString(),
      author: {
        '@type': 'Person',
        name: article.author_name || 'Redaksi Four Tribuan News',
      },
      publisher: {
        '@type': 'NewsMediaOrganization',
        name: 'Media Four Tribuan News',
        logo: {
          '@type': 'ImageObject',
          url: `${BASE_URL}/images/logo-mftn.jpg`,
        },
      },
      articleSection: article.category_name || 'Nasional',
      keywords: article.tags || 'berita, nasional, indonesia',
    }

    ldEl.textContent = JSON.stringify(schemaObj)
  } else if (ldEl) {
    ldEl.remove()
  }
}

export function resetPageSeo() {
  document.title = DEFAULT_TITLE
  const ldEl = document.getElementById('article-seo-schema')
  if (ldEl) ldEl.remove()
}
