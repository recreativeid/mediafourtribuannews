<script setup>
import { ref, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  portalState,
  clearBookmarks,
  toggleBookmark,
} from '../composables/usePortal'
import { resolveImg, timeAgoID } from '../api/client'
import AdBanner from '../components/AdBanner.vue'
import {
  Search,
  Menu,
  X,
  Bookmark,
  Home,
  LayoutGrid,
  Info,
  Phone,
  Mail,
  MapPin,
  ChevronRight,
  Trash2,
  Play,
  Flame,
  Calendar,
  ArrowUp,
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const searchInput = ref('')

function scrollToTop() {
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const todayID = computed(() =>
  new Intl.DateTimeFormat('id-ID', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  }).format(new Date())
)

const primaryNav = computed(() => {
  const preferred = ['nasional', 'daerah', 'politik', 'hukum', 'ekonomi', 'bisnis', 'olahraga', 'teknologi', 'pendidikan', 'internasional', 'editorial']
  if (!portalState.categories.length) {
    return preferred.map((slug) => ({
      slug,
      name: slug.charAt(0).toUpperCase() + slug.slice(1),
    }))
  }
  const bySlug = Object.fromEntries(portalState.categories.map((c) => [c.slug, c]))
  const ordered = preferred.map((s) => bySlug[s]).filter(Boolean)
  const rest = portalState.categories.filter((c) => !preferred.includes(c.slug))
  return [...ordered, ...rest].slice(0, 12)
})

function submitSearch() {
  const q = searchInput.value.trim()
  portalState.searchOpen = false
  if (q) {
    router.push({ name: 'search', query: { q } })
  } else {
    router.push({ name: 'search' })
  }
}

function goCategory(slug) {
  portalState.drawerOpen = false
  router.push(`/kategori/${slug}`)
}

function openQuickTag(tag) {
  portalState.searchOpen = false
  searchInput.value = tag
  router.push({ name: 'search', query: { q: tag } })
}
</script>

<template>
  <div class="min-h-screen flex flex-col bg-[#F5F7FB] pb-16 lg:pb-0">
    <!-- ==================== HEADER ==================== -->
    <header class="sticky top-0 z-40 shadow-sm">
      <!-- 1. Top Royal Blue National Strip -->
      <div class="bg-[#0B2563] text-white/90 text-[11px] border-b border-blue-900/60">
        <div class="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8 h-8 flex items-center justify-between gap-3">
          <div class="flex items-center gap-2 min-w-0">
            <Calendar class="w-3.5 h-3.5 text-[#F5B700] shrink-0" />
            <span class="truncate font-medium">{{ todayID }}</span>
            <span class="hidden md:inline text-white/30">|</span>
            <span class="hidden md:inline text-[#F5B700] font-bold tracking-wide">
              {{ portalState.settings.site_tagline }}
            </span>
          </div>

          <div class="flex items-center gap-3 shrink-0">
            <router-link to="/redaksi" class="hover:text-[#F5B700] transition-colors font-semibold">
              Redaksi
            </router-link>
            <router-link to="/kode-etik" class="hidden sm:inline hover:text-[#F5B700] transition-colors font-semibold">
              Kode Etik
            </router-link>
            <router-link to="/indeks" class="hidden sm:inline hover:text-[#F5B700] transition-colors font-semibold">
              Indeks
            </router-link>
            <router-link to="/tentang" class="hover:text-[#F5B700] transition-colors font-semibold">
              Tentang Kami
            </router-link>
          </div>
        </div>
      </div>

      <!-- 2. White Seamless Logo Masthead -->
      <div class="bg-white border-b border-slate-200/80">
        <div class="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8 h-16 sm:h-20 flex items-center justify-between gap-3">
          <!-- Brand Logo (seamless on pure white) -->
          <router-link to="/" class="flex items-center gap-2.5 shrink-0 group" aria-label="Media Four Tribuan News Beranda">
            <img
              src="/images/logo-mftn.jpg"
              alt="Media Four Tribuan News Nasional"
              class="h-12 sm:h-16 w-auto object-contain group-hover:scale-[1.02] transition-transform"
            />
          </router-link>

          <!-- Desktop Search Pill -->
          <form
            @submit.prevent="submitSearch"
            class="hidden lg:flex items-center flex-1 max-w-md mx-6 relative"
          >
            <input
              v-model="searchInput"
              type="text"
              placeholder="Cari berita nasional, daerah, politik, hukum..."
              class="w-full pl-4 pr-11 py-2.5 text-xs bg-slate-100/90 hover:bg-slate-100 focus:bg-white rounded-full border border-slate-200 focus:border-[#0B2563] focus:outline-none transition-all"
            />
            <button
              type="submit"
              class="absolute right-1.5 w-8 h-8 rounded-full bg-[#0B2563] hover:bg-[#D91E28] text-white flex items-center justify-center transition-colors"
              aria-label="Cari berita"
            >
              <Search class="w-4 h-4" />
            </button>
          </form>

          <!-- Right Action Buttons -->
          <div class="flex items-center gap-1.5 sm:gap-2">
            <!-- Mobile Quick Search -->
            <button
              type="button"
              @click="portalState.searchOpen = true"
              class="lg:hidden w-10 h-10 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 flex items-center justify-center transition-colors"
              aria-label="Cari Berita"
            >
              <Search class="w-5 h-5" />
            </button>

            <!-- Bookmarks Button -->
            <button
              type="button"
              @click="portalState.bookmarksOpen = true"
              class="relative w-10 h-10 rounded-xl bg-slate-100 hover:bg-blue-50 text-slate-700 hover:text-[#0B2563] flex items-center justify-center transition-colors"
              aria-label="Berita Tersimpan"
              title="Berita Tersimpan"
            >
              <Bookmark class="w-5 h-5" />
              <span
                v-if="portalState.bookmarks.length"
                class="absolute -top-1 -right-1 min-w-[18px] h-[18px] px-1 rounded-full bg-[#D91E28] text-white text-[10px] font-black flex items-center justify-center shadow-xs"
              >
                {{ portalState.bookmarks.length }}
              </span>
            </button>

            <!-- Menu Drawer Toggle -->
            <button
              type="button"
              @click="portalState.drawerOpen = true"
              class="w-10 h-10 rounded-xl bg-[#0B2563] hover:bg-[#D91E28] text-white flex items-center justify-center transition-colors shadow-xs"
              aria-label="Buka Menu Rubrik"
            >
              <Menu class="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>

      <!-- 3. Horizontal Category Navigation Rail (Mobile Swipeable) -->
      <div class="bg-gradient-to-r from-[#0B2563] via-[#12358A] to-[#0B2563] border-b-2 border-[#D91E28]">
        <div class="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8">
          <nav class="flex items-center gap-1 sm:gap-2 overflow-x-auto no-scrollbar py-2 text-xs font-bold uppercase tracking-wider">
            <router-link
              to="/"
              class="px-3 py-1.5 rounded-lg whitespace-nowrap transition-all shrink-0"
              :class="route.name === 'home' ? 'bg-[#D91E28] text-white shadow-xs' : 'text-blue-100 hover:bg-white/10 hover:text-white'"
            >
              Beranda
            </router-link>
            <router-link
              to="/kategori/terpopuler"
              class="px-3 py-1.5 rounded-lg whitespace-nowrap transition-all shrink-0 inline-flex items-center gap-1"
              :class="route.params.slug === 'terpopuler' ? 'bg-[#F5B700] text-slate-950 shadow-xs' : 'text-[#F5B700] hover:bg-white/10'"
            >
              <Flame class="w-3.5 h-3.5" />
              Terpopuler
            </router-link>
            <router-link
              v-for="cat in primaryNav"
              :key="cat.slug"
              :to="`/kategori/${cat.slug}`"
              class="px-3 py-1.5 rounded-lg whitespace-nowrap transition-all shrink-0"
              :class="route.params.slug === cat.slug ? 'bg-[#D91E28] text-white shadow-xs' : 'text-blue-100 hover:bg-white/10 hover:text-white'"
            >
              {{ cat.name }}
            </router-link>
          </nav>
        </div>
      </div>
    </header>

    <!-- Floating Desktop Skyscraper Ads (Sisi Kiri & Kanan) -->
    <AdBanner :ads="portalState.ads" position="sidebar_left" />
    <AdBanner :ads="portalState.ads" position="sidebar_right" />

    <!-- Top Header Leaderboard Ad (Sisi Atas Portal) -->
    <div class="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8 pt-3 sm:pt-4 w-full">
      <AdBanner :ads="portalState.ads" position="top_header" />
    </div>

    <!-- ==================== PAGE CONTENT ==================== -->
    <main class="flex-1 w-full">
      <router-view />
    </main>

    <!-- Sticky Bottom Floating Banner (Sisi Bawah Melayang) -->
    <AdBanner :ads="portalState.ads" position="sticky_bottom" />

    <!-- ==================== FOOTER ==================== -->
    <footer class="bg-[#081A47] text-slate-300 mt-12 border-t-4 border-[#D91E28]">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <div class="grid grid-cols-1 md:grid-cols-12 gap-8 pb-8 border-b border-blue-900/70">
          <!-- Brand Column -->
          <div class="md:col-span-5 space-y-4">
            <div class="inline-block bg-white rounded-2xl px-3.5 py-2 shadow-md">
              <img
                src="/images/logo-mftn.jpg"
                alt="Media Four Tribuan News"
                class="h-12 w-auto object-contain"
              />
            </div>
            <p class="text-xs sm:text-sm text-blue-100/80 leading-relaxed max-w-md">
              {{ portalState.settings.site_description }}
            </p>
            <div class="flex flex-wrap gap-2 text-[11px] font-bold">
              <span class="px-2.5 py-1 rounded-full bg-white/10 text-[#F5B700]">Aktual</span>
              <span class="px-2.5 py-1 rounded-full bg-white/10 text-white">Terpercaya</span>
              <span class="px-2.5 py-1 rounded-full bg-[#D91E28] text-white">Independen</span>
            </div>
          </div>

          <!-- Rubrik Links -->
          <div class="md:col-span-3">
            <h4 class="text-xs font-extrabold uppercase tracking-widest text-[#F5B700] mb-3">
              Kanal Berita
            </h4>
            <div class="grid grid-cols-2 gap-y-2 gap-x-4 text-xs">
              <router-link
                v-for="cat in primaryNav.slice(0, 10)"
                :key="cat.slug"
                :to="`/kategori/${cat.slug}`"
                class="hover:text-white transition-colors"
              >
                {{ cat.name }}
              </router-link>
            </div>
          </div>

          <!-- Contact & Redaksi -->
          <div class="md:col-span-4 space-y-3 text-xs">
            <h4 class="text-xs font-extrabold uppercase tracking-widest text-[#F5B700]">
              Redaksi & Kontak
            </h4>
            <div class="flex items-start gap-2.5 text-blue-100/80">
              <MapPin class="w-4 h-4 text-[#D91E28] shrink-0 mt-0.5" />
              <span>{{ portalState.settings.office_address }}</span>
            </div>
            <div class="flex items-center gap-2.5 text-blue-100/80">
              <Phone class="w-4 h-4 text-[#F5B700] shrink-0" />
              <a
                :href="`https://wa.me/${portalState.settings.whatsapp_number}`"
                target="_blank"
                class="hover:text-white font-semibold"
              >
                Hotline: {{ portalState.settings.hotline_phone }}
              </a>
            </div>
            <div class="flex items-center gap-2.5 text-blue-100/80">
              <Mail class="w-4 h-4 text-sky-400 shrink-0" />
              <span>{{ portalState.settings.redaksi_email }}</span>
            </div>
            <div class="pt-2 flex flex-wrap gap-3 text-[11px] font-semibold">
              <router-link to="/tentang" class="hover:text-[#F5B700]">Tentang Kami</router-link>
              <span class="text-blue-700">&bull;</span>
              <router-link to="/redaksi" class="hover:text-[#F5B700]">Susunan Redaksi</router-link>
              <span class="text-blue-700">&bull;</span>
              <router-link to="/kode-etik" class="hover:text-[#F5B700]">Kode Etik</router-link>
              <span class="text-blue-700">&bull;</span>
              <router-link to="/pedoman-media-siber" class="hover:text-[#F5B700]">Pedoman Siber</router-link>
            </div>
          </div>
        </div>

        <!-- ==================== STRIP FOOTER RESMI (PERSIS GAMBAR 3) ==================== -->
        <div class="mt-8 pt-8 border-t border-blue-900/80 text-center space-y-4">
          <!-- Banner Media Online Nasional Kemitraan Pers TNI & Polri -->
          <div class="flex justify-center">
            <div class="inline-flex flex-col sm:flex-row items-center gap-3 bg-gradient-to-r from-red-800 via-red-700 to-amber-700 text-white px-5 py-2.5 rounded-xl border border-amber-400/50 shadow-lg text-center max-w-2xl">
              <div class="flex items-center gap-2">
                <span class="w-8 h-8 rounded-lg bg-amber-400 text-red-950 font-black flex items-center justify-center text-xs shadow">MJMTP</span>
                <div class="text-left leading-tight">
                  <div class="text-[10px] font-bold text-amber-300 uppercase tracking-widest">Media Online Nasional</div>
                  <div class="text-xs sm:text-sm font-black tracking-wider text-white">MEDIAJAYAMABESTNIPOLRI & FOUR TRIBUAN</div>
                </div>
              </div>
              <div class="hidden sm:block h-6 w-px bg-white/20"></div>
              <div class="text-[11px] font-semibold text-amber-100/95 text-center sm:text-left">
                Tegas &bull; Tajam &bull; Terpercaya &bull; Profesional &bull; Mitra Publikasi TNI-Polri
              </div>
            </div>
          </div>

          <!-- Bulatan Sosial Media: Instagram, WhatsApp, RSS -->
          <div class="flex items-center justify-center gap-3 pt-1">
            <!-- Instagram -->
            <a
              href="https://instagram.com"
              target="_blank"
              rel="noopener"
              class="w-10 h-10 rounded-full bg-gradient-to-tr from-[#f09433] via-[#dc2743] to-[#bc1888] text-white flex items-center justify-center hover:scale-110 transition-transform shadow-md"
              aria-label="Instagram Resmi"
              title="Instagram Resmi"
            >
              <svg class="w-5 h-5 fill-current" viewBox="0 0 24 24">
                <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
              </svg>
            </a>

            <!-- WhatsApp -->
            <a
              :href="`https://wa.me/${portalState.settings.whatsapp_number}`"
              target="_blank"
              rel="noopener"
              class="w-10 h-10 rounded-full bg-[#25D366] hover:bg-[#20bd5a] text-white flex items-center justify-center hover:scale-110 transition-transform shadow-md"
              aria-label="WhatsApp Redaksi"
              title="WhatsApp Redaksi"
            >
              <svg class="w-5 h-5 fill-current" viewBox="0 0 24 24">
                <path d="M.057 24l1.687-6.163c-1.041-1.804-1.588-3.849-1.587-5.946.003-6.556 5.338-11.891 11.893-11.891 3.181.001 6.167 1.24 8.413 3.488 2.245 2.248 3.481 5.236 3.48 8.414-.003 6.557-5.338 11.892-11.893 11.892-1.99-.001-3.951-.5-5.688-1.448l-6.305 1.654zm6.597-3.807c1.676.995 3.276 1.591 5.392 1.592 5.448 0 9.886-4.434 9.889-9.885.002-5.462-4.415-9.89-9.881-9.892-5.452 0-9.887 4.434-9.889 9.884-.001 2.225.651 3.891 1.746 5.634l-.999 3.648 3.742-.981zm11.387-5.464c-.074-.124-.272-.198-.57-.347-.297-.149-1.758-.868-2.031-.967-.272-.099-.47-.149-.669.149-.198.297-.768.967-.941 1.165-.173.198-.347.223-.644.074-.297-.149-1.255-.462-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.297-.347.446-.521.151-.172.2-.296.3-.495.099-.198.05-.372-.025-.521-.075-.148-.669-1.611-.916-2.206-.242-.579-.487-.501-.669-.51l-.57-.01c-.198 0-.52.074-.792.372s-1.04 1.016-1.04 2.479 1.065 2.876 1.213 3.074c.149.198 2.095 3.2 5.076 4.487.709.306 1.263.489 1.694.626.712.226 1.36.194 1.872.118.571-.085 1.758-.719 2.006-1.413.248-.695.248-1.29.173-1.414z"/>
              </svg>
            </a>

            <!-- RSS -->
            <router-link
              to="/indeks"
              class="w-10 h-10 rounded-full bg-[#F57C00] hover:bg-[#e65100] text-white flex items-center justify-center hover:scale-110 transition-transform shadow-md"
              aria-label="Indeks Berita & RSS Feed"
              title="Indeks Berita & RSS Feed"
            >
              <svg class="w-5 h-5 fill-current" viewBox="0 0 24 24">
                <circle cx="6.18" cy="17.82" r="2.18"/>
                <path d="M4 4.44v2.83c7.03 0 12.73 5.7 12.73 12.73h2.83c0-8.59-6.97-15.56-15.56-15.56zm0 5.66v2.83c3.9 0 7.07 3.17 7.07 7.07h2.83c0-5.47-4.43-9.9-9.9-9.9z"/>
              </svg>
            </router-link>
          </div>

          <!-- Navigasi Menu Persis Gambar 3: REDAKSI - Indeks - Kode Etik - Privacy Policy - Disclaimer - Pedoman Media Siber -->
          <nav class="flex flex-wrap items-center justify-center gap-x-3.5 gap-y-2 text-xs font-bold text-slate-300 pt-1 tracking-wide" aria-label="Menu Institusional Redaksi">
            <router-link to="/redaksi" class="hover:text-[#F5B700] transition-colors">REDAKSI</router-link>
            <span class="text-slate-500 font-normal">-</span>
            <router-link to="/indeks" class="hover:text-[#F5B700] transition-colors">Indeks</router-link>
            <span class="text-slate-500 font-normal">-</span>
            <router-link to="/kode-etik" class="hover:text-[#F5B700] transition-colors">Kode Etik</router-link>
            <span class="text-slate-500 font-normal">-</span>
            <router-link to="/privacy-policy" class="hover:text-[#F5B700] transition-colors">Privacy Policy</router-link>
            <span class="text-slate-500 font-normal">-</span>
            <router-link to="/disclaimer" class="hover:text-[#F5B700] transition-colors">Disclaimer</router-link>
            <span class="text-slate-500 font-normal">-</span>
            <router-link to="/pedoman-media-siber" class="hover:text-[#F5B700] transition-colors">Pedoman Media Siber</router-link>
          </nav>

          <!-- Copyright & Scroll To Top (Persis Gambar 3) -->
          <div class="pt-4 flex items-center justify-center relative max-w-4xl mx-auto px-4">
            <div class="text-[11px] text-slate-400">
              Copyright Owned by
              <a href="https://mediafourtribuannews.my.id/" class="text-slate-200 hover:text-white font-semibold">
                https://mediafourtribuannews.my.id/
              </a>
            </div>

            <!-- Scroll to Top Circle Button (Persis Gambar 3) -->
            <button
              type="button"
              @click="scrollToTop"
              class="absolute right-0 sm:right-4 w-9 h-9 rounded-full border-2 border-white/70 hover:border-white text-white hover:bg-white/10 flex items-center justify-center transition-all shadow-md group"
              aria-label="Scroll ke atas"
              title="Kembali ke atas"
            >
              <ArrowUp class="w-4 h-4 group-hover:-translate-y-0.5 transition-transform" />
            </button>
          </div>
        </div>
      </div>
    </footer>

    <!-- ==================== MOBILE VERSE BOTTOM APP NAV ==================== -->
    <nav
      class="lg:hidden fixed bottom-0 inset-x-0 z-40 bg-white/95 backdrop-blur-md border-t border-slate-200 shadow-[0_-4px_20px_rgba(11,37,99,0.08)] safe-pb"
      aria-label="Navigasi Mobile"
    >
      <div class="grid grid-cols-5 h-16 max-w-lg mx-auto">
        <router-link
          to="/"
          class="flex flex-col items-center justify-center gap-1 text-[10px] font-bold transition-colors"
          :class="route.name === 'home' ? 'text-[#D91E28]' : 'text-slate-500'"
        >
          <Home class="w-5 h-5" />
          <span>Beranda</span>
        </router-link>

        <button
          type="button"
          @click="portalState.drawerOpen = true"
          class="flex flex-col items-center justify-center gap-1 text-[10px] font-bold text-slate-500 hover:text-[#0B2563]"
        >
          <LayoutGrid class="w-5 h-5" />
          <span>Rubrik</span>
        </button>

        <button
          type="button"
          @click="portalState.searchOpen = true"
          class="flex flex-col items-center justify-center gap-1 text-[10px] font-bold text-slate-500 hover:text-[#0B2563]"
        >
          <div class="w-10 h-10 -mt-5 rounded-full bg-gradient-to-tr from-[#0B2563] to-[#1648B8] text-white flex items-center justify-center shadow-lg ring-4 ring-white">
            <Search class="w-5 h-5" />
          </div>
          <span class="-mt-0.5 text-[#0B2563]">Cari</span>
        </button>

        <button
          type="button"
          @click="portalState.bookmarksOpen = true"
          class="relative flex flex-col items-center justify-center gap-1 text-[10px] font-bold text-slate-500 hover:text-[#0B2563]"
        >
          <div class="relative">
            <Bookmark class="w-5 h-5" />
            <span
              v-if="portalState.bookmarks.length"
              class="absolute -top-1.5 -right-2 min-w-[16px] h-4 px-1 rounded-full bg-[#D91E28] text-white text-[9px] font-black flex items-center justify-center"
            >
              {{ portalState.bookmarks.length }}
            </span>
          </div>
          <span>Simpan</span>
        </button>

        <router-link
          to="/tentang"
          class="flex flex-col items-center justify-center gap-1 text-[10px] font-bold transition-colors"
          :class="route.name === 'about' ? 'text-[#D91E28]' : 'text-slate-500 hover:text-[#0B2563]'"
        >
          <Info class="w-5 h-5" />
          <span>Redaksi</span>
        </router-link>
      </div>
    </nav>

    <!-- ==================== SLIDE-OVER RUBRIK DRAWER ==================== -->
    <div v-if="portalState.drawerOpen" class="fixed inset-0 z-50 flex">
      <div class="fixed inset-0 bg-slate-950/70 backdrop-blur-xs" @click="portalState.drawerOpen = false"></div>
      <div class="relative w-[86%] max-w-sm bg-white h-full z-10 flex flex-col shadow-2xl">
        <div class="p-4 border-b border-slate-200 flex items-center justify-between">
          <img src="/images/logo-mftn.jpg" alt="Media Four Tribuan News" class="h-11 w-auto object-contain" />
          <button
            type="button"
            @click="portalState.drawerOpen = false"
            class="w-9 h-9 rounded-xl bg-slate-100 hover:bg-slate-200 flex items-center justify-center text-slate-700"
          >
            <X class="w-5 h-5" />
          </button>
        </div>

        <div class="flex-1 overflow-y-auto p-4 space-y-5">
          <div>
            <p class="text-[10px] font-extrabold uppercase tracking-widest text-slate-400 px-2 mb-2">
              Semua Rubrik Berita
            </p>
            <div class="grid grid-cols-2 gap-2">
              <button
                v-for="cat in portalState.categories"
                :key="cat.slug"
                type="button"
                @click="goCategory(cat.slug)"
                class="flex items-center justify-between px-3 py-2.5 rounded-xl bg-slate-50 hover:bg-[#0B2563] hover:text-white text-slate-800 text-xs font-bold transition-colors text-left"
              >
                <span class="truncate">{{ cat.name }}</span>
                <ChevronRight class="w-3.5 h-3.5 opacity-60 shrink-0" />
              </button>
            </div>
          </div>

          <div class="pt-3 border-t border-slate-200 space-y-1.5">
            <p class="text-[10px] font-extrabold uppercase tracking-widest text-slate-400 px-2 mb-2">
              Informasi & Redaksi
            </p>
            <router-link
              to="/tentang"
              @click="portalState.drawerOpen = false"
              class="block px-3 py-2.5 rounded-xl text-xs font-bold text-slate-700 hover:bg-slate-100"
            >
              Tentang Media Four Tribuan News
            </router-link>
            <router-link
              to="/tentang#redaksi"
              @click="portalState.drawerOpen = false"
              class="block px-3 py-2.5 rounded-xl text-xs font-bold text-slate-700 hover:bg-slate-100"
            >
              Susunan Redaksi
            </router-link>
            <router-link
              to="/tentang#pedoman"
              @click="portalState.drawerOpen = false"
              class="block px-3 py-2.5 rounded-xl text-xs font-bold text-slate-700 hover:bg-slate-100"
            >
              Pedoman Media Siber
            </router-link>
          </div>
        </div>

        <div class="p-4 border-t border-slate-200 bg-slate-50 space-y-2">
          <a
            :href="`https://wa.me/${portalState.settings.whatsapp_number}`"
            target="_blank"
            rel="noopener noreferrer"
            class="w-full py-2.5 rounded-xl bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-extrabold flex items-center justify-center gap-2 transition-colors"
          >
            <Phone class="w-4 h-4 text-[#F5B700]" />
            <span>Hotline Redaksi: {{ portalState.settings.hotline_phone }}</span>
          </a>
        </div>
      </div>
    </div>

    <!-- ==================== SEARCH MODAL ==================== -->
    <div
      v-if="portalState.searchOpen"
      class="fixed inset-0 z-50 flex items-start sm:items-center justify-center p-4 pt-16 sm:pt-4"
    >
      <div class="fixed inset-0 bg-slate-950/70 backdrop-blur-xs" @click="portalState.searchOpen = false"></div>
      <div class="relative bg-white rounded-2xl w-full max-w-lg p-5 shadow-2xl z-10 border border-slate-200">
        <div class="flex items-center justify-between pb-3 mb-4 border-b border-slate-100">
          <h3 class="text-sm font-extrabold uppercase tracking-wider text-[#0B2563] flex items-center gap-2">
            <Search class="w-4 h-4 text-[#D91E28]" />
            Pencarian Berita
          </h3>
          <button
            type="button"
            @click="portalState.searchOpen = false"
            class="p-1.5 rounded-lg hover:bg-slate-100 text-slate-500"
          >
            <X class="w-5 h-5" />
          </button>
        </div>

        <form @submit.prevent="submitSearch" class="space-y-4">
          <div class="relative">
            <input
              v-model="searchInput"
              type="text"
              autofocus
              placeholder="Ketik judul, topik, tokoh, atau daerah..."
              class="w-full pl-4 pr-12 py-3.5 rounded-xl bg-slate-50 border border-slate-200 focus:border-[#0B2563] focus:bg-white text-sm focus:outline-none"
            />
            <button
              type="submit"
              class="absolute right-2 top-1/2 -translate-y-1/2 px-3 py-1.5 rounded-lg bg-[#D91E28] text-white text-xs font-bold"
            >
              Cari
            </button>
          </div>

          <div class="flex flex-wrap items-center gap-1.5 text-xs">
            <span class="font-bold text-slate-500 mr-1">Topik Hangat:</span>
            <button
              v-for="tag in ['Nasional', 'IKN', 'Ekonomi', 'Teknologi', 'Pendidikan', 'Olahraga']"
              :key="tag"
              type="button"
              @click="openQuickTag(tag)"
              class="px-3 py-1 rounded-full bg-slate-100 hover:bg-[#0B2563] hover:text-white text-slate-700 font-semibold transition-colors"
            >
              #{{ tag }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- ==================== BOOKMARKS DRAWER ==================== -->
    <div v-if="portalState.bookmarksOpen" class="fixed inset-0 z-50 flex justify-end">
      <div class="fixed inset-0 bg-slate-950/70 backdrop-blur-xs" @click="portalState.bookmarksOpen = false"></div>
      <div class="relative w-full max-w-md bg-[#F5F7FB] h-full z-10 flex flex-col shadow-2xl">
        <div class="p-4 bg-[#0B2563] text-white flex items-center justify-between border-b-2 border-[#D91E28]">
          <div class="flex items-center gap-2">
            <Bookmark class="w-5 h-5 text-[#F5B700]" />
            <h3 class="text-sm font-extrabold uppercase tracking-wider">Berita Tersimpan</h3>
          </div>
          <button
            type="button"
            @click="portalState.bookmarksOpen = false"
            class="p-1.5 rounded-lg hover:bg-white/10"
          >
            <X class="w-5 h-5" />
          </button>
        </div>

        <div class="flex-1 overflow-y-auto p-4 space-y-3">
          <div v-if="!portalState.bookmarks.length" class="text-center py-14 text-slate-400">
            <Bookmark class="w-12 h-12 mx-auto mb-3 opacity-30" />
            <p class="font-bold text-sm text-slate-600">Belum Ada Berita Tersimpan</p>
            <p class="text-xs mt-1">Ketuk ikon bookmark pada kartu berita untuk menyimpannya di sini.</p>
          </div>

          <div
            v-for="item in portalState.bookmarks"
            :key="item.slug"
            class="bg-white rounded-xl p-3 border border-slate-200 flex gap-3 items-center shadow-2xs"
          >
            <router-link
              :to="`/berita/${item.slug}`"
              @click="portalState.bookmarksOpen = false"
              class="w-20 h-16 rounded-lg overflow-hidden shrink-0 bg-slate-100"
            >
              <img :src="resolveImg(item.thumbnail)" :alt="item.title" class="w-full h-full object-cover" />
            </router-link>
            <div class="flex-1 min-w-0">
              <span class="text-[10px] font-extrabold text-[#D91E28] uppercase">{{ item.category_name }}</span>
              <router-link
                :to="`/berita/${item.slug}`"
                @click="portalState.bookmarksOpen = false"
                class="block text-xs font-bold text-slate-900 hover:text-[#0B2563] line-clamp-2 leading-snug"
              >
                {{ item.title }}
              </router-link>
              <span class="text-[10px] text-slate-400">{{ timeAgoID(item.published_at) }}</span>
            </div>
            <button
              type="button"
              @click="toggleBookmark(item)"
              class="p-2 text-slate-400 hover:text-[#D91E28]"
              aria-label="Hapus simpanan"
            >
              <Trash2 class="w-4 h-4" />
            </button>
          </div>
        </div>

        <div class="p-4 bg-white border-t border-slate-200 flex items-center justify-between">
          <button
            v-if="portalState.bookmarks.length"
            type="button"
            @click="clearBookmarks"
            class="text-xs font-bold text-[#D91E28] hover:underline"
          >
            Hapus Semua
          </button>
          <span v-else></span>
          <button
            type="button"
            @click="portalState.bookmarksOpen = false"
            class="px-4 py-2 rounded-xl bg-[#0B2563] text-white text-xs font-bold"
          >
            Tutup
          </button>
        </div>
      </div>
    </div>

    <!-- ==================== VIDEO PLAYER MODAL ==================== -->
    <div
      v-if="portalState.videoModal"
      class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6"
    >
      <div class="fixed inset-0 bg-slate-950/85 backdrop-blur-xs" @click="portalState.videoModal = null"></div>
      <div class="relative bg-[#081A47] border border-blue-800 rounded-2xl w-full max-w-3xl overflow-hidden text-white shadow-2xl z-10">
        <button
          type="button"
          @click="portalState.videoModal = null"
          class="absolute top-3 right-3 z-20 w-9 h-9 rounded-full bg-black/60 hover:bg-[#D91E28] text-white flex items-center justify-center"
        >
          <X class="w-5 h-5" />
        </button>
        <div class="aspect-video bg-black w-full">
          <iframe
            :src="`https://www.youtube.com/embed/${portalState.videoModal.youtube_id}?autoplay=1`"
            class="w-full h-full"
            frameborder="0"
            allow="autoplay; encrypted-media; picture-in-picture"
            allowfullscreen
          ></iframe>
        </div>
        <div class="p-5 space-y-2">
          <div class="inline-flex items-center gap-1.5 bg-[#D91E28] text-white text-[10px] font-black uppercase px-2.5 py-0.5 rounded">
            <Play class="w-3 h-3 fill-current" />
            Four Tribuan Video
          </div>
          <h3 class="text-base sm:text-lg font-extrabold leading-snug">{{ portalState.videoModal.title }}</h3>
          <p class="text-xs sm:text-sm text-blue-100/80 leading-relaxed">{{ portalState.videoModal.caption }}</p>
        </div>
      </div>
    </div>

    <!-- ==================== PHOTO LIGHTBOX MODAL ==================== -->
    <div
      v-if="portalState.photoModal"
      class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6"
    >
      <div class="fixed inset-0 bg-slate-950/90 backdrop-blur-xs" @click="portalState.photoModal = null"></div>
      <div class="relative bg-slate-900 border border-slate-700 rounded-2xl w-full max-w-3xl overflow-hidden text-white shadow-2xl z-10">
        <button
          type="button"
          @click="portalState.photoModal = null"
          class="absolute top-3 right-3 z-20 w-9 h-9 rounded-full bg-black/70 hover:bg-[#D91E28] text-white flex items-center justify-center"
        >
          <X class="w-5 h-5" />
        </button>
        <div class="bg-black flex items-center justify-center max-h-[60vh] overflow-hidden">
          <img
            :src="resolveImg(portalState.photoModal.thumbnail)"
            :alt="portalState.photoModal.title"
            class="max-h-[60vh] w-auto object-contain"
          />
        </div>
        <div class="p-5 space-y-2">
          <span class="inline-block bg-[#F5B700] text-slate-950 text-[10px] font-black uppercase px-2.5 py-0.5 rounded">
            Lensa Foto
          </span>
          <h3 class="text-base sm:text-lg font-extrabold leading-snug">{{ portalState.photoModal.title }}</h3>
          <p class="text-xs sm:text-sm text-slate-300">{{ portalState.photoModal.caption || portalState.photoModal.excerpt }}</p>
          <router-link
            :to="`/berita/${portalState.photoModal.slug}`"
            @click="portalState.photoModal = null"
            class="inline-flex items-center gap-1 text-xs font-bold text-[#F5B700] hover:underline pt-1"
          >
            Baca Liputan Lengkap &rarr;
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>
