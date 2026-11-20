<script setup>
import { ref, onMounted } from 'vue'
import { api } from '../../api/client'
import { bootstrapPortal, showToast } from '../../composables/usePortal'
import {
  getSupabaseConfig,
  setSupabaseConfig,
  testSupabaseConnection,
  syncAllToSupabase,
} from '../../api/supabase'
import { getLocalStore } from '../../api/client'
import { Save, Database, CheckCircle2, AlertCircle, RefreshCw, ExternalLink, Search, Globe, FileCode, Radio } from 'lucide-vue-next'

const saving = ref(false)
const testingSb = ref(false)
const syncingSb = ref(false)
const sbStatus = ref(null)
const pingingGoogle = ref(false)

const form = ref({
  site_title: '',
  site_subtitle: '',
  site_tagline: '',
  site_description: '',
  google_site_verification: '',
  company_name: '',
  hotline_phone: '',
  whatsapp_number: '',
  redaksi_email: '',
  office_address: '',
  facebook_url: '',
  instagram_url: '',
  twitter_url: '',
  youtube_url: '',
})

const sbForm = ref({
  url: '',
  key: '',
})

onMounted(async () => {
  const res = await api.get('/settings')
  if (res.data) {
    Object.assign(form.value, res.data)
  }

  const sbConf = getSupabaseConfig()
  sbForm.value.url = sbConf.url
  sbForm.value.key = sbConf.key
  if (sbConf.isConfigured) {
    sbStatus.value = { ok: true, message: 'Supabase terkonfigurasi di browser ini' }
  }
})

async function save() {
  saving.value = true
  try {
    await api.put('/admin/settings', form.value)
    await bootstrapPortal(true)
    showToast('Pengaturan portal berhasil disimpan!')
  } catch (e) {
    showToast(e.message, 'error')
  } finally {
    saving.value = false
  }
}

async function testSupabase() {
  testingSb.value = true
  sbStatus.value = null
  try {
    const res = await testSupabaseConnection(sbForm.value.url, sbForm.value.key)
    if (res.ok) {
      sbStatus.value = { ok: true, message: 'Koneksi ke Supabase berhasil!' }
      showToast('Koneksi Supabase berhasil terhubung!')
    } else {
      sbStatus.value = { ok: false, message: res.error || 'Koneksi gagal' }
      showToast(res.error || 'Gagal terhubung ke Supabase', 'error')
    }
  } catch (e) {
    sbStatus.value = { ok: false, message: e.message }
    showToast(e.message, 'error')
  } finally {
    testingSb.value = false
  }
}

function saveSupabase() {
  if (!sbForm.value.url.trim() && !sbForm.value.key.trim()) {
    setSupabaseConfig('', '')
    sbStatus.value = null
    showToast('Kredensial Supabase dikosongkan (kembali ke penyimpanan lokal/offline)')
    return
  }
  setSupabaseConfig(sbForm.value.url, sbForm.value.key)
  showToast('Kredensial Supabase berhasil disimpan!')
  testSupabase()
}

async function handleSyncToSupabase() {
  if (!confirm('Apakah Anda yakin ingin mengunggah semua kategori, 63 berita, video, iklan, dan struktur redaksi lokal ke database Supabase Anda?')) {
    return
  }
  syncingSb.value = true
  try {
    const local = getLocalStore()
    const res = await syncAllToSupabase(local)
    showToast(`Sukses sinkron: ${res.articles} berita, ${res.categories} kategori, ${res.videos} video ke Supabase!`)
  } catch (e) {
    showToast('Gagal sinkron data ke Supabase: ' + e.message, 'error')
  } finally {
    syncingSb.value = false
  }
}
async function pingGoogleSitemap() {
  pingingGoogle.value = true
  try {
    window.open('https://www.google.com/ping?sitemap=https://mediafourtribuannews.my.id/sitemap.xml', '_blank')
    showToast('Ping sitemap dikirim ke Google & Bing!', 'success')
  } catch (e) {
    showToast('Gagal mengirim ping: ' + e.message, 'error')
  } finally {
    pingingGoogle.value = false
  }
}
</script>

<template>
  <div class="max-w-3xl space-y-6">
    <!-- Card 1: Pengaturan Portal Publik -->
    <div class="bg-white rounded-2xl border border-slate-200 p-5 sm:p-7 shadow-2xs space-y-5">
      <div>
        <h2 class="text-lg font-black text-[#0B2563]">Pengaturan Portal Berita</h2>
        <p class="text-xs text-slate-500">Identitas media, kontak redaksi, dan alamat kantor yang tampil di seluruh halaman publik.</p>
      </div>

      <form @submit.prevent="save" class="space-y-4">
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label class="block text-xs font-extrabold text-slate-700 mb-1">Nama Media</label>
            <input v-model="form.site_title" class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm focus:bg-white focus:border-[#0B2563] outline-hidden" />
          </div>
          <div>
            <label class="block text-xs font-extrabold text-slate-700 mb-1">Tagline</label>
            <input v-model="form.site_tagline" class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm focus:bg-white focus:border-[#0B2563] outline-hidden" />
          </div>
          <div>
            <label class="block text-xs font-extrabold text-slate-700 mb-1">Nama Perusahaan Penerbit</label>
            <input v-model="form.company_name" class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm focus:bg-white focus:border-[#0B2563] outline-hidden" />
          </div>
          <div>
            <label class="block text-xs font-extrabold text-slate-700 mb-1">Email Redaksi</label>
            <input v-model="form.redaksi_email" class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm focus:bg-white focus:border-[#0B2563] outline-hidden" />
          </div>
          <div>
            <label class="block text-xs font-extrabold text-slate-700 mb-1">Hotline Telepon</label>
            <input v-model="form.hotline_phone" class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm focus:bg-white focus:border-[#0B2563] outline-hidden" />
          </div>
          <div>
            <label class="block text-xs font-extrabold text-slate-700 mb-1">Nomor WhatsApp (62...)</label>
            <input v-model="form.whatsapp_number" class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm focus:bg-white focus:border-[#0B2563] outline-hidden" />
          </div>
        </div>

        <div>
          <label class="block text-xs font-extrabold text-slate-700 mb-1">Deskripsi Portal (SEO)</label>
          <textarea v-model="form.site_description" rows="2" class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm focus:bg-white focus:border-[#0B2563] outline-hidden"></textarea>
        </div>

        <div>
          <label class="block text-xs font-extrabold text-slate-700 mb-1">Alamat Kantor Redaksi</label>
          <textarea v-model="form.office_address" rows="2" class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm focus:bg-white focus:border-[#0B2563] outline-hidden"></textarea>
        </div>

        <div class="flex justify-end pt-2">
          <button
            type="submit"
            :disabled="saving"
            class="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-extrabold transition-colors disabled:opacity-50 cursor-pointer"
          >
            <Save class="w-4 h-4" /> {{ saving ? 'Menyimpan...' : 'Simpan Pengaturan' }}
          </button>
        </div>
      </form>
    </div>

    <!-- Card 2: Database Supabase Cloud Integration -->
    <div class="bg-white rounded-2xl border border-slate-200 p-5 sm:p-7 shadow-2xs space-y-5">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <div class="flex items-center gap-2">
            <Database class="w-5 h-5 text-emerald-600" />
            <h2 class="text-lg font-black text-[#0B2563]">Integrasi Database Supabase (Serverless Cloud)</h2>
          </div>
          <p class="text-xs text-slate-500 mt-0.5">
            Gunakan Supabase agar portal berita dan CMS Admin tetap online di GitHub Pages secara gratis tanpa server backend lokal.
          </p>
        </div>

        <span
          class="self-start sm:self-auto inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold"
          :class="sbStatus?.ok ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' : 'bg-amber-50 text-amber-700 border border-amber-200'"
        >
          <component :is="sbStatus?.ok ? CheckCircle2 : AlertCircle" class="w-3.5 h-3.5" />
          {{ sbStatus?.ok ? 'Supabase Terhubung' : 'Mode Offline / Bundled Aktif' }}
        </span>
      </div>

      <!-- Quick Info / Panduan Setup -->
      <div class="p-4 rounded-xl bg-slate-50 border border-slate-200/80 text-xs text-slate-600 space-y-2">
        <p class="font-bold text-slate-800 flex items-center gap-1.5">
          <span>🚀 Cara Menghubungkan Supabase:</span>
        </p>
        <ol class="list-decimal list-inside space-y-1 text-slate-600 leading-relaxed">
          <li>Buat proyek baru di <a href="https://supabase.com" target="_blank" class="text-emerald-700 font-bold underline inline-flex items-center gap-0.5">supabase.com <ExternalLink class="w-3 h-3" /></a>.</li>
          <li>Buka menu <strong>SQL Editor</strong> di Supabase, lalu jalankan (Run) seluruh isi file <code class="px-1.5 py-0.5 rounded bg-white border border-slate-300 font-mono text-[11px] text-blue-800">supabase_schema.sql</code> yang sudah disediakan di folder utama proyek ini.</li>
          <li>Salin <strong>Project URL</strong> dan <strong>anon / public key</strong> dari menu <em>Project Settings -> API</em>, lalu tempelkan di bawah ini.</li>
        </ol>
      </div>

      <div class="space-y-4">
        <div>
          <label class="block text-xs font-extrabold text-slate-700 mb-1">Supabase Project URL</label>
          <input
            v-model="sbForm.url"
            placeholder="https://xxxxxxxxxxxxxxxxxxxx.supabase.co"
            class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm font-mono text-xs focus:bg-white focus:border-emerald-600 outline-hidden"
          />
        </div>

        <div>
          <label class="block text-xs font-extrabold text-slate-700 mb-1">Supabase Anon Public API Key</label>
          <input
            v-model="sbForm.key"
            placeholder="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
            type="password"
            class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm font-mono text-xs focus:bg-white focus:border-emerald-600 outline-hidden"
          />
        </div>

        <div v-if="sbStatus" class="p-3 rounded-xl text-xs font-semibold" :class="sbStatus.ok ? 'bg-emerald-50 text-emerald-800 border border-emerald-200' : 'bg-rose-50 text-rose-800 border border-rose-200'">
          {{ sbStatus.message }}
        </div>

        <div class="flex flex-wrap items-center justify-between gap-3 pt-2">
          <button
            type="button"
            @click="handleSyncToSupabase"
            :disabled="syncingSb || !sbForm.url || !sbForm.key"
            class="inline-flex items-center gap-1.5 px-4 py-2.5 rounded-xl bg-emerald-50 text-emerald-700 hover:bg-emerald-100 border border-emerald-200 text-xs font-extrabold transition-colors disabled:opacity-40 cursor-pointer"
          >
            <RefreshCw class="w-3.5 h-3.5" :class="{ 'animate-spin': syncingSb }" />
            {{ syncingSb ? 'Mengunggah...' : 'Unggah Data Awal ke Supabase' }}
          </button>

          <div class="flex items-center gap-2">
            <button
              type="button"
              @click="testSupabase"
              :disabled="testingSb || !sbForm.url || !sbForm.key"
              class="px-4 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-800 text-xs font-bold transition-colors disabled:opacity-40 cursor-pointer"
            >
              {{ testingSb ? 'Menguji...' : 'Uji Koneksi' }}
            </button>
            <button
              type="button"
              @click="saveSupabase"
              class="px-5 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-extrabold transition-colors shadow-2xs cursor-pointer"
            >
              Simpan Kredensial Supabase
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Card 3: Optimasi SEO & Google Search Console -->
    <div class="bg-white rounded-2xl border border-slate-200 p-5 sm:p-7 shadow-2xs space-y-5">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <div class="flex items-center gap-2">
            <Search class="w-5 h-5 text-blue-700" />
            <h2 class="text-lg font-black text-[#0B2563]">Optimasi SEO & Google Search Console</h2>
          </div>
          <p class="text-xs text-slate-500 mt-0.5">
            Daftarkan situs ke Google agar berita dan portal Media Four Tribuan News cepat terindeks dan muncul di pencarian Google.
          </p>
        </div>

        <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-blue-50 text-blue-700 border border-blue-200">
          <Globe class="w-3.5 h-3.5" />
          Status SEO: Siap Terindeks Google
        </span>
      </div>

      <!-- Indikator File SEO Siap Pakai -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
        <a
          href="/sitemap.xml"
          target="_blank"
          class="p-3.5 rounded-xl border border-slate-200 bg-slate-50 hover:bg-blue-50/60 hover:border-blue-300 transition-colors block"
        >
          <div class="flex items-center justify-between">
            <span class="text-xs font-extrabold text-[#0B2563]">sitemap.xml</span>
            <CheckCircle2 class="w-4 h-4 text-emerald-600" />
          </div>
          <p class="text-[11px] text-slate-500 mt-1">89 URL Berita & Halaman terindeks otomatis</p>
        </a>

        <a
          href="/news-sitemap.xml"
          target="_blank"
          class="p-3.5 rounded-xl border border-slate-200 bg-slate-50 hover:bg-blue-50/60 hover:border-blue-300 transition-colors block"
        >
          <div class="flex items-center justify-between">
            <span class="text-xs font-extrabold text-[#0B2563]">news-sitemap.xml</span>
            <CheckCircle2 class="w-4 h-4 text-emerald-600" />
          </div>
          <p class="text-[11px] text-slate-500 mt-1">Format resmi Google News Feed</p>
        </a>

        <a
          href="/rss.xml"
          target="_blank"
          class="p-3.5 rounded-xl border border-slate-200 bg-slate-50 hover:bg-blue-50/60 hover:border-blue-300 transition-colors block"
        >
          <div class="flex items-center justify-between">
            <span class="text-xs font-extrabold text-[#0B2563]">rss.xml</span>
            <CheckCircle2 class="w-4 h-4 text-emerald-600" />
          </div>
          <p class="text-[11px] text-slate-500 mt-1">Umpan sindikasi berita RSS 2.0</p>
        </a>

        <a
          href="/robots.txt"
          target="_blank"
          class="p-3.5 rounded-xl border border-slate-200 bg-slate-50 hover:bg-blue-50/60 hover:border-blue-300 transition-colors block"
        >
          <div class="flex items-center justify-between">
            <span class="text-xs font-extrabold text-[#0B2563]">robots.txt</span>
            <CheckCircle2 class="w-4 h-4 text-emerald-600" />
          </div>
          <p class="text-[11px] text-slate-500 mt-1">Izin bot Googlebot & bingbot</p>
        </a>
      </div>

      <!-- Verifikasi Google Search Console -->
      <div class="p-4 rounded-xl bg-slate-50 border border-slate-200/90 space-y-3">
        <label class="block text-xs font-extrabold text-slate-800">
          Kode Verifikasi Google Search Console (HTML Tag Meta)
        </label>
        <p class="text-xs text-slate-500">
          Tempelkan kode verifikasi dari Google Search Console di sini (contoh: <code class="px-1.5 py-0.5 rounded bg-white border border-slate-300 font-mono text-[11px]">google-site-verification=XXXXXXXXXXXXXXXXXXXX</code>).
        </p>
        <div class="flex gap-2">
          <input
            v-model="form.google_site_verification"
            placeholder="google-site-verification=..."
            class="flex-1 px-3.5 py-2.5 rounded-xl bg-white border border-slate-200 text-xs sm:text-sm font-mono focus:border-[#0B2563] outline-hidden"
          />
          <button
            type="button"
            @click="save"
            class="px-5 py-2.5 rounded-xl bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-extrabold transition-colors shadow-2xs"
          >
            Simpan Kode
          </button>
        </div>
      </div>

      <!-- Tombol Aksi Cepat Google Console & Ping -->
      <div class="flex flex-wrap items-center justify-between gap-3 pt-2">
        <button
          type="button"
          @click="pingGoogleSitemap"
          :disabled="pingingGoogle"
          class="inline-flex items-center gap-1.5 px-4 py-2.5 rounded-xl bg-blue-50 text-blue-700 hover:bg-blue-100 border border-blue-200 text-xs font-extrabold transition-colors cursor-pointer"
        >
          <Radio class="w-3.5 h-3.5" :class="{ 'animate-pulse': pingingGoogle }" />
          <span>{{ pingingGoogle ? 'Mengirim Ping...' : 'Kirim Ping Sitemap ke Google' }}</span>
        </button>

        <a
          href="https://search.google.com/search-console"
          target="_blank"
          rel="noopener"
          class="inline-flex items-center gap-1.5 px-5 py-2.5 rounded-xl bg-[#4285F4] hover:bg-blue-600 text-white text-xs font-extrabold transition-colors shadow-2xs cursor-pointer"
        >
          <span>Buka Google Search Console</span>
          <ExternalLink class="w-3.5 h-3.5" />
        </a>
      </div>
    </div>
  </div>
</template>
