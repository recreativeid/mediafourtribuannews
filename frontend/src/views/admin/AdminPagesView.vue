<script setup>
import { ref, computed, onMounted } from 'vue'
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
  Sparkles,
  ChevronDown,
  ChevronUp,
  Search,
  Plus,
  Trash2,
  RotateCcw,
  Check
} from 'lucide-vue-next'

const pages = ref([])
const loading = ref(false)
const searchQuery = ref('')
const currentTab = ref('all') // 'all' | 'published' | 'draft' | 'trash'
const selectedSlugs = ref([])
const expandedSlugs = ref([])

// Quick Edit state
const quickEditingSlug = ref(null)
const quickEditForm = ref({
  title: '',
  slug: '',
  status: 'published',
  updated_at: ''
})

// Full Modal Editor state
const editingPage = ref(null)
const editForm = ref({
  title: '',
  slug: '',
  subtitle: '',
  summary: '',
  tni_polri_support: '',
  commitment_text: '',
  moral_foundation_text: '',
  content: '',
  status: 'published'
})

// Add New Page modal
const isCreating = ref(false)
const createForm = ref({
  title: '',
  slug: '',
  subtitle: '',
  summary: '',
  content: '',
  status: 'published'
})

// Bulk action
const bulkAction = ref('')

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

// Computed stats & filters
const filteredPages = computed(() => {
  let list = [...pages.value]

  // Filter by tab
  if (currentTab.value === 'published') {
    list = list.filter((p) => (p.status || 'published') === 'published')
  } else if (currentTab.value === 'draft') {
    list = list.filter((p) => p.status === 'draft')
  } else if (currentTab.value === 'trash') {
    list = list.filter((p) => p.status === 'trash')
  } else {
    // 'all' excludes trash by default like WordPress
    list = list.filter((p) => p.status !== 'trash')
  }

  // Filter by search query
  if (searchQuery.value.trim()) {
    const q = searchQuery.value.trim().toLowerCase()
    list = list.filter(
      (p) =>
        p.title?.toLowerCase().includes(q) ||
        p.slug?.toLowerCase().includes(q) ||
        p.subtitle?.toLowerCase().includes(q)
    )
  }

  return list
})

const countAll = computed(() => pages.value.filter((p) => p.status !== 'trash').length)
const countPublished = computed(() => pages.value.filter((p) => (p.status || 'published') === 'published').length)
const countDraft = computed(() => pages.value.filter((p) => p.status === 'draft').length)
const countTrash = computed(() => pages.value.filter((p) => p.status === 'trash').length)

const isAllSelected = computed(() => {
  if (!filteredPages.value.length) return false
  return filteredPages.value.every((p) => selectedSlugs.value.includes(p.slug))
})

function toggleSelectAll() {
  if (isAllSelected.value) {
    selectedSlugs.value = []
  } else {
    selectedSlugs.value = filteredPages.value.map((p) => p.slug)
  }
}

function toggleSelect(slug) {
  const idx = selectedSlugs.value.indexOf(slug)
  if (idx > -1) {
    selectedSlugs.value.splice(idx, 1)
  } else {
    selectedSlugs.value.push(slug)
  }
}

function toggleExpand(slug) {
  const idx = expandedSlugs.value.indexOf(slug)
  if (idx > -1) {
    expandedSlugs.value.splice(idx, 1)
  } else {
    expandedSlugs.value.push(slug)
  }
}

// --- Quick Edit ---
function startQuickEdit(p) {
  quickEditingSlug.value = p.slug
  quickEditForm.value = {
    title: p.title || '',
    slug: p.slug || '',
    status: p.status || 'published',
    updated_at: p.updated_at ? p.updated_at.slice(0, 10) : new Date().toISOString().slice(0, 10)
  }
}

function cancelQuickEdit() {
  quickEditingSlug.value = null
}

async function saveQuickEdit(originalSlug) {
  try {
    const target = pages.value.find((p) => p.slug === originalSlug)
    if (!target) return

    const payload = {
      ...target,
      title: quickEditForm.value.title,
      slug: quickEditForm.value.slug || originalSlug,
      status: quickEditForm.value.status,
      updated_at: new Date().toISOString()
    }

    await api.put(`/admin/pages/${originalSlug}`, payload)
    showToast(`Halaman "${payload.title}" berhasil diperbarui!`)
    quickEditingSlug.value = null
    await loadPages()
  } catch (e) {
    showToast(e.message || 'Gagal memperbarui halaman', 'error')
  }
}

// --- Full Edit Modal ---
function openEdit(p) {
  editingPage.value = p
  editForm.value = {
    title: p.title || '',
    slug: p.slug || '',
    subtitle: p.subtitle || '',
    summary: p.summary || '',
    status: p.status || 'published',
    tni_polri_support: p.tni_polri_support || '',
    commitment_text: p.commitment_text || '',
    moral_foundation_text: Array.isArray(p.moral_foundation)
      ? p.moral_foundation.join('\n\n')
      : (p.moral_foundation || ''),
    content: p.content || ''
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
      slug: editForm.value.slug || editingPage.value.slug,
      subtitle: editForm.value.subtitle,
      summary: editForm.value.summary,
      status: editForm.value.status,
      tni_polri_support: editForm.value.tni_polri_support,
      commitment_text: editForm.value.commitment_text,
      moral_foundation: editForm.value.moral_foundation_text
        ? editForm.value.moral_foundation_text.split('\n\n').filter((s) => s.trim().length > 0)
        : editingPage.value.moral_foundation,
      content: editForm.value.content,
      updated_at: new Date().toISOString(),
    }

    await api.put(`/admin/pages/${editingPage.value.slug}`, payload)
    showToast(`Halaman "${payload.title}" berhasil disimpan!`)
    closeEdit()
    await loadPages()
  } catch (e) {
    showToast(e.message || 'Gagal menyimpan perubahan halaman', 'error')
  }
}

// --- Trash / Delete Actions ---
async function moveToTrash(p) {
  if (!confirm(`Pindahkan halaman "${p.title}" ke Tong Sampah?`)) return
  try {
    await api.put(`/admin/pages/${p.slug}`, { ...p, status: 'trash' })
    showToast(`Halaman "${p.title}" dipindahkan ke Tong Sampah`)
    await loadPages()
  } catch (e) {
    showToast('Gagal memindahkan ke sampah', 'error')
  }
}

async function restorePage(p) {
  try {
    await api.put(`/admin/pages/${p.slug}`, { ...p, status: 'published' })
    showToast(`Halaman "${p.title}" berhasil dipulihkan`)
    await loadPages()
  } catch (e) {
    showToast('Gagal memulihkan halaman', 'error')
  }
}

async function deletePermanently(p) {
  if (!confirm(`Hapus permanen halaman "${p.title}"? Tindakan ini tidak dapat dibatalkan.`)) return
  try {
    await api.del(`/admin/pages/${p.slug}`)
    showToast(`Halaman "${p.title}" dihapus permanen`)
    await loadPages()
  } catch (e) {
    showToast('Gagal menghapus halaman', 'error')
  }
}

// --- Bulk Actions ---
async function applyBulkAction() {
  if (!bulkAction.value) {
    showToast('Pilih tindakan massal terlebih dahulu', 'warning')
    return
  }
  if (!selectedSlugs.value.length) {
    showToast('Pilih setidaknya satu halaman dengan mencentang kotak', 'warning')
    return
  }

  if (bulkAction.value === 'trash') {
    if (!confirm(`Pindahkan ${selectedSlugs.value.length} halaman terpilih ke Tong Sampah?`)) return
    for (const slug of selectedSlugs.value) {
      const p = pages.value.find((pg) => pg.slug === slug)
      if (p) await api.put(`/admin/pages/${slug}`, { ...p, status: 'trash' })
    }
    showToast(`${selectedSlugs.value.length} halaman dipindahkan ke Tong Sampah`)
  } else if (bulkAction.value === 'restore') {
    for (const slug of selectedSlugs.value) {
      const p = pages.value.find((pg) => pg.slug === slug)
      if (p) await api.put(`/admin/pages/${slug}`, { ...p, status: 'published' })
    }
    showToast(`${selectedSlugs.value.length} halaman berhasil dipulihkan`)
  } else if (bulkAction.value === 'delete') {
    if (!confirm(`Hapus permanen ${selectedSlugs.value.length} halaman terpilih?`)) return
    for (const slug of selectedSlugs.value) {
      await api.del(`/admin/pages/${slug}`)
    }
    showToast(`${selectedSlugs.value.length} halaman dihapus permanen`)
  }

  selectedSlugs.value = []
  bulkAction.value = ''
  await loadPages()
}

// --- Create New Page ---
function openCreate() {
  createForm.value = {
    title: '',
    slug: '',
    subtitle: '',
    summary: '',
    content: '',
    status: 'published'
  }
  isCreating.value = true
}

function autoSlug() {
  if (!createForm.value.slug && createForm.value.title) {
    createForm.value.slug = createForm.value.title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '')
  }
}

async function saveCreate() {
  if (!createForm.value.title.trim()) {
    showToast('Judul halaman wajib diisi', 'error')
    return
  }
  try {
    const slug = createForm.value.slug.trim() || createForm.value.title.toLowerCase().replace(/[^a-z0-9]+/g, '-')
    const payload = {
      ...createForm.value,
      slug,
      short_title: createForm.value.title,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    }

    await api.post('/admin/pages', payload)
    showToast(`Halaman "${payload.title}" berhasil dibuat!`)
    isCreating.value = false
    await loadPages()
  } catch (e) {
    showToast(e.message || 'Gagal membuat halaman baru', 'error')
  }
}

function formatDate(isoStr) {
  if (!isoStr) return '-'
  try {
    const d = new Date(isoStr)
    return new Intl.DateTimeFormat('id-ID', {
      day: 'numeric',
      month: 'long',
      year: 'numeric'
    }).format(d)
  } catch (e) {
    return isoStr
  }
}

onMounted(loadPages)
</script>

<template>
  <div class="space-y-4 font-sans text-slate-800">
    <!-- Top Bar: Title & Add New Page -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
      <div class="flex items-center gap-3">
        <h1 class="text-xl sm:text-2xl font-bold text-[#1d2327]">Halaman</h1>
        <button
          type="button"
          @click="openCreate"
          class="px-2.5 py-1 text-xs font-semibold text-[#2271b1] border border-[#2271b1] hover:bg-[#2271b1] hover:text-white rounded transition-colors inline-flex items-center gap-1 cursor-pointer"
        >
          <Plus class="w-3.5 h-3.5" />
          <span>Tambah Halaman Baru</span>
        </button>
      </div>

      <!-- Search Pages Form (Top right like WordPress) -->
      <div class="flex items-center gap-1.5 self-end sm:self-auto w-full sm:w-auto">
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Cari Halaman..."
          class="px-2.5 py-1 text-xs border border-slate-300 rounded bg-white focus:outline-none focus:border-[#2271b1] w-full sm:w-48 shadow-2xs"
          @keyup.enter="() => {}"
        />
        <button
          type="button"
          class="px-3 py-1 text-xs font-semibold text-[#2271b1] border border-[#2271b1] bg-white hover:bg-slate-50 rounded whitespace-nowrap cursor-pointer shadow-2xs"
        >
          Search Pages
        </button>
      </div>
    </div>

    <!-- Status Tabs (WordPress style: All | Published | Trash) -->
    <div class="flex items-center gap-2 text-xs text-slate-600 border-b border-slate-200 pb-2">
      <button
        type="button"
        @click="currentTab = 'all'"
        class="cursor-pointer"
        :class="currentTab === 'all' ? 'font-bold text-slate-900' : 'text-[#2271b1] hover:underline'"
      >
        Semua ({{ countAll }})
      </button>
      <span class="text-slate-300">|</span>
      <button
        type="button"
        @click="currentTab = 'published'"
        class="cursor-pointer"
        :class="currentTab === 'published' ? 'font-bold text-slate-900' : 'text-[#2271b1] hover:underline'"
      >
        Diterbitkan ({{ countPublished }})
      </button>
      <span v-if="countDraft > 0" class="text-slate-300">|</span>
      <button
        v-if="countDraft > 0"
        type="button"
        @click="currentTab = 'draft'"
        class="cursor-pointer"
        :class="currentTab === 'draft' ? 'font-bold text-slate-900' : 'text-[#2271b1] hover:underline'"
      >
        Draf ({{ countDraft }})
      </button>
      <span v-if="countTrash > 0" class="text-slate-300">|</span>
      <button
        v-if="countTrash > 0"
        type="button"
        @click="currentTab = 'trash'"
        class="cursor-pointer"
        :class="currentTab === 'trash' ? 'font-bold text-red-600' : 'text-red-500 hover:underline'"
      >
        Tong Sampah ({{ countTrash }})
      </button>
    </div>

    <!-- WordPress Table Wrapper -->
    <div class="bg-white border border-[#ccd0d4] rounded shadow-2xs overflow-hidden">
      <!-- Top Table Header: [ ] Title ▲ -->
      <div class="bg-[#f6f7f7] border-b border-[#ccd0d4] px-3 py-2 flex items-center justify-between text-xs font-semibold text-[#2c3338]">
        <div class="flex items-center gap-3">
          <input
            type="checkbox"
            :checked="isAllSelected"
            @change="toggleSelectAll"
            class="w-4 h-4 rounded border-slate-300 text-[#2271b1] focus:ring-0 cursor-pointer"
          />
          <span class="inline-flex items-center gap-1 cursor-pointer select-none">
            Title <span class="text-[10px]">▲</span>
          </span>
        </div>
        <div class="text-[11px] text-slate-500 font-normal hidden sm:block">
          Media Four Tribuan News
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="p-8 text-center text-xs text-slate-500">
        Memuat daftar halaman...
      </div>

      <!-- Empty State -->
      <div v-else-if="!filteredPages.length" class="p-8 text-center text-xs text-slate-500">
        Tidak ada halaman ditemukan.
      </div>

      <!-- Rows List (Faithfully styled like WordPress Mobile Pages table) -->
      <div v-else class="divide-y divide-slate-200">
        <template v-for="p in filteredPages" :key="p.slug">
          <!-- Normal Row -->
          <div
            class="p-3 sm:px-4 sm:py-3 transition-colors"
            :class="[
              selectedSlugs.includes(p.slug) ? 'bg-blue-50/40' : 'hover:bg-[#f9f9f9]',
              quickEditingSlug === p.slug ? 'bg-amber-50/50' : ''
            ]"
          >
            <div class="flex items-start justify-between gap-2">
              <!-- Left: Checkbox + Title + Action links -->
              <div class="flex items-start gap-3 flex-1 min-w-0">
                <input
                  type="checkbox"
                  :checked="selectedSlugs.includes(p.slug)"
                  @change="toggleSelect(p.slug)"
                  class="w-4 h-4 mt-0.5 rounded border-slate-300 text-[#2271b1] focus:ring-0 cursor-pointer shrink-0"
                />

                <div class="flex-1 min-w-0 space-y-1">
                  <!-- Page Title (Blue bold link like WordPress) -->
                  <div class="flex items-baseline gap-2 flex-wrap">
                    <span
                      @click="openEdit(p)"
                      class="text-[13px] sm:text-sm font-bold text-[#135e96] hover:text-[#0b436d] cursor-pointer hover:underline break-words"
                    >
                      {{ p.title }}
                    </span>
                    <span
                      v-if="p.status === 'draft'"
                      class="text-[10px] font-bold uppercase px-1.5 py-0.2 bg-slate-200 text-slate-700 rounded"
                    >
                      — Draf
                    </span>
                    <span
                      v-if="p.status === 'trash'"
                      class="text-[10px] font-bold uppercase px-1.5 py-0.2 bg-red-100 text-red-700 rounded"
                    >
                      — Sampah
                    </span>
                  </div>

                  <!-- WordPress Sub-action links: Edit | Quick Edit | Trash | View -->
                  <div class="flex items-center flex-wrap gap-2 text-xs pt-0.5">
                    <template v-if="p.status !== 'trash'">
                      <button
                        type="button"
                        @click="openEdit(p)"
                        class="text-[#2271b1] hover:underline cursor-pointer"
                      >
                        Edit
                      </button>
                      <span class="text-slate-300">|</span>

                      <button
                        type="button"
                        @click="startQuickEdit(p)"
                        class="text-[#2271b1] hover:underline cursor-pointer"
                      >
                        Quick Edit
                      </button>
                      <span class="text-slate-300">|</span>

                      <button
                        type="button"
                        @click="moveToTrash(p)"
                        class="text-[#d63638] hover:underline cursor-pointer"
                      >
                        Trash
                      </button>
                      <span class="text-slate-300">|</span>

                      <a
                        :href="`/${p.slug}`"
                        target="_blank"
                        class="text-[#2271b1] hover:underline cursor-pointer inline-flex items-center gap-0.5"
                      >
                        View
                      </a>
                    </template>

                    <template v-else>
                      <button
                        type="button"
                        @click="restorePage(p)"
                        class="text-[#2271b1] hover:underline cursor-pointer"
                      >
                        Pulihkan (Restore)
                      </button>
                      <span class="text-slate-300">|</span>

                      <button
                        type="button"
                        @click="deletePermanently(p)"
                        class="text-[#d63638] hover:underline cursor-pointer"
                      >
                        Hapus Permanen
                      </button>
                    </template>
                  </div>
                </div>
              </div>

              <!-- Right: Toggle Arrow ▼ / ▲ (Accordion for extra details on mobile) -->
              <button
                type="button"
                @click="toggleExpand(p.slug)"
                class="p-1 text-slate-500 hover:text-slate-900 cursor-pointer shrink-0"
                title="Rincian Halaman"
              >
                <span class="text-xs font-mono font-bold">{{ expandedSlugs.includes(p.slug) ? '▲' : '▼' }}</span>
              </button>
            </div>

            <!-- Expanded Details (toggled by ▼) -->
            <div
              v-if="expandedSlugs.includes(p.slug)"
              class="mt-3 pt-2.5 border-t border-dashed border-slate-200 text-xs text-slate-600 pl-7 space-y-1 bg-slate-50/60 p-2.5 rounded"
            >
              <div class="flex items-center gap-2">
                <span class="text-slate-400 w-20">Penulis:</span>
                <span class="font-semibold text-slate-800">Redaksi Media Four Tribuan News</span>
              </div>
              <div class="flex items-center gap-2">
                <span class="text-slate-400 w-20">Tanggal:</span>
                <span>{{ formatDate(p.updated_at) }}</span>
              </div>
              <div class="flex items-center gap-2">
                <span class="text-slate-400 w-20">Status:</span>
                <span
                  class="px-1.5 py-0.5 rounded text-[10px] font-bold"
                  :class="p.status === 'trash' ? 'bg-red-100 text-red-700' : 'bg-emerald-100 text-emerald-700'"
                >
                  {{ p.status === 'trash' ? 'Di Tong Sampah' : 'Diterbitkan' }}
                </span>
              </div>
              <div class="flex items-center gap-2">
                <span class="text-slate-400 w-20">URL Slug:</span>
                <code class="text-[#2271b1] font-mono text-[11px]">/{{ p.slug }}</code>
              </div>
            </div>

            <!-- Quick Edit Form (Expands right inline under the row) -->
            <div
              v-if="quickEditingSlug === p.slug"
              class="mt-3 p-3 sm:p-4 bg-white border border-[#2271b1] rounded shadow-sm text-xs space-y-3"
            >
              <div class="font-bold text-[#1d2327] uppercase tracking-wide text-[11px] border-b border-slate-200 pb-1.5 flex items-center justify-between">
                <span>QUICK EDIT</span>
                <span class="text-[10px] text-slate-400 font-normal">Edit Cepat Halaman</span>
              </div>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label class="block font-semibold text-slate-700 mb-1">Judul</label>
                  <input
                    v-model="quickEditForm.title"
                    type="text"
                    class="w-full px-2.5 py-1.5 border border-slate-300 rounded text-xs focus:border-[#2271b1] outline-hidden"
                  />
                </div>

                <div>
                  <label class="block font-semibold text-slate-700 mb-1">Slug / URL</label>
                  <input
                    v-model="quickEditForm.slug"
                    type="text"
                    class="w-full px-2.5 py-1.5 border border-slate-300 rounded text-xs font-mono focus:border-[#2271b1] outline-hidden"
                  />
                </div>

                <div>
                  <label class="block font-semibold text-slate-700 mb-1">Status Publikasi</label>
                  <select
                    v-model="quickEditForm.status"
                    class="w-full px-2.5 py-1.5 border border-slate-300 rounded text-xs bg-white focus:border-[#2271b1] outline-hidden"
                  >
                    <option value="published">Diterbitkan (Published)</option>
                    <option value="draft">Draf (Draft)</option>
                    <option value="trash">Tong Sampah (Trash)</option>
                  </select>
                </div>

                <div>
                  <label class="block font-semibold text-slate-700 mb-1">Tanggal Pembaruan</label>
                  <input
                    v-model="quickEditForm.updated_at"
                    type="date"
                    class="w-full px-2.5 py-1.5 border border-slate-300 rounded text-xs focus:border-[#2271b1] outline-hidden"
                  />
                </div>
              </div>

              <!-- Quick Edit Buttons -->
              <div class="flex items-center justify-end gap-2 pt-2 border-t border-slate-200">
                <button
                  type="button"
                  @click="cancelQuickEdit"
                  class="px-3 py-1.5 border border-slate-300 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded font-semibold cursor-pointer"
                >
                  Batal
                </button>
                <button
                  type="button"
                  @click="saveQuickEdit(p.slug)"
                  class="px-4 py-1.5 bg-[#2271b1] hover:bg-[#135e96] text-white rounded font-semibold cursor-pointer shadow-2xs"
                >
                  Perbarui
                </button>
              </div>
            </div>
          </div>
        </template>
      </div>

      <!-- Bottom Table Header: [ ] Title ▲ (repeated as in WordPress screenshot) -->
      <div class="bg-[#f6f7f7] border-t border-[#ccd0d4] px-3 py-2 flex items-center justify-between text-xs font-semibold text-[#2c3338]">
        <div class="flex items-center gap-3">
          <input
            type="checkbox"
            :checked="isAllSelected"
            @change="toggleSelectAll"
            class="w-4 h-4 rounded border-slate-300 text-[#2271b1] focus:ring-0 cursor-pointer"
          />
          <span class="inline-flex items-center gap-1 cursor-pointer select-none">
            Title <span class="text-[10px]">▲</span>
          </span>
        </div>
      </div>
    </div>

    <!-- Bottom Actions Bar: [ Bulk actions ▼ ] [ Apply ] ........... 12 items -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pt-1">
      <div class="flex items-center gap-2">
        <select
          v-model="bulkAction"
          class="px-2.5 py-1.5 text-xs border border-slate-300 rounded bg-white text-slate-800 focus:outline-none focus:border-[#2271b1] shadow-2xs"
        >
          <option value="">Bulk actions</option>
          <option v-if="currentTab !== 'trash'" value="trash">Pindahkan ke Tong Sampah</option>
          <option v-if="currentTab === 'trash'" value="restore">Pulihkan Halaman</option>
          <option value="delete">Hapus Permanen</option>
        </select>
        <button
          type="button"
          @click="applyBulkAction"
          class="px-3 py-1.5 text-xs font-semibold text-[#2271b1] border border-[#2271b1] bg-white hover:bg-slate-50 rounded shadow-2xs cursor-pointer"
        >
          Apply
        </button>
      </div>

      <div class="text-xs text-slate-600 font-semibold text-right">
        {{ filteredPages.length }} items
      </div>
    </div>

    <!-- Full Edit Modal (Opens on 'Edit') -->
    <div
      v-if="editingPage"
      class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6"
    >
      <div class="fixed inset-0 bg-slate-950/70 backdrop-blur-xs" @click="closeEdit"></div>
      <div class="relative bg-white rounded-2xl border border-slate-300 w-full max-w-3xl max-h-[90vh] overflow-hidden flex flex-col shadow-2xl z-10">
        <!-- Modal Header -->
        <div class="p-4 sm:p-5 bg-[#0B2563] text-white flex items-center justify-between">
          <div>
            <span class="text-[10px] uppercase font-bold text-[#F5B700]">Editor Halaman Penuh</span>
            <h2 class="text-base sm:text-lg font-black text-white">Edit: {{ editingPage.title }}</h2>
          </div>
          <button
            type="button"
            @click="closeEdit"
            class="p-1.5 rounded-lg hover:bg-white/10 text-white cursor-pointer"
          >
            <X class="w-5 h-5" />
          </button>
        </div>

        <!-- Modal Body Form -->
        <div class="p-5 sm:p-6 overflow-y-auto space-y-4 flex-1 text-xs">
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Judul Halaman *
              </label>
              <input
                v-model="editForm.title"
                type="text"
                class="w-full px-3 py-2 rounded-lg border border-slate-300 text-sm font-bold text-slate-800"
              />
            </div>
            <div>
              <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Slug / Tautan URL
              </label>
              <input
                v-model="editForm.slug"
                type="text"
                class="w-full px-3 py-2 rounded-lg border border-slate-300 text-sm font-mono text-slate-700"
              />
            </div>
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
              Sub-Judul / Keterangan Singkat
            </label>
            <input
              v-model="editForm.subtitle"
              type="text"
              class="w-full px-3 py-2 rounded-lg border border-slate-300 text-xs sm:text-sm text-slate-700"
            />
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
              Ringkasan (Summary)
            </label>
            <textarea
              v-model="editForm.summary"
              rows="2"
              class="w-full p-2.5 rounded-lg border border-slate-300 text-xs text-slate-700"
            ></textarea>
          </div>

          <!-- Dukungan Kemitraan Pers Polri/TNI (jika halaman redaksi atau kode etik) -->
          <div v-if="editingPage.slug.includes('redaksi') || editingPage.slug.includes('kode-etik')">
            <label class="block text-xs font-bold text-[#D91E28] uppercase tracking-wider mb-1">
              Teks Dukungan Kemitraan Pers (Polri - TNI)
            </label>
            <textarea
              v-model="editForm.tni_polri_support"
              rows="3"
              class="w-full p-3 rounded-lg border border-slate-300 text-xs text-slate-800 leading-relaxed font-medium"
            ></textarea>
          </div>

          <!-- Komitmen Kode Etik -->
          <div v-if="editingPage.slug.includes('kode-etik')">
            <label class="block text-xs font-bold text-[#0B2563] uppercase tracking-wider mb-1">
              Teks Komitmen Publikasi Media Four Tribuan News / Mitra Polri-TNI
            </label>
            <textarea
              v-model="editForm.commitment_text"
              rows="3"
              class="w-full p-3 rounded-lg border border-slate-300 text-xs text-slate-800 leading-relaxed font-medium"
            ></textarea>
          </div>

          <!-- Landasan Moral (Redaksi) -->
          <div v-if="editingPage.slug.includes('redaksi')">
            <label class="block text-xs font-bold text-[#0B2563] uppercase tracking-wider mb-1">
              Isian Redaksi (Landasan Moral & Etika Pers — Pisahkan antar paragraf dengan enter 2x)
            </label>
            <textarea
              v-model="editForm.moral_foundation_text"
              rows="6"
              class="w-full p-3 rounded-lg border border-slate-300 text-xs text-slate-800 leading-relaxed"
            ></textarea>
          </div>

          <!-- Status Halaman -->
          <div>
            <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
              Status Halaman
            </label>
            <select
              v-model="editForm.status"
              class="px-3 py-2 rounded-lg border border-slate-300 text-xs bg-white"
            >
              <option value="published">Diterbitkan (Published)</option>
              <option value="draft">Draf (Draft)</option>
              <option value="trash">Tong Sampah (Trash)</option>
            </select>
          </div>
        </div>

        <!-- Modal Footer Actions -->
        <div class="p-4 bg-slate-50 border-t border-slate-200 flex items-center justify-end gap-2">
          <button
            type="button"
            @click="closeEdit"
            class="px-4 py-2 rounded-lg border border-slate-300 text-xs font-bold text-slate-700 hover:bg-slate-100 cursor-pointer"
          >
            Batal
          </button>
          <button
            type="button"
            @click="saveEdit"
            class="px-5 py-2 rounded-lg bg-[#2271b1] hover:bg-[#135e96] text-white text-xs font-bold inline-flex items-center gap-1.5 shadow-2xs cursor-pointer"
          >
            <Save class="w-4 h-4" />
            <span>Simpan Perubahan</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Create New Page Modal -->
    <div
      v-if="isCreating"
      class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6"
    >
      <div class="fixed inset-0 bg-slate-950/70 backdrop-blur-xs" @click="isCreating = false"></div>
      <div class="relative bg-white rounded-2xl border border-slate-300 w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col shadow-2xl z-10 text-xs">
        <div class="p-4 sm:p-5 bg-[#0B2563] text-white flex items-center justify-between">
          <h2 class="text-base font-bold text-white">Tambah Halaman Baru</h2>
          <button
            type="button"
            @click="isCreating = false"
            class="p-1.5 rounded-lg hover:bg-white/10 text-white cursor-pointer"
          >
            <X class="w-5 h-5" />
          </button>
        </div>

        <div class="p-5 sm:p-6 overflow-y-auto space-y-4 flex-1">
          <div>
            <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
              Judul Halaman *
            </label>
            <input
              v-model="createForm.title"
              @blur="autoSlug"
              type="text"
              placeholder="Contoh: Struktur Organisasi Redaksi"
              class="w-full px-3 py-2 rounded-lg border border-slate-300 text-sm font-bold text-slate-800"
            />
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
              Slug / Tautan URL *
            </label>
            <input
              v-model="createForm.slug"
              type="text"
              placeholder="struktur-organisasi"
              class="w-full px-3 py-2 rounded-lg border border-slate-300 text-xs font-mono text-slate-700"
            />
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
              Sub-Judul / Keterangan Singkat
            </label>
            <input
              v-model="createForm.subtitle"
              type="text"
              placeholder="Keterangan dokumen institusional"
              class="w-full px-3 py-2 rounded-lg border border-slate-300 text-xs text-slate-700"
            />
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
              Isi Dokumen / Teks Halaman
            </label>
            <textarea
              v-model="createForm.content"
              rows="6"
              placeholder="Ketik isi lengkap halaman di sini..."
              class="w-full p-3 rounded-lg border border-slate-300 text-xs text-slate-800 leading-relaxed"
            ></textarea>
          </div>
        </div>

        <div class="p-4 bg-slate-50 border-t border-slate-200 flex items-center justify-end gap-2">
          <button
            type="button"
            @click="isCreating = false"
            class="px-4 py-2 rounded-lg border border-slate-300 text-xs font-bold text-slate-700 hover:bg-slate-100 cursor-pointer"
          >
            Batal
          </button>
          <button
            type="button"
            @click="saveCreate"
            class="px-5 py-2 rounded-lg bg-[#2271b1] hover:bg-[#135e96] text-white text-xs font-bold inline-flex items-center gap-1.5 shadow-2xs cursor-pointer"
          >
            <Save class="w-4 h-4" />
            <span>Terbitkan Halaman</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
