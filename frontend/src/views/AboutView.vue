<script setup>
import { ref, onMounted } from 'vue'
import { api } from '../api/client'
import { portalState } from '../composables/usePortal'
import { Users, Shield, Phone, Mail, MapPin, CheckCircle2 } from 'lucide-vue-next'

const team = ref([])

onMounted(async () => {
  try {
    const res = await api.get('/redaksi')
    team.value = res.data || []
  } catch {}
})
</script>

<template>
  <div class="max-w-5xl mx-auto px-3 sm:px-6 lg:px-8 py-6 sm:py-9 space-y-8">
    <!-- Hero Profile Card -->
    <section class="rounded-3xl bg-white border border-slate-200 p-6 sm:p-8 shadow-xs space-y-4">
      <div class="flex flex-col sm:flex-row sm:items-center gap-5 pb-5 border-b border-slate-100">
        <img src="/images/logo-mftn.jpg" alt="Media Four Tribuan News" class="h-20 w-auto object-contain self-start" />
        <div>
          <span class="inline-block px-3 py-1 rounded-full bg-[#0B2563] text-[#F5B700] text-[10px] font-black uppercase tracking-widest mb-2">
            Profil Media Nasional
          </span>
          <h1 class="font-editorial text-2xl sm:text-3xl font-bold text-[#0B2563]">
            {{ portalState.settings.site_title }}
          </h1>
          <p class="text-xs sm:text-sm font-bold text-[#D91E28] mt-0.5">
            {{ portalState.settings.site_tagline }}
          </p>
        </div>
      </div>

      <p class="text-sm text-slate-700 leading-relaxed">
        <strong>Media Four Tribuan News</strong> yang dikelola oleh <strong>{{ portalState.settings.company_name }}</strong>
        adalah portal berita digital nasional yang hadir menyajikan jurnalisme cepat, terverifikasi, berimbang, dan
        independen. Kami menjunjung tinggi Undang-Undang Pers No. 40 Tahun 1999 serta Kode Etik Jurnalistik Dewan Pers.
      </p>

      <div class="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-2">
        <div class="p-4 rounded-2xl bg-blue-50/70 border border-blue-100">
          <div class="font-extrabold text-sm text-[#0B2563] flex items-center gap-1.5">
            <CheckCircle2 class="w-4 h-4 text-[#D91E28]" /> Aktual
          </div>
          <p class="text-xs text-slate-600 mt-1">Peliputan peristiwa terkini secara sigap dari biro pusat hingga daerah.</p>
        </div>
        <div class="p-4 rounded-2xl bg-blue-50/70 border border-blue-100">
          <div class="font-extrabold text-sm text-[#0B2563] flex items-center gap-1.5">
            <CheckCircle2 class="w-4 h-4 text-[#1648B8]" /> Terpercaya
          </div>
          <p class="text-xs text-slate-600 mt-1">Setiap berita melewati verifikasi narasumber dan disiplin cek fakta redaksi.</p>
        </div>
        <div class="p-4 rounded-2xl bg-blue-50/70 border border-blue-100">
          <div class="font-extrabold text-sm text-[#0B2563] flex items-center gap-1.5">
            <CheckCircle2 class="w-4 h-4 text-[#F5B700]" /> Independen
          </div>
          <p class="text-xs text-slate-600 mt-1">Berpihak pada kepentingan publik tanpa intervensi kepentingan golongan.</p>
        </div>
      </div>
    </section>

    <!-- Susunan Redaksi -->
    <section id="redaksi" class="rounded-3xl bg-white border border-slate-200 p-6 sm:p-8 shadow-xs space-y-5">
      <div class="flex items-center gap-2.5">
        <span class="w-9 h-9 rounded-xl bg-[#0B2563] text-[#F5B700] flex items-center justify-center">
          <Users class="w-5 h-5" />
        </span>
        <div>
          <h2 class="text-lg font-black text-[#0B2563]">Susunan Redaksi</h2>
          <p class="text-xs text-slate-500">{{ portalState.settings.company_name }}</p>
        </div>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
        <div
          v-for="m in team"
          :key="m.id"
          class="p-4 rounded-2xl border border-slate-200/90 bg-slate-50/60 hover:border-[#0B2563]/40 transition-colors"
        >
          <span class="text-[10px] font-extrabold uppercase tracking-wider text-[#D91E28]">{{ m.division }}</span>
          <h3 class="text-sm font-extrabold text-slate-900 mt-0.5">{{ m.name }}</h3>
          <p class="text-xs font-bold text-[#0B2563]">{{ m.position }}</p>
          <p v-if="m.description" class="text-xs text-slate-500 mt-1">{{ m.description }}</p>
          <div v-if="m.email" class="text-[11px] text-slate-500 mt-2">{{ m.email }}</div>
        </div>
      </div>
    </section>

    <!-- Pedoman Media Siber -->
    <section id="pedoman" class="rounded-3xl bg-white border border-slate-200 p-6 sm:p-8 shadow-xs space-y-3">
      <div class="flex items-center gap-2.5">
        <span class="w-9 h-9 rounded-xl bg-[#D91E28]/10 text-[#D91E28] flex items-center justify-center">
          <Shield class="w-5 h-5" />
        </span>
        <h2 class="text-lg font-black text-[#0B2563]">Pedoman Pemberitaan Media Siber</h2>
      </div>
      <p class="text-xs sm:text-sm text-slate-700 leading-relaxed">
        Media Four Tribuan News mematuhi sepenuhnya Pedoman Pemberitaan Media Siber yang ditetapkan Dewan Pers.
        Setiap berita yang memerlukan verifikasi lanjutan akan diperbarui secara transparan, serta menyediakan
        ruang Hak Jawab dan Koreksi bagi masyarakat maupun pihak terkait melalui alamat redaksi resmi kami.
      </p>
    </section>

    <!-- Kontak Redaksi -->
    <section id="kontak" class="rounded-3xl bg-gradient-to-br from-[#081A47] to-[#0B2563] text-white p-6 sm:p-8 shadow-md space-y-4">
      <h2 class="text-lg font-black text-[#F5B700]">Kontak Redaksi & Kemitraan Iklan</h2>
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs sm:text-sm">
        <div class="bg-white/10 rounded-2xl p-4 space-y-1.5">
          <MapPin class="w-5 h-5 text-[#F5B700]" />
          <div class="font-bold">Alamat Kantor</div>
          <p class="text-blue-100/85 text-xs">{{ portalState.settings.office_address }}</p>
        </div>
        <div class="bg-white/10 rounded-2xl p-4 space-y-1.5">
          <Phone class="w-5 h-5 text-[#F5B700]" />
          <div class="font-bold">Hotline / WhatsApp</div>
          <a
            :href="`https://wa.me/${portalState.settings.whatsapp_number}`"
            target="_blank"
            class="text-blue-100 hover:text-[#F5B700] text-xs font-semibold block"
          >
            {{ portalState.settings.hotline_phone }}
          </a>
        </div>
        <div class="bg-white/10 rounded-2xl p-4 space-y-1.5">
          <Mail class="w-5 h-5 text-[#F5B700]" />
          <div class="font-bold">Email Redaksi</div>
          <p class="text-blue-100/85 text-xs break-all">{{ portalState.settings.redaksi_email }}</p>
        </div>
      </div>
    </section>
  </div>
</template>
