<script setup>
import { ref, onMounted, watch } from 'vue'
import { api, timeAgoID } from '../../api/client'
import { showToast } from '../../composables/usePortal'
import { Check, XCircle, Trash2, Newspaper, ExternalLink, ArrowUpRight, MessageSquare } from 'lucide-vue-next'

const comments = ref([])
const statusFilter = ref('all')

async function load() {
  const q = statusFilter.value === 'all' ? '' : `?status=${statusFilter.value}`
  const res = await api.get(`/admin/comments${q}`)
  const raw = res.data || []
  if (statusFilter.value === 'all') {
    comments.value = raw
  } else {
    comments.value = raw.filter((c) => c.status === statusFilter.value)
  }
}

async function setStatus(cm, status) {
  try {
    await api.put(`/admin/comments/${cm.id}/status`, { status })
    showToast(`Status komentar diubah menjadi ${status}`)
    load()
  } catch (err) {
    showToast(err.message || 'Gagal memperbarui status komentar', 'error')
  }
}

async function remove(cm) {
  if (!confirm('Hapus komentar ini?')) return
  try {
    await api.del(`/admin/comments/${cm.id}`)
    showToast('Komentar dihapus', 'info')
    load()
  } catch (err) {
    showToast(err.message || 'Gagal menghapus komentar', 'error')
  }
}

watch(statusFilter, load)
onMounted(load)
</script>

<template>
  <div class="space-y-4">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
      <div>
        <h2 class="text-lg font-black text-[#0B2563] flex items-center gap-2">
          <MessageSquare class="w-5 h-5 text-[#D91E28]" />
          Moderasi Komentar Pembaca
        </h2>
        <p class="text-xs text-slate-500">
          Setujui, tolak, atau hapus komentar serta pantau postingan berita mana yang dikomentari pembaca.
        </p>
      </div>
      <div class="flex gap-1.5 flex-wrap">
        <button
          v-for="s in ['all', 'pending', 'approved', 'rejected']"
          :key="s"
          type="button"
          @click="statusFilter = s"
          class="px-3 py-1.5 rounded-xl text-xs font-bold uppercase transition-colors"
          :class="statusFilter === s ? 'bg-[#0B2563] text-white shadow-xs' : 'bg-white border border-slate-200 text-slate-600 hover:border-slate-300'"
        >
          {{ s }}
        </button>
      </div>
    </div>

    <div class="space-y-3">
      <div
        v-for="cm in comments"
        :key="cm.id"
        class="bg-white rounded-2xl border border-slate-200/90 p-4 shadow-2xs space-y-3 transition-all hover:border-blue-200"
      >
        <!-- Header Komentar: Nama, Email, Waktu & Status -->
        <div class="flex flex-wrap items-center justify-between gap-2">
          <div class="flex items-center gap-2.5">
            <div class="w-8 h-8 rounded-full bg-slate-100 border border-slate-200 text-[#0B2563] font-black text-xs flex items-center justify-center shrink-0">
              {{ (cm.name || 'P').slice(0, 2).toUpperCase() }}
            </div>
            <div>
              <div class="flex items-center gap-2">
                <span class="font-extrabold text-sm text-slate-900">{{ cm.name || 'Pembaca' }}</span>
                <span class="text-[11px] text-slate-400 font-mono">{{ cm.email }}</span>
              </div>
              <div class="text-[11px] text-slate-400">
                {{ timeAgoID(cm.created_at) }}
              </div>
            </div>
          </div>

          <span
            class="px-2.5 py-1 rounded-full text-[10px] font-extrabold uppercase tracking-wide"
            :class="{
              'bg-emerald-50 text-emerald-700 border border-emerald-200/60': cm.status === 'approved',
              'bg-amber-50 text-amber-700 border border-amber-200/60': cm.status === 'pending',
              'bg-red-50 text-red-700 border border-red-200/60': cm.status === 'rejected' || cm.status === 'spam',
            }"
          >
            {{ cm.status }}
          </span>
        </div>

        <!-- Isi Komentar -->
        <div class="bg-slate-50/80 border border-slate-100 rounded-xl p-3 text-xs sm:text-sm text-slate-700 leading-relaxed">
          {{ cm.comment || cm.content }}
        </div>

        <!-- Detail Postingan Berita yang Dikomentari -->
        <div class="p-2.5 rounded-xl bg-blue-50/70 border border-blue-100/90 flex flex-col sm:flex-row sm:items-center justify-between gap-2.5">
          <div class="flex items-center gap-2 min-w-0">
            <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-[#0B2563] text-white text-[10px] font-black uppercase tracking-wider shrink-0">
              <Newspaper class="w-3 h-3 text-[#F5B700]" />
              Berita
            </span>
            <span
              v-if="cm.article_category"
              class="px-2 py-0.5 rounded-md bg-white text-slate-700 border border-slate-200 text-[10px] font-bold shrink-0"
            >
              {{ cm.article_category }}
            </span>
            <router-link
              :to="`/berita/${cm.article_slug || cm.article_id}`"
              target="_blank"
              class="text-xs font-extrabold text-[#0B2563] hover:text-[#D91E28] hover:underline truncate inline-flex items-center gap-1"
              :title="cm.article_title"
            >
              <span class="truncate">{{ cm.article_title || ('Artikel ID: #' + cm.article_id) }}</span>
              <ExternalLink class="w-3 h-3 shrink-0 text-slate-400" />
            </router-link>
          </div>

          <!-- Tombol Aksi Moderasi & Buka Berita -->
          <div class="flex items-center gap-1.5 shrink-0 self-end sm:self-auto">
            <router-link
              :to="`/berita/${cm.article_slug || cm.article_id}`"
              target="_blank"
              class="px-2.5 py-1.5 rounded-lg bg-white hover:bg-[#0B2563] hover:text-white border border-blue-200 text-[#0B2563] text-[11px] font-extrabold transition-colors inline-flex items-center gap-1 shadow-2xs"
            >
              <span>Buka Berita</span>
              <ArrowUpRight class="w-3 h-3" />
            </router-link>
            <button
              v-if="cm.status !== 'approved'"
              type="button"
              @click="setStatus(cm, 'approved')"
              class="px-2.5 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white text-[11px] font-bold inline-flex items-center gap-1 shadow-2xs transition-colors"
            >
              <Check class="w-3 h-3" /> Setujui
            </button>
            <button
              v-if="cm.status !== 'rejected'"
              type="button"
              @click="setStatus(cm, 'rejected')"
              class="px-2.5 py-1.5 rounded-lg bg-amber-500 hover:bg-amber-600 text-white text-[11px] font-bold inline-flex items-center gap-1 shadow-2xs transition-colors"
            >
              <XCircle class="w-3 h-3" /> Tolak
            </button>
            <button
              type="button"
              @click="remove(cm)"
              class="p-1.5 rounded-lg bg-red-50 text-[#D91E28] hover:bg-[#D91E28] hover:text-white transition-colors"
              title="Hapus Komentar"
            >
              <Trash2 class="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </div>

      <div v-if="!comments.length" class="bg-white rounded-2xl border border-slate-200 p-10 text-center space-y-1">
        <MessageSquare class="w-8 h-8 text-slate-300 mx-auto mb-1" />
        <p class="text-sm font-bold text-slate-700">Tidak ada komentar pada filter ini</p>
        <p class="text-xs text-slate-400">Semua komentar dari artikel berita akan muncul di halaman ini.</p>
      </div>
    </div>
  </div>
</template>
