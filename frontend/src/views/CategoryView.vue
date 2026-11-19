<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { api } from '../api/client'
import { portalState } from '../composables/usePortal'
import NewsCard from '../components/NewsCard.vue'
import AdBanner from '../components/AdBanner.vue'
import { ChevronLeft, ChevronRight, Flame, Clock } from 'lucide-vue-next'

const route = useRoute()
const articles = ref([])
const loading = ref(true)
const page = ref(1)
const totalPages = ref(1)
const total = ref(0)
const sortBy = ref('latest')

const slug = computed(() => String(route.params.slug || 'terbaru'))

const currentCategory = computed(() => {
  if (slug.value === 'terpopuler') {
    return {
      name: 'Berita Terpopuler',
      description: 'Deretan berita paling banyak dibaca dan menjadi perhatian publik di Media Four Tribuan News.',
    }
  }
  if (slug.value === 'terbaru') {
    return {
      name: 'Berita Terbaru',
      description: 'Arsip kronologis berita aktual, terpercaya, dan independen yang baru saja diterbitkan redaksi.',
    }
  }
  return (
    portalState.categories.find((c) => c.slug === slug.value) || {
      name: slug.value.charAt(0).toUpperCase() + slug.value.slice(1),
      description: `Kumpulan liputan dan laporan terkini kanal ${slug.value}.`,
    }
  )
})

async function fetchArticles() {
  loading.value = true
  try {
    const params = new URLSearchParams({
      page: String(page.value),
      limit: '12',
    })
    if (slug.value === 'terpopuler') {
      params.set('sort', 'popular')
    } else if (slug.value !== 'terbaru') {
      params.set('category', slug.value)
      if (sortBy.value === 'popular') params.set('sort', 'popular')
    } else if (sortBy.value === 'popular') {
      params.set('sort', 'popular')
    }

    const res = await api.get(`/articles?${params.toString()}`)
    articles.value = res.data || []
    total.value = res.total || 0
    totalPages.value = Math.max(1, res.totalPages || 1)
  } finally {
    loading.value = false
  }
}

watch([slug, sortBy], () => {
  page.value = 1
  fetchArticles()
})

watch(page, () => {
  fetchArticles()
  window.scrollTo({ top: 0, behavior: 'smooth' })
})

onMounted(fetchArticles)
</script>

<template>
  <div class="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8 py-5 sm:py-7 space-y-6">
    <!-- Category Header Banner -->
    <div class="rounded-2xl bg-gradient-to-r from-[#0B2563] via-[#12358A] to-[#0B2563] text-white p-5 sm:p-7 shadow-md border-l-4 border-[#D91E28]">
      <div class="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
        <div class="space-y-1.5">
          <div class="text-[11px] font-bold uppercase tracking-widest text-[#F5B700]">
            Kanal Rubrik &bull; {{ total }} Berita
          </div>
          <h1 class="font-editorial text-2xl sm:text-3xl font-bold">{{ currentCategory.name }}</h1>
          <p class="text-xs sm:text-sm text-blue-100/85 max-w-2xl">{{ currentCategory.description }}</p>
        </div>

        <div v-if="slug !== 'terpopuler'" class="flex items-center gap-2 shrink-0">
          <button
            type="button"
            @click="sortBy = 'latest'"
            class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold transition-colors"
            :class="sortBy === 'latest' ? 'bg-[#D91E28] text-white' : 'bg-white/10 text-blue-100 hover:bg-white/20'"
          >
            <Clock class="w-3.5 h-3.5" /> Terbaru
          </button>
          <button
            type="button"
            @click="sortBy = 'popular'"
            class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold transition-colors"
            :class="sortBy === 'popular' ? 'bg-[#F5B700] text-slate-950' : 'bg-white/10 text-blue-100 hover:bg-white/20'"
          >
            <Flame class="w-3.5 h-3.5" /> Terpopuler
          </button>
        </div>
      </div>
    </div>

    <!-- Skeleton -->
    <div v-if="loading" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
      <div v-for="i in 6" :key="i" class="h-64 rounded-2xl bg-slate-200 animate-pulse"></div>
    </div>

    <!-- Articles Grid -->
    <div v-else-if="articles.length" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-5">
      <NewsCard v-for="art in articles" :key="art.id" :article="art" variant="grid" />
    </div>

    <div v-else class="bg-white rounded-2xl border border-slate-200 p-10 text-center space-y-2">
      <p class="font-bold text-slate-800">Belum ada berita di rubrik ini</p>
      <router-link to="/" class="inline-block text-xs font-bold text-[#D91E28] hover:underline">
        &larr; Kembali ke Beranda
      </router-link>
    </div>

    <!-- Pagination -->
    <div v-if="totalPages > 1" class="flex items-center justify-center gap-2 pt-2">
      <button
        type="button"
        :disabled="page <= 1"
        @click="page--"
        class="px-3.5 py-2 rounded-xl bg-white border border-slate-200 text-xs font-bold text-slate-700 disabled:opacity-40 hover:border-[#0B2563] inline-flex items-center gap-1"
      >
        <ChevronLeft class="w-4 h-4" /> Sebelumnya
      </button>
      <span class="px-4 py-2 rounded-xl bg-[#0B2563] text-white text-xs font-bold">
        Halaman {{ page }} / {{ totalPages }}
      </span>
      <button
        type="button"
        :disabled="page >= totalPages"
        @click="page++"
        class="px-3.5 py-2 rounded-xl bg-white border border-slate-200 text-xs font-bold text-slate-700 disabled:opacity-40 hover:border-[#0B2563] inline-flex items-center gap-1"
      >
        Selanjutnya <ChevronRight class="w-4 h-4" />
      </button>
    </div>

    <!-- Ad Slot -->
    <AdBanner :ads="portalState.ads" position="home_bottom" class="mt-6" />
  </div>
</template>
