<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api } from '../api/client'
import { portalState } from '../composables/usePortal'
import { defaultPages } from '../data/pagesData.js'
import {
  Shield,
  ShieldCheck,
  Users,
  FileCheck,
  Lock,
  AlertTriangle,
  Scale,
  Phone,
  Mail,
  MapPin,
  CheckCircle2,
  Share2,
  Printer,
  ChevronRight,
  ExternalLink,
  Award,
  BookOpen
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()

const props = defineProps({
  defaultTab: {
    type: String,
    default: 'redaksi',
  },
})

const activeTab = ref(props.defaultTab || 'redaksi')
const team = ref([])
const pagesData = ref([...defaultPages])

const tabs = [
  { id: 'profil', label: 'Tentang Kami', icon: BookOpen, routePath: '/tentang' },
  { id: 'redaksi', label: 'REDAKSI', icon: Users, routePath: '/redaksi' },
  { id: 'kode-etik', label: 'Kode Etik', icon: ShieldCheck, routePath: '/kode-etik' },
  { id: 'pedoman', label: 'Pedoman Media Siber', icon: FileCheck, routePath: '/pedoman-media-siber' },
  { id: 'privacy', label: 'Kebijakan Privasi', icon: Lock, routePath: '/privacy-policy' },
  { id: 'disclaimer', label: 'Disclaimer', icon: AlertTriangle, routePath: '/disclaimer' },
  { id: 'dewan-pers', label: 'Dewan PERS', icon: Scale, routePath: '/dewan-pers' },
]

function determineTabFromRoute() {
  const p = route.path.toLowerCase()
  if (p.includes('/kode-etik')) activeTab.value = 'kode-etik'
  else if (p.includes('/pedoman-media-siber')) activeTab.value = 'pedoman'
  else if (p.includes('/privacy-policy') || p.includes('/kebijakan-privasi')) activeTab.value = 'privacy'
  else if (p.includes('/disclaimer')) activeTab.value = 'disclaimer'
  else if (p.includes('/dewan-pers')) activeTab.value = 'dewan-pers'
  else if (p.includes('/redaksi')) activeTab.value = 'redaksi'
  else if (p.includes('/tentang') || p.includes('/kontak')) activeTab.value = 'profil'
  else activeTab.value = props.defaultTab || 'profil'
}

watch(() => route.path, determineTabFromRoute, { immediate: true })

function switchTab(t) {
  activeTab.value = t.id
  if (route.path !== t.routePath) {
    router.push(t.routePath)
  }
}

async function loadData() {
  try {
    const resTeam = await api.get('/redaksi')
    team.value = resTeam.data || []
  } catch (e) {
    console.warn('Failed to load editorial team:', e)
  }

  try {
    const resPages = await api.get('/pages')
    if (resPages?.data && Array.isArray(resPages.data)) {
      pagesData.value = resPages.data
    }
  } catch (e) {
    console.warn('Failed to load pages data:', e)
  }
}

onMounted(() => {
  determineTabFromRoute()
  loadData()
})

const redaksiPage = computed(() => pagesData.value.find((p) => p.slug === 'redaksi') || defaultPages[0])
const kodeEtikPage = computed(() => pagesData.value.find((p) => p.slug === 'kode-etik') || defaultPages[1])
const pedomanPage = computed(() => pagesData.value.find((p) => p.slug === 'pedoman-media-siber') || defaultPages[2])
const privacyPage = computed(() => pagesData.value.find((p) => p.slug === 'privacy-policy') || defaultPages[3])
const disclaimerPage = computed(() => pagesData.value.find((p) => p.slug === 'disclaimer') || defaultPages[4])
const dewanPersPage = computed(() => pagesData.value.find((p) => p.slug === 'dewan-pers') || defaultPages[5])

function printPage() {
  window.print()
}

function sharePage() {
  if (navigator.share) {
    navigator.share({
      title: `${activeTabTitle.value} - ${portalState.settings.site_title}`,
      url: window.location.href,
    }).catch(() => {})
  } else {
    navigator.clipboard.writeText(window.location.href)
    alert('Tautan halaman berhasil disalin!')
  }
}

const activeTabTitle = computed(() => {
  const current = tabs.find((t) => t.id === activeTab.value)
  return current ? current.label : 'Dokumen Redaksi'
})
</script>

<template>
  <div class="max-w-6xl mx-auto px-3 sm:px-6 lg:px-8 py-6 sm:py-10 space-y-8">
    <!-- Breadcrumb & Top Bar -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-slate-200">
      <div class="flex items-center gap-2 text-xs text-slate-500">
        <router-link to="/" class="hover:text-[#0B2563] font-semibold">Beranda</router-link>
        <ChevronRight class="w-3.5 h-3.5 text-slate-400" />
        <span class="font-bold text-[#D91E28]">Informasi Institusional Pers</span>
        <ChevronRight class="w-3.5 h-3.5 text-slate-400" />
        <span class="font-bold text-slate-800 uppercase">{{ activeTabTitle }}</span>
      </div>

      <div class="flex items-center gap-2 print:hidden">
        <button
          type="button"
          @click="sharePage"
          class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-xs font-semibold text-slate-700 shadow-2xs transition-colors"
        >
          <Share2 class="w-3.5 h-3.5" />
          <span>Bagikan</span>
        </button>
        <button
          type="button"
          @click="printPage"
          class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-xs font-semibold text-slate-700 shadow-2xs transition-colors"
        >
          <Printer class="w-3.5 h-3.5" />
          <span>Cetak Dokumen</span>
        </button>
      </div>
    </div>

    <!-- Institutional Tab Navigation Pills -->
    <nav class="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-none print:hidden" aria-label="Navigasi Halaman Statis">
      <button
        v-for="t in tabs"
        :key="t.id"
        type="button"
        @click="switchTab(t)"
        class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs sm:text-sm font-bold whitespace-nowrap transition-all shrink-0 shadow-2xs"
        :class="
          activeTab === t.id
            ? 'bg-[#0B2563] text-white shadow-md ring-2 ring-[#0B2563]/20'
            : 'bg-white text-slate-700 hover:bg-slate-100 hover:text-[#0B2563] border border-slate-200/90'
        "
      >
        <component :is="t.icon" class="w-4 h-4" :class="activeTab === t.id ? 'text-[#F5B700]' : 'text-slate-400'" />
        <span>{{ t.label }}</span>
      </button>
    </nav>

    <!-- ============================================================== -->
    <!-- TAB 1: REDAKSI                                                -->
    <!-- ============================================================== -->
    <div v-if="activeTab === 'redaksi'" class="space-y-6">
      <!-- Header Banner Redaksi -->
      <div class="bg-gradient-to-r from-[#081A47] via-[#0B2563] to-[#1648B8] text-white rounded-3xl p-6 sm:p-8 shadow-md">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div class="space-y-1.5">
            <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/10 text-[#F5B700] text-[11px] font-black uppercase tracking-wider">
              <Award class="w-3.5 h-3.5" /> Dokumen Resmi Dewan Redaksi
            </span>
            <h1 class="text-2xl sm:text-3xl font-black font-editorial tracking-tight text-white">
              REDAKSI & LANDASAN MORAL PERS
            </h1>
            <p class="text-xs sm:text-sm text-blue-100/90">
              {{ portalState.settings.company_name }} — {{ portalState.settings.site_title }}
            </p>
          </div>
          <div class="shrink-0 bg-white/10 p-3 rounded-2xl border border-white/20 text-center">
            <span class="text-[10px] uppercase font-bold text-blue-200 block">Kepatuhan Hukum</span>
            <span class="text-sm font-extrabold text-[#F5B700]">UU Pers No. 40 / 1999</span>
          </div>
        </div>
      </div>

      <!-- Kemitraan Pers TNI & Polri Callout -->
      <div class="bg-gradient-to-r from-red-900/10 via-red-800/10 to-amber-900/10 border-l-4 border-[#D91E28] rounded-2xl p-5 sm:p-6 bg-white shadow-2xs">
        <div class="flex items-start gap-3.5">
          <div class="w-10 h-10 rounded-xl bg-[#D91E28] text-white flex items-center justify-center shrink-0 shadow">
            <Shield class="w-5 h-5" />
          </div>
          <div class="space-y-1.5">
            <h3 class="text-sm sm:text-base font-extrabold text-slate-900 uppercase tracking-wide">
              Dukungan & Kemitraan Publikasi Pers Terhadap Polri - TNI
            </h3>
            <p class="text-xs sm:text-sm text-slate-700 leading-relaxed font-medium">
              "{{ redaksiPage.tni_polri_support }}"
            </p>
          </div>
        </div>
      </div>

      <!-- Landasan Moral & Etika Pers (5 Paragraf Resmi Dewan Pers yang diberikan user) -->
      <div class="bg-white rounded-3xl border border-slate-200 p-6 sm:p-8 shadow-2xs space-y-5">
        <div class="flex items-center gap-2.5 pb-3 border-b border-slate-100">
          <span class="w-9 h-9 rounded-xl bg-blue-50 text-[#0B2563] flex items-center justify-center">
            <BookOpen class="w-5 h-5" />
          </span>
          <div>
            <h2 class="text-lg font-black text-[#0B2563]">Landasan Moral & Etika Profesi Wartawan</h2>
            <p class="text-xs text-slate-500">Pedoman operasional dalam menjaga integritas dan kepercayaan publik</p>
          </div>
        </div>

        <div class="space-y-4 text-xs sm:text-sm text-slate-700 leading-relaxed">
          <p
            v-for="(para, idx) in redaksiPage.moral_foundation"
            :key="idx"
            class="p-4 rounded-2xl bg-slate-50/70 border border-slate-100 hover:border-blue-200 transition-colors"
          >
            {{ para }}
          </p>
        </div>
      </div>

      <!-- Susunan Dewan Redaksi -->
      <div class="bg-white rounded-3xl border border-slate-200 p-6 sm:p-8 shadow-2xs space-y-6">
        <div class="flex items-center justify-between gap-3 pb-3 border-b border-slate-100">
          <div class="flex items-center gap-2.5">
            <span class="w-9 h-9 rounded-xl bg-[#0B2563] text-[#F5B700] flex items-center justify-center">
              <Users class="w-5 h-5" />
            </span>
            <div>
              <h2 class="text-lg font-black text-[#0B2563]">Boks Susunan Redaksi</h2>
              <p class="text-xs text-slate-500">{{ portalState.settings.company_name }}</p>
            </div>
          </div>
          <span class="text-[11px] font-bold text-[#D91E28] bg-red-50 px-3 py-1 rounded-full">
            KTA & SK Resmi
          </span>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <div
            v-for="m in team"
            :key="m.id"
            class="p-4 rounded-2xl border border-slate-200/90 bg-slate-50/60 hover:bg-white hover:border-[#0B2563]/50 transition-all shadow-2xs"
          >
            <span class="text-[10px] font-black uppercase tracking-wider text-[#D91E28] block mb-1">
              {{ m.division || 'Redaksi' }}
            </span>
            <h3 class="text-sm font-extrabold text-slate-900">{{ m.name }}</h3>
            <p class="text-xs font-bold text-[#0B2563] mt-0.5">{{ m.position }}</p>
            <p v-if="m.description" class="text-xs text-slate-500 mt-1.5">{{ m.description }}</p>
            <div v-if="m.email || m.phone" class="text-[11px] text-slate-500 mt-2.5 pt-2 border-t border-slate-200/60">
              <span v-if="m.email" class="block">{{ m.email }}</span>
              <span v-if="m.phone" class="block">{{ m.phone }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Hak Jawab & Hak Koreksi -->
      <div class="bg-amber-50/70 border border-amber-200/80 rounded-2xl p-5 text-xs sm:text-sm text-slate-800 space-y-2">
        <div class="font-extrabold text-amber-900 flex items-center gap-1.5 text-sm">
          <CheckCircle2 class="w-4 h-4 text-amber-700" /> Layanan Hak Jawab dan Hak Koreksi
        </div>
        <p class="leading-relaxed">
          Sesuai dengan Undang-Undang Pers No. 40 Tahun 1999 Pasal 1 ayat (11) dan (12), setiap pihak berhak mengajukan Hak Jawab
          maupun Hak Koreksi terhadap kekeliruan pemberitaan. Pengajuan dilayangkan melalui surat resmi ke email
          <strong>{{ portalState.settings.redaksi_email }}</strong> atau hotline redaksi dengan menyertakan bukti identitas yang sah.
        </p>
      </div>
    </div>

    <!-- ============================================================== -->
    <!-- TAB 2: KODE ETIK                                              -->
    <!-- ============================================================== -->
    <div v-if="activeTab === 'kode-etik'" class="space-y-6">
      <div class="bg-gradient-to-r from-[#0B2563] via-[#081A47] to-[#8B0000] text-white rounded-3xl p-6 sm:p-8 shadow-md">
        <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/10 text-[#F5B700] text-[11px] font-black uppercase tracking-wider mb-2">
          <ShieldCheck class="w-3.5 h-3.5" /> Pedoman Etika Pers
        </span>
        <h1 class="text-2xl sm:text-3xl font-black font-editorial tracking-tight">
          KODE ETIK JURNALISTIK & KOMITMEN KEMITRAAN
        </h1>
        <p class="text-xs sm:text-sm text-blue-100/90 mt-1">
          Landasan independensi, integritas moral, dan tanggung jawab pemberitaan kepada bangsa dan negara.
        </p>
      </div>

      <!-- Komitmen Kode Etik Isian User -->
      <div class="bg-white rounded-3xl border border-slate-200 p-6 sm:p-8 shadow-2xs space-y-4">
        <div class="p-5 rounded-2xl bg-gradient-to-br from-blue-900 via-[#0B2563] to-red-900 text-white shadow">
          <div class="text-[10px] font-black uppercase tracking-widest text-[#F5B700] mb-1">
            Komitmen Publikasi Kemitraan
          </div>
          <p class="text-sm sm:text-base font-semibold leading-relaxed">
            "{{ kodeEtikPage.commitment_text }}"
          </p>
        </div>

        <div class="p-4 rounded-2xl bg-amber-50/80 border border-amber-200 text-xs sm:text-sm text-slate-800 leading-relaxed">
          <strong class="text-amber-950 font-extrabold block mb-1">Prinsip Kemitraan Pers Profesional:</strong>
          "{{ kodeEtikPage.tni_polri_support }}"
        </div>
      </div>

      <!-- 11 Pasal Kode Etik Jurnalistik (KEJ Dewan Pers) -->
      <div class="bg-white rounded-3xl border border-slate-200 p-6 sm:p-8 shadow-2xs space-y-5">
        <div class="pb-3 border-b border-slate-100">
          <h2 class="text-lg font-black text-[#0B2563]">Sebelas (11) Pasal Kode Etik Jurnalistik (KEJ)</h2>
          <p class="text-xs text-slate-500 mt-0.5">Ditetapkan oleh Dewan Pers sebagai pedoman mutlak wartawan Indonesia</p>
        </div>

        <div class="space-y-3">
          <div
            v-for="item in kodeEtikPage.articles"
            :key="item.pasal"
            class="p-4 rounded-2xl bg-slate-50/70 border border-slate-200/90 hover:border-[#0B2563]/40 transition-colors"
          >
            <div class="space-y-1">
              <h3 class="text-xs sm:text-sm font-extrabold text-[#0B2563]">
                Pasal {{ item.pasal }} — {{ item.title }}
              </h3>
              <p class="text-xs text-slate-700 leading-relaxed">{{ item.desc }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ============================================================== -->
    <!-- TAB 3: PEDOMAN MEDIA SIBER                                    -->
    <!-- ============================================================== -->
    <div v-if="activeTab === 'pedoman'" class="space-y-6">
      <div class="bg-gradient-to-r from-[#081A47] to-[#0B2563] text-white rounded-3xl p-6 sm:p-8 shadow-md">
        <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/10 text-[#F5B700] text-[11px] font-black uppercase tracking-wider mb-2">
          <FileCheck class="w-3.5 h-3.5" /> Regulasi Dewan Pers
        </span>
        <h1 class="text-2xl sm:text-3xl font-black font-editorial tracking-tight">
          PEDOMAN PEMBERITAAN MEDIA SIBER
        </h1>
        <p class="text-xs sm:text-sm text-blue-100/90 mt-1">
          Peraturan Dewan Pers Nomor: 1/Peraturan-DP/III/2012 tentang Standar Operasional Pemberitaan Media Siber di Indonesia.
        </p>
      </div>

      <div class="bg-white rounded-3xl border border-slate-200 p-6 sm:p-8 shadow-2xs space-y-5">
        <div
          v-for="c in pedomanPage.clauses"
          :key="c.no"
          class="p-5 rounded-2xl bg-slate-50/70 border border-slate-200/90 space-y-1.5"
        >
          <div class="text-[11px] font-black uppercase tracking-wider text-[#D91E28]">
            Butir {{ c.no }}
          </div>
          <h3 class="text-sm font-extrabold text-slate-900">{{ c.title }}</h3>
          <p class="text-xs sm:text-sm text-slate-700 leading-relaxed">{{ c.desc }}</p>
        </div>
      </div>
    </div>

    <!-- ============================================================== -->
    <!-- TAB 4: PRIVACY POLICY                                         -->
    <!-- ============================================================== -->
    <div v-if="activeTab === 'privacy'" class="space-y-6">
      <div class="bg-gradient-to-r from-slate-900 via-[#0B2563] to-slate-800 text-white rounded-3xl p-6 sm:p-8 shadow-md">
        <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/10 text-[#F5B700] text-[11px] font-black uppercase tracking-wider mb-2">
          <Lock class="w-3.5 h-3.5" /> Keamanan & Privasi
        </span>
        <h1 class="text-2xl sm:text-3xl font-black font-editorial tracking-tight">
          KEBIJAKAN PRIVASI (PRIVACY POLICY)
        </h1>
        <p class="text-xs sm:text-sm text-blue-100/90 mt-1">
          Perlindungan data pribadi pembaca, kerahasiaan identitas narasumber, dan keamanan sistem informasi.
        </p>
      </div>

      <div class="bg-white rounded-3xl border border-slate-200 p-6 sm:p-8 shadow-2xs space-y-4">
        <div
          v-for="(p, i) in privacyPage.points"
          :key="i"
          class="p-5 rounded-2xl bg-slate-50/70 border border-slate-200/90 space-y-1.5"
        >
          <h3 class="text-sm font-extrabold text-[#0B2563] flex items-center gap-2">
            <CheckCircle2 class="w-4 h-4 text-emerald-600 shrink-0" />
            {{ p.title }}
          </h3>
          <p class="text-xs sm:text-sm text-slate-700 leading-relaxed pl-6">{{ p.desc }}</p>
        </div>
      </div>
    </div>

    <!-- ============================================================== -->
    <!-- TAB 5: DISCLAIMER                                             -->
    <!-- ============================================================== -->
    <div v-if="activeTab === 'disclaimer'" class="space-y-6">
      <div class="bg-gradient-to-r from-[#D91E28] via-red-900 to-[#081A47] text-white rounded-3xl p-6 sm:p-8 shadow-md">
        <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/10 text-white text-[11px] font-black uppercase tracking-wider mb-2">
          <AlertTriangle class="w-3.5 h-3.5" /> Sangkalan Hukum
        </span>
        <h1 class="text-2xl sm:text-3xl font-black font-editorial tracking-tight">
          DISCLAIMER & IDENTITAS RESMI
        </h1>
        <p class="text-xs sm:text-sm text-red-100/90 mt-1">
          Ketentuan legalitas pers, perlindungan integritas jurnalis, dan batasan tanggung jawab konten.
        </p>
      </div>

      <div class="bg-white rounded-3xl border border-slate-200 p-6 sm:p-8 shadow-2xs space-y-4">
        <div
          v-for="(n, i) in disclaimerPage.notices"
          :key="i"
          class="p-5 rounded-2xl bg-slate-50/70 border border-slate-200/90 space-y-1.5"
        >
          <h3 class="text-sm font-extrabold text-[#D91E28] flex items-center gap-2">
            <Shield class="w-4 h-4 text-[#D91E28] shrink-0" />
            {{ n.title }}
          </h3>
          <p class="text-xs sm:text-sm text-slate-700 leading-relaxed pl-6">{{ n.desc }}</p>
        </div>
      </div>
    </div>

    <!-- ============================================================== -->
    <!-- TAB 6: DEWAN PERS                                             -->
    <!-- ============================================================== -->
    <div v-if="activeTab === 'dewan-pers'" class="space-y-6">
      <div class="bg-gradient-to-r from-[#0B2563] via-[#1648B8] to-[#081A47] text-white rounded-3xl p-6 sm:p-8 shadow-md">
        <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/10 text-[#F5B700] text-[11px] font-black uppercase tracking-wider mb-2">
          <Scale class="w-3.5 h-3.5" /> Kepatuhan Standar Pers
        </span>
        <h1 class="text-2xl sm:text-3xl font-black font-editorial tracking-tight">
          DEWAN PERS & HUKUM PERS
        </h1>
        <p class="text-xs sm:text-sm text-blue-100/90 mt-1">
          Komitmen implementasi Undang-Undang Pokok Pers No. 40 Tahun 1999 dan Standar Perusahaan Pers.
        </p>
      </div>

      <div class="bg-white rounded-3xl border border-slate-200 p-6 sm:p-8 shadow-2xs space-y-4">
        <div
          v-for="(c, i) in dewanPersPage.commitments"
          :key="i"
          class="p-5 rounded-2xl bg-slate-50/70 border border-slate-200/90 space-y-1.5"
        >
          <h3 class="text-sm font-extrabold text-[#0B2563] flex items-center gap-2">
            <Award class="w-4 h-4 text-[#F5B700] shrink-0" />
            {{ c.title }}
          </h3>
          <p class="text-xs sm:text-sm text-slate-700 leading-relaxed pl-6">{{ c.desc }}</p>
        </div>
      </div>
    </div>

    <!-- ============================================================== -->
    <!-- TAB 1: TENTANG KAMI & PROFIL REDAKSI                           -->
    <!-- ============================================================== -->
    <div v-if="activeTab === 'profil'" class="space-y-6">
      <!-- Hero Header Tentang Kami -->
      <div class="bg-gradient-to-r from-[#0B2563] via-[#081A47] to-[#1648B8] text-white rounded-3xl p-6 sm:p-8 shadow-md">
        <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/10 text-[#F5B700] text-[11px] font-black uppercase tracking-wider mb-2">
          <BookOpen class="w-3.5 h-3.5" /> Mengenal Lebih Dekat
        </span>
        <h1 class="text-2xl sm:text-3xl font-black font-editorial tracking-tight text-white">
          TENTANG MEDIA FOUR TRIBUAN NEWS
        </h1>
        <p class="text-xs sm:text-sm text-blue-100/90 mt-1">
          Portal Berita Siber Nasional — Aktual, Terpercaya, Independen, Tegas, Tajam, dan Profesional.
        </p>
      </div>

      <!-- Apa itu Media Four Tribuan News -->
      <div class="bg-white rounded-3xl border border-slate-200 p-6 sm:p-8 shadow-2xs space-y-6">
        <div class="flex flex-col sm:flex-row sm:items-center gap-5 pb-5 border-b border-slate-100">
          <img src="/images/logo-mftn.jpg" alt="Logo Media Four Tribuan News" class="h-20 w-auto object-contain self-start" />
          <div class="space-y-1">
            <span class="inline-block px-3 py-0.5 rounded-full bg-blue-50 text-[#0B2563] text-[10px] font-black uppercase tracking-widest">
              Identitas Resmi Perusahaan Pers
            </span>
            <h2 class="text-xl sm:text-2xl font-black text-[#0B2563]">
              {{ portalState.settings.site_title }}
            </h2>
            <p class="text-xs sm:text-sm font-bold text-[#D91E28]">
              {{ portalState.settings.site_tagline }} &bull; Tegas &bull; Tajam &bull; Profesional
            </p>
          </div>
        </div>

        <div class="space-y-4 text-xs sm:text-sm text-slate-700 leading-relaxed">
          <p>
            <strong>Media Four Tribuan News</strong> adalah portal media siber berita online nasional yang hadir menjawab kebutuhan publik Indonesia akan akses informasi jurnalistik yang cepat, faktual, mendalam, dan berimbang.
          </p>
          <p>
            Didirikan berlandaskan payung hukum <strong>Undang-Undang Republik Indonesia Nomor 40 Tahun 1999 tentang Pers</strong> serta sepenuhnya tunduk pada <strong>Pedoman Pemberitaan Media Siber (PPMS)</strong> yang ditetapkan oleh Dewan Pers, Media Four Tribuan News memposisikan diri sebagai pilar komunikasi masyarakat yang berintegritas dan terpercaya dalam mengawal kedaulatan Negara Kesatuan Republik Indonesia (NKRI).
          </p>
        </div>

        <!-- Callout Kemitraan Publikasi TNI - Polri -->
        <div class="rounded-2xl bg-gradient-to-br from-red-50 to-amber-50/60 border-2 border-red-200/80 p-5 space-y-3">
          <div class="flex items-center gap-2 text-sm font-black text-[#D91E28]">
            <ShieldCheck class="w-5 h-5 text-[#D91E28] shrink-0" />
            <span>Kemitraan Publikasi Pers — Sinergitas Bersama Polri & TNI</span>
          </div>
          <blockquote class="text-xs sm:text-sm text-slate-800 italic leading-relaxed pl-3 border-l-4 border-[#D91E28]">
            "Dukungan Media Four Tribuan News terhadap Polri TNI merupakan bentuk kemitraan pers yang dibangun atas dasar profesionalisme, integritas, dan tanggung jawab jurnalistik. Kami percaya bahwa setiap kinerja positif Polri TNI patut diketahui masyarakat."
          </blockquote>
          <p class="text-xs sm:text-sm text-slate-700 leading-relaxed font-medium">
            Media Four Tribuan News bukan sekadar hadir untuk memberitakan, tetapi berkomitmen menjadi mitra publikasi yang konsisten dalam menyampaikan pengabdian, transparansi penegakan hukum, stabilitas keamanan, dan kinerja nyata Polri dan TNI kepada seluruh masyarakat di pelosok Nusantara.
          </p>
        </div>

        <!-- 4 Pilar Visi & Misi Redaksi -->
        <div class="space-y-3 pt-2">
          <h3 class="text-base font-extrabold text-[#0B2563] flex items-center gap-2">
            <Award class="w-4 h-4 text-[#F5B700]" /> Visi & 4 Pilar Misi Redaksi
          </h3>
          <p class="text-xs text-slate-600">
            <strong>Visi:</strong> Menjadi portal berita siber nasional terkemuka dan terpercaya dalam menyuarakan kebenaran fakta, mencerdaskan kehidupan bangsa, menjaga persatuan keberagaman, serta mengawal pembangunan nasional yang berkeadilan.
          </p>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-2">
            <div class="p-4 rounded-xl bg-slate-50 border border-slate-200 space-y-1">
              <div class="font-bold text-xs text-[#0B2563] flex items-center gap-1.5">
                <CheckCircle2 class="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                1. Jurnalisme Terpercaya & Berimbang
              </div>
              <p class="text-[11px] text-slate-600 leading-relaxed">
                Menghasilkan produk jurnalistik faktual, independen, menguji kebenaran informasi (*check and recheck*), serta menerapkan asas praduga tak bersalah.
              </p>
            </div>

            <div class="p-4 rounded-xl bg-slate-50 border border-slate-200 space-y-1">
              <div class="font-bold text-xs text-[#0B2563] flex items-center gap-1.5">
                <CheckCircle2 class="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                2. Kemitraan Publikasi Strategis
              </div>
              <p class="text-[11px] text-slate-600 leading-relaxed">
                Membangun jembatan komunikasi antara institusi penegak hukum (Polri), pertahanan (TNI), dan instansi pemerintah dengan masyarakat luas.
              </p>
            </div>

            <div class="p-4 rounded-xl bg-slate-50 border border-slate-200 space-y-1">
              <div class="font-bold text-xs text-[#0B2563] flex items-center gap-1.5">
                <CheckCircle2 class="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                3. Pilar Keempat Demokrasi
              </div>
              <p class="text-[11px] text-slate-600 leading-relaxed">
                Menjalankan fungsi kontrol sosial yang konstruktif, adil, profesional, dan terbuka untuk dikontrol oleh masyarakat demi kepentingan publik.
              </p>
            </div>

            <div class="p-4 rounded-xl bg-slate-50 border border-slate-200 space-y-1">
              <div class="font-bold text-xs text-[#0B2563] flex items-center gap-1.5">
                <CheckCircle2 class="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                4. Integritas Moral & Anti-Hoaks
              </div>
              <p class="text-[11px] text-slate-600 leading-relaxed">
                Melawan secara tegas peredaran berita palsu (hoaks), fitnah, ujaran kebencian, dan manipulasi informasi di ruang publik siber.
              </p>
            </div>
          </div>
        </div>

        <!-- Fokus Kanal Berita -->
        <div class="space-y-3 pt-2">
          <h3 class="text-base font-extrabold text-[#0B2563]">Cakupan Rubrikasi & Kanal Berita</h3>
          <div class="grid grid-cols-2 sm:grid-cols-3 gap-2.5 text-xs">
            <div class="p-3 rounded-xl bg-blue-50/50 border border-blue-100">
              <div class="font-black text-[#0B2563]">Nasional & IKN</div>
              <p class="text-[11px] text-slate-500 mt-0.5">Kebijakan pusat, kementerian, dan pembangunan negara.</p>
            </div>
            <div class="p-3 rounded-xl bg-red-50/50 border border-red-100">
              <div class="font-black text-[#D91E28]">Polri - TNI & Hukum</div>
              <p class="text-[11px] text-slate-500 mt-0.5">Penegakan hukum, kamtibmas, dan teritorial Nusantara.</p>
            </div>
            <div class="p-3 rounded-xl bg-amber-50/50 border border-amber-100">
              <div class="font-black text-amber-800">Daerah Nusantara</div>
              <p class="text-[11px] text-slate-500 mt-0.5">Kabar peristiwa dari 38 provinsi di seluruh pelosok.</p>
            </div>
            <div class="p-3 rounded-xl bg-emerald-50/50 border border-emerald-100">
              <div class="font-black text-emerald-800">Ekonomi & Bisnis</div>
              <p class="text-[11px] text-slate-500 mt-0.5">Pasar, komoditas, inflasi, perbankan, dan UMKM digital.</p>
            </div>
            <div class="p-3 rounded-xl bg-purple-50/50 border border-purple-100">
              <div class="font-black text-purple-800">Politik & Demokrasi</div>
              <p class="text-[11px] text-slate-500 mt-0.5">Dinamika legislatif, partai, pilkada, dan etika berbangsa.</p>
            </div>
            <div class="p-3 rounded-xl bg-sky-50/50 border border-sky-100">
              <div class="font-black text-sky-800">Teknologi & Pendidikan</div>
              <p class="text-[11px] text-slate-500 mt-0.5">Inovasi siber, kurikulum merdeka, dan olahraga prestasi.</p>
            </div>
          </div>
        </div>

        <!-- Tombol Cepat Menuju Dokumen Legalitas & Disclaimer -->
        <div class="p-5 rounded-2xl bg-slate-50 border border-slate-200 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div class="space-y-1 text-center sm:text-left">
            <div class="text-xs font-black text-[#0B2563] uppercase tracking-wider">
              Legalitas & Sangkalan Hukum Pers
            </div>
            <p class="text-[11px] text-slate-500">
              Pelajari identitas resmi wartawan, larangan gratifikasi, serta sangkalan hukum portal.
            </p>
          </div>
          <div class="flex items-center gap-2 shrink-0">
            <button
              type="button"
              @click="activeTab = 'disclaimer'"
              class="px-4 py-2 rounded-xl bg-[#D91E28] hover:bg-red-700 text-white text-xs font-extrabold inline-flex items-center gap-1.5 transition-colors shadow-2xs cursor-pointer"
            >
              <AlertTriangle class="w-3.5 h-3.5" />
              <span>Buka Disclaimer &rarr;</span>
            </button>
            <button
              type="button"
              @click="activeTab = 'redaksi'"
              class="px-4 py-2 rounded-xl bg-[#0B2563] hover:bg-blue-900 text-white text-xs font-extrabold inline-flex items-center gap-1.5 transition-colors shadow-2xs cursor-pointer"
            >
              <Users class="w-3.5 h-3.5" />
              <span>Susunan Redaksi</span>
            </button>
          </div>
        </div>
      </div>

      <!-- Kontak Redaksi, Iklan & Pengaduan Hak Jawab -->
      <div id="kontak" class="rounded-3xl bg-gradient-to-br from-[#081A47] to-[#0B2563] text-white p-6 sm:p-8 shadow-md space-y-4">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-white/10 pb-4">
          <div>
            <span class="text-[10px] uppercase font-bold text-[#F5B700] tracking-wider">Layanan Komunikasi Publik</span>
            <h2 class="text-lg font-black text-white">Kontak Redaksi, Iklan & Pengaduan Hak Jawab</h2>
          </div>
          <div class="text-[11px] text-blue-200">
            Layanan pengaduan hak jawab dan hak koreksi terbuka 24 jam.
          </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs sm:text-sm">
          <div class="bg-white/10 rounded-2xl p-4 space-y-1.5">
            <MapPin class="w-5 h-5 text-[#F5B700]" />
            <div class="font-bold text-white">Alamat Kantor Redaksi</div>
            <p class="text-blue-100/85 text-xs leading-relaxed">{{ portalState.settings.office_address }}</p>
          </div>

          <div class="bg-white/10 rounded-2xl p-4 space-y-1.5">
            <Phone class="w-5 h-5 text-[#F5B700]" />
            <div class="font-bold text-white">Hotline / WhatsApp Resmi</div>
            <a
              :href="`https://wa.me/${portalState.settings.whatsapp_number}`"
              target="_blank"
              rel="noopener noreferrer"
              class="text-blue-100 hover:text-[#F5B700] text-xs font-semibold block transition-colors"
            >
              {{ portalState.settings.hotline_phone }}
            </a>
            <p class="text-[10px] text-blue-200/70">Senin - Minggu (Pelayanan Media)</p>
          </div>

          <div class="bg-white/10 rounded-2xl p-4 space-y-1.5">
            <Mail class="w-5 h-5 text-[#F5B700]" />
            <div class="font-bold text-white">Email Redaksi & Kerjasama</div>
            <a
              :href="`mailto:${portalState.settings.redaksi_email}`"
              class="text-blue-100 hover:text-[#F5B700] text-xs font-semibold block break-all transition-colors"
            >
              {{ portalState.settings.redaksi_email }}
            </a>
            <p class="text-[10px] text-blue-200/70">Kirimkan rilis pers, hak jawab, atau penawaran iklan.</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
