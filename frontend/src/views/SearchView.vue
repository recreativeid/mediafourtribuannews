<script setup>
import { ref, watch, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api } from '../api/client'
import { portalState } from '../composables/usePortal'
import NewsCard from '../components/NewsCard.vue'
import { Search, SlidersHorizontal } from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()

const keyword = ref(String(route.query.q || ''))
const selectedCat = ref(String(route.query.cat || 'all'))
const results = ref([])
const total = ref(0)
const loading = ref(false)

async function runSearch() {
  loading.value = true
  try {
    const params = new URLSearchParams({ limit: '24' })
    if (keyword.value.trim()) params.set('q', keyword.value.trim())
    if (selectedCat.value && selectedCat.value !== 'all') params.set('category', selectedCat.value)
    const res = await api.get(`/articles?${params.toString()}`)
    results.value = res.data || []
    total.value = res.total || 0
  } finally {
    loading.value = false
  }
}

function submitForm() {
  router.replace({
    name: 'search',
    query: {
      ...(keyword.value.trim() ? { q: keyword.value.trim() } : {}),
      ...(selectedCat.value !== 'all' ? { cat: selectedCat.value } : {}),
    },
  })
}

watch(
  () => [route.query.q, route.query.cat],
  () => {
    keyword.value = String(route.query.q || '')
    selectedCat.value = String(route.query.cat || 'all')
    runSearch()
  }
)

onMounted(runSearch)
</script>

<template>
  <div class="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8 py-5 sm:py-7 space-y-6">
    <!-- Search Bar Box -->
    <div class="bg-white rounded-2xl border border-slate-200 p-4 sm:p-6 shadow-xs space-y-4">
      <h1 class="text-lg sm:text-xl font-black text-[#0B2563] flex items-center gap-2">
        <Search class="w-5 h-5 text-[#D91E28]" />
        Pencarian Berita Media Four Tribuan News
      </h1>

      <form @submit.prevent="submitForm" class="flex flex-col sm:flex-row gap-3">
        <div class="relative flex-1">
          <input
            v-model="keyword"
            type="text"
            placeholder="Masukkan kata kunci peristiwa, tokoh, atau daerah..."
            class="w-full pl-4 pr-10 py-3 rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:border-[#0B2563] text-sm focus:outline-none"
          />
          <Search class="w-4 h-4 text-slate-400 absolute right-3.5 top-1/2 -translate-y-1/2" />
        </div>

        <div class="flex items-center gap-2">
          <div class="relative">
            <SlidersHorizontal class="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
            <select
              v-model="selectedCat"
              @change="submitForm"
              class="pl-8 pr-8 py-3 rounded-xl bg-slate-50 border border-slate-200 text-xs sm:text-sm font-semibold text-slate-700 focus:border-[#0B2563] focus:outline-none"
            >
              <option value="all">Semua Rubrik</option>
              <option v-for="c in portalState.categories" :key="c.slug" :value="c.slug">
                {{ c.name }}
              </option>
            </select>
          </div>
          <button
            type="submit"
            class="px-6 py-3 rounded-xl bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs sm:text-sm font-extrabold transition-colors shrink-0"
          >
            Cari
          </button>
        </div>
      </form>

      <div class="text-xs text-slate-500">
        Menampilkan <strong class="text-[#0B2563]">{{ total }}</strong> hasil
        <span v-if="keyword"> untuk kata kunci "<strong class="text-[#D91E28]">{{ keyword }}</strong>"</span>
      </div>
    </div>

    <div v-if="loading" class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div v-for="i in 4" :key="i" class="h-32 rounded-2xl bg-slate-200 animate-pulse"></div>
    </div>

    <div v-else-if="results.length" class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <NewsCard v-for="art in results" :key="art.id" :article="art" variant="horizontal" />
    </div>

    <div v-else class="bg-white rounded-2xl border border-slate-200 p-10 text-center space-y-2">
      <p class="font-bold text-slate-800">Tidak ada berita yang cocok dengan pencarian Anda.</p>
      <p class="text-xs text-slate-500">Coba gunakan kata kunci yang lebih singkat atau ganti pilihan rubrik.</p>
    </div>
  </div>
</template>
