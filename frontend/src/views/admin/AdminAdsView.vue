<script setup>
import { ref, onMounted } from 'vue'
import { api, resolveImg } from '../../api/client'
import { showToast, refreshAds } from '../../composables/usePortal'
import { Plus, Pencil, Trash2, Upload, Megaphone, Info, RefreshCw } from 'lucide-vue-next'

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

const positionOptions = [
  { value: 'top_header', label: 'Header Atas (Leaderboard)', desc: 'Tampil di atas portal / bawah navbar' },
  { value: 'home_middle', label: 'Beranda Tengah', desc: 'Di antara blok berita utama beranda' },
  { value: 'home_bottom', label: 'Beranda Bawah', desc: 'Di atas footer beranda' },
  { value: 'sidebar', label: 'Sidebar Kanan (Beranda & Artikel)', desc: 'Kolom samping kanan artikel & beranda' },
  { value: 'sidebar_left', label: 'Floating Sisi Kiri (Desktop Skin)', desc: 'Melayang di tepi kiri luar layar desktop' },
  { value: 'sidebar_right', label: 'Floating Sisi Kanan (Desktop Skin)', desc: 'Melayang di tepi kanan luar layar desktop' },
  { value: 'article_top', label: 'Atas Berita (Di Bawah Judul)', desc: 'Tepat di bawah judul berita sebelum artikel' },
  { value: 'article_middle', label: 'Tengah Konten Berita', desc: 'Di sela-sela paragraf dalam artikel berita' },
  { value: 'article_bottom', label: 'Bawah Berita (Sebelum Komentar)', desc: 'Di bawah isi berita sebelum kolom komentar' },
  { value: 'sticky_bottom', label: 'Banner Melayang Bawah (Sticky Footer)', desc: 'Melayang di bawah layar dengan tombol tutup' },
]

function posLabel(pos) {
  const match = positionOptions.find((p) => p.value === pos)
  return match ? match.label : pos
}

async function load() {
  const res = await api.get('/admin/ads')
  ads.value = res.data || []
}

function edit(a) {
  editingId.value = a.id
  form.value = { ...a }
  window.scrollTo({ top: 0, behavior: 'smooth' })
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
  try {
    const res = await api.upload(f)
    form.value.image = res.url
    showToast('Banner berhasil diunggah')
  } catch (err) {
    showToast(err.message || 'Gagal mengunggah banner', 'error')
  }
}

async function save() {
  try {
    if (editingId.value) {
      await api.put(`/admin/ads/${editingId.value}`, form.value)
      showToast('Slot iklan diperbarui!')
    } else {
      await api.post('/admin/ads', form.value)
      showToast('Slot iklan ditambahkan!')
    }
    reset()
    await load()
    refreshAds()
  } catch (err) {
    showToast(err.message || 'Gagal menyimpan iklan', 'error')
  }
}

async function remove(a) {
  if (!confirm(`Hapus iklan "${a.title}"?`)) return
  try {
    await api.del(`/admin/ads/${a.id}`)
    showToast('Iklan dihapus', 'info')
    await load()
    refreshAds()
  } catch (err) {
    showToast(err.message || 'Gagal menghapus iklan', 'error')
  }
}

onMounted(load)
</script>

<template>
  <div class="space-y-4">
    <!-- Info Banner: Multi-Side & Auto-Rotate -->
    <div class="bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200/80 rounded-2xl p-4 flex items-start gap-3 shadow-2xs">
      <div class="w-8 h-8 rounded-xl bg-[#0B2563] text-white flex items-center justify-center shrink-0 mt-0.5">
        <RefreshCw class="w-4 h-4" />
      </div>
      <div class="text-xs space-y-1">
        <h3 class="font-extrabold text-[#0B2563] text-sm">Fitur Iklan Multi-Posisi & Rotasi Bergantian Otomatis</h3>
        <p class="text-slate-600 leading-relaxed">
          Anda dapat menempatkan iklan dan banner di <strong>berbagai sisi yang berbeda</strong> (Header Atas, Beranda Tengah/Bawah, Sidebar Kanan, Floating Sisi Kiri & Kanan Desktop, Dalam Artikel, hingga Sticky Bawah).
          Jika Anda menambahkan <strong>lebih dari satu iklan pada posisi yang sama</strong>, sistem secara otomatis akan <strong>menampilkannya secara bergantian (rotasi carousel tiap 5 detik)</strong> lengkap dengan tombol geser dan indikator navigasi sehingga semua pengiklan tampil adil.
        </p>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
      <!-- FORM TAMBAH / EDIT IKLAN -->
      <div class="lg:col-span-5 bg-white rounded-2xl border border-slate-200 p-5 h-fit shadow-2xs space-y-4">
        <h2 class="text-base font-black text-[#0B2563] flex items-center gap-2">
          <Megaphone class="w-4 h-4 text-[#D91E28]" />
          {{ editingId ? 'Edit Iklan / Banner' : 'Tambah Slot Iklan / Sponsor' }}
        </h2>

        <form @submit.prevent="save" class="space-y-3">
          <div>
            <label class="block text-xs font-bold text-slate-700 mb-1">Judul Iklan / Sponsor *</label>
            <input
              v-model="form.title"
              required
              placeholder="Contoh: Kemitraan Liputan Resmi Instansi..."
              class="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm focus:bg-white focus:border-[#0B2563] transition-colors"
            />
          </div>

          <div class="grid grid-cols-2 gap-2.5">
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">Tipe Iklan</label>
              <select
                v-model="form.type"
                class="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-xs font-bold"
              >
                <option value="banner">Banner Gambar</option>
                <option value="html">HTML / AdSense</option>
              </select>
            </div>

            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">Posisi / Sisi *</label>
              <select
                v-model="form.position"
                class="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-xs font-bold text-[#0B2563]"
              >
                <option v-for="pos in positionOptions" :key="pos.value" :value="pos.value">
                  {{ pos.label }}
                </option>
              </select>
            </div>
          </div>

          <div v-if="form.type === 'banner'" class="space-y-2">
            <div class="flex items-center justify-between">
              <label class="text-xs font-bold text-slate-700">Gambar Banner</label>
              <label class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-[#0B2563] text-white text-[11px] font-bold cursor-pointer hover:bg-[#D91E28] transition-colors">
                <Upload class="w-3 h-3" /> Upload
                <input type="file" accept="image/*" class="hidden" @change="uploadImg" />
              </label>
            </div>
            <input
              v-model="form.image"
              placeholder="/uploads/... atau URL https://..."
              class="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 text-xs font-mono"
            />
            <input
              v-model="form.target_url"
              placeholder="Link tujuan klik (https://... atau /tentang#kontak)"
              class="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 text-xs"
            />
          </div>

          <div v-else>
            <label class="block text-xs font-bold text-slate-700 mb-1">Kode HTML / Script AdSense</label>
            <textarea
              v-model="form.html_code"
              rows="4"
              placeholder="<script ...> atau <ins class='adsbygoogle' ...>"
              class="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 text-xs font-mono"
            ></textarea>
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 mb-1">Keterangan / Tagline Sponsor</label>
            <input
              v-model="form.description"
              placeholder="Contoh: Mitra Terpercaya UMKM Nusantara..."
              class="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 text-xs"
            />
          </div>

          <label class="flex items-center gap-2 text-xs font-bold text-slate-700 cursor-pointer pt-1">
            <input v-model="form.is_active" type="checkbox" class="w-4 h-4 accent-[#D91E28] rounded" />
            <span>Aktifkan Penayangan Iklan Ini</span>
          </label>

          <div class="flex gap-2 pt-2">
            <button
              type="submit"
              class="flex-1 py-2.5 rounded-xl bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-extrabold inline-flex items-center justify-center gap-1.5 transition-colors shadow-2xs"
            >
              <Plus class="w-4 h-4" /> {{ editingId ? 'Simpan Perubahan' : 'Tambah Iklan' }}
            </button>
            <button
              v-if="editingId"
              type="button"
              @click="reset"
              class="px-4 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-xs font-bold transition-colors"
            >
              Batal
            </button>
          </div>
        </form>
      </div>

      <!-- DAFTAR SEMUA IKLAN -->
      <div class="lg:col-span-7 space-y-3">
        <div class="flex items-center justify-between pb-1">
          <h3 class="text-sm font-extrabold text-slate-800">
            Daftar Iklan Terpasang ({{ ads.length }})
          </h3>
          <span class="text-[11px] text-slate-400">Posisi sama akan dirotasi bergantian</span>
        </div>

        <div
          v-for="a in ads"
          :key="a.id"
          class="bg-white rounded-2xl border border-slate-200 p-4 flex gap-3.5 items-center shadow-2xs transition-all hover:border-blue-200"
        >
          <img
            v-if="a.image"
            :src="resolveImg(a.image)"
            :alt="a.title"
            class="w-24 h-16 rounded-xl object-cover shrink-0 bg-slate-100 border border-slate-100"
          />
          <div
            v-else
            class="w-24 h-16 rounded-xl bg-slate-100 flex items-center justify-center text-[10px] text-slate-400 font-mono shrink-0"
          >
            HTML / Script
          </div>

          <div class="flex-1 min-w-0 space-y-1">
            <div class="flex items-center gap-1.5 flex-wrap">
              <span class="px-2 py-0.5 rounded bg-blue-50 border border-blue-200/60 text-[#0B2563] text-[10px] font-extrabold">
                {{ posLabel(a.position) }}
              </span>
              <span
                class="px-2 py-0.5 rounded text-[10px] font-extrabold uppercase"
                :class="a.is_active ? 'bg-emerald-50 text-emerald-700 border border-emerald-200/60' : 'bg-slate-100 text-slate-500'"
              >
                {{ a.is_active ? 'Aktif' : 'Nonaktif' }}
              </span>
              <span v-if="a.type === 'html'" class="px-1.5 py-0.5 rounded bg-amber-50 text-amber-700 text-[9px] font-bold">
                Script AdSense
              </span>
            </div>
            <h4 class="text-sm font-extrabold text-slate-900 truncate">{{ a.title }}</h4>
            <p v-if="a.description" class="text-xs text-slate-500 truncate">{{ a.description }}</p>
            <p v-if="a.target_url" class="text-[11px] text-blue-600 truncate font-mono">{{ a.target_url }}</p>
          </div>

          <div class="flex gap-1.5 shrink-0">
            <button
              type="button"
              @click="edit(a)"
              class="p-2 rounded-lg bg-slate-100 hover:bg-[#0B2563] hover:text-white transition-colors"
              title="Edit Iklan"
            >
              <Pencil class="w-3.5 h-3.5" />
            </button>
            <button
              type="button"
              @click="remove(a)"
              class="p-2 rounded-lg bg-red-50 text-[#D91E28] hover:bg-[#D91E28] hover:text-white transition-colors"
              title="Hapus Iklan"
            >
              <Trash2 class="w-3.5 h-3.5" />
            </button>
          </div>
        </div>

        <div v-if="!ads.length" class="bg-white rounded-2xl border border-slate-200 p-8 text-center text-xs text-slate-500">
          Belum ada iklan atau banner yang ditambahkan.
        </div>
      </div>
    </div>
  </div>
</template>
