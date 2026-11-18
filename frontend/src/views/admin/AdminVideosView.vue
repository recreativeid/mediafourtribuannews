<script setup>
import { ref, onMounted } from 'vue'
import { api } from '../../api/client'
import { showToast } from '../../composables/usePortal'
import { Plus, Trash2, Pencil, Play } from 'lucide-vue-next'

const videos = ref([])
const editingId = ref(null)
const form = ref({ title: '', youtube_url: '', caption: '', is_active: true })

async function load() {
  const res = await api.get('/admin/videos')
  videos.value = res.data || []
}

function edit(v) {
  editingId.value = v.id
  form.value = { title: v.title, youtube_url: v.youtube_url, caption: v.caption, is_active: v.is_active }
}

function reset() {
  editingId.value = null
  form.value = { title: '', youtube_url: '', caption: '', is_active: true }
}

async function save() {
  try {
    if (editingId.value) {
      await api.put(`/admin/videos/${editingId.value}`, form.value)
      showToast('Video diperbarui!')
    } else {
      await api.post('/admin/videos', form.value)
      showToast('Video berhasil ditambahkan!')
    }
    reset()
    load()
  } catch (e) {
    showToast(e.message, 'error')
  }
}

async function remove(v) {
  if (!confirm(`Hapus video "${v.title}"?`)) return
  await api.del(`/admin/videos/${v.id}`)
  showToast('Video dihapus', 'info')
  load()
}

onMounted(load)
</script>

<template>
  <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
    <div class="lg:col-span-4 bg-white rounded-2xl border border-slate-200 p-5 h-fit shadow-2xs space-y-4">
      <h2 class="text-base font-black text-[#0B2563]">{{ editingId ? 'Edit Berita Video' : 'Tambah Berita Video' }}</h2>
      <form @submit.prevent="save" class="space-y-3">
        <div>
          <label class="block text-xs font-bold text-slate-700 mb-1">Judul Video *</label>
          <input v-model="form.title" required class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm" />
        </div>
        <div>
          <label class="block text-xs font-bold text-slate-700 mb-1">URL YouTube *</label>
          <input v-model="form.youtube_url" required placeholder="https://www.youtube.com/watch?v=..." class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm" />
        </div>
        <div>
          <label class="block text-xs font-bold text-slate-700 mb-1">Deskripsi / Keterangan</label>
          <textarea v-model="form.caption" rows="3" class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm"></textarea>
        </div>
        <label class="flex items-center gap-2 text-xs font-bold text-slate-700">
          <input v-model="form.is_active" type="checkbox" class="accent-[#D91E28]" /> Aktif tampil di beranda
        </label>
        <div class="flex gap-2">
          <button type="submit" class="flex-1 py-2.5 rounded-xl bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-extrabold inline-flex items-center justify-center gap-1.5">
            <Plus class="w-4 h-4" /> {{ editingId ? 'Simpan' : 'Tambah Video' }}
          </button>
          <button v-if="editingId" type="button" @click="reset" class="px-4 py-2.5 rounded-xl bg-slate-100 text-xs font-bold">Batal</button>
        </div>
      </form>
    </div>

    <div class="lg:col-span-8 grid grid-cols-1 sm:grid-cols-2 gap-4">
      <div v-for="v in videos" :key="v.id" class="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-2xs flex flex-col">
        <div class="relative aspect-video bg-black">
          <img :src="`https://img.youtube.com/vi/${v.youtube_id}/hqdefault.jpg`" :alt="v.title" class="w-full h-full object-cover opacity-90" />
          <span class="absolute top-2 left-2 px-2 py-0.5 rounded bg-black/70 text-white text-[10px] font-bold inline-flex items-center gap-1">
            <Play class="w-3 h-3 fill-current text-[#D91E28]" /> {{ v.youtube_id }}
          </span>
        </div>
        <div class="p-4 flex-1 flex flex-col justify-between gap-3">
          <div>
            <h3 class="text-sm font-extrabold text-slate-900 line-clamp-2">{{ v.title }}</h3>
            <p class="text-xs text-slate-500 line-clamp-2 mt-1">{{ v.caption }}</p>
          </div>
          <div class="flex items-center justify-between pt-2 border-t border-slate-100">
            <span class="text-[10px] font-extrabold uppercase px-2 py-0.5 rounded-full" :class="v.is_active ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-500'">
              {{ v.is_active ? 'Aktif' : 'Nonaktif' }}
            </span>
            <div class="flex gap-1.5">
              <button type="button" @click="edit(v)" class="p-1.5 rounded-lg bg-slate-100 hover:bg-[#0B2563] hover:text-white"><Pencil class="w-3.5 h-3.5" /></button>
              <button type="button" @click="remove(v)" class="p-1.5 rounded-lg bg-red-50 text-[#D91E28] hover:bg-[#D91E28] hover:text-white"><Trash2 class="w-3.5 h-3.5" /></button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
