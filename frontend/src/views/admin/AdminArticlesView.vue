<script setup>
import { ref, onMounted, watch } from 'vue'
import { api, resolveImg, formatNumber, timeAgoID } from '../../api/client'
import { showToast } from '../../composables/usePortal'
import RichEditor from '../../components/RichEditor.vue'
import { Plus, Search, Pencil, Trash2, X, Upload, Star, ExternalLink } from 'lucide-vue-next'

const articles = ref([])
const categories = ref([])
const loading = ref(true)
const search = ref('')
const statusFilter = ref('all')
const categoryFilter = ref('all')

const modalOpen = ref(false)
const saving = ref(false)
const uploading = ref(false)
const editingId = ref(null)

const form = ref({
  title: '',
  category_id: 1,
  excerpt: '',
  content: '',
  thumbnail: '',
  caption: '',
  tags: '',
  status: 'published',
  is_featured: false,
})

async function loadData() {
  loading.value = true
  try {
    const params = new URLSearchParams({ limit: '50' })
    if (search.value.trim()) params.set('q', search.value.trim())
    if (statusFilter.value !== 'all') params.set('status', statusFilter.value)
    if (categoryFilter.value !== 'all') params.set('category', categoryFilter.value)

    const [artRes, catRes] = await Promise.all([
      api.get(`/admin/articles?${params.toString()}`),
      api.get('/admin/categories'),
    ])
    articles.value = artRes.data || []
    categories.value = catRes.data || []
  } finally {
    loading.value = false
  }
}

function openCreate() {
  editingId.value = null
  form.value = {
    title: '',
    category_id: categories.value[0]?.id || 1,
    excerpt: '',
    content: '<p class="lead"><strong>JAKARTA</strong> — Tulis paragraf pembuka berita di sini...</p>\n<p>Lanjutkan uraian berita secara lengkap, aktual, dan berimbang.</p>',
    thumbnail: '/uploads/berita/nasional/pembangunan-ikn-nusantara.jpg',
    caption: '',
    tags: 'Nasional, Media Four Tribuan News',
    status: 'published',
    is_featured: false,
  }
  modalOpen.value = true
}

function openEdit(art) {
  editingId.value = art.id
  form.value = {
    title: art.title,
    category_id: art.category_id,
    excerpt: art.excerpt,
    content: art.content,
    thumbnail: art.thumbnail,
    caption: art.caption,
    tags: art.tags,
    status: art.status,
    is_featured: Boolean(art.is_featured),
  }
  modalOpen.value = true
}

async function handleImageUpload(e) {
  const file = e.target.files?.[0]
  if (!file) return
  uploading.value = true
  try {
    const res = await api.upload(file)
    form.value.thumbnail = res.url
    showToast('Gambar berhasil diunggah!')
  } catch (err) {
    showToast(err.message || 'Gagal mengunggah gambar', 'error')
  } finally {
    uploading.value = false
  }
}

async function saveArticle() {
  saving.value = true
  try {
    const payload = {
      ...form.value,
      category_id: Number(form.value.category_id),
    }
    if (editingId.value) {
      await api.put(`/admin/articles/${editingId.value}`, payload)
      showToast('Berita berhasil diperbarui!')
    } else {
      await api.post('/admin/articles', payload)
      showToast('Berita baru berhasil diterbitkan!')
    }
    modalOpen.value = false
    loadData()
  } catch (err) {
    showToast(err.message || 'Gagal menyimpan berita', 'error')
  } finally {
    saving.value = false
  }
}

async function removeArticle(art) {
  if (!confirm(`Hapus berita "${art.title}"?`)) return
  try {
    await api.del(`/admin/articles/${art.id}`)
    showToast('Berita berhasil dihapus', 'info')
    loadData()
  } catch (err) {
    showToast(err.message, 'error')
  }
}

watch([statusFilter, categoryFilter], loadData)
onMounted(loadData)
</script>

<template>
  <div class="space-y-5">
    <!-- Header Bar -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
      <div>
        <h2 class="text-lg sm:text-xl font-black text-[#0B2563]">Manajemen Berita</h2>
        <p class="text-xs text-slate-500">Tambah, sunting, unggah foto, atau kelola status publikasi berita.</p>
      </div>
      <button
        type="button"
        @click="openCreate"
        class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-[#D91E28] hover:bg-red-700 text-white text-xs font-extrabold shadow-xs transition-colors"
      >
        <Plus class="w-4 h-4" /> Tambah Berita
      </button>
    </div>

    <!-- Filters -->
    <div class="bg-white rounded-2xl border border-slate-200 p-3.5 flex flex-col md:flex-row gap-3">
      <form @submit.prevent="loadData" class="relative flex-1">
        <Search class="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
        <input
          v-model="search"
          type="text"
          placeholder="Cari judul atau tag berita..."
          class="w-full pl-9 pr-4 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-xs sm:text-sm focus:bg-white focus:border-[#0B2563] focus:outline-none"
        />
      </form>
      <div class="flex gap-2">
        <select
          v-model="categoryFilter"
          class="px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-xs font-bold text-slate-700"
        >
          <option value="all">Semua Rubrik</option>
          <option v-for="c in categories" :key="c.id" :value="c.slug">{{ c.name }}</option>
        </select>
        <select
          v-model="statusFilter"
          class="px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-xs font-bold text-slate-700"
        >
          <option value="all">Semua Status</option>
          <option value="published">Published</option>
          <option value="draft">Draft</option>
          <option value="review">Review</option>
        </select>
      </div>
    </div>

    <!-- Responsive Cards / List -->
    <div v-if="loading" class="space-y-3">
      <div v-for="i in 4" :key="i" class="h-20 bg-white rounded-2xl animate-pulse border border-slate-200"></div>
    </div>

    <div v-else class="space-y-3">
      <div
        v-for="art in articles"
        :key="art.id"
        class="bg-white rounded-2xl border border-slate-200 p-3.5 flex flex-col sm:flex-row sm:items-center gap-3.5 shadow-2xs"
      >
        <img
          :src="resolveImg(art.thumbnail)"
          :alt="art.title"
          class="w-full sm:w-28 h-36 sm:h-20 rounded-xl object-cover bg-slate-100 shrink-0"
        />
        <div class="flex-1 min-w-0 space-y-1">
          <div class="flex flex-wrap items-center gap-1.5">
            <span class="px-2 py-0.5 rounded bg-blue-50 text-[#0B2563] text-[10px] font-extrabold uppercase">
              {{ art.category_name }}
            </span>
            <span
              class="px-2 py-0.5 rounded-full text-[10px] font-extrabold uppercase"
              :class="art.status === 'published' ? 'bg-emerald-50 text-emerald-700' : 'bg-amber-50 text-amber-700'"
            >
              {{ art.status }}
            </span>
            <span
              v-if="art.is_featured"
              class="inline-flex items-center gap-0.5 px-2 py-0.5 rounded-full bg-amber-100 text-amber-800 text-[10px] font-extrabold"
            >
              <Star class="w-3 h-3 fill-current" /> Headline
            </span>
          </div>
          <h3 class="text-sm font-extrabold text-slate-900 line-clamp-2">{{ art.title }}</h3>
          <div class="text-[11px] text-slate-500 flex flex-wrap gap-2">
            <span>{{ art.author_name }}</span>
            <span>&bull;</span>
            <span>{{ formatNumber(art.views) }} views</span>
            <span>&bull;</span>
            <span>{{ timeAgoID(art.published_at) }}</span>
          </div>
        </div>

        <div class="flex items-center gap-2 shrink-0 pt-2 sm:pt-0 border-t sm:border-t-0 border-slate-100">
          <router-link
            :to="`/berita/${art.slug}`"
            target="_blank"
            class="p-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-600"
            title="Pratinjau"
          >
            <ExternalLink class="w-4 h-4" />
          </router-link>
          <button
            type="button"
            @click="openEdit(art)"
            class="px-3 py-2 rounded-xl bg-[#0B2563] hover:bg-[#1648B8] text-white text-xs font-bold inline-flex items-center gap-1.5"
          >
            <Pencil class="w-3.5 h-3.5" /> Edit
          </button>
          <button
            type="button"
            @click="removeArticle(art)"
            class="p-2 rounded-xl bg-red-50 hover:bg-[#D91E28] text-[#D91E28] hover:text-white transition-colors"
            title="Hapus"
          >
            <Trash2 class="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>

    <!-- CREATE / EDIT MODAL -->
    <div v-if="modalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-2 sm:p-5">
      <div class="fixed inset-0 bg-slate-950/75 backdrop-blur-xs" @click="modalOpen = false"></div>
      <div class="relative bg-white rounded-3xl w-full max-w-4xl max-h-[94vh] flex flex-col overflow-hidden shadow-2xl z-10">
        <div class="px-6 py-4 bg-[#0B2563] text-white flex items-center justify-between">
          <h3 class="text-sm sm:text-base font-black">
            {{ editingId ? 'Sunting Berita' : 'Tulis Berita Baru' }}
          </h3>
          <button type="button" @click="modalOpen = false" class="p-1.5 rounded-lg hover:bg-white/10">
            <X class="w-5 h-5" />
          </button>
        </div>

        <form @submit.prevent="saveArticle" class="p-5 sm:p-6 overflow-y-auto space-y-4">
          <div>
            <label class="block text-xs font-extrabold text-slate-700 mb-1">Judul Berita *</label>
            <input
              v-model="form.title"
              type="text"
              required
              placeholder="Tulis judul berita yang kuat dan informatif..."
              class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:border-[#0B2563] text-sm font-semibold focus:outline-none"
            />
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label class="block text-xs font-extrabold text-slate-700 mb-1">Rubrik / Kategori</label>
              <select
                v-model="form.category_id"
                class="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-xs sm:text-sm font-semibold"
              >
                <option v-for="c in categories" :key="c.id" :value="c.id">{{ c.name }}</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-extrabold text-slate-700 mb-1">Status</label>
              <select
                v-model="form.status"
                class="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-xs sm:text-sm font-semibold"
              >
                <option value="published">Published (Tayang)</option>
                <option value="draft">Draft</option>
                <option value="review">Review Editor</option>
              </select>
            </div>
            <div class="flex items-end pb-2">
              <label class="inline-flex items-center gap-2 cursor-pointer text-xs font-extrabold text-[#0B2563]">
                <input v-model="form.is_featured" type="checkbox" class="w-4 h-4 accent-[#D91E28]" />
                <span>Tampilkan di Headline Hero</span>
              </label>
            </div>
          </div>

          <!-- Thumbnail Upload + Preview -->
          <div class="p-3.5 rounded-2xl bg-slate-50 border border-slate-200 space-y-2.5">
            <div class="flex items-center justify-between gap-2">
              <label class="text-xs font-extrabold text-slate-700">Foto Utama Berita</label>
              <label class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-bold cursor-pointer transition-colors">
                <Upload class="w-3.5 h-3.5" />
                <span>{{ uploading ? 'Mengunggah...' : 'Upload Foto' }}</span>
                <input type="file" accept="image/*" class="hidden" @change="handleImageUpload" />
              </label>
            </div>
            <div class="flex flex-col sm:flex-row gap-3 items-center">
              <img
                :src="resolveImg(form.thumbnail)"
                alt="Preview"
                class="w-full sm:w-32 h-24 rounded-xl object-cover border border-slate-200 bg-white shrink-0"
              />
              <div class="flex-1 w-full space-y-2">
                <input
                  v-model="form.thumbnail"
                  type="text"
                  placeholder="/uploads/berita/..."
                  class="w-full px-3 py-2 rounded-lg bg-white border border-slate-200 text-xs"
                />
                <input
                  v-model="form.caption"
                  type="text"
                  placeholder="Keterangan foto / kredit fotografer..."
                  class="w-full px-3 py-2 rounded-lg bg-white border border-slate-200 text-xs"
                />
              </div>
            </div>
          </div>

          <div>
            <label class="block text-xs font-extrabold text-slate-700 mb-1">Ringkasan (Excerpt)</label>
            <textarea
              v-model="form.excerpt"
              rows="2"
              placeholder="Ringkasan singkat berita (kosongkan untuk otomatis dari isi)..."
              class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-xs sm:text-sm focus:bg-white focus:border-[#0B2563] focus:outline-none"
            ></textarea>
          </div>

          <div>
            <div class="flex items-center justify-between mb-1.5">
              <label class="block text-xs font-extrabold text-slate-700">
                Isi Berita *
              </label>
              <span class="text-[11px] text-slate-400">
                Visual editor: sisipkan foto/video di tengah tulisan, perataan teks, link/backlink
              </span>
            </div>
            <RichEditor v-model="form.content" />
          </div>

          <div>
            <label class="block text-xs font-extrabold text-slate-700 mb-1">Tags (pisahkan dengan koma)</label>
            <input
              v-model="form.tags"
              type="text"
              placeholder="Nasional, Ekonomi, Kebijakan"
              class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-xs sm:text-sm"
            />
          </div>

          <div class="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
            <button
              type="button"
              @click="modalOpen = false"
              class="px-4 py-2.5 rounded-xl bg-slate-100 text-slate-700 text-xs font-bold"
            >
              Batal
            </button>
            <button
              type="submit"
              :disabled="saving"
              class="px-6 py-2.5 rounded-xl bg-[#D91E28] hover:bg-red-700 text-white text-xs font-extrabold shadow-xs disabled:opacity-50"
            >
              {{ saving ? 'Menyimpan...' : editingId ? 'Simpan Perubahan' : 'Terbitkan Berita' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>
