<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getSessionExpiresAt, isSessionExpired } from '../api/client'
import { portalState, logoutAdmin, showToast } from '../composables/usePortal'
import {
  LayoutDashboard,
  Newspaper,
  Tags,
  Video,
  MessageSquare,
  Megaphone,
  Users,
  FileText,
  UserCog,
  KeyRound,
  Settings,
  LogOut,
  Menu,
  X,
  Clock,
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const sidebarOpen = ref(false)
const remainingSeconds = ref(1200)
let sessionTimer = null

const menuItems = [
  { name: 'admin-dashboard', label: 'Dashboard', icon: LayoutDashboard, to: '/admin' },
  { name: 'admin-articles', label: 'Kelola Berita', icon: Newspaper, to: '/admin/berita' },
  { name: 'admin-categories', label: 'Kategori / Rubrik', icon: Tags, to: '/admin/kategori' },
  { name: 'admin-videos', label: 'Berita Video', icon: Video, to: '/admin/video' },
  { name: 'admin-comments', label: 'Komentar', icon: MessageSquare, to: '/admin/komentar' },
  { name: 'admin-ads', label: 'Iklan & Banner', icon: Megaphone, to: '/admin/iklan' },
  { name: 'admin-editorial', label: 'Susunan Redaksi', icon: Users, to: '/admin/redaksi' },
  { name: 'admin-pages', label: 'Halaman Statis', icon: FileText, to: '/admin/halaman' },
  { name: 'admin-users', label: 'Pengguna & Wartawan', icon: UserCog, to: '/admin/pengguna' },
  { name: 'admin-account', label: 'Ganti Email & Password', icon: KeyRound, to: '/admin/akun' },
  { name: 'admin-settings', label: 'Pengaturan Portal', icon: Settings, to: '/admin/pengaturan' },
]

const formattedCountdown = computed(() => {
  const s = Math.max(0, remainingSeconds.value)
  const mins = String(Math.floor(s / 60)).padStart(2, '0')
  const secs = String(s % 60).padStart(2, '0')
  return `${mins}:${secs}`
})

function forceAutoLogout() {
  if (sessionTimer) {
    clearInterval(sessionTimer)
    sessionTimer = null
  }
  logoutAdmin()
  showToast('Sesi 20 menit berakhir. Silakan login kembali.', 'info')
  router.replace({ name: 'admin-login', query: { expired: '1' } })
}

function tickSession() {
  if (isSessionExpired()) {
    forceAutoLogout()
    return
  }
  const exp = getSessionExpiresAt()
  remainingSeconds.value = Math.max(0, Math.floor((exp - Date.now()) / 1000))
  if (remainingSeconds.value <= 0) {
    forceAutoLogout()
  }
}

function handleLogout() {
  if (sessionTimer) {
    clearInterval(sessionTimer)
    sessionTimer = null
  }
  logoutAdmin()
  showToast('Anda telah keluar dari Panel Redaksi', 'info')
  router.push('/admin/login')
}

onMounted(() => {
  tickSession()
  sessionTimer = setInterval(tickSession, 1000)
})

onUnmounted(() => {
  if (sessionTimer) clearInterval(sessionTimer)
})
</script>

<template>
  <div class="min-h-screen flex bg-[#F1F5F9] text-slate-900">
    <!-- Mobile Backdrop -->
    <div
      v-if="sidebarOpen"
      class="fixed inset-0 bg-slate-950/60 backdrop-blur-xs z-40 lg:hidden"
      @click="sidebarOpen = false"
    ></div>

    <!-- SIDEBAR -->
    <aside
      class="fixed lg:static inset-y-0 left-0 z-50 w-64 bg-[#081A47] text-blue-100 flex flex-col justify-between transition-transform duration-200 border-r border-blue-900"
      :class="sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'"
    >
      <div class="flex flex-col min-h-0 flex-1">
        <!-- Brand Header -->
        <div class="h-16 px-4 border-b border-blue-900/80 flex items-center justify-between gap-2 shrink-0">
          <router-link to="/admin" class="flex items-center gap-2.5 min-w-0">
            <div class="bg-white rounded-lg px-2 py-1 shrink-0">
              <img src="/images/logo-mftn.jpg" alt="MFTN" class="h-8 w-auto object-contain" />
            </div>
            <div class="min-w-0">
              <div class="text-xs font-black text-white truncate">CMS REDAKSI</div>
              <div class="text-[10px] font-bold text-[#F5B700] truncate">Four Tribuan News</div>
            </div>
          </router-link>
          <button
            type="button"
            @click="sidebarOpen = false"
            class="lg:hidden p-1.5 rounded-lg hover:bg-white/10 text-blue-200"
            aria-label="Tutup Menu"
          >
            <X class="w-5 h-5" />
          </button>
        </div>

        <!-- Menu Links -->
        <nav class="flex-1 overflow-y-auto p-3 space-y-1">
          <router-link
            v-for="item in menuItems"
            :key="item.name"
            :to="item.to"
            @click="sidebarOpen = false"
            class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all"
            :class="route.name === item.name
              ? 'bg-[#D91E28] text-white shadow-sm'
              : 'text-blue-100/80 hover:bg-white/10 hover:text-white'"
          >
            <component :is="item.icon" class="w-4 h-4 shrink-0" />
            <span>{{ item.label }}</span>
          </router-link>
        </nav>
      </div>

      <!-- User Info & Session Timer Footer (Logout moved to Top Bar) -->
      <div class="p-3 border-t border-blue-900/80 bg-[#061438] space-y-2">
        <router-link
          to="/admin/akun"
          @click="sidebarOpen = false"
          class="flex items-center gap-2.5 px-2 py-1.5 rounded-xl hover:bg-white/10 transition-colors"
        >
          <div class="w-8 h-8 rounded-full bg-[#F5B700] text-slate-950 font-black text-xs flex items-center justify-center shrink-0">
            {{ (portalState.user?.name || 'AD').slice(0, 2).toUpperCase() }}
          </div>
          <div class="min-w-0 flex-1">
            <div class="text-xs font-bold text-white truncate">{{ portalState.user?.name || 'Admin' }}</div>
            <div class="text-[10px] text-blue-300 truncate">{{ portalState.user?.email || portalState.user?.role }}</div>
          </div>
        </router-link>

        <div
          class="px-2.5 py-1.5 rounded-lg text-[11px] font-mono flex items-center justify-between"
          :class="remainingSeconds <= 120 ? 'bg-red-500/20 text-red-200 border border-red-400/30' : 'bg-white/5 text-blue-200/80'"
        >
          <span class="inline-flex items-center gap-1.5">
            <Clock class="w-3.5 h-3.5 text-[#F5B700]" />
            <span>Auto keluar</span>
          </span>
          <span class="font-extrabold">{{ formattedCountdown }}</span>
        </div>
      </div>
    </aside>

    <!-- MAIN PANEL -->
    <div class="flex-1 flex flex-col min-w-0">
      <!-- Top Bar (Logout button placed here instead of Lihat Portal) -->
      <header class="sticky top-0 z-30 h-16 bg-white border-b border-slate-200 px-4 sm:px-6 flex items-center justify-between gap-3 shadow-2xs">
        <div class="flex items-center gap-3 min-w-0">
          <button
            type="button"
            @click="sidebarOpen = true"
            class="lg:hidden p-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 shrink-0"
            aria-label="Buka Menu Admin"
          >
            <Menu class="w-5 h-5" />
          </button>
          <div class="min-w-0">
            <h1 class="text-sm sm:text-base font-black text-[#0B2563] truncate">Panel Redaksi Four Tribuan News</h1>
            <p class="text-[11px] text-slate-500 hidden sm:block">Manajemen Berita, Rubrik, Multimedia & Pengaturan Portal</p>
          </div>
        </div>

        <div class="flex items-center gap-2.5 shrink-0">
          <span
            class="hidden sm:inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-mono font-bold border"
            :class="remainingSeconds <= 120 ? 'bg-red-50 text-[#D91E28] border-red-200' : 'bg-slate-50 text-slate-600 border-slate-200'"
            title="Sesi akan otomatis keluar setelah 20 menit"
          >
            <Clock class="w-3.5 h-3.5" />
            <span>{{ formattedCountdown }}</span>
          </span>

          <button
            type="button"
            @click="handleLogout"
            class="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[#D91E28] hover:bg-red-700 text-white text-xs font-extrabold transition-colors shadow-xs"
          >
            <LogOut class="w-3.5 h-3.5" />
            <span>Keluar</span>
          </button>
        </div>
      </header>

      <!-- Route Content -->
      <main class="flex-1 p-4 sm:p-6 overflow-x-hidden">
        <router-view />
      </main>
    </div>
  </div>
</template>
