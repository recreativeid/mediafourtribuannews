<script setup>
import { resolveImg, timeAgoID, formatNumber } from '../api/client'
import { isBookmarked, toggleBookmark } from '../composables/usePortal'
import { Bookmark, Clock, Eye } from 'lucide-vue-next'

defineProps({
  article: { type: Object, required: true },
  variant: { type: String, default: 'horizontal' }, // horizontal | grid | compact
  rank: { type: Number, default: 0 },
})
</script>

<template>
  <!-- HORIZONTAL (Mobile-First Feed Card) -->
  <article
    v-if="variant === 'horizontal'"
    class="group bg-white rounded-2xl border border-slate-200/80 p-3 sm:p-3.5 flex gap-3 sm:gap-4 items-stretch shadow-[0_1px_3px_rgba(11,37,99,0.04)] hover:shadow-md hover:border-[#1648B8]/30 transition-all"
  >
    <router-link
      :to="`/berita/${article.slug}`"
      class="relative w-28 sm:w-36 h-24 sm:h-28 rounded-xl overflow-hidden shrink-0 bg-slate-100"
    >
      <img
        :src="resolveImg(article.thumbnail)"
        :alt="article.title"
        loading="lazy"
        class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
      />
      <span
        v-if="article.category_name"
        class="absolute top-1.5 left-1.5 bg-[#0B2563]/90 text-white text-[9px] font-extrabold uppercase tracking-wider px-2 py-0.5 rounded-md backdrop-blur-xs"
      >
        {{ article.category_name }}
      </span>
    </router-link>

    <div class="flex-1 min-w-0 flex flex-col justify-between">
      <div>
        <div class="flex items-center justify-between gap-2 mb-1">
          <span class="text-[10px] font-extrabold uppercase tracking-wider text-[#D91E28]">
            {{ article.category_name }}
          </span>
          <button
            type="button"
            @click.prevent="toggleBookmark(article)"
            :aria-label="isBookmarked(article.slug) ? 'Hapus dari tersimpan' : 'Simpan berita'"
            class="p-1 -mr-1 rounded-lg transition-colors"
            :class="isBookmarked(article.slug) ? 'text-[#D91E28] bg-red-50' : 'text-slate-400 hover:text-[#0B2563] hover:bg-slate-100'"
          >
            <Bookmark class="w-3.5 h-3.5" :class="{ 'fill-current': isBookmarked(article.slug) }" />
          </button>
        </div>

        <router-link :to="`/berita/${article.slug}`">
          <h3 class="text-[13.5px] sm:text-[15px] font-bold text-slate-900 group-hover:text-[#0B2563] leading-snug line-clamp-2 transition-colors">
            {{ article.title }}
          </h3>
        </router-link>
        <p v-if="article.excerpt" class="hidden sm:line-clamp-1 text-xs text-slate-500 mt-1">
          {{ article.excerpt }}
        </p>
      </div>

      <div class="flex items-center gap-3 text-[11px] text-slate-500 mt-2">
        <span class="inline-flex items-center gap-1">
          <Clock class="w-3 h-3 text-slate-400" />
          {{ timeAgoID(article.published_at) }}
        </span>
        <span class="inline-flex items-center gap-1">
          <Eye class="w-3 h-3 text-slate-400" />
          {{ formatNumber(article.views) }}
        </span>
      </div>
    </div>
  </article>

  <!-- GRID CARD -->
  <article
    v-else-if="variant === 'grid'"
    class="group bg-white rounded-2xl border border-slate-200/80 overflow-hidden shadow-[0_1px_3px_rgba(11,37,99,0.04)] hover:shadow-lg hover:border-[#1648B8]/30 transition-all flex flex-col"
  >
    <router-link :to="`/berita/${article.slug}`" class="relative aspect-[16/10] bg-slate-100 overflow-hidden block">
      <img
        :src="resolveImg(article.thumbnail)"
        :alt="article.title"
        loading="lazy"
        class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
      />
      <span class="absolute top-2.5 left-2.5 bg-[#D91E28] text-white text-[10px] font-extrabold uppercase tracking-wider px-2.5 py-0.5 rounded-md shadow-xs">
        {{ article.category_name }}
      </span>
    </router-link>

    <div class="p-4 flex flex-col flex-1 justify-between">
      <div>
        <router-link :to="`/berita/${article.slug}`">
          <h3 class="text-sm sm:text-[15px] font-bold text-slate-900 group-hover:text-[#0B2563] leading-snug line-clamp-2 transition-colors">
            {{ article.title }}
          </h3>
        </router-link>
        <p class="text-xs text-slate-500 line-clamp-2 mt-1.5 leading-relaxed">
          {{ article.excerpt }}
        </p>
      </div>

      <div class="flex items-center justify-between pt-3 mt-3 border-t border-slate-100 text-[11px] text-slate-500">
        <div class="flex items-center gap-2.5">
          <span>{{ timeAgoID(article.published_at) }}</span>
          <span>&bull;</span>
          <span>{{ article.read_time || '3 menit' }}</span>
        </div>
        <button
          type="button"
          @click.prevent="toggleBookmark(article)"
          class="p-1 rounded-lg transition-colors"
          :class="isBookmarked(article.slug) ? 'text-[#D91E28] bg-red-50' : 'text-slate-400 hover:text-[#0B2563]'"
          aria-label="Simpan berita"
        >
          <Bookmark class="w-3.5 h-3.5" :class="{ 'fill-current': isBookmarked(article.slug) }" />
        </button>
      </div>
    </div>
  </article>

  <!-- COMPACT TRENDING ITEM -->
  <article
    v-else
    class="group flex items-start gap-3 py-2.5 first:pt-0 last:pb-0 border-b last:border-b-0 border-slate-100"
  >
    <div
      v-if="rank > 0"
      class="w-7 h-7 rounded-lg font-extrabold text-xs flex items-center justify-center shrink-0 mt-0.5"
      :class="rank === 1 ? 'bg-[#D91E28] text-white shadow-xs' : rank === 2 ? 'bg-[#0B2563] text-white' : rank === 3 ? 'bg-[#F5B700] text-slate-950' : 'bg-slate-100 text-slate-600'"
    >
      {{ rank }}
    </div>
    <div class="flex-1 min-w-0">
      <router-link :to="`/berita/${article.slug}`">
        <h4 class="text-[13px] font-bold text-slate-900 group-hover:text-[#D91E28] leading-snug line-clamp-2 transition-colors">
          {{ article.title }}
        </h4>
      </router-link>
      <div class="flex items-center gap-2 mt-1 text-[10.5px] text-slate-500">
        <span class="font-bold text-[#0B2563] uppercase">{{ article.category_name }}</span>
        <span>&bull;</span>
        <span class="inline-flex items-center gap-0.5">
          <Eye class="w-3 h-3" /> {{ formatNumber(article.views) }}
        </span>
      </div>
    </div>
    <router-link
      :to="`/berita/${article.slug}`"
      class="w-16 h-14 rounded-lg overflow-hidden shrink-0 bg-slate-100 hidden sm:block"
    >
      <img
        :src="resolveImg(article.thumbnail)"
        :alt="article.title"
        loading="lazy"
        class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
      />
    </router-link>
  </article>
</template>
