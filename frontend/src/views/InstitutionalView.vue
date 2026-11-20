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
  { id: 'redaksi', label: 'REDAKSI', icon: Users, routePath: '/redaksi' },
  { id: 'kode-etik', label: 'Kode Etik', icon: ShieldCheck, routePath: '/kode-etik' },
  { id: 'pedoman', label: 'Pedoman Media Siber', icon: FileCheck, routePath: '/pedoman-media-siber' },
  { id: 'privacy', label: 'Privacy Policy', icon: Lock, routePath: '/privacy-policy' },
  { id: 'disclaimer', label: 'Disclaimer', icon: AlertTriangle, routePath: '/disclaimer' },
  { id: 'dewan-pers', label: 'Dewan PERS', icon: Scale, routePath: '/dewan-pers' },
  { id: 'profil', label: 'Profil & Kontak', icon: BookOpen, routePath: '/tentang' },
]

function determineTabFromRoute() {
  const p = route.path.toLowerCase()
  if (p.includes('/kode-etik')) activeTab.value = 'kode-etik'
  else if (p.includes('/pedoman-media-siber')) activeTab.value = 'pedoman'
  else if (p.includes('/privacy-policy') || p.includes('/kebijakan-privasi')) activeTab.value = 'privacy'
  else if (p.includes('/disclaimer')) activeTab.value = 'disclaimer'
  else if (p.includes('/dewan-pers')) activeTab.value = 'dewan-pers'
  else if (p.includes('/tentang')) activeTab.value = 'profil'
  else if (p.includes('/redaksi')) activeTab.value = 'redaksi'
  else activeTab.value = props.defaultTab || 'redaksi'
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
    <!-- TAB 7: PROFIL & KONTAK                                        -->
    <!-- ============================================================== -->
    <div v-if="activeTab === 'profil'" class="space-y-6">
      <div class="bg-white rounded-3xl border border-slate-200 p-6 sm:p-8 shadow-2xs space-y-5">
        <div class="flex flex-col sm:flex-row sm:items-center gap-5 pb-5 border-b border-slate-100">
          <img src="/images/logo-mftn.jpg" alt="Logo Media Four Tribuan News" class="h-20 w-auto object-contain self-start" />
          <div>
            <span class="inline-block px-3 py-1 rounded-full bg-[#0B2563] text-[#F5B700] text-[10px] font-black uppercase tracking-widest mb-2">
              Profil Perusahaan Pers
            </span>
            <h1 class="text-2xl sm:text-3xl font-bold font-editorial text-[#0B2563]">
              {{ portalState.settings.site_title }}
            </h1>
            <p class="text-xs sm:text-sm font-bold text-[#D91E28] mt-0.5">
              {{ portalState.settings.site_tagline }}
            </p>
          </div>
        </div>

        <p class="text-sm text-slate-700 leading-relaxed">
          <strong>Media Four Tribuan News</strong> yang dikelola oleh <strong>{{ portalState.settings.company_name }}</strong>
          adalah portal berita digital nasional yang hadir menyajikan jurnalisme cepat, terverifikasi, berimbang, dan
          independen demi kepentingan masyarakat dan bangsa Indonesia.
        </p>

        <!-- Kemitraan Pers Callout -->
        <div class="p-4 rounded-2xl bg-blue-50/80 border border-blue-200/80 text-xs sm:text-sm text-slate-800 space-y-1.5">
          <div class="font-bold text-[#0B2563] flex items-center gap-1.5">
            <Shield class="w-4 h-4 text-[#D91E28]" /> Kemitraan Jurnalistik & Publikasi Resmi
          </div>
          <p class="leading-relaxed">
            "{{ redaksiPage.tni_polri_support }}"
          </p>
        </div>
      </div>

      <!-- Kontak Redaksi -->
      <div class="rounded-3xl bg-gradient-to-br from-[#081A47] to-[#0B2563] text-white p-6 sm:p-8 shadow-md space-y-4">
        <h2 class="text-lg font-black text-[#F5B700]">Kontak Redaksi, Iklan & Informasi</h2>
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs sm:text-sm">
          <div class="bg-white/10 rounded-2xl p-4 space-y-1.5">
            <MapPin class="w-5 h-5 text-[#F5B700]" />
            <div class="font-bold">Alamat Kantor Redaksi</div>
            <p class="text-blue-100/85 text-xs">{{ portalState.settings.office_address }}</p>
          </div>
          <div class="bg-white/10 rounded-2xl p-4 space-y-1.5">
            <Phone class="w-5 h-5 text-[#F5B700]" />
            <div class="font-bold">Hotline / WhatsApp Resmi</div>
            <a
              :href="`https://wa.me/${portalState.settings.whatsapp_number}`"
              target="_blank"
              class="text-blue-100 hover:text-[#F5B700] text-xs font-semibold block"
            >
              {{ portalState.settings.hotline_phone }}
            </a>
          </div>
          <div class="bg-white/10 rounded-2xl p-4 space-y-1.5">
            <Mail class="w-5 h-5 text-[#F5B700]" />
            <div class="font-bold">Email Redaksi</div>
            <p class="text-blue-100/85 text-xs break-all">{{ portalState.settings.redaksi_email }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
