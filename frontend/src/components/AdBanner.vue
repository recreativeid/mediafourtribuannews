<script setup>
import { computed } from 'vue'
import { resolveImg } from '../api/client'
import { ExternalLink } from 'lucide-vue-next'

const props = defineProps({
  ads: { type: Array, default: () => [] },
  position: { type: String, required: true },
})

const matchedAds = computed(() =>
  props.ads.filter((a) => a.is_active && a.position === props.position)
)
</script>

<template>
  <div v-if="matchedAds.length" class="space-y-3">
    <div
      v-for="ad in matchedAds"
      :key="ad.id"
      class="rounded-2xl overflow-hidden border border-slate-200/80 bg-white shadow-xs"
    >
      <div class="px-3 py-1 bg-slate-50 border-b border-slate-100 flex items-center justify-between text-[10px] font-bold uppercase tracking-wider text-slate-400">
        <span>Advertorial / Sponsor</span>
        <ExternalLink class="w-3 h-3" />
      </div>
      <div v-if="ad.type === 'html' && ad.html_code" class="p-3" v-html="ad.html_code"></div>
      <a
        v-else
        :href="ad.target_url || '#'"
        :target="ad.target_url?.startsWith('http') ? '_blank' : '_self'"
        rel="noopener noreferrer"
        class="group block relative"
      >
        <div class="relative aspect-[16/5] sm:aspect-[21/5] bg-slate-900 overflow-hidden">
          <img
            :src="resolveImg(ad.image)"
            :alt="ad.title"
            class="w-full h-full object-cover opacity-85 group-hover:scale-105 transition-transform duration-500"
          />
          <div class="absolute inset-0 bg-gradient-to-r from-[#0B2563]/90 via-[#0B2563]/65 to-transparent flex items-center p-4 sm:p-6">
            <div class="max-w-lg text-white">
              <span class="inline-block bg-[#F5B700] text-slate-950 text-[10px] font-black uppercase px-2 py-0.5 rounded mb-1.5">
                Mitra Resmi
              </span>
              <h4 class="text-sm sm:text-lg font-extrabold leading-snug">{{ ad.title }}</h4>
              <p v-if="ad.description" class="text-[11px] sm:text-xs text-slate-200 mt-1 line-clamp-1">
                {{ ad.description }}
              </p>
            </div>
          </div>
        </div>
      </a>
    </div>
  </div>
</template>
