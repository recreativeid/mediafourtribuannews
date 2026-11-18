<script setup>
import { ref, onMounted } from 'vue'
import { api } from '../../api/client'
import { showToast } from '../../composables/usePortal'
import { Plus, Pencil, Trash2 } from 'lucide-vue-next'

const members = ref([])
const editingId = ref(null)
const form = ref({
  name: '',
  position: '',
  division: 'Redaktur',
  description: '',
  email: '',
  phone: '',
  sort_order: 1,
  status: 'active',
})

async function load() {
  const res = await api.get('/admin/redaksi')
  members.value = res.data || []
}

function edit(m) {
  editingId.value = m.id
  form.value = { ...m }
}

function reset() {
  editingId.value = null
  form.value = { name: '', position: '', division: 'Redaktur', description: '', email: '', phone: '', sort_order: members.value.length + 1, status: 'active' }
}

async function save() {
  const payload = { ...form.value, sort_order: Number(form.value.sort_order) }
  if (editingId.value) {
    await api.put(`/admin/redaksi/${editingId.value}`, payload)
    showToast('Data redaksi diperbarui!')
  } else {
    await api.post('/admin/redaksi', payload)
    showToast('Anggota redaksi ditambahkan!')
  }
  reset()
  load()
}

async function remove(m) {
  if (!confirm(`Hapus ${m.name} dari susunan redaksi?`)) return
  await api.del(`/admin/redaksi/${m.id}`)
  showToast('Data dihapus', 'info')
  load()
}

onMounted(load)
</script>

<template>
  <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
    <div class="lg:col-span-4 bg-white rounded-2xl border border-slate-200 p-5 h-fit shadow-2xs space-y-3">
      <h2 class="text-base font-black text-[#0B2563]">{{ editingId ? 'Edit Anggota Redaksi' : 'Tambah Anggota Redaksi' }}</h2>
      <form @submit.prevent="save" class="space-y-3">
        <input v-model="form.name" required placeholder="Nama Lengkap *" class="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm" />
        <input v-model="form.position" required placeholder="Jabatan (misal: Pemimpin Redaksi) *" class="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm" />
        <input v-model="form.division" placeholder="Divisi (Pimpinan, Redaktur, IT)" class="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm" />
        <input v-model="form.email" placeholder="Email" class="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm" />
        <input v-model="form.phone" placeholder="Telepon / WA" class="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm" />
        <input v-model="form.description" placeholder="Keterangan singkat" class="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm" />
        <input v-model.number="form.sort_order" type="number" placeholder="Urutan tampil" class="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm" />
        <div class="flex gap-2">
          <button type="submit" class="flex-1 py-2.5 rounded-xl bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-extrabold inline-flex items-center justify-center gap-1">
            <Plus class="w-4 h-4" /> {{ editingId ? 'Simpan' : 'Tambah' }}
          </button>
          <button v-if="editingId" type="button" @click="reset" class="px-4 py-2.5 rounded-xl bg-slate-100 text-xs font-bold">Batal</button>
        </div>
      </form>
    </div>

    <div class="lg:col-span-8 bg-white rounded-2xl border border-slate-200 p-5 shadow-2xs divide-y divide-slate-100">
      <div v-for="m in members" :key="m.id" class="py-3 flex items-center justify-between gap-3">
        <div>
          <span class="text-[10px] font-extrabold uppercase text-[#D91E28]">{{ m.division }} &bull; #{{ m.sort_order }}</span>
          <h3 class="text-sm font-extrabold text-slate-900">{{ m.name }}</h3>
          <p class="text-xs font-semibold text-[#0B2563]">{{ m.position }}</p>
          <p class="text-[11px] text-slate-500">{{ m.email }} {{ m.phone ? '• ' + m.phone : '' }}</p>
        </div>
        <div class="flex gap-1.5">
          <button type="button" @click="edit(m)" class="p-2 rounded-lg bg-slate-100 hover:bg-[#0B2563] hover:text-white"><Pencil class="w-3.5 h-3.5" /></button>
          <button type="button" @click="remove(m)" class="p-2 rounded-lg bg-red-50 text-[#D91E28] hover:bg-[#D91E28] hover:text-white"><Trash2 class="w-3.5 h-3.5" /></button>
        </div>
      </div>
    </div>
  </div>
</template>
