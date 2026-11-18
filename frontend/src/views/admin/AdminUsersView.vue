<script setup>
import { ref, onMounted } from 'vue'
import { api } from '../../api/client'
import { showToast } from '../../composables/usePortal'
import { Plus, Pencil, Trash2 } from 'lucide-vue-next'

const users = ref([])
const editingId = ref(null)
const form = ref({ name: '', email: '', password: '', role: 'Reporter', status: 'active', bio: '' })

async function load() {
  const res = await api.get('/admin/users')
  users.value = res.data || []
}

function edit(u) {
  editingId.value = u.id
  form.value = { name: u.name, email: u.email, password: '', role: u.role, status: u.status, bio: u.bio }
}

function reset() {
  editingId.value = null
  form.value = { name: '', email: '', password: '', role: 'Reporter', status: 'active', bio: '' }
}

async function save() {
  try {
    if (editingId.value) {
      await api.put(`/admin/users/${editingId.value}`, form.value)
      showToast('Akun pengguna diperbarui!')
    } else {
      await api.post('/admin/users', form.value)
      showToast('Pengguna baru ditambahkan!')
    }
    reset()
    load()
  } catch (e) {
    showToast(e.message, 'error')
  }
}

async function remove(u) {
  if (!confirm(`Hapus akun ${u.name}?`)) return
  try {
    await api.del(`/admin/users/${u.id}`)
    showToast('Pengguna dihapus', 'info')
    load()
  } catch (e) {
    showToast(e.message, 'error')
  }
}

onMounted(load)
</script>

<template>
  <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
    <div class="lg:col-span-4 bg-white rounded-2xl border border-slate-200 p-5 h-fit shadow-2xs space-y-3">
      <h2 class="text-base font-black text-[#0B2563]">{{ editingId ? 'Edit Pengguna' : 'Tambah Wartawan / Admin' }}</h2>
      <form @submit.prevent="save" class="space-y-3">
        <input v-model="form.name" required placeholder="Nama Lengkap *" class="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm" />
        <input v-model="form.email" type="email" required placeholder="Email *" class="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm" />
        <input
          v-model="form.password"
          type="password"
          :required="!editingId"
          :placeholder="editingId ? 'Password baru (kosongkan jika tetap)' : 'Kata sandi (min 6 karakter) *'"
          class="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm"
        />
        <div class="grid grid-cols-2 gap-2">
          <select v-model="form.role" class="px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-xs font-bold">
            <option value="Administrator">Administrator</option>
            <option value="Editor">Editor</option>
            <option value="Reporter">Reporter</option>
          </select>
          <select v-model="form.status" class="px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-xs font-bold">
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>
        </div>
        <textarea v-model="form.bio" rows="2" placeholder="Bio singkat" class="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm"></textarea>
        <div class="flex gap-2">
          <button type="submit" class="flex-1 py-2.5 rounded-xl bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-extrabold inline-flex items-center justify-center gap-1">
            <Plus class="w-4 h-4" /> {{ editingId ? 'Simpan' : 'Tambah Akun' }}
          </button>
          <button v-if="editingId" type="button" @click="reset" class="px-4 py-2.5 rounded-xl bg-slate-100 text-xs font-bold">Batal</button>
        </div>
      </form>
    </div>

    <div class="lg:col-span-8 bg-white rounded-2xl border border-slate-200 p-5 shadow-2xs divide-y divide-slate-100">
      <div v-for="u in users" :key="u.id" class="py-3.5 flex items-center justify-between gap-3">
        <div>
          <div class="flex items-center gap-2">
            <span class="font-extrabold text-sm text-slate-900">{{ u.name }}</span>
            <span class="px-2 py-0.5 rounded bg-blue-50 text-[#0B2563] text-[10px] font-extrabold uppercase">{{ u.role }}</span>
            <span class="px-2 py-0.5 rounded-full text-[10px] font-bold" :class="u.status === 'active' ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-500'">{{ u.status }}</span>
          </div>
          <div class="text-xs text-slate-500 mt-0.5">{{ u.email }}</div>
        </div>
        <div class="flex gap-1.5">
          <button type="button" @click="edit(u)" class="p-2 rounded-lg bg-slate-100 hover:bg-[#0B2563] hover:text-white"><Pencil class="w-3.5 h-3.5" /></button>
          <button v-if="u.id !== 1" type="button" @click="remove(u)" class="p-2 rounded-lg bg-red-50 text-[#D91E28] hover:bg-[#D91E28] hover:text-white"><Trash2 class="w-3.5 h-3.5" /></button>
        </div>
      </div>
    </div>
  </div>
</template>
