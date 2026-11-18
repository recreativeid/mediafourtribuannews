<script setup>
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { loginAdmin, showToast } from '../../composables/usePortal'
import { Lock, Mail, Eye, EyeOff, ArrowLeft, ShieldCheck } from 'lucide-vue-next'

const router = useRouter()
const route = useRoute()

const email = ref('admin@mediafourtribuannews.id')
const password = ref('')
const showPass = ref(false)
const loading = ref(false)
const errorMsg = ref('')

function fillDemo() {
  email.value = 'admin@mediafourtribuannews.id'
  password.value = 'admin123'
}

async function handleSubmit() {
  errorMsg.value = ''
  loading.value = true
  try {
    await loginAdmin(email.value, password.value)
    showToast('Selamat datang di Panel Redaksi!')
    const target = route.query.redirect ? String(route.query.redirect) : '/admin'
    router.push(target)
  } catch (e) {
    errorMsg.value = e.message || 'Email atau kata sandi tidak sesuai'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen flex flex-col bg-gradient-to-br from-[#081A47] via-[#0B2563] to-[#12358A] text-slate-900">
    <!-- Top Back Strip -->
    <header class="px-4 sm:px-8 py-4 flex items-center justify-between text-white/90 text-xs">
      <router-link to="/" class="inline-flex items-center gap-2 hover:text-[#F5B700] font-bold transition-colors">
        <ArrowLeft class="w-4 h-4" />
        <span>Kembali ke Portal Berita</span>
      </router-link>
      <span class="hidden sm:inline font-mono text-blue-200/80">CMS EDITORIAL v3.0 &bull; VUE + GO</span>
    </header>

    <!-- Login Card -->
    <main class="flex-1 flex items-center justify-center p-4">
      <div class="w-full max-w-md bg-white rounded-3xl shadow-2xl overflow-hidden border border-white/20">
        <!-- Brand Header (pure white so logo blends cleanly) -->
        <div class="bg-white px-6 pt-7 pb-5 text-center border-b-4 border-[#D91E28]">
          <img
            src="/images/logo-mftn.jpg"
            alt="Media Four Tribuan News"
            class="h-20 w-auto mx-auto object-contain mb-3"
          />
          <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#0B2563] text-[#F5B700] text-[10px] font-black uppercase tracking-widest">
            <ShieldCheck class="w-3.5 h-3.5" />
            <span>Portal Login Redaksi & Admin</span>
          </div>
        </div>

        <div class="p-6 sm:p-8 space-y-5">
          <div v-if="errorMsg" class="p-3 rounded-xl bg-red-50 border border-red-200 text-xs font-semibold text-red-700">
            {{ errorMsg }}
          </div>

          <form @submit.prevent="handleSubmit" class="space-y-4">
            <div>
              <label class="block text-xs font-extrabold text-slate-700 mb-1.5">Email Redaksi</label>
              <div class="relative">
                <Mail class="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  v-model="email"
                  type="text"
                  required
                  autocomplete="username"
                  placeholder="admin@mediafourtribuannews.id"
                  class="w-full pl-10 pr-4 py-3 rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:border-[#0B2563] text-sm focus:outline-none"
                />
              </div>
            </div>

            <div>
              <label class="block text-xs font-extrabold text-slate-700 mb-1.5">Kata Sandi</label>
              <div class="relative">
                <Lock class="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  v-model="password"
                  :type="showPass ? 'text' : 'password'"
                  required
                  autocomplete="current-password"
                  placeholder="Masukkan kata sandi"
                  class="w-full pl-10 pr-11 py-3 rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:border-[#0B2563] text-sm focus:outline-none"
                />
                <button
                  type="button"
                  @click="showPass = !showPass"
                  class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-700"
                >
                  <EyeOff v-if="showPass" class="w-4 h-4" />
                  <Eye v-else class="w-4 h-4" />
                </button>
              </div>
            </div>

            <button
              type="submit"
              :disabled="loading"
              class="w-full py-3.5 rounded-xl bg-[#0B2563] hover:bg-[#D91E28] text-white font-extrabold text-sm shadow-md transition-colors disabled:opacity-50"
            >
              {{ loading ? 'Memverifikasi...' : 'Masuk ke Dashboard Admin' }}
            </button>
          </form>

          <!-- Quick Demo Credential Helper -->
          <div class="p-3.5 rounded-2xl bg-blue-50/80 border border-blue-100 text-xs flex items-center justify-between gap-2">
            <div class="text-slate-600">
              <div class="font-extrabold text-[#0B2563]">Akun Demo Admin:</div>
              <div class="font-mono text-[11px]">admin@mediafourtribuannews.id / admin123</div>
            </div>
            <button
              type="button"
              @click="fillDemo"
              class="px-3 py-1.5 rounded-lg bg-[#0B2563] text-white text-[11px] font-bold hover:bg-[#D91E28] shrink-0 transition-colors"
            >
              Isi Otomatis
            </button>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>
