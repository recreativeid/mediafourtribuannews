<script setup>
import { ref, onMounted } from 'vue'
import { api, resolveImg } from '../../api/client'
import { showToast } from '../../composables/usePortal'
import { Plus, Pencil, Trash2, Upload } from 'lucide-vue-next'

const ads = ref([])
const editingId = ref(null)
const form = ref({
  title: '',
  type: 'banner',
  position: 'home_middle',
  target_device: 'all',
  target_page: 'all',
  html_code: '',
  image: '/uploads/berita/ekonomi/panen-kopi-gayo-organik.jpg',
  target_url: '',
  description: '',
  is_active: true,
  sort_order: 1,
})

async function load() {
  const res = await api.get('/admin/ads')
  ads.value = res.data || []
}

function edit(a) {
  editingId.value = a.id
  form.value = { ...a }
}

function reset() {
  editingId.value = null
  form.value = {
    title: '',
    type: 'banner',
    position: 'home_middle',
    target_device: 'all',
    target_page: 'all',
    html_code: '',
    image: '/uploads/berita/ekonomi/panen-kopi-gayo-organik.jpg',
    target_url: '',
    description: '',
    is_active: true,
    sort_order: 1,
  }
}

async function uploadImg(e) {
  const f = e.target.files?.[0]
  if (!f) return
  const res = await api.upload(f)
  form.value.image = res.url
  showToast('Banner berhasil diunggah')
}

async function save() {
  if (editingId.value) {
    await api.put(`/admin/ads/${editingId.value}`, form.value)
    showToast('Slot iklan diperbarui!')
  } else {
    await api.post('/admin/ads', form.value)
    showToast('Slot iklan ditambahkan!')
  }
  reset()
  load()
}

async function remove(a) {
  if (!confirm(`Hapus iklan "${a.title}"?`)) return
  await api.del(`/admin/ads/${a.id}`)
  showToast('Iklan dihapus', 'info')
  load()
}

onMounted(load)
</script>

<template>
  <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
    <div class="lg:col-span-5 bg-white rounded-2xl border border-slate-200 p-5 h-fit shadow-2xs space-y-4">
      <h2 class="text-base font-black text-[#0B2563]">{{ editingId ? 'Edit Iklan' : 'Tambah Slot Iklan / Sponsor' }}</h2>
      <form @submit.prevent="save" class="space-y-3">
        <div>
          <label class="block text-xs font-bold text-slate-700 mb-1">Judul Iklan / Sponsor *</label>
          <input v-model="form.title" required class="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm" />
        </div>
        <div class="grid grid-cols-2 gap-2.5">
          <div>
            <label class="block text-xs font-bold text-slate-700 mb-1">Tipe</label>
            <select v-model="form.type" class="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-xs font-bold">
              <option value="banner">Banner Gambar</option>
              <option value="html">HTML / AdSense</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-bold text-slate-700 mb-1">Posisi</label>
            <select v-model="form.position" class="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-xs font-bold">
              <option value="home_middle">Beranda Tengah</option>
              <option value="sidebar">Sidebar Artikel</option>
              <option value="article_middle">Tengah Artikel</option>
              <option value="footer">Footer</option>
            </select>
          </div>
        </div>
        <div v-if="form.type === 'banner'" class="space-y-2">
          <div class="flex items-center justify-between">
            <label class="text-xs font-bold text-slate-700">Gambar Banner</label>
            <label class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-[#0B2563] text-white text-[11px] font-bold cursor-pointer">
              <Upload class="w-3 h-3" /> Upload
              <input type="file" accept="image/*" class="hidden" @change="uploadImg" />
            </label>
          </div>
          <input v-model="form.image" class="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 text-xs" />
          <input v-model="form.target_url" placeholder="Link tujuan (https://...)" class="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 text-xs" />
        </div>
        <div v-else>
          <label class="block text-xs font-bold text-slate-700 mb-1">Kode HTML / AdSense</label>
          <textarea v-model="form.html_code" rows="4" class="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 text-xs font-mono"></textarea>
        </div>
        <div>
          <label class="block text-xs font-bold text-slate-700 mb-1">Keterangan</label>
          <input v-model="form.description" class="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 text-xs" />
        </div>
        <label class="flex items-center gap-2 text-xs font-bold text-slate-700">
          <input v-model="form.is_active" type="checkbox" class="accent-[#D91E28]" /> Aktif
        </label>
        <div class="flex gap-2">
          <button type="submit" class="flex-1 py-2.5 rounded-xl bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-extrabold inline-flex items-center justify-center gap-1.5">
            <Plus class="w-4 h-4" /> {{ editingId ? 'Simpan' : 'Tambah Iklan' }}
          </button>
          <button v-if="editingId" type="button" @click="reset" class="px-4 py-2.5 rounded-xl bg-slate-100 text-xs font-bold">Batal</button>
        </div>
      </form>
    </div>

    <div class="lg:col-span-7 space-y-3">
      <div v-for="a in ads" :key="a.id" class="bg-white rounded-2xl border border-slate-200 p-4 flex gap-3.5 items-center shadow-2xs">
        <img v-if="a.image" :src="resolveImg(a.image)" :alt="a.title" class="w-24 h-16 rounded-xl object-cover shrink-0 bg-slate-100" />
        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-1.5 mb-0.5">
            <span class="px-2 py-0.5 rounded bg-blue-50 text-[#0B2563] text-[10px] font-extrabold uppercase">{{ a.position }}</span>
            <span class="px-2 py-0.5 rounded text-[10px] font-extrabold uppercase" :class="a.is_active ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-500'">
              {{ a.is_active ? 'Aktif' : 'Nonaktif' }}
            </span>
          </div>
          <h3 class="text-sm font-extrabold text-slate-900 truncate">{{ a.title }}</h3>
          <p class="text-xs text-slate-500 truncate">{{ a.description }}</p>
        </div>
        <div class="flex gap-1.5 shrink-0">
          <button type="button" @click="edit(a)" class="p-2 rounded-lg bg-slate-100 hover:bg-[#0B2563] hover:text-white"><Pencil class="w-3.5 h-3.5" /></button>
          <button type="button" @click="remove(a)" class="p-2 rounded-lg bg-red-50 text-[#D91E28] hover:bg-[#D91E28] hover:text-white"><Trash2 class="w-3.5 h-3.5" /></button>
        </div>
      </div>
    </div>
  </div>
</template>
