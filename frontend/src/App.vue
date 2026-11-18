<script setup>
import { onMounted } from 'vue'
import { bootstrapPortal, portalState } from './composables/usePortal'
import { CheckCircle2, Info, AlertCircle } from 'lucide-vue-next'

onMounted(() => {
  bootstrapPortal()
})
</script>

<template>
  <router-view />

  <!-- Global Toast Notification -->
  <Transition
    enter-active-class="transition duration-200 ease-out"
    enter-from-class="translate-y-4 opacity-0"
    enter-to-class="translate-y-0 opacity-100"
    leave-active-class="transition duration-150 ease-in"
    leave-from-class="translate-y-0 opacity-100"
    leave-to-class="translate-y-4 opacity-0"
  >
    <div
      v-if="portalState.toast"
      class="fixed bottom-20 lg:bottom-6 right-4 z-[90] flex items-center gap-2.5 px-4 py-3 rounded-xl shadow-xl border text-xs sm:text-sm font-semibold max-w-xs sm:max-w-sm"
      :class="{
        'bg-[#0B2563] text-white border-blue-800': portalState.toast.type === 'success',
        'bg-slate-900 text-white border-slate-700': portalState.toast.type === 'info',
        'bg-[#D91E28] text-white border-red-700': portalState.toast.type === 'error',
      }"
    >
      <CheckCircle2 v-if="portalState.toast.type === 'success'" class="w-4 h-4 text-[#F5B700] shrink-0" />
      <AlertCircle v-else-if="portalState.toast.type === 'error'" class="w-4 h-4 text-white shrink-0" />
      <Info v-else class="w-4 h-4 text-sky-300 shrink-0" />
      <span>{{ portalState.toast.message }}</span>
    </div>
  </Transition>
</template>
