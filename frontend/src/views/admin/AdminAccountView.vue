<script setup>
import { ref, onMounted } from 'vue'
import { portalState, updateAdminAccount, showToast } from '../../composables/usePortal'
import { KeyRound, Mail, Lock, User, Eye, EyeOff, Save, ShieldCheck } from 'lucide-vue-next'

const form = ref({
  name: '',
  email: '',
  current_password: '',
  new_password: '',
  confirm_password: '',
})

const showCurrent = ref(false)
const showNew = ref(false)
const showConfirm = ref(false)
const saving = ref(false)
const errorMsg = ref('')

onMounted(() => {
  form.value.name = portalState.user?.name || ''
  form.value.email = portalState.user?.email || ''
})

async function handleSubmit() {
  errorMsg.value = ''

  if (!form.value.email.trim()) {
    errorMsg.value = 'Email wajib diisi.'
    return
  }
  if (!form.value.current_password) {
    errorMsg.value = 'Masukkan kata sandi saat ini untuk verifikasi keamanan.'
    return
  }
  if (form.value.new_password) {
    if (form.value.new_password.length < 6) {
      errorMsg.value = 'Kata sandi baru minimal 6 karakter.'
      return
    }
    if (form.value.new_password !== form.value.confirm_password) {
      errorMsg.value = 'Konfirmasi kata sandi baru tidak cocok.'
      return
    }
  }

  saving.value = true
  try {
    await updateAdminAccount({
      name: form.value.name.trim(),
      email: form.value.email.trim(),
      current_password: form.value.current_password,
      new_password: form.value.new_password,
    })
    form.value.current_password = ''
    form.value.new_password = ''
    form.value.confirm_password = ''
    showToast('Email & kata sandi akun berhasil diperbarui!')
  } catch (e) {
    errorMsg.value = e.message || 'Gagal memperbarui akun'
    showToast(errorMsg.value, 'error')
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div class="max-w-2xl space-y-5">
    <div class="bg-white rounded-2xl border border-slate-200 p-5 sm:p-7 shadow-2xs space-y-5">
      <div class="flex items-start gap-3 pb-4 border-b border-slate-100">
        <div class="w-10 h-10 rounded-xl bg-[#0B2563] text-[#F5B700] flex items-center justify-center shrink-0">
          <KeyRound class="w-5 h-5" />
        </div>
        <div>
          <h2 class="text-lg font-black text-[#0B2563]">Ganti Email & Kata Sandi</h2>
          <p class="text-xs text-slate-500 mt-0.5">
            Perbarui email login dan kata sandi akun admin Anda. Demi keamanan, masukkan kata sandi saat ini sebelum menyimpan.
          </p>
        </div>
      </div>

      <div v-if="errorMsg" class="p-3.5 rounded-xl bg-red-50 border border-red-200 text-xs font-semibold text-red-700">
        {{ errorMsg }}
      </div>

      <form @submit.prevent="handleSubmit" autocomplete="off" class="space-y-4">
        <div>
          <label class="block text-xs font-extrabold text-slate-700 mb-1.5">Nama Tampilan</label>
          <div class="relative">
            <User class="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              v-model="form.name"
              type="text"
              required
              placeholder="Nama admin"
              class="w-full pl-10 pr-4 py-2.5 rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:border-[#0B2563] text-sm focus:outline-none"
            />
          </div>
        </div>

        <div>
          <label class="block text-xs font-extrabold text-slate-700 mb-1.5">Email Login *</label>
          <div class="relative">
            <Mail class="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              v-model="form.email"
              type="email"
              required
              placeholder="emailbaru@domain.com"
              class="w-full pl-10 pr-4 py-2.5 rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:border-[#0B2563] text-sm focus:outline-none"
            />
          </div>
        </div>

        <div class="pt-2 border-t border-slate-100 space-y-4">
          <div>
            <label class="block text-xs font-extrabold text-slate-700 mb-1.5">
              Kata Sandi Saat Ini (Wajib untuk verifikasi) *
            </label>
            <div class="relative">
              <Lock class="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                v-model="form.current_password"
                :type="showCurrent ? 'text' : 'password'"
                required
                autocomplete="current-password"
                placeholder="Masukkan kata sandi saat ini"
                class="w-full pl-10 pr-11 py-2.5 rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:border-[#0B2563] text-sm focus:outline-none"
              />
              <button
                type="button"
                @click="showCurrent = !showCurrent"
                class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-700"
              >
                <EyeOff v-if="showCurrent" class="w-4 h-4" />
                <Eye v-else class="w-4 h-4" />
              </button>
            </div>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-extrabold text-slate-700 mb-1.5">
                Kata Sandi Baru <span class="text-slate-400 font-normal">(opsional)</span>
              </label>
              <div class="relative">
                <Lock class="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  v-model="form.new_password"
                  :type="showNew ? 'text' : 'password'"
                  autocomplete="new-password"
                  placeholder="Minimal 6 karakter"
                  class="w-full pl-10 pr-11 py-2.5 rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:border-[#0B2563] text-sm focus:outline-none"
                />
                <button
                  type="button"
                  @click="showNew = !showNew"
                  class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-700"
                >
                  <EyeOff v-if="showNew" class="w-4 h-4" />
                  <Eye v-else class="w-4 h-4" />
                </button>
              </div>
            </div>

            <div>
              <label class="block text-xs font-extrabold text-slate-700 mb-1.5">
                Konfirmasi Kata Sandi Baru
              </label>
              <div class="relative">
                <Lock class="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  v-model="form.confirm_password"
                  :type="showConfirm ? 'text' : 'password'"
                  autocomplete="new-password"
                  placeholder="Ulangi kata sandi baru"
                  class="w-full pl-10 pr-11 py-2.5 rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:border-[#0B2563] text-sm focus:outline-none"
                />
                <button
                  type="button"
                  @click="showConfirm = !showConfirm"
                  class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-700"
                >
                  <EyeOff v-if="showConfirm" class="w-4 h-4" />
                  <Eye v-else class="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        </div>

        <div class="p-3.5 rounded-xl bg-blue-50/70 border border-blue-100 flex items-center gap-2.5 text-xs text-slate-600">
          <ShieldCheck class="w-4 h-4 text-[#0B2563] shrink-0" />
          <span>Kosongkan kolom kata sandi baru jika Anda hanya ingin mengganti email atau nama.</span>
        </div>

        <div class="flex justify-end pt-2">
          <button
            type="submit"
            :disabled="saving"
            class="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-extrabold transition-colors disabled:opacity-50"
          >
            <Save class="w-4 h-4" />
            <span>{{ saving ? 'Menyimpan...' : 'Simpan Perubahan Akun' }}</span>
          </button>
        </div>
      </form>
    </div>
  </div>
</template>
