<script setup>
import { ref, onMounted } from 'vue'
import { api } from '../../api/client'
import { defaultPages } from '../../data/pagesData.js'
import { showToast } from '../../composables/usePortal'
import RichEditor from '../../components/RichEditor.vue'
import {
  FileText,
  ExternalLink,
  Pencil,
  Copy,
  CheckCircle2,
  X,
  Save,
  Clock,
  Sparkles
} from 'lucide-vue-next'

const pages = ref([])
const loading = ref(false)
const editingPage = ref(null)
const editForm = ref({
  title: '',
  subtitle: '',
  tni_polri_support: '',
  commitment_text: '',
  moral_foundation_text: '',
})

async function loadPages() {
  loading.value = true
  try {
    const res = await api.get('/admin/pages')
    if (res.data && Array.isArray(res.data) && res.data.length) {
      pages.value = res.data
    } else {
      pages.value = JSON.parse(JSON.stringify(defaultPages))
    }
  } catch (e) {
    pages.value = JSON.parse(JSON.stringify(defaultPages))
  } finally {
    loading.value = false
  }
}

function openEdit(p) {
  editingPage.value = p
  editForm.value = {
    title: p.title || '',
    subtitle: p.subtitle || '',
    tni_polri_support: p.tni_polri_support || '',
    commitment_text: p.commitment_text || '',
    moral_foundation_text: Array.isArray(p.moral_foundation) ? p.moral_foundation.join('\n\n') : (p.moral_foundation || ''),
  }
}

function closeEdit() {
  editingPage.value = null
}

async function saveEdit() {
  if (!editingPage.value) return
  try {
    const payload = {
      ...editingPage.value,
      title: editForm.value.title,
      subtitle: editForm.value.subtitle,
      tni_polri_support: editForm.value.tni_polri_support,
      commitment_text: editForm.value.commitment_text,
      moral_foundation: editForm.value.moral_foundation_text
        ? editForm.value.moral_foundation_text.split('\n\n').filter((s) => s.trim().length > 0)
        : editingPage.value.moral_foundation,
      updated_at: new Date().toISOString(),
    }

    await api.put(`/admin/pages/${editingPage.value.slug}`, payload)
    showToast(`Halaman "${editingPage.value.title}" berhasil diperbarui!`)
    closeEdit()
    loadPages()
  } catch (e) {
    showToast(e.message || 'Gagal menyimpan perubahan halaman', 'error')
  }
}

function copyLink(slug) {
  const url = `${window.location.origin}/${slug}`
  navigator.clipboard.writeText(url)
  showToast('Tautan halaman disalin ke clipboard!', 'info')
}

onMounted(loadPages)
</script>

<template>
  <div class="space-y-6">
    <!-- Header Admin Pages -->
    <div class="bg-white rounded-2xl border border-slate-200 p-6 shadow-2xs flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-blue-50 text-[#0B2563] text-xs font-bold mb-2">
          <FileText class="w-3.5 h-3.5" /> Manajemen Halaman Statis & Legalitas
        </div>
        <h1 class="text-xl sm:text-2xl font-black text-[#0B2563]">Halaman Dokumen Institusional & Legalitas Pers</h1>
        <p class="text-xs sm:text-sm text-slate-500 mt-1">
          Kelola dokumen resmi kelembagaan pers: Redaksi, Kode Etik Jurnalistik, Kemitraan Polri/TNI, Pedoman Media Siber, dsb.
        </p>
      </div>

      <div class="flex items-center gap-2">
        <router-link
          to="/redaksi"
          target="_blank"
          class="px-4 py-2.5 rounded-xl border border-slate-200 hover:bg-slate-50 text-slate-700 text-xs font-bold inline-flex items-center gap-1.5"
        >
          <ExternalLink class="w-3.5 h-3.5" />
          <span>Lihat di Website</span>
        </router-link>
      </div>
    </div>

    <!-- Table of Pages (WordPress Pages style matching user's Image 1 & 2) -->
    <div class="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-2xs">
      <div class="p-4 bg-slate-50 border-b border-slate-200 flex items-center justify-between text-xs font-extrabold text-slate-700 uppercase tracking-wider">
        <span>Daftar Halaman Statis ({{ pages.length }} Items)</span>
        <span class="text-slate-400 font-normal">Standar Regulasi Dewan Pers No. 1/2012</span>
      </div>

      <div class="divide-y divide-slate-100">
        <div
          v-for="p in pages"
          :key="p.slug"
          class="p-4 sm:p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:bg-slate-50/70 transition-colors"
        >
          <div class="space-y-1 flex-1 min-w-0">
            <div class="flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-emerald-500"></span>
              <h3 class="text-base font-extrabold text-[#0B2563] truncate">
                {{ p.title }}
              </h3>
              <span class="text-[10px] font-bold text-slate-400 bg-slate-100 px-2 py-0.5 rounded">
                /{{ p.slug }}
              </span>
            </div>
            <p class="text-xs text-slate-600 line-clamp-1">{{ p.subtitle }}</p>
            <div class="text-[11px] text-slate-400 flex items-center gap-1.5 pt-0.5">
              <Clock class="w-3 h-3" />
              <span>Status: <strong class="text-emerald-600">Publikasi Aktif</strong></span>
            </div>
          </div>

          <div class="flex items-center gap-2 shrink-0">
            <button
              type="button"
              @click="copyLink(p.slug)"
              class="px-3 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold inline-flex items-center gap-1.5"
              title="Salin Tautan"
            >
              <Copy class="w-3.5 h-3.5" />
              <span>Salin Link</span>
            </button>

            <button
              type="button"
              @click="openEdit(p)"
              class="px-3 py-2 rounded-xl bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-bold inline-flex items-center gap-1.5 transition-colors shadow-2xs"
            >
              <Pencil class="w-3.5 h-3.5" />
              <span>Edit Konten</span>
            </button>

            <a
              :href="`/${p.slug}`"
              target="_blank"
              class="p-2 rounded-xl border border-slate-200 hover:bg-slate-100 text-slate-600"
              title="Buka Halaman"
            >
              <ExternalLink class="w-4 h-4" />
            </a>
          </div>
        </div>
      </div>
    </div>

    <!-- Edit Modal Dialog -->
    <div
      v-if="editingPage"
      class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6"
    >
      <div class="fixed inset-0 bg-slate-950/70 backdrop-blur-xs" @click="closeEdit"></div>
      <div class="relative bg-white rounded-3xl border border-slate-200 w-full max-w-3xl max-h-[90vh] overflow-hidden flex flex-col shadow-2xl z-10">
        <!-- Modal Header -->
        <div class="p-5 bg-[#0B2563] text-white flex items-center justify-between">
          <div>
            <span class="text-[10px] uppercase font-bold text-[#F5B700]">Editor Halaman Statis</span>
            <h2 class="text-lg font-black text-white">Edit {{ editingPage.title }}</h2>
          </div>
          <button
            type="button"
            @click="closeEdit"
            class="p-2 rounded-xl hover:bg-white/10 text-white"
          >
            <X class="w-5 h-5" />
          </button>
        </div>

        <!-- Modal Body Form -->
        <div class="p-6 overflow-y-auto space-y-4 flex-1">
          <div>
            <label class="block text-xs font-extrabold text-slate-700 uppercase tracking-wider mb-1">
              Judul Halaman
            </label>
            <input
              v-model="editForm.title"
              type="text"
              class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm font-bold text-slate-800"
            />
          </div>

          <div>
            <label class="block text-xs font-extrabold text-slate-700 uppercase tracking-wider mb-1">
              Sub-Judul / Keterangan Singkat
            </label>
            <input
              v-model="editForm.subtitle"
              type="text"
              class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm text-slate-700"
            />
          </div>

          <!-- Dukungan Kemitraan Pers Polri/TNI (jika halaman redaksi atau kode etik) -->
          <div v-if="editingPage.slug === 'redaksi' || editingPage.slug === 'kode-etik'">
            <label class="block text-xs font-extrabold text-[#D91E28] uppercase tracking-wider mb-1">
              Teks Dukungan Kemitraan Pers (Polri - TNI)
            </label>
            <textarea
              v-model="editForm.tni_polri_support"
              rows="3"
              class="w-full p-3 rounded-xl border border-slate-200 text-xs sm:text-sm text-slate-800 leading-relaxed font-medium"
            ></textarea>
          </div>

          <!-- Komitmen Kode Etik -->
          <div v-if="editingPage.slug === 'kode-etik'">
            <label class="block text-xs font-extrabold text-[#0B2563] uppercase tracking-wider mb-1">
              Teks Komitmen Publikasi Media Four Tribuan News / Mitra Polri-TNI
            </label>
            <textarea
              v-model="editForm.commitment_text"
              rows="3"
              class="w-full p-3 rounded-xl border border-slate-200 text-xs sm:text-sm text-slate-800 leading-relaxed font-medium"
            ></textarea>
          </div>

          <!-- Landasan Moral (Redaksi) -->
          <div v-if="editingPage.slug === 'redaksi'">
            <label class="block text-xs font-extrabold text-[#0B2563] uppercase tracking-wider mb-1">
              Isian Redaksi (Landasan Moral & Etika Pers — Pisahkan antar paragraf dengan enter 2x)
            </label>
            <textarea
              v-model="editForm.moral_foundation_text"
              rows="7"
              class="w-full p-3 rounded-xl border border-slate-200 text-xs sm:text-sm text-slate-800 leading-relaxed"
            ></textarea>
          </div>
        </div>

        <!-- Modal Footer Actions -->
        <div class="p-4 bg-slate-50 border-t border-slate-200 flex items-center justify-end gap-2">
          <button
            type="button"
            @click="closeEdit"
            class="px-4 py-2 rounded-xl border border-slate-200 text-xs font-bold text-slate-700 hover:bg-slate-100"
          >
            Batal
          </button>
          <button
            type="button"
            @click="saveEdit"
            class="px-5 py-2.5 rounded-xl bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-black inline-flex items-center gap-1.5 shadow"
          >
            <Save class="w-4 h-4" />
            <span>Simpan Perubahan</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
