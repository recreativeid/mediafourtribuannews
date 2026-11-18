<script setup>
import { ref, onMounted } from 'vue'
import { api } from '../../api/client'
import { showToast, bootstrapPortal } from '../../composables/usePortal'
import { Plus, Pencil, Trash2 } from 'lucide-vue-next'

const categories = ref([])
const editingId = ref(null)
const form = ref({ name: '', slug: '', description: '' })

async function load() {
  const res = await api.get('/admin/categories')
  categories.value = res.data || []
}

function edit(c) {
  editingId.value = c.id
  form.value = { name: c.name, slug: c.slug, description: c.description }
}

function reset() {
  editingId.value = null
  form.value = { name: '', slug: '', description: '' }
}

async function save() {
  try {
    if (editingId.value) {
      await api.put(`/admin/categories/${editingId.value}`, form.value)
      showToast('Kategori diperbarui!')
    } else {
      await api.post('/admin/categories', form.value)
      showToast('Kategori baru ditambahkan!')
    }
    reset()
    await load()
    bootstrapPortal(true)
  } catch (e) {
    showToast(e.message, 'error')
  }
}

async function remove(c) {
  if (!confirm(`Hapus kategori "${c.name}"?`)) return
  await api.del(`/admin/categories/${c.id}`)
  showToast('Kategori dihapus', 'info')
  await load()
  bootstrapPortal(true)
}

onMounted(load)
</script>

<template>
  <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
    <div class="lg:col-span-4 bg-white rounded-2xl border border-slate-200 p-5 h-fit shadow-2xs space-y-4">
      <h2 class="text-base font-black text-[#0B2563]">
        {{ editingId ? 'Edit Rubrik' : 'Tambah Rubrik Baru' }}
      </h2>
      <form @submit.prevent="save" class="space-y-3">
        <div>
          <label class="block text-xs font-bold text-slate-700 mb-1">Nama Kategori *</label>
          <input v-model="form.name" required class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm" placeholder="Contoh: Investigasi" />
        </div>
        <div>
          <label class="block text-xs font-bold text-slate-700 mb-1">Slug (otomatis jika kosong)</label>
          <input v-model="form.slug" class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm font-mono" placeholder="investigasi" />
        </div>
        <div>
          <label class="block text-xs font-bold text-slate-700 mb-1">Deskripsi</label>
          <textarea v-model="form.description" rows="3" class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm"></textarea>
        </div>
        <div class="flex gap-2">
          <button type="submit" class="flex-1 py-2.5 rounded-xl bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-extrabold inline-flex items-center justify-center gap-1.5 transition-colors">
            <Plus class="w-4 h-4" /> {{ editingId ? 'Simpan' : 'Tambah Rubrik' }}
          </button>
          <button v-if="editingId" type="button" @click="reset" class="px-4 py-2.5 rounded-xl bg-slate-100 text-xs font-bold">Batal</button>
        </div>
      </form>
    </div>

    <div class="lg:col-span-8 bg-white rounded-2xl border border-slate-200 p-5 shadow-2xs space-y-3">
      <h2 class="text-base font-black text-[#0B2563]">Daftar Rubrik ({{ categories.length }})</h2>
      <div class="divide-y divide-slate-100">
        <div v-for="c in categories" :key="c.id" class="py-3 flex items-center justify-between gap-3">
          <div class="min-w-0">
            <div class="flex items-center gap-2">
              <span class="font-extrabold text-sm text-slate-900">{{ c.name }}</span>
              <span class="text-[10px] font-mono px-2 py-0.5 rounded bg-slate-100 text-slate-500">/{{ c.slug }}</span>
              <span class="text-[10px] font-bold px-2 py-0.5 rounded bg-blue-50 text-[#0B2563]">{{ c.article_count || 0 }} berita</span>
            </div>
            <p class="text-xs text-slate-500 line-clamp-1 mt-0.5">{{ c.description }}</p>
          </div>
          <div class="flex items-center gap-1.5 shrink-0">
            <button type="button" @click="edit(c)" class="p-2 rounded-lg bg-slate-100 hover:bg-[#0B2563] hover:text-white"><Pencil class="w-3.5 h-3.5" /></button>
            <button type="button" @click="remove(c)" class="p-2 rounded-lg bg-red-50 text-[#D91E28] hover:bg-[#D91E28] hover:text-white"><Trash2 class="w-3.5 h-3.5" /></button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
