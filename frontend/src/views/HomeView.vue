<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { api, resolveImg, timeAgoID, formatNumber } from '../api/client'
import { portalState } from '../composables/usePortal'
import NewsCard from '../components/NewsCard.vue'
import AdBanner from '../components/AdBanner.vue'
import {
  Zap,
  Flame,
  ChevronLeft,
  ChevronRight,
  ArrowRight,
  Play,
  Camera,
  BookOpen,
  Eye,
  Clock,
} from 'lucide-vue-next'

const loading = ref(true)
const latestArticles = ref([])
const popularArticles = ref([])
const editorialArticles = ref([])
const photoArticles = ref([])
const videos = ref([])
const ads = ref([])

const activeFilter = ref('all')
const heroIndex = ref(0)
let heroTimer = null
let touchStartX = 0

const heroSlides = computed(() => {
  const featured = latestArticles.value.filter((a) => a.is_featured)
  const base = featured.length >= 3 ? featured : latestArticles.value
  return base.slice(0, 5)
})

const currentHero = computed(() => heroSlides.value[heroIndex.value] || latestArticles.value[0] || null)

const filteredLatest = computed(() => {
  if (activeFilter.value === 'all') return latestArticles.value.slice(0, 10)
  return latestArticles.value
    .filter((a) => a.category_slug === activeFilter.value)
    .slice(0, 8)
})

const quickTabs = [
  { slug: 'all', label: 'Semua' },
  { slug: 'nasional', label: 'Nasional' },
  { slug: 'daerah', label: 'Daerah' },
  { slug: 'politik', label: 'Politik' },
  { slug: 'hukum', label: 'Hukum' },
  { slug: 'ekonomi', label: 'Ekonomi' },
  { slug: 'teknologi', label: 'Teknologi' },
  { slug: 'olahraga', label: 'Olahraga' },
]

function nextSlide() {
  if (!heroSlides.value.length) return
  heroIndex.value = (heroIndex.value + 1) % heroSlides.value.length
}

function prevSlide() {
  if (!heroSlides.value.length) return
  heroIndex.value = (heroIndex.value - 1 + heroSlides.value.length) % heroSlides.value.length
}

function onTouchStart(e) {
  touchStartX = e.changedTouches[0].clientX
}
function onTouchEnd(e) {
  const delta = e.changedTouches[0].clientX - touchStartX
  if (Math.abs(delta) > 40) {
    if (delta < 0) nextSlide()
    else prevSlide()
  }
}

async function loadHome() {
  loading.value = true
  try {
    const [latestRes, popRes, edRes, fotoRes, vidRes, adRes] = await Promise.all([
      api.get('/articles?limit=30'),
      api.get('/articles?sort=popular&limit=6'),
      api.get('/articles?category=editorial&limit=3'),
      api.get('/articles?category=foto&limit=3'),
      api.get('/videos'),
      api.get('/ads'),
    ])
    latestArticles.value = latestRes.data || []
    popularArticles.value = popRes.data || []
    editorialArticles.value = edRes.data || []
    photoArticles.value = fotoRes.data || []
    videos.value = vidRes.data || []
    ads.value = adRes.data || []
  } catch (e) {
    console.error('Home load error:', e)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadHome()
  heroTimer = setInterval(nextSlide, 5500)
})

onUnmounted(() => {
  if (heroTimer) clearInterval(heroTimer)
})
</script>

<template>
  <div class="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8 py-4 sm:py-6 space-y-6 sm:space-y-8">
    <!-- ==================== 1. BREAKING NEWS TICKER ==================== -->
    <div class="bg-white border border-slate-200/90 rounded-2xl p-1.5 sm:p-2 flex items-center gap-2.5 shadow-2xs overflow-hidden">
      <div class="flex items-center gap-1.5 bg-[#D91E28] text-white text-[10px] sm:text-[11px] font-black uppercase px-2.5 sm:px-3 py-1.5 rounded-xl shrink-0">
        <span class="relative flex h-2 w-2">
          <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-[#F5B700] opacity-75"></span>
          <span class="relative inline-flex rounded-full h-2 w-2 bg-[#F5B700]"></span>
        </span>
        <Zap class="w-3.5 h-3.5 fill-current hidden sm:inline" />
        <span>BREAKING</span>
      </div>

      <div class="flex-1 overflow-hidden relative">
        <div v-if="popularArticles.length" class="animate-marquee items-center gap-8 text-xs sm:text-[13px] font-semibold text-slate-800">
          <template v-for="copy in 2" :key="copy">
            <router-link
              v-for="art in popularArticles"
              :key="`${copy}-${art.id}`"
              :to="`/berita/${art.slug}`"
              class="inline-flex items-center gap-2 hover:text-[#D91E28] transition-colors whitespace-nowrap"
            >
              <span class="w-1.5 h-1.5 rounded-full bg-[#0B2563]"></span>
              <span>{{ art.title }}</span>
            </router-link>
          </template>
        </div>
        <div v-else class="text-xs text-slate-400 py-1">Memuat berita terkini Media Four Tribuan News...</div>
      </div>
    </div>

    <!-- LOADING SKELETON -->
    <div v-if="loading" class="grid grid-cols-1 lg:grid-cols-12 gap-5">
      <div class="lg:col-span-8 h-72 sm:h-96 rounded-2xl bg-slate-200 animate-pulse"></div>
      <div class="lg:col-span-4 h-72 sm:h-96 rounded-2xl bg-slate-200 animate-pulse"></div>
    </div>

    <template v-else>
      <!-- ==================== 2A. MOBILE-VERSE SWIPE HERO CAROUSEL ==================== -->
      <section v-if="currentHero" class="lg:hidden" @touchstart="onTouchStart" @touchend="onTouchEnd">
        <div class="relative rounded-2xl overflow-hidden bg-slate-950 h-[290px] sm:h-[360px] shadow-md">
          <router-link :to="`/berita/${currentHero.slug}`" class="block w-full h-full">
            <img
              :src="resolveImg(currentHero.thumbnail)"
              :alt="currentHero.title"
              class="w-full h-full object-cover transition-all duration-500"
            />
          </router-link>
          <div class="absolute inset-0 bg-gradient-to-t from-[#081A47] via-[#081A47]/45 to-transparent pointer-events-none"></div>

          <!-- Top Pill + Slide Counter -->
          <div class="absolute top-3 inset-x-3 flex items-center justify-between z-10">
            <span class="bg-[#D91E28] text-white text-[10px] font-black uppercase tracking-wider px-2.5 py-1 rounded-lg shadow-xs">
              HEADLINE &bull; {{ currentHero.category_name }}
            </span>
            <span class="bg-black/50 backdrop-blur-xs text-white text-[10px] font-bold px-2.5 py-1 rounded-full">
              {{ heroIndex + 1 }} / {{ heroSlides.length }}
            </span>
          </div>

          <!-- Prev / Next -->
          <button
            type="button"
            @click="prevSlide"
            aria-label="Berita Sebelumnya"
            class="absolute left-2.5 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-black/45 hover:bg-[#D91E28] text-white flex items-center justify-center backdrop-blur-xs z-20"
          >
            <ChevronLeft class="w-4 h-4" />
          </button>
          <button
            type="button"
            @click="nextSlide"
            aria-label="Berita Selanjutnya"
            class="absolute right-2.5 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-black/45 hover:bg-[#D91E28] text-white flex items-center justify-center backdrop-blur-xs z-20"
          >
            <ChevronRight class="w-4 h-4" />
          </button>

          <!-- Overlay Caption -->
          <div class="absolute bottom-0 inset-x-0 p-4 z-10">
            <router-link :to="`/berita/${currentHero.slug}`">
              <h1 class="font-editorial text-lg sm:text-2xl font-bold text-white leading-snug line-clamp-2 drop-shadow">
                {{ currentHero.title }}
              </h1>
            </router-link>
            <div class="flex items-center justify-between mt-2.5">
              <div class="flex items-center gap-2 text-[11px] text-blue-100/90">
                <Clock class="w-3 h-3 text-[#F5B700]" />
                <span>{{ timeAgoID(currentHero.published_at) }}</span>
                <span>&bull;</span>
                <span>{{ currentHero.read_time }}</span>
              </div>
              <div class="flex items-center gap-1.5">
                <button
                  v-for="(s, idx) in heroSlides"
                  :key="s.id"
                  type="button"
                  @click="heroIndex = idx"
                  :aria-label="`Slide ${idx + 1}`"
                  class="h-1.5 rounded-full transition-all"
                  :class="idx === heroIndex ? 'w-5 bg-[#F5B700]' : 'w-1.5 bg-white/40'"
                ></button>
              </div>
            </div>
          </div>
        </div>
      </section>

      <!-- ==================== 2B. DESKTOP EDITORIAL BENTO HERO ==================== -->
      <section v-if="heroSlides.length" class="hidden lg:grid lg:grid-cols-12 gap-5 items-stretch">
        <!-- Main Featured Story (6 cols) -->
        <article
          v-if="heroSlides[0]"
          class="lg:col-span-6 relative rounded-2xl overflow-hidden bg-slate-950 min-h-[450px] group shadow-md"
        >
          <router-link :to="`/berita/${heroSlides[0].slug}`" class="block w-full h-full">
            <img
              :src="resolveImg(heroSlides[0].thumbnail)"
              :alt="heroSlides[0].title"
              class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700"
            />
          </router-link>
          <div class="absolute inset-0 bg-gradient-to-t from-[#081A47] via-[#081A47]/45 to-transparent pointer-events-none"></div>
          <div class="absolute top-4 left-4">
            <span class="inline-flex items-center gap-1.5 bg-[#D91E28] text-white text-[11px] font-black uppercase tracking-wider px-3 py-1 rounded-lg shadow">
              UTAMA &bull; {{ heroSlides[0].category_name }}
            </span>
          </div>
          <div class="absolute bottom-0 inset-x-0 p-6">
            <router-link :to="`/berita/${heroSlides[0].slug}`">
              <h1 class="font-editorial text-2xl xl:text-[28px] font-bold text-white leading-tight group-hover:text-[#F5B700] transition-colors line-clamp-3">
                {{ heroSlides[0].title }}
              </h1>
            </router-link>
            <p class="text-xs xl:text-sm text-blue-100/85 line-clamp-2 mt-2.5 leading-relaxed">
              {{ heroSlides[0].excerpt }}
            </p>
            <div class="flex items-center gap-3 text-xs text-blue-200 mt-3">
              <span class="font-semibold text-[#F5B700]">{{ heroSlides[0].author_name }}</span>
              <span>&bull;</span>
              <span>{{ timeAgoID(heroSlides[0].published_at) }}</span>
              <span>&bull;</span>
              <span class="inline-flex items-center gap-1"><Eye class="w-3.5 h-3.5" /> {{ formatNumber(heroSlides[0].views) }}</span>
            </div>
          </div>
        </article>

        <!-- Secondary Stacked Stories (3 cols) -->
        <div class="lg:col-span-3 flex flex-col gap-5">
          <article
            v-for="sub in heroSlides.slice(1, 3)"
            :key="sub.id"
            class="flex-1 relative rounded-2xl overflow-hidden bg-slate-900 group shadow-sm min-h-[215px]"
          >
            <router-link :to="`/berita/${sub.slug}`" class="block w-full h-full">
              <img
                :src="resolveImg(sub.thumbnail)"
                :alt="sub.title"
                class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
              />
            </router-link>
            <div class="absolute inset-0 bg-gradient-to-t from-slate-950/95 via-slate-950/35 to-transparent pointer-events-none"></div>
            <div class="absolute bottom-0 inset-x-0 p-4">
              <span class="inline-block bg-[#0B2563] text-[#F5B700] text-[9.5px] font-extrabold uppercase tracking-wider px-2 py-0.5 rounded mb-1.5">
                {{ sub.category_name }}
              </span>
              <router-link :to="`/berita/${sub.slug}`">
                <h2 class="text-sm font-bold text-white leading-snug line-clamp-2 group-hover:text-[#F5B700] transition-colors">
                  {{ sub.title }}
                </h2>
              </router-link>
              <div class="text-[10px] text-slate-300 mt-1.5">{{ timeAgoID(sub.published_at) }}</div>
            </div>
          </article>
        </div>

        <!-- Trending #1 - #5 Rail (3 cols) -->
        <aside class="lg:col-span-3 bg-white rounded-2xl border border-slate-200/80 p-4 shadow-xs flex flex-col">
          <div class="flex items-center justify-between pb-3 mb-3 border-b border-slate-100">
            <div class="flex items-center gap-2">
              <span class="w-7 h-7 rounded-lg bg-[#D91E28]/10 text-[#D91E28] flex items-center justify-center">
                <Flame class="w-4 h-4" />
              </span>
              <h2 class="text-sm font-black uppercase tracking-tight text-[#0B2563]">Terpopuler</h2>
            </div>
            <router-link to="/kategori/terpopuler" class="text-[11px] font-bold text-[#D91E28] hover:underline">
              Semua &rarr;
            </router-link>
          </div>
          <div class="flex-1 flex flex-col justify-between">
            <NewsCard
              v-for="(art, idx) in popularArticles.slice(0, 5)"
              :key="art.id"
              :article="art"
              variant="compact"
              :rank="idx + 1"
            />
          </div>
        </aside>
      </section>

      <!-- ==================== 3. BERITA TERBARU + INSTANT CATEGORY CHIPS ==================== -->
      <section class="space-y-4">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div class="flex items-center gap-2.5">
            <span class="w-1.5 h-6 rounded-full bg-gradient-to-b from-[#D91E28] to-[#0B2563]"></span>
            <div>
              <h2 class="text-base sm:text-lg font-black uppercase tracking-tight text-[#0B2563]">
                Berita Terbaru
              </h2>
            </div>
          </div>

          <!-- Swipeable Rubric Filter Chips -->
          <div class="flex items-center gap-1.5 overflow-x-auto no-scrollbar pb-0.5">
            <button
              v-for="tab in quickTabs"
              :key="tab.slug"
              type="button"
              @click="activeFilter = tab.slug"
              class="px-3 py-1.5 rounded-full text-xs font-bold whitespace-nowrap transition-all shrink-0 border"
              :class="activeFilter === tab.slug
                ? 'bg-[#0B2563] text-white border-[#0B2563] shadow-xs'
                : 'bg-white text-slate-600 border-slate-200 hover:border-[#0B2563] hover:text-[#0B2563]'"
            >
              {{ tab.label }}
            </button>
          </div>
        </div>

        <div v-if="filteredLatest.length" class="grid grid-cols-1 md:grid-cols-2 gap-3.5 sm:gap-4">
          <NewsCard
            v-for="art in filteredLatest"
            :key="art.id"
            :article="art"
            variant="horizontal"
          />
        </div>
        <div v-else class="bg-white rounded-2xl p-8 text-center text-sm text-slate-500 border border-slate-200">
          Belum ada berita pada kategori ini.
        </div>

        <div class="text-center pt-1">
          <router-link
            :to="activeFilter === 'all' ? '/kategori/terbaru' : `/kategori/${activeFilter}`"
            class="inline-flex items-center gap-2 px-6 py-2.5 rounded-full bg-white hover:bg-[#0B2563] text-[#0B2563] hover:text-white border border-slate-300 hover:border-[#0B2563] text-xs font-extrabold transition-all shadow-2xs"
          >
            <span>Lihat Semua Berita {{ activeFilter === 'all' ? 'Terbaru' : activeFilter.toUpperCase() }}</span>
            <ArrowRight class="w-3.5 h-3.5" />
          </router-link>
        </div>
      </section>

      <!-- ==================== 4. MOBILE TERPOPULER RANKING ==================== -->
      <section class="lg:hidden bg-white rounded-2xl border border-slate-200/80 p-4 shadow-xs space-y-3">
        <div class="flex items-center justify-between pb-2 border-b border-slate-100">
          <div class="flex items-center gap-2">
            <Flame class="w-4 h-4 text-[#D91E28]" />
            <h2 class="text-sm font-black uppercase tracking-tight text-[#0B2563]">Berita Terpopuler</h2>
          </div>
          <router-link to="/kategori/terpopuler" class="text-[11px] font-bold text-[#D91E28]">
            Lihat Semua &rarr;
          </router-link>
        </div>
        <div>
          <NewsCard
            v-for="(art, idx) in popularArticles.slice(0, 5)"
            :key="art.id"
            :article="art"
            variant="compact"
            :rank="idx + 1"
          />
        </div>
      </section>

      <!-- ==================== 5. AD SLOT: HOME MIDDLE ==================== -->
      <AdBanner :ads="ads" position="home_middle" />

      <!-- ==================== 6. MULTIMEDIA HUB (DARK ROYAL NAVY BAND) ==================== -->
      <section class="rounded-3xl bg-gradient-to-br from-[#081A47] via-[#0B2563] to-[#0F3180] text-white p-5 sm:p-7 shadow-lg border border-blue-900">
        <div class="flex items-center justify-between mb-5">
          <div>
            <span class="text-[10px] font-black uppercase tracking-widest text-[#F5B700]">
              Multimedia & Tajuk
            </span>
            <h2 class="text-lg sm:text-xl font-black tracking-tight text-white">
              Lensa, Video & Editorial Four Tribuan
            </h2>
          </div>
          <router-link to="/kategori/video" class="hidden sm:inline-flex items-center gap-1 text-xs font-bold text-[#F5B700] hover:underline">
            Jelajahi Kanal <ArrowRight class="w-3.5 h-3.5" />
          </router-link>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-5">
          <!-- VIDEO SHOWCASE (5 cols) -->
          <div class="lg:col-span-5 space-y-3">
            <div class="flex items-center gap-2 text-xs font-extrabold uppercase tracking-wider text-[#F5B700]">
              <Play class="w-4 h-4 fill-current text-[#D91E28]" />
              <span>Berita Video</span>
            </div>
            <div
              v-if="videos[0]"
              @click="portalState.videoModal = videos[0]"
              class="group cursor-pointer rounded-2xl overflow-hidden bg-slate-950 border border-white/10"
            >
              <div class="relative aspect-video overflow-hidden">
                <img
                  :src="`https://img.youtube.com/vi/${videos[0].youtube_id}/hqdefault.jpg`"
                  :alt="videos[0].title"
                  class="w-full h-full object-cover opacity-85 group-hover:scale-105 transition-transform duration-500"
                />
                <div class="absolute inset-0 bg-black/30 flex items-center justify-center">
                  <div class="w-14 h-14 rounded-full bg-[#D91E28] group-hover:scale-110 text-white flex items-center justify-center shadow-xl transition-transform">
                    <Play class="w-6 h-6 fill-current ml-0.5" />
                  </div>
                </div>
              </div>
              <div class="p-4">
                <h3 class="text-sm font-bold text-white leading-snug line-clamp-2 group-hover:text-[#F5B700] transition-colors">
                  {{ videos[0].title }}
                </h3>
                <p class="text-xs text-blue-200/80 line-clamp-2 mt-1">{{ videos[0].caption }}</p>
              </div>
            </div>

            <div class="grid grid-cols-2 gap-2.5">
              <button
                v-for="vid in videos.slice(1, 3)"
                :key="vid.id"
                type="button"
                @click="portalState.videoModal = vid"
                class="group text-left bg-white/5 hover:bg-white/10 border border-white/10 rounded-xl p-2.5 transition-colors"
              >
                <div class="relative aspect-video rounded-lg overflow-hidden mb-2 bg-black">
                  <img
                    :src="`https://img.youtube.com/vi/${vid.youtube_id}/mqdefault.jpg`"
                    :alt="vid.title"
                    class="w-full h-full object-cover opacity-85 group-hover:scale-105 transition-transform"
                  />
                  <div class="absolute inset-0 flex items-center justify-center">
                    <span class="w-7 h-7 rounded-full bg-[#D91E28]/90 text-white flex items-center justify-center">
                      <Play class="w-3.5 h-3.5 fill-current ml-0.5" />
                    </span>
                  </div>
                </div>
                <p class="text-[11px] font-bold text-white line-clamp-2 leading-snug">{{ vid.title }}</p>
              </button>
            </div>
          </div>

          <!-- EDITORIAL / TAJUK (4 cols) -->
          <div class="lg:col-span-4 space-y-3">
            <div class="flex items-center gap-2 text-xs font-extrabold uppercase tracking-wider text-[#F5B700]">
              <BookOpen class="w-4 h-4" />
              <span>Editorial & Tajuk</span>
            </div>
            <div class="space-y-3">
              <router-link
                v-for="ed in (editorialArticles.length ? editorialArticles : latestArticles.slice(5, 8))"
                :key="ed.id"
                :to="`/berita/${ed.slug}`"
                class="block bg-white/10 hover:bg-white/15 border border-white/10 rounded-2xl p-4 transition-all group"
              >
                <span class="text-[10px] font-extrabold uppercase tracking-wider text-[#F5B700]">
                  {{ ed.category_name }}
                </span>
                <h3 class="font-editorial text-base font-bold text-white leading-snug mt-1 group-hover:text-[#F5B700] transition-colors line-clamp-2">
                  {{ ed.title }}
                </h3>
                <p class="text-xs text-blue-100/75 line-clamp-2 mt-1.5">{{ ed.excerpt }}</p>
              </router-link>
            </div>
          </div>

          <!-- BERITA FOTO (3 cols) -->
          <div class="lg:col-span-3 space-y-3">
            <div class="flex items-center gap-2 text-xs font-extrabold uppercase tracking-wider text-[#F5B700]">
              <Camera class="w-4 h-4" />
              <span>Lensa Foto</span>
            </div>
            <div class="grid grid-cols-2 lg:grid-cols-1 gap-3">
              <button
                v-for="ph in (photoArticles.length ? photoArticles : latestArticles.slice(8, 10))"
                :key="ph.id"
                type="button"
                @click="portalState.photoModal = ph"
                class="group relative rounded-2xl overflow-hidden aspect-[16/11] bg-slate-900 border border-white/10 text-left"
              >
                <img
                  :src="resolveImg(ph.thumbnail)"
                  :alt="ph.title"
                  class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                />
                <div class="absolute inset-0 bg-gradient-to-t from-black/90 via-black/30 to-transparent"></div>
                <div class="absolute top-2 right-2 w-7 h-7 rounded-lg bg-black/50 text-[#F5B700] flex items-center justify-center backdrop-blur-xs">
                  <Camera class="w-3.5 h-3.5" />
                </div>
                <div class="absolute bottom-0 inset-x-0 p-3">
                  <p class="text-xs font-bold text-white line-clamp-2 leading-snug">{{ ph.title }}</p>
                </div>
              </button>
            </div>
          </div>
        </div>
      </section>

      <!-- ==================== 7. PILIHAN RUBRIK GRID ==================== -->
      <section class="space-y-4">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2.5">
            <span class="w-1.5 h-6 rounded-full bg-[#D91E28]"></span>
            <h2 class="text-base sm:text-lg font-black uppercase tracking-tight text-[#0B2563]">
              Sorotan Nusantara
            </h2>
          </div>
          <router-link to="/kategori/nasional" class="text-xs font-bold text-[#D91E28] hover:underline">
            Lihat Semua &rarr;
          </router-link>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <NewsCard
            v-for="art in latestArticles.slice(10, 18)"
            :key="art.id"
            :article="art"
            variant="grid"
          />
        </div>
      </section>

      <!-- ==================== 8. AD SLOT: HOME BOTTOM ==================== -->
      <AdBanner :ads="ads" position="home_bottom" class="mt-4" />
    </template>
  </div>
</template>
