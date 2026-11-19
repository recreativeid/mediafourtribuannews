<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { resolveImg } from '../api/client'
import { portalState } from '../composables/usePortal'
import {
  ExternalLink,
  ChevronLeft,
  ChevronRight,
  X,
  Sparkles,
} from 'lucide-vue-next'

const props = defineProps({
  ads: { type: Array, default: () => [] },
  position: { type: String, required: true },
  interval: { type: Number, default: 5000 }, // 5 detik per rotasi
  autoRotate: { type: Boolean, default: true },
})

const currentIndex = ref(0)
const isHovered = ref(false)
const isDismissed = ref(false)
let timer = null
let touchStartX = 0

// Source ads: props.ads or portalState.ads fallback
const activeAds = computed(() => {
  const source = props.ads?.length ? props.ads : portalState.ads || []
  return source.filter((a) => a.is_active && a.position === props.position)
})

const currentAd = computed(() => activeAds.value[currentIndex.value] || null)

function nextAd() {
  if (activeAds.value.length <= 1) return
  currentIndex.value = (currentIndex.value + 1) % activeAds.value.length
}

function prevAd() {
  if (activeAds.value.length <= 1) return
  currentIndex.value =
    (currentIndex.value - 1 + activeAds.value.length) % activeAds.value.length
}

function setIndex(idx) {
  currentIndex.value = idx
}

function startTimer() {
  stopTimer()
  if (props.autoRotate && activeAds.value.length > 1) {
    timer = setInterval(() => {
      if (!isHovered.value) {
        nextAd()
      }
    }, props.interval)
  }
}

function stopTimer() {
  if (timer) {
    clearInterval(timer)
    timer = null
  }
}

function onTouchStart(e) {
  touchStartX = e.changedTouches[0].clientX
}

function onTouchEnd(e) {
  const diffX = e.changedTouches[0].clientX - touchStartX
  if (diffX > 40) {
    prevAd()
  } else if (diffX < -40) {
    nextAd()
  }
}

watch(
  () => activeAds.value.length,
  (len) => {
    if (currentIndex.value >= len) {
      currentIndex.value = 0
    }
    startTimer()
  }
)

onMounted(() => {
  startTimer()
})

onUnmounted(() => {
  stopTimer()
})
</script>

<template>
  <!-- Render nothing if no active ads or if dismissed -->
  <div v-if="activeAds.length && !isDismissed">
    <!-- ========================================================================= -->
    <!-- 1. STICKY BOTTOM FLOATING BANNER                                          -->
    <!-- ========================================================================= -->
    <div
      v-if="position === 'sticky_bottom'"
      @mouseenter="isHovered = true"
      @mouseleave="isHovered = false"
      @touchstart="onTouchStart"
      @touchend="onTouchEnd"
      class="fixed bottom-0 inset-x-0 z-40 bg-slate-950/95 backdrop-blur-md text-white border-t-2 border-[#F5B700] shadow-2xl transition-all duration-300"
    >
      <div class="max-w-7xl mx-auto px-3 sm:px-6 py-2 sm:py-2.5 flex items-center justify-between gap-3">
        <!-- Close button -->
        <button
          type="button"
          @click="isDismissed = true"
          class="order-last sm:order-first p-1.5 rounded-lg bg-white/10 hover:bg-[#D91E28] text-white/80 hover:text-white transition-colors"
          title="Tutup Iklan"
        >
          <X class="w-4 h-4" />
        </button>

        <!-- Current Banner Content -->
        <div class="flex-1 min-w-0 flex items-center gap-3">
          <span class="hidden sm:inline-flex items-center gap-1 px-2 py-0.5 rounded bg-[#F5B700] text-slate-950 text-[10px] font-black uppercase tracking-wider shrink-0">
            <Sparkles class="w-3 h-3" /> Mitra Resmi
          </span>
          <a
            :href="currentAd.target_url || '#'"
            :target="currentAd.target_url?.startsWith('http') ? '_blank' : '_self'"
            rel="noopener noreferrer"
            class="flex items-center gap-3 min-w-0 group"
          >
            <img
              v-if="currentAd.image"
              :src="resolveImg(currentAd.image)"
              :alt="currentAd.title"
              class="w-12 h-9 sm:w-16 sm:h-10 rounded-md object-cover shrink-0 border border-white/20"
            />
            <div class="min-w-0">
              <h4 class="text-xs sm:text-sm font-bold text-white group-hover:text-[#F5B700] transition-colors truncate">
                {{ currentAd.title }}
              </h4>
              <p v-if="currentAd.description" class="text-[11px] text-slate-300 truncate hidden md:block">
                {{ currentAd.description }}
              </p>
            </div>
          </a>
        </div>

        <!-- Carousel Indicators & Arrows if multiple -->
        <div v-if="activeAds.length > 1" class="flex items-center gap-2 shrink-0">
          <div class="hidden sm:flex items-center gap-1 text-[10px] text-slate-300 font-mono">
            <span>{{ currentIndex + 1 }}/{{ activeAds.length }}</span>
          </div>
          <button
            type="button"
            @click="prevAd"
            class="p-1 rounded bg-white/10 hover:bg-white/25 text-white transition-colors"
          >
            <ChevronLeft class="w-3.5 h-3.5" />
          </button>
          <button
            type="button"
            @click="nextAd"
            class="p-1 rounded bg-white/10 hover:bg-white/25 text-white transition-colors"
          >
            <ChevronRight class="w-3.5 h-3.5" />
          </button>
        </div>
      </div>
    </div>

    <!-- ========================================================================= -->
    <!-- 2. DESKTOP FLOATING SKYSCRAPER (LEFT OR RIGHT)                           -->
    <!-- ========================================================================= -->
    <div
      v-else-if="position === 'sidebar_left' || position === 'sidebar_right'"
      @mouseenter="isHovered = true"
      @mouseleave="isHovered = false"
      class="fixed top-28 z-30 hidden 2xl:block w-36 shadow-xl rounded-2xl overflow-hidden border border-slate-200/90 bg-white"
      :class="position === 'sidebar_left' ? 'left-3' : 'right-3'"
    >
      <div class="p-1.5 bg-[#0B2563] text-white flex items-center justify-between text-[10px] font-bold">
        <span class="truncate">Sponsor</span>
        <button type="button" @click="isDismissed = true" class="hover:text-[#F5B700]" title="Tutup">
          <X class="w-3 h-3" />
        </button>
      </div>

      <div class="relative group">
        <a
          :href="currentAd.target_url || '#'"
          :target="currentAd.target_url?.startsWith('http') ? '_blank' : '_self'"
          rel="noopener noreferrer"
          class="block"
        >
          <div class="aspect-[1/2] bg-slate-900 overflow-hidden relative">
            <img
              :src="resolveImg(currentAd.image)"
              :alt="currentAd.title"
              class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500 opacity-90"
            />
            <div class="absolute inset-0 bg-gradient-to-t from-[#0B2563] via-transparent to-transparent flex items-end p-2.5">
              <div class="text-white">
                <span class="inline-block bg-[#F5B700] text-slate-950 text-[9px] font-black uppercase px-1.5 py-0.5 rounded mb-1">
                  Mitra
                </span>
                <h5 class="text-xs font-bold leading-tight line-clamp-2">{{ currentAd.title }}</h5>
              </div>
            </div>
          </div>
        </a>

        <!-- Controls if multiple -->
        <div
          v-if="activeAds.length > 1"
          class="p-1.5 bg-slate-50 border-t border-slate-100 flex items-center justify-between text-[10px]"
        >
          <button type="button" @click="prevAd" class="p-0.5 hover:text-[#0B2563]">
            <ChevronLeft class="w-3 h-3" />
          </button>
          <span class="font-mono text-slate-500">{{ currentIndex + 1 }}/{{ activeAds.length }}</span>
          <button type="button" @click="nextAd" class="p-0.5 hover:text-[#0B2563]">
            <ChevronRight class="w-3 h-3" />
          </button>
        </div>
      </div>
    </div>

    <!-- ========================================================================= -->
    <!-- 3. IN-PAGE BANNER / CAROUSEL (TOP, MIDDLE, SIDEBAR, IN-ARTICLE, ETC.)    -->
    <!-- ========================================================================= -->
    <div
      v-else
      @mouseenter="isHovered = true"
      @mouseleave="isHovered = false"
      @touchstart="onTouchStart"
      @touchend="onTouchEnd"
      class="group/banner relative rounded-2xl overflow-hidden border border-slate-200/90 bg-white shadow-xs transition-shadow hover:shadow-md"
    >
      <!-- Top Meta Strip -->
      <div class="px-3.5 py-1.5 bg-slate-50/95 border-b border-slate-100 flex items-center justify-between text-[10px] font-extrabold uppercase tracking-wider text-slate-500">
        <div class="flex items-center gap-2 min-w-0">
          <span class="text-[#0B2563]">Advertorial / Sponsor Resmi</span>
          <!-- Dynamic rotation counter badge if multiple ads -->
          <span
            v-if="activeAds.length > 1"
            class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-blue-100/80 text-[#0B2563] text-[9px] font-bold lowercase tracking-normal"
          >
            <span class="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
            <span>bergantian {{ currentIndex + 1 }} dari {{ activeAds.length }}</span>
          </span>
        </div>

        <div class="flex items-center gap-2 shrink-0">
          <!-- Prev / Next buttons if multiple ads -->
          <div v-if="activeAds.length > 1" class="flex items-center gap-1">
            <button
              type="button"
              @click="prevAd"
              class="w-5 h-5 rounded-md bg-white border border-slate-200 hover:bg-[#0B2563] hover:text-white flex items-center justify-center transition-colors"
              title="Iklan Sebelumnya"
            >
              <ChevronLeft class="w-3 h-3" />
            </button>
            <button
              type="button"
              @click="nextAd"
              class="w-5 h-5 rounded-md bg-white border border-slate-200 hover:bg-[#0B2563] hover:text-white flex items-center justify-center transition-colors"
              title="Iklan Selanjutnya"
            >
              <ChevronRight class="w-3 h-3" />
            </button>
          </div>
          <ExternalLink class="w-3.5 h-3.5 text-slate-400" />
        </div>
      </div>

      <!-- HTML Ad Slot -->
      <div v-if="currentAd.type === 'html' && currentAd.html_code" class="p-3" v-html="currentAd.html_code"></div>

      <!-- Image Banner Slot -->
      <a
        v-else
        :href="currentAd.target_url || '#'"
        :target="currentAd.target_url?.startsWith('http') ? '_blank' : '_self'"
        rel="noopener noreferrer"
        class="group block relative overflow-hidden"
      >
        <!-- Adaptive Aspect Ratio based on position -->
        <div
          class="relative bg-slate-900 overflow-hidden"
          :class="{
            'aspect-[16/5] sm:aspect-[21/5]': position === 'home_middle' || position === 'home_bottom' || position === 'top_header',
            'aspect-[16/9] sm:aspect-[4/3]': position === 'sidebar',
            'aspect-[16/6]': position === 'article_top' || position === 'article_middle' || position === 'article_bottom',
            'aspect-[16/5]': !['home_middle', 'home_bottom', 'top_header', 'sidebar', 'article_top', 'article_middle', 'article_bottom'].includes(position),
          }"
        >
          <img
            :key="currentAd.id"
            :src="resolveImg(currentAd.image)"
            :alt="currentAd.title"
            class="w-full h-full object-cover opacity-90 group-hover:scale-105 transition-transform duration-700"
          />

          <!-- Gradient Overlay -->
          <div class="absolute inset-0 bg-gradient-to-r from-[#0B2563]/90 via-[#0B2563]/60 to-transparent flex items-center p-4 sm:p-6">
            <div class="max-w-xl text-white">
              <span class="inline-block bg-[#F5B700] text-slate-950 text-[10px] font-black uppercase px-2 py-0.5 rounded mb-1.5 shadow-2xs">
                Mitra Resmi MFTN
              </span>
              <h4
                class="font-black leading-snug line-clamp-2"
                :class="position === 'sidebar' ? 'text-sm sm:text-base' : 'text-base sm:text-xl'"
              >
                {{ currentAd.title }}
              </h4>
              <p
                v-if="currentAd.description"
                class="text-xs text-slate-200 mt-1.5 line-clamp-1 sm:line-clamp-2"
              >
                {{ currentAd.description }}
              </p>
            </div>
          </div>
        </div>
      </a>

      <!-- Dot Indicators at bottom if multiple ads -->
      <div
        v-if="activeAds.length > 1"
        class="py-1.5 bg-slate-50/80 border-t border-slate-100 flex items-center justify-center gap-1.5"
      >
        <button
          v-for="(_, idx) in activeAds"
          :key="idx"
          type="button"
          @click="setIndex(idx)"
          class="h-1.5 rounded-full transition-all duration-300"
          :class="idx === currentIndex ? 'w-6 bg-[#0B2563]' : 'w-1.5 bg-slate-300 hover:bg-slate-400'"
          :title="`Tampilkan Iklan ke-${idx + 1}`"
        ></button>
      </div>
    </div>
  </div>
</template>
