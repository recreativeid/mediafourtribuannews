<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { api, resolveImg, formatDateID, formatNumber, timeAgoID } from '../api/client'
import { isBookmarked, toggleBookmark, showToast } from '../composables/usePortal'
import NewsCard from '../components/NewsCard.vue'
import AdBanner from '../components/AdBanner.vue'
import {
  Bookmark,
  Share2,
  Eye,
  Clock,
  MessageSquare,
  Send,
  Link2,
  Flame,
  ArrowLeft,
  Type,
} from 'lucide-vue-next'

const route = useRoute()
const loading = ref(true)
const article = ref(null)
const related = ref([])
const comments = ref([])
const popular = ref([])
const ads = ref([])
const progress = ref(0)
const fontSize = ref(16) // 14 | 16 | 18 | 20

const commentForm = ref({ name: '', email: '', comment: '' })
const submittingComment = ref(false)

const tagList = computed(() => {
  if (!article.value?.tags) return []
  return article.value.tags
    .split(',')
    .map((t) => t.trim())
    .filter(Boolean)
})

function onScroll() {
  const scrollTop = window.scrollY
  const docHeight = document.documentElement.scrollHeight - window.innerHeight
  progress.value = docHeight > 0 ? Math.min(100, Math.round((scrollTop / docHeight) * 100)) : 0
}

async function fetchArticle() {
  loading.value = true
  try {
    const [artRes, popRes, adRes] = await Promise.all([
      api.get(`/articles/${route.params.slug}`),
      api.get('/articles?sort=popular&limit=5'),
      api.get('/ads'),
    ])
    article.value = artRes.article
    related.value = artRes.related || []
    comments.value = artRes.comments || []
    popular.value = popRes.data || []
    ads.value = adRes.data || []
    if (article.value?.title) {
      document.title = `${article.value.title} — Media Four Tribuan News`
    }
  } catch (e) {
    article.value = null
  } finally {
    loading.value = false
  }
}

async function submitComment() {
  if (!article.value || !commentForm.value.name.trim() || !commentForm.value.comment.trim()) return
  submittingComment.value = true
  try {
    const res = await api.post('/comments', {
      article_id: article.value.id,
      name: commentForm.value.name,
      email: commentForm.value.email,
      comment: commentForm.value.comment,
    })
    if (res.data) {
      comments.value.unshift(res.data)
    }
    commentForm.value = { name: '', email: '', comment: '' }
    showToast('Komentar Anda berhasil dikirim!')
  } catch (e) {
    showToast(e.message || 'Gagal mengirim komentar', 'error')
  } finally {
    submittingComment.value = false
  }
}

function shareWhatsApp() {
  const url = encodeURIComponent(window.location.href)
  const text = encodeURIComponent(`${article.value?.title || ''} — Media Four Tribuan News`)
  window.open(`https://wa.me/?text=${text}%20${url}`, '_blank')
}

async function copyLink() {
  try {
    await navigator.clipboard.writeText(window.location.href)
    showToast('Tautan berita berhasil disalin')
  } catch {
    showToast('Salin tautan secara manual dari address bar', 'info')
  }
}

async function nativeShare() {
  if (navigator.share && article.value) {
    try {
      await navigator.share({
        title: article.value.title,
        text: article.value.excerpt,
        url: window.location.href,
      })
      return
    } catch {}
  }
  copyLink()
}

watch(() => route.params.slug, fetchArticle)
onMounted(() => {
  fetchArticle()
  window.addEventListener('scroll', onScroll, { passive: true })
})
onUnmounted(() => {
  window.removeEventListener('scroll', onScroll)
})
</script>

<template>
  <!-- Reading Progress Bar -->
  <div class="fixed top-0 left-0 right-0 h-1 z-50 bg-transparent pointer-events-none">
    <div
      class="h-full bg-gradient-to-r from-[#D91E28] via-[#F5B700] to-[#1648B8] transition-all duration-100"
      :style="{ width: `${progress}%` }"
    ></div>
  </div>

  <div class="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8 py-4 sm:py-7">
    <div v-if="loading" class="max-w-4xl space-y-4">
      <div class="h-8 w-2/3 bg-slate-200 rounded-xl animate-pulse"></div>
      <div class="h-72 w-full bg-slate-200 rounded-2xl animate-pulse"></div>
    </div>

    <div v-else-if="!article" class="bg-white rounded-2xl border border-slate-200 p-10 text-center space-y-3">
      <h1 class="text-xl font-black text-[#0B2563]">Berita Tidak Ditemukan</h1>
      <p class="text-sm text-slate-500">Artikel mungkin telah dipindahkan atau dihapus oleh redaksi.</p>
      <router-link to="/" class="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#0B2563] text-white text-xs font-bold">
        <ArrowLeft class="w-4 h-4" /> Kembali ke Beranda
      </router-link>
    </div>

    <div v-else class="grid grid-cols-1 lg:grid-cols-12 gap-6 lg:gap-8">
      <!-- ==================== MAIN ARTICLE (8 cols) ==================== -->
      <article class="lg:col-span-8 bg-white rounded-2xl sm:rounded-3xl border border-slate-200/80 p-4 sm:p-8 shadow-xs">
        <!-- Breadcrumb & Category -->
        <div class="flex items-center justify-between gap-2 mb-3">
          <div class="flex items-center gap-2 text-xs">
            <router-link to="/" class="text-slate-400 hover:text-[#0B2563] font-semibold">Beranda</router-link>
            <span class="text-slate-300">/</span>
            <router-link
              :to="`/kategori/${article.category_slug}`"
              class="px-2.5 py-0.5 rounded-md bg-[#D91E28] text-white font-extrabold uppercase tracking-wider text-[10px]"
            >
              {{ article.category_name }}
            </router-link>
          </div>

          <!-- Font size control -->
          <div class="inline-flex items-center gap-1 bg-slate-100 rounded-lg p-1 text-[11px] font-bold">
            <Type class="w-3.5 h-3.5 text-slate-400 ml-1" />
            <button
              type="button"
              @click="fontSize = Math.max(14, fontSize - 2)"
              class="px-1.5 py-0.5 rounded hover:bg-white text-slate-700"
            >
              A-
            </button>
            <button
              type="button"
              @click="fontSize = Math.min(22, fontSize + 2)"
              class="px-1.5 py-0.5 rounded hover:bg-white text-slate-700"
            >
              A+
            </button>
          </div>
        </div>

        <!-- Headline -->
        <h1 class="font-editorial text-2xl sm:text-3xl lg:text-[36px] font-bold text-slate-950 leading-tight tracking-tight">
          {{ article.title }}
        </h1>

        <!-- Date, Read time, Views -->
        <div class="flex flex-wrap items-center gap-x-3 gap-y-1.5 mt-3 text-xs text-slate-500 font-medium">
          <span>{{ formatDateID(article.published_at, true) }}</span>
          <span>&bull;</span>
          <span class="inline-flex items-center gap-1 text-[#D91E28] font-bold">
            <Clock class="w-3.5 h-3.5" /> {{ article.read_time }}
          </span>
          <span>&bull;</span>
          <span class="inline-flex items-center gap-1">
            <Eye class="w-3.5 h-3.5" /> {{ formatNumber(article.views) }} dibaca
          </span>
        </div>

        <!-- Author & Share Toolbar -->
        <div class="flex flex-wrap items-center justify-between gap-3 py-4 my-4 border-y border-slate-100">
          <div class="flex items-center gap-3">
            <div class="w-9 h-9 rounded-full bg-[#0B2563] text-[#F5B700] font-black text-xs flex items-center justify-center shrink-0">
              {{ (article.author_name || 'RD').slice(0, 2).toUpperCase() }}
            </div>
            <div class="text-xs leading-tight">
              <div class="font-extrabold text-slate-900">{{ article.author_name }}</div>
              <div class="text-slate-500 text-[11px]">
                Redaksi Media Four Tribuan News
                <span v-if="article.editor_name"> &bull; Editor: {{ article.editor_name }}</span>
              </div>
            </div>
          </div>

          <div class="flex items-center gap-1.5">
            <button
              type="button"
              @click="toggleBookmark(article)"
              class="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold border transition-colors"
              :class="isBookmarked(article.slug)
                ? 'bg-[#D91E28] text-white border-[#D91E28]'
                : 'bg-slate-50 text-slate-700 border-slate-200 hover:border-[#0B2563]'"
            >
              <Bookmark class="w-3.5 h-3.5" :class="{ 'fill-current': isBookmarked(article.slug) }" />
              <span class="hidden sm:inline">{{ isBookmarked(article.slug) ? 'Tersimpan' : 'Simpan' }}</span>
            </button>
            <button
              type="button"
              @click="shareWhatsApp"
              class="px-3 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold transition-colors"
            >
              WhatsApp
            </button>
            <button
              type="button"
              @click="nativeShare"
              class="p-2 rounded-xl bg-[#0B2563] hover:bg-[#1648B8] text-white transition-colors"
              title="Bagikan"
            >
              <Share2 class="w-4 h-4" />
            </button>
            <button
              type="button"
              @click="copyLink"
              class="p-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 transition-colors"
              title="Salin Tautan"
            >
              <Link2 class="w-4 h-4" />
            </button>
          </div>
        </div>

        <!-- Featured Photo -->
        <figure class="mb-6">
          <div class="rounded-2xl overflow-hidden bg-slate-100 aspect-[16/10]">
            <img
              :src="resolveImg(article.thumbnail)"
              :alt="article.title"
              class="w-full h-full object-cover"
            />
          </div>
          <figcaption v-if="article.caption" class="mt-2 text-xs text-slate-500 italic leading-relaxed px-1">
            {{ article.caption }}
          </figcaption>
        </figure>

        <!-- Article Body -->
        <div
          class="article-prose max-w-none"
          :style="{ fontSize: `${fontSize}px` }"
          v-html="article.content"
        ></div>

        <!-- Tags -->
        <div v-if="tagList.length" class="flex flex-wrap items-center gap-2 pt-6 mt-6 border-t border-slate-100">
          <span class="text-xs font-extrabold uppercase tracking-wider text-slate-400">Tag:</span>
          <router-link
            v-for="tag in tagList"
            :key="tag"
            :to="{ name: 'search', query: { q: tag } }"
            class="px-3 py-1 rounded-full bg-slate-100 hover:bg-[#0B2563] hover:text-white text-slate-700 text-xs font-bold transition-colors"
          >
            #{{ tag }}
          </router-link>
        </div>

        <!-- ==================== READER COMMENTS ==================== -->
        <section class="mt-8 pt-7 border-t-2 border-slate-100 space-y-5">
          <div class="flex items-center gap-2">
            <MessageSquare class="w-5 h-5 text-[#D91E28]" />
            <h2 class="text-base font-black uppercase tracking-tight text-[#0B2563]">
              Komentar Pembaca ({{ comments.length }})
            </h2>
          </div>

          <form @submit.prevent="submitComment" class="bg-slate-50 border border-slate-200/80 rounded-2xl p-4 space-y-3">
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <input
                v-model="commentForm.name"
                type="text"
                required
                placeholder="Nama lengkap Anda *"
                class="w-full px-3.5 py-2.5 rounded-xl bg-white border border-slate-200 text-xs sm:text-sm focus:border-[#0B2563] focus:outline-none"
              />
              <input
                v-model="commentForm.email"
                type="email"
                placeholder="Email (opsional, tidak dipublikasikan)"
                class="w-full px-3.5 py-2.5 rounded-xl bg-white border border-slate-200 text-xs sm:text-sm focus:border-[#0B2563] focus:outline-none"
              />
            </div>
            <textarea
              v-model="commentForm.comment"
              rows="3"
              required
              placeholder="Tulis tanggapan Anda secara sopan dan konstruktif..."
              class="w-full px-3.5 py-2.5 rounded-xl bg-white border border-slate-200 text-xs sm:text-sm focus:border-[#0B2563] focus:outline-none"
            ></textarea>
            <div class="flex justify-end">
              <button
                type="submit"
                :disabled="submittingComment"
                class="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-extrabold transition-colors disabled:opacity-50"
              >
                <Send class="w-3.5 h-3.5" />
                <span>{{ submittingComment ? 'Mengirim...' : 'Kirim Komentar' }}</span>
              </button>
            </div>
          </form>

          <div class="space-y-3">
            <div
              v-for="cm in comments"
              :key="cm.id"
              class="bg-white border border-slate-200/80 rounded-2xl p-4 space-y-1.5"
            >
              <div class="flex items-center justify-between">
                <span class="text-xs font-extrabold text-[#0B2563]">{{ cm.name }}</span>
                <span class="text-[11px] text-slate-400">{{ timeAgoID(cm.created_at) }}</span>
              </div>
              <p class="text-xs sm:text-sm text-slate-700 leading-relaxed">{{ cm.comment }}</p>
            </div>
            <p v-if="!comments.length" class="text-xs text-slate-400 text-center py-4">
              Belum ada komentar. Jadilah yang pertama memberikan tanggapan!
            </p>
          </div>
        </section>
      </article>

      <!-- ==================== SIDEBAR (4 cols) ==================== -->
      <aside class="lg:col-span-4 space-y-6">
        <!-- Ad Sidebar -->
        <AdBanner :ads="ads" position="sidebar" />

        <!-- Popular Articles -->
        <div class="bg-white rounded-2xl border border-slate-200/80 p-4 sm:p-5 shadow-xs">
          <div class="flex items-center gap-2 pb-3 mb-3 border-b border-slate-100">
            <Flame class="w-4 h-4 text-[#D91E28]" />
            <h3 class="text-sm font-black uppercase tracking-tight text-[#0B2563]">Terpopuler</h3>
          </div>
          <div>
            <NewsCard
              v-for="(art, idx) in popular"
              :key="art.id"
              :article="art"
              variant="compact"
              :rank="idx + 1"
            />
          </div>
        </div>

        <!-- Related Articles -->
        <div v-if="related.length" class="bg-white rounded-2xl border border-slate-200/80 p-4 sm:p-5 shadow-xs space-y-3">
          <div class="flex items-center gap-2 pb-2 border-b border-slate-100">
            <span class="w-1.5 h-5 rounded-full bg-[#D91E28]"></span>
            <h3 class="text-sm font-black uppercase tracking-tight text-[#0B2563]">Berita Terkait</h3>
          </div>
          <div class="space-y-3">
            <NewsCard v-for="rel in related" :key="rel.id" :article="rel" variant="compact" />
          </div>
        </div>
      </aside>
    </div>
  </div>
</template>
