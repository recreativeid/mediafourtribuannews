<script setup>
import { ref, onMounted, watch } from 'vue'
import { api, timeAgoID } from '../../api/client'
import { showToast } from '../../composables/usePortal'
import { Check, XCircle, Trash2 } from 'lucide-vue-next'

const comments = ref([])
const statusFilter = ref('all')

async function load() {
  const q = statusFilter.value === 'all' ? '' : `?status=${statusFilter.value}`
  const res = await api.get(`/admin/comments${q}`)
  comments.value = res.data || []
}

async function setStatus(cm, status) {
  await api.put(`/admin/comments/${cm.id}/status`, { status })
  showToast(`Status komentar diubah menjadi ${status}`)
  load()
}

async function remove(cm) {
  if (!confirm('Hapus komentar ini?')) return
  await api.del(`/admin/comments/${cm.id}`)
  showToast('Komentar dihapus', 'info')
  load()
}

watch(statusFilter, load)
onMounted(load)
</script>

<template>
  <div class="space-y-4">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
      <div>
        <h2 class="text-lg font-black text-[#0B2563]">Moderasi Komentar Pembaca</h2>
        <p class="text-xs text-slate-500">Setujui, tolak, atau hapus komentar yang masuk pada artikel.</p>
      </div>
      <div class="flex gap-1.5 flex-wrap">
        <button
          v-for="s in ['all', 'pending', 'approved', 'rejected']"
          :key="s"
          type="button"
          @click="statusFilter = s"
          class="px-3 py-1.5 rounded-xl text-xs font-bold uppercase transition-colors"
          :class="statusFilter === s ? 'bg-[#0B2563] text-white' : 'bg-white border border-slate-200 text-slate-600'"
        >
          {{ s }}
        </button>
      </div>
    </div>

    <div class="space-y-3">
      <div v-for="cm in comments" :key="cm.id" class="bg-white rounded-2xl border border-slate-200 p-4 shadow-2xs space-y-2.5">
        <div class="flex flex-wrap items-center justify-between gap-2">
          <div>
            <span class="font-extrabold text-sm text-slate-900">{{ cm.name }}</span>
            <span class="text-xs text-slate-400 ml-2">{{ cm.email }}</span>
            <span class="text-xs text-slate-400 ml-2">&bull; {{ timeAgoID(cm.created_at) }}</span>
          </div>
          <span
            class="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold uppercase"
            :class="{
              'bg-emerald-50 text-emerald-700': cm.status === 'approved',
              'bg-amber-50 text-amber-700': cm.status === 'pending',
              'bg-red-50 text-red-700': cm.status === 'rejected' || cm.status === 'spam',
            }"
          >
            {{ cm.status }}
          </span>
        </div>

        <p class="text-xs sm:text-sm text-slate-700 bg-slate-50 p-3 rounded-xl">{{ cm.comment }}</p>

        <div class="flex flex-wrap items-center justify-between gap-2 pt-1">
          <router-link :to="`/berita/${cm.article_slug}`" target="_blank" class="text-[11px] font-bold text-[#0B2563] hover:underline truncate max-w-md">
            Artikel: {{ cm.article_title }}
          </router-link>
          <div class="flex gap-1.5">
            <button type="button" @click="setStatus(cm, 'approved')" class="px-3 py-1.5 rounded-lg bg-emerald-600 text-white text-xs font-bold inline-flex items-center gap-1">
              <Check class="w-3.5 h-3.5" /> Setujui
            </button>
            <button type="button" @click="setStatus(cm, 'rejected')" class="px-3 py-1.5 rounded-lg bg-amber-500 text-white text-xs font-bold inline-flex items-center gap-1">
              <XCircle class="w-3.5 h-3.5" /> Tolak
            </button>
            <button type="button" @click="remove(cm)" class="p-1.5 rounded-lg bg-red-50 text-[#D91E28] hover:bg-[#D91E28] hover:text-white">
              <Trash2 class="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      <div v-if="!comments.length" class="bg-white rounded-2xl border border-slate-200 p-8 text-center text-xs text-slate-500">
        Tidak ada komentar pada filter ini.
      </div>
    </div>
  </div>
</template>
