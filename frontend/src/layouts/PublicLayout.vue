<script setup>
import { ref, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  portalState,
  isAuthenticated,
  clearBookmarks,
  toggleBookmark,
} from '../composables/usePortal'
import { resolveImg, timeAgoID } from '../api/client'
import {
  Search,
  Menu,
  X,
  Bookmark,
  Home,
  LayoutGrid,
  ShieldCheck,
  Phone,
  Mail,
  MapPin,
  ChevronRight,
  Trash2,
  Play,
  Flame,
  Calendar,
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const searchInput = ref('')

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
            <router-link to="/tentang" class="hidden sm:inline hover:text-[#F5B700] transition-colors">
              Tentang Kami
            </router-link>
            <router-link to="/tentang#redaksi" class="hidden sm:inline hover:text-[#F5B700] transition-colors">
              Redaksi
            </router-link>
            <router-link
              :to="isAuthenticated ? '/admin' : '/admin/login'"
              class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-white/10 hover:bg-[#D91E28] text-white font-bold transition-colors"
            >
              <ShieldCheck class="w-3 h-3 text-[#F5B700]" />
              <span>{{ isAuthenticated ? 'Panel Admin' : 'Login Redaksi' }}</span>
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

    <!-- ==================== PAGE CONTENT ==================== -->
    <main class="flex-1 w-full">
      <router-view />
    </main>

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
              <router-link to="/tentang#redaksi" class="hover:text-[#F5B700]">Susunan Redaksi</router-link>
              <span class="text-blue-700">&bull;</span>
              <router-link to="/tentang#pedoman" class="hover:text-[#F5B700]">Pedoman Siber</router-link>
            </div>
          </div>
        </div>

        <div class="pt-5 flex flex-col sm:flex-row items-center justify-between gap-2 text-[11px] text-blue-200/70">
          <div>
            &copy; {{ new Date().getFullYear() }} <strong class="text-white">{{ portalState.settings.company_name }}</strong> — Media Four Tribuan News.
          </div>
          <div>Platform Portal Berita Nasional (Vue 3 &bull; Golang)</div>
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
          :to="isAuthenticated ? '/admin' : '/admin/login'"
          class="flex flex-col items-center justify-center gap-1 text-[10px] font-bold text-slate-500 hover:text-[#0B2563]"
        >
          <ShieldCheck class="w-5 h-5 text-[#0B2563]" />
          <span>{{ isAuthenticated ? 'Admin' : 'Login' }}</span>
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
          <router-link
            :to="isAuthenticated ? '/admin' : '/admin/login'"
            @click="portalState.drawerOpen = false"
            class="w-full py-2.5 rounded-xl bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-extrabold flex items-center justify-center gap-2 transition-colors"
          >
            <ShieldCheck class="w-4 h-4 text-[#F5B700]" />
            <span>{{ isAuthenticated ? 'Buka Dashboard Admin' : 'Login Panel Redaksi' }}</span>
          </router-link>
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
