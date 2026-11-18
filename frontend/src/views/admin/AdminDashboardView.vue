<script setup>
import { ref, computed, onMounted } from 'vue'
import { api, formatNumber, timeAgoID, resolveImg } from '../../api/client'
import {
  Newspaper,
  Eye,
  MessageSquare,
  Tags,
  Video,
  Megaphone,
  Plus,
  TrendingUp,
} from 'lucide-vue-next'

const loading = ref(true)
const stats = ref({
  total_articles: 0,
  published_articles: 0,
  draft_articles: 0,
  total_views: 0,
  total_categories: 0,
  total_users: 0,
  total_videos: 0,
  total_ads: 0,
  pending_comments: 0,
  total_comments: 0,
  category_stats: [],
  latest_articles: [],
  top_articles: [],
  recent_comments: [],
})

const maxCatCount = computed(() =>
  Math.max(1, ...stats.value.category_stats.map((c) => c.count || 0))
)

onMounted(async () => {
  try {
    stats.value = await api.get('/admin/dashboard')
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="space-y-6">
    <!-- Top Welcome & Quick Action -->
    <div class="rounded-2xl bg-gradient-to-r from-[#081A47] via-[#0B2563] to-[#12358A] text-white p-5 sm:p-6 flex flex-col sm:flex-row sm:items-center justify-between gap-4 shadow-md">
      <div>
        <span class="text-[10px] font-black uppercase tracking-widest text-[#F5B700]">Ringkasan Redaksi</span>
        <h2 class="text-xl sm:text-2xl font-black mt-0.5">Dashboard Media Four Tribuan News</h2>
        <p class="text-xs text-blue-100/80 mt-1">Pantau statistik berita, pembaca, komentar, dan kanal multimedia secara real-time.</p>
      </div>
      <router-link
        to="/admin/berita"
        class="inline-flex items-center justify-center gap-2 px-5 py-3 rounded-xl bg-[#D91E28] hover:bg-red-700 text-white text-xs font-extrabold shadow shrink-0 transition-colors"
      >
        <Plus class="w-4 h-4" /> Tulis Berita Baru
      </router-link>
    </div>

    <!-- KPI Grid -->
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-3.5 sm:gap-4">
      <div class="bg-white rounded-2xl border border-slate-200 p-4 shadow-2xs">
        <div class="flex items-center justify-between">
          <span class="text-xs font-bold text-slate-500">Total Berita</span>
          <span class="w-9 h-9 rounded-xl bg-blue-50 text-[#0B2563] flex items-center justify-center">
            <Newspaper class="w-4 h-4" />
          </span>
        </div>
        <div class="text-2xl font-black text-slate-900 mt-2">{{ formatNumber(stats.total_articles) }}</div>
        <div class="text-[11px] text-emerald-600 font-bold mt-1">
          {{ stats.published_articles }} tayang &bull; {{ stats.draft_articles }} draft
        </div>
      </div>

      <div class="bg-white rounded-2xl border border-slate-200 p-4 shadow-2xs">
        <div class="flex items-center justify-between">
          <span class="text-xs font-bold text-slate-500">Total Pembaca</span>
          <span class="w-9 h-9 rounded-xl bg-red-50 text-[#D91E28] flex items-center justify-center">
            <Eye class="w-4 h-4" />
          </span>
        </div>
        <div class="text-2xl font-black text-slate-900 mt-2">{{ formatNumber(stats.total_views) }}</div>
        <div class="text-[11px] text-slate-500 font-semibold mt-1">Akumulasi tayangan artikel</div>
      </div>

      <div class="bg-white rounded-2xl border border-slate-200 p-4 shadow-2xs">
        <div class="flex items-center justify-between">
          <span class="text-xs font-bold text-slate-500">Komentar</span>
          <span class="w-9 h-9 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
            <MessageSquare class="w-4 h-4" />
          </span>
        </div>
        <div class="text-2xl font-black text-slate-900 mt-2">{{ formatNumber(stats.total_comments) }}</div>
        <div class="text-[11px] text-amber-600 font-bold mt-1">
          {{ stats.pending_comments }} menunggu moderasi
        </div>
      </div>

      <div class="bg-white rounded-2xl border border-slate-200 p-4 shadow-2xs">
        <div class="flex items-center justify-between">
          <span class="text-xs font-bold text-slate-500">Rubrik & Media</span>
          <span class="w-9 h-9 rounded-xl bg-indigo-50 text-indigo-700 flex items-center justify-center">
            <Tags class="w-4 h-4" />
          </span>
        </div>
        <div class="text-2xl font-black text-slate-900 mt-2">{{ stats.total_categories }}</div>
        <div class="text-[11px] text-slate-500 font-semibold mt-1 flex items-center gap-2">
          <span class="inline-flex items-center gap-1"><Video class="w-3 h-3" /> {{ stats.total_videos }} Video</span>
          <span class="inline-flex items-center gap-1"><Megaphone class="w-3 h-3" /> {{ stats.total_ads }} Iklan</span>
        </div>
      </div>
    </div>

    <!-- Category Distribution & Top Articles -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-5">
      <div class="lg:col-span-6 bg-white rounded-2xl border border-slate-200 p-5 shadow-2xs space-y-4">
        <div class="flex items-center justify-between">
          <h3 class="text-sm font-black uppercase tracking-tight text-[#0B2563]">Distribusi Berita per Rubrik</h3>
          <router-link to="/admin/kategori" class="text-xs font-bold text-[#D91E28] hover:underline">Kelola &rarr;</router-link>
        </div>
        <div class="space-y-3">
          <div v-for="c in stats.category_stats" :key="c.slug" class="space-y-1">
            <div class="flex items-center justify-between text-xs font-bold">
              <span class="text-slate-700">{{ c.name }}</span>
              <span class="text-[#0B2563]">{{ c.count }} berita <span class="text-slate-400 font-normal">({{ formatNumber(c.views) }} views)</span></span>
            </div>
            <div class="h-2 rounded-full bg-slate-100 overflow-hidden">
              <div
                class="h-full rounded-full bg-gradient-to-r from-[#0B2563] to-[#D91E28]"
                :style="{ width: `${Math.max(6, Math.round((c.count / maxCatCount) * 100))}%` }"
              ></div>
            </div>
          </div>
        </div>
      </div>

      <div class="lg:col-span-6 bg-white rounded-2xl border border-slate-200 p-5 shadow-2xs space-y-4">
        <div class="flex items-center justify-between">
          <h3 class="text-sm font-black uppercase tracking-tight text-[#0B2563] flex items-center gap-1.5">
            <TrendingUp class="w-4 h-4 text-[#D91E28]" /> Berita Paling Banyak Dibaca
          </h3>
          <router-link to="/admin/berita" class="text-xs font-bold text-[#D91E28] hover:underline">Semua &rarr;</router-link>
        </div>
        <div class="space-y-3">
          <div
            v-for="art in stats.top_articles"
            :key="art.id"
            class="flex items-center gap-3 p-2.5 rounded-xl bg-slate-50 border border-slate-100"
          >
            <img :src="resolveImg(art.thumbnail)" :alt="art.title" class="w-14 h-12 rounded-lg object-cover shrink-0" />
            <div class="flex-1 min-w-0">
              <div class="text-xs font-bold text-slate-900 line-clamp-1">{{ art.title }}</div>
              <div class="text-[11px] text-slate-500 mt-0.5 flex items-center gap-2">
                <span class="font-bold text-[#0B2563]">{{ art.category_name }}</span>
                <span>&bull;</span>
                <span>{{ formatNumber(art.views) }} views</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Latest Articles Table -->
    <div class="bg-white rounded-2xl border border-slate-200 p-5 shadow-2xs space-y-4">
      <div class="flex items-center justify-between">
        <h3 class="text-sm font-black uppercase tracking-tight text-[#0B2563]">Artikel Terbaru</h3>
        <router-link to="/admin/berita" class="text-xs font-bold text-[#D91E28] hover:underline">Kelola Berita &rarr;</router-link>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full text-left text-xs">
          <thead>
            <tr class="border-b border-slate-200 text-slate-400 uppercase text-[10px]">
              <th class="pb-2.5 font-extrabold">Judul</th>
              <th class="pb-2.5 font-extrabold">Rubrik</th>
              <th class="pb-2.5 font-extrabold">Status</th>
              <th class="pb-2.5 font-extrabold">Views</th>
              <th class="pb-2.5 font-extrabold">Terbit</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100">
            <tr v-for="art in stats.latest_articles" :key="art.id">
              <td class="py-3 pr-4 font-bold text-slate-900 max-w-md truncate">{{ art.title }}</td>
              <td class="py-3 pr-4">
                <span class="px-2 py-0.5 rounded bg-blue-50 text-[#0B2563] font-bold">{{ art.category_name }}</span>
              </td>
              <td class="py-3 pr-4">
                <span
                  class="px-2 py-0.5 rounded-full text-[10px] font-extrabold uppercase"
                  :class="art.status === 'published' ? 'bg-emerald-50 text-emerald-700' : 'bg-amber-50 text-amber-700'"
                >
                  {{ art.status }}
                </span>
              </td>
              <td class="py-3 pr-4 font-semibold text-slate-600">{{ formatNumber(art.views) }}</td>
              <td class="py-3 text-slate-500 whitespace-nowrap">{{ timeAgoID(art.published_at) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
