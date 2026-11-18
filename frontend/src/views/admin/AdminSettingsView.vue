<script setup>
import { ref, onMounted } from 'vue'
import { api } from '../../api/client'
import { bootstrapPortal, showToast } from '../../composables/usePortal'
import { Save } from 'lucide-vue-next'

const saving = ref(false)
const form = ref({
  site_title: '',
  site_subtitle: '',
  site_tagline: '',
  site_description: '',
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

onMounted(async () => {
  const res = await api.get('/settings')
  if (res.data) {
    Object.assign(form.value, res.data)
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
</script>

<template>
  <div class="max-w-3xl bg-white rounded-2xl border border-slate-200 p-5 sm:p-7 shadow-2xs space-y-5">
    <div>
      <h2 class="text-lg font-black text-[#0B2563]">Pengaturan Portal Berita</h2>
      <p class="text-xs text-slate-500">Identitas media, kontak redaksi, dan alamat kantor yang tampil di seluruh halaman publik.</p>
    </div>

    <form @submit.prevent="save" class="space-y-4">
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label class="block text-xs font-extrabold text-slate-700 mb-1">Nama Media</label>
          <input v-model="form.site_title" class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm" />
        </div>
        <div>
          <label class="block text-xs font-extrabold text-slate-700 mb-1">Tagline</label>
          <input v-model="form.site_tagline" class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm" />
        </div>
        <div>
          <label class="block text-xs font-extrabold text-slate-700 mb-1">Nama Perusahaan Penerbit</label>
          <input v-model="form.company_name" class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm" />
        </div>
        <div>
          <label class="block text-xs font-extrabold text-slate-700 mb-1">Email Redaksi</label>
          <input v-model="form.redaksi_email" class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm" />
        </div>
        <div>
          <label class="block text-xs font-extrabold text-slate-700 mb-1">Hotline Telepon</label>
          <input v-model="form.hotline_phone" class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm" />
        </div>
        <div>
          <label class="block text-xs font-extrabold text-slate-700 mb-1">Nomor WhatsApp (62...)</label>
          <input v-model="form.whatsapp_number" class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm" />
        </div>
      </div>

      <div>
        <label class="block text-xs font-extrabold text-slate-700 mb-1">Deskripsi Portal (SEO)</label>
        <textarea v-model="form.site_description" rows="2" class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm"></textarea>
      </div>

      <div>
        <label class="block text-xs font-extrabold text-slate-700 mb-1">Alamat Kantor Redaksi</label>
        <textarea v-model="form.office_address" rows="2" class="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm"></textarea>
      </div>

      <div class="flex justify-end pt-2">
        <button
          type="submit"
          :disabled="saving"
          class="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-extrabold transition-colors disabled:opacity-50"
        >
          <Save class="w-4 h-4" /> {{ saving ? 'Menyimpan...' : 'Simpan Pengaturan' }}
        </button>
      </div>
    </form>
  </div>
</template>
