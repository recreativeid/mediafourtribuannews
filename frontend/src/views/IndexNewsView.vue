<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api, resolveImg, timeAgoID } from '../api/client'
import { portalState } from '../composables/usePortal'
import {
  Calendar,
  Filter,
  Search,
  Clock,
  Eye,
  ChevronRight,
  BookOpen,
  ArrowRight,
  RotateCcw
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()

const loading = ref(false)
const articles = ref([])
const searchFilter = ref('')
const selectedCategory = ref('all')

// Format default: YYYY-MM-DD hari ini
const todayStr = new Date().toISOString().split('T')[0]
const selectedDate = ref(todayStr)

async function loadArticles() {
  loading.value = true
  try {
    const res = await api.get('/articles?limit=100')
    articles.value = res.data || res.articles || []
  } catch (err) {
    console.warn('Failed to load articles for index:', err)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  if (route.query.date) {
    selectedDate.value = route.query.date
  }
  if (route.query.cat) {
    selectedCategory.value = route.query.cat
  }
  loadArticles()
})

const filteredArticles = computed(() => {
  let list = [...articles.value]

  // Filter Kategori
  if (selectedCategory.value && selectedCategory.value !== 'all') {
    list = list.filter((a) => a.category_slug === selectedCategory.value)
  }

  // Filter Kata Kunci
  if (searchFilter.value.trim()) {
    const q = searchFilter.value.trim().toLowerCase()
    list = list.filter((a) =>
      (a.title || '').toLowerCase().includes(q) ||
      (a.excerpt || '').toLowerCase().includes(q) ||
      (a.author_name || '').toLowerCase().includes(q)
    )
  }

  // Filter Tanggal (jika user memilih filter tanggal spesifik)
  if (selectedDate.value) {
    const dateMatches = list.filter((a) => {
      if (!a.published_at) return false
      return a.published_at.startsWith(selectedDate.value)
    })
    // Jika tidak ada berita persis di tanggal tersebut, kembalikan semua dengan urutan tanggal
    if (dateMatches.length > 0) {
      list = dateMatches
    }
  }

  // Urutkan dari tanggal terbaru
  return list.sort((a, b) => new Date(b.published_at || 0) - new Date(a.published_at || 0))
})

function formatArticleTime(isoStr) {
  if (!isoStr) return ''
  const d = new Date(isoStr)
  return d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) + ' WIB'
}

function formatArticleDate(isoStr) {
  if (!isoStr) return ''
  return new Intl.DateTimeFormat('id-ID', {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  }).format(new Date(isoStr))
}

function resetFilter() {
  selectedCategory.value = 'all'
  searchFilter.value = ''
  selectedDate.value = ''
}
</script>

<template>
  <div class="max-w-6xl mx-auto px-3 sm:px-6 lg:px-8 py-6 sm:py-10 space-y-7">
    <!-- Breadcrumb -->
    <div class="flex items-center gap-2 text-xs text-slate-500 pb-2 border-b border-slate-200">
      <router-link to="/" class="hover:text-[#0B2563] font-semibold">Beranda</router-link>
      <ChevronRight class="w-3.5 h-3.5 text-slate-400" />
      <span class="font-bold text-[#D91E28]">Indeks Berita</span>
    </div>

    <!-- Header Banner -->
    <div class="bg-gradient-to-r from-[#081A47] via-[#0B2563] to-[#1648B8] text-white rounded-3xl p-6 sm:p-8 shadow-md">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div class="space-y-1.5">
          <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/10 text-[#F5B700] text-[11px] font-black uppercase tracking-wider">
            <Calendar class="w-3.5 h-3.5" /> Arsip Publikasi Nasional
          </span>
          <h1 class="text-2xl sm:text-3xl font-black font-editorial tracking-tight text-white">
            INDEKS BERITA TERAKHIR
          </h1>
          <p class="text-xs sm:text-sm text-blue-100/90">
            Telusuri seluruh arsip berita terbit {{ portalState.settings.site_title }} berdasarkan waktu dan rubrikasi.
          </p>
        </div>
        <div class="shrink-0 bg-white/10 px-4 py-3 rounded-2xl border border-white/20 text-center">
          <span class="text-[10px] uppercase font-bold text-blue-200 block">Total Berita Terindeks</span>
          <span class="text-xl font-black text-[#F5B700]">{{ filteredArticles.length }} Artikel</span>
        </div>
      </div>
    </div>

    <!-- Filter Control Bar -->
    <div class="bg-white rounded-2xl border border-slate-200 p-4 sm:p-5 shadow-2xs space-y-4">
      <div class="grid grid-cols-1 sm:grid-cols-12 gap-3 items-center">
        <!-- Tanggal -->
        <div class="sm:col-span-4">
          <label class="block text-[11px] font-extrabold uppercase tracking-wider text-slate-500 mb-1">
            Pilih Tanggal Publikasi
          </label>
          <div class="relative">
            <input
              v-model="selectedDate"
              type="date"
              class="w-full px-3 py-2 text-xs sm:text-sm rounded-xl bg-slate-50 border border-slate-200 text-slate-800 focus:outline-none focus:border-[#0B2563] font-medium"
            />
          </div>
        </div>

        <!-- Rubrik -->
        <div class="sm:col-span-4">
          <label class="block text-[11px] font-extrabold uppercase tracking-wider text-slate-500 mb-1">
            Pilih Rubrik Berita
          </label>
          <select
            v-model="selectedCategory"
            class="w-full px-3 py-2 text-xs sm:text-sm rounded-xl bg-slate-50 border border-slate-200 text-slate-800 focus:outline-none focus:border-[#0B2563] font-medium"
          >
            <option value="all">Semua Rubrik</option>
            <option
              v-for="cat in portalState.categories"
              :key="cat.slug"
              :value="cat.slug"
            >
              {{ cat.name }}
            </option>
          </select>
        </div>

        <!-- Pencarian Cepat -->
        <div class="sm:col-span-4">
          <label class="block text-[11px] font-extrabold uppercase tracking-wider text-slate-500 mb-1">
            Cari Kata Kunci
          </label>
          <div class="relative">
            <input
              v-model="searchFilter"
              type="text"
              placeholder="Filter judul atau topik..."
              class="w-full pl-3 pr-8 py-2 text-xs sm:text-sm rounded-xl bg-slate-50 border border-slate-200 text-slate-800 focus:outline-none focus:border-[#0B2563]"
            />
            <button
              v-if="searchFilter || selectedCategory !== 'all' || selectedDate"
              type="button"
              @click="resetFilter"
              class="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-[#D91E28]"
              title="Reset Filter"
            >
              <RotateCcw class="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Hasil Indeks List -->
    <div class="space-y-3">
      <div v-if="loading" class="p-12 text-center text-slate-400">
        Memuat indeks berita...
      </div>

      <div
        v-else-if="!filteredArticles.length"
        class="bg-white rounded-2xl border border-slate-200 p-12 text-center text-slate-500 space-y-2"
      >
        <BookOpen class="w-12 h-12 text-slate-300 mx-auto" />
        <h3 class="text-sm font-bold text-slate-700">Tidak ada berita ditemukan</h3>
        <p class="text-xs text-slate-500">Coba ubah tanggal atau pilih "Semua Rubrik" untuk melihat arsip lainnya.</p>
        <button
          type="button"
          @click="resetFilter"
          class="mt-3 px-4 py-2 rounded-xl bg-[#0B2563] text-white text-xs font-bold"
        >
          Tampilkan Semua Berita
        </button>
      </div>

      <div
        v-for="art in filteredArticles"
        :key="art.slug"
        class="bg-white rounded-2xl border border-slate-200/90 p-4 sm:p-5 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 hover:border-[#0B2563]/40 hover:shadow-xs transition-all group"
      >
        <div class="flex items-start gap-4 flex-1 min-w-0">
          <!-- Thumbnail -->
          <router-link
            :to="`/berita/${art.slug}`"
            class="w-24 sm:w-32 h-20 sm:h-24 rounded-xl overflow-hidden bg-slate-100 shrink-0 block"
          >
            <img
              :src="resolveImg(art.thumbnail)"
              :alt="art.title"
              class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
            />
          </router-link>

          <!-- Teks -->
          <div class="flex-1 min-w-0 space-y-1.5">
            <div class="flex flex-wrap items-center gap-2 text-[10px] font-extrabold uppercase">
              <span class="text-[#D91E28]">{{ art.category_name }}</span>
              <span class="text-slate-300">&bull;</span>
              <span class="text-slate-500 font-semibold flex items-center gap-1">
                <Clock class="w-3 h-3" />
                {{ formatArticleTime(art.published_at) }}
              </span>
              <span class="text-slate-300">&bull;</span>
              <span class="text-slate-500 font-semibold">
                {{ formatArticleDate(art.published_at) }}
              </span>
            </div>

            <router-link
              :to="`/berita/${art.slug}`"
              class="block text-sm sm:text-base font-extrabold text-slate-900 group-hover:text-[#0B2563] line-clamp-2 leading-snug transition-colors"
            >
              {{ art.title }}
            </router-link>

            <p class="text-xs text-slate-600 line-clamp-1 hidden sm:block">
              {{ art.excerpt }}
            </p>

            <div class="flex items-center gap-3 text-[11px] text-slate-400 pt-0.5">
              <span>Wartawan: <strong class="text-slate-700 font-semibold">{{ art.author_name || 'Redaksi' }}</strong></span>
              <span>&bull;</span>
              <span class="flex items-center gap-1">
                <Eye class="w-3 h-3" /> {{ art.views || 0 }} views
              </span>
            </div>
          </div>
        </div>

        <!-- Tombol Aksi -->
        <router-link
          :to="`/berita/${art.slug}`"
          class="shrink-0 w-full sm:w-auto text-center px-4 py-2 rounded-xl bg-slate-100 hover:bg-[#0B2563] text-slate-700 hover:text-white text-xs font-bold transition-colors inline-flex items-center justify-center gap-1.5"
        >
          <span>Baca Berita</span>
          <ArrowRight class="w-3.5 h-3.5" />
        </router-link>
      </div>
    </div>
  </div>
</template>
