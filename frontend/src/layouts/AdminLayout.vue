<script setup>
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { portalState, logoutAdmin, showToast } from '../composables/usePortal'
import {
  LayoutDashboard,
  Newspaper,
  Tags,
  Video,
  MessageSquare,
  Megaphone,
  Users,
  UserCog,
  Settings,
  LogOut,
  Menu,
  X,
  ExternalLink,
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const sidebarOpen = ref(false)

const menuItems = [
  { name: 'admin-dashboard', label: 'Dashboard', icon: LayoutDashboard, to: '/admin' },
  { name: 'admin-articles', label: 'Kelola Berita', icon: Newspaper, to: '/admin/berita' },
  { name: 'admin-categories', label: 'Kategori / Rubrik', icon: Tags, to: '/admin/kategori' },
  { name: 'admin-videos', label: 'Berita Video', icon: Video, to: '/admin/video' },
  { name: 'admin-comments', label: 'Komentar', icon: MessageSquare, to: '/admin/komentar' },
  { name: 'admin-ads', label: 'Iklan & Banner', icon: Megaphone, to: '/admin/iklan' },
  { name: 'admin-editorial', label: 'Susunan Redaksi', icon: Users, to: '/admin/redaksi' },
  { name: 'admin-users', label: 'Pengguna & Wartawan', icon: UserCog, to: '/admin/pengguna' },
  { name: 'admin-settings', label: 'Pengaturan Portal', icon: Settings, to: '/admin/pengaturan' },
]

function handleLogout() {
  logoutAdmin()
  showToast('Anda telah keluar dari Panel Redaksi', 'info')
  router.push('/admin/login')
}
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

      <!-- User Footer -->
      <div class="p-3 border-t border-blue-900/80 bg-[#061438] space-y-2">
        <div class="flex items-center gap-2.5 px-2 py-1.5">
          <div class="w-8 h-8 rounded-full bg-[#F5B700] text-slate-950 font-black text-xs flex items-center justify-center shrink-0">
            {{ (portalState.user?.name || 'AD').slice(0, 2).toUpperCase() }}
          </div>
          <div class="min-w-0 flex-1">
            <div class="text-xs font-bold text-white truncate">{{ portalState.user?.name || 'Admin' }}</div>
            <div class="text-[10px] text-blue-300 truncate">{{ portalState.user?.role || 'Administrator' }}</div>
          </div>
        </div>
        <button
          type="button"
          @click="handleLogout"
          class="w-full py-2 rounded-xl bg-white/10 hover:bg-[#D91E28] text-white text-xs font-bold flex items-center justify-center gap-2 transition-colors"
        >
          <LogOut class="w-3.5 h-3.5" />
          <span>Keluar</span>
        </button>
      </div>
    </aside>

    <!-- MAIN PANEL -->
    <div class="flex-1 flex flex-col min-w-0">
      <!-- Top Bar -->
      <header class="sticky top-0 z-30 h-16 bg-white border-b border-slate-200 px-4 sm:px-6 flex items-center justify-between gap-3 shadow-2xs">
        <div class="flex items-center gap-3">
          <button
            type="button"
            @click="sidebarOpen = true"
            class="lg:hidden p-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700"
            aria-label="Buka Menu Admin"
          >
            <Menu class="w-5 h-5" />
          </button>
          <div>
            <h1 class="text-sm sm:text-base font-black text-[#0B2563]">Panel Redaksi Four Tribuan News</h1>
            <p class="text-[11px] text-slate-500 hidden sm:block">Manajemen Berita, Rubrik, Multimedia & Pengaturan Portal</p>
          </div>
        </div>

        <router-link
          to="/"
          class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-bold transition-colors"
        >
          <ExternalLink class="w-3.5 h-3.5" />
          <span>Lihat Portal</span>
        </router-link>
      </header>

      <!-- Route Content -->
      <main class="flex-1 p-4 sm:p-6 overflow-x-hidden">
        <router-view />
      </main>
    </div>
  </div>
</template>
