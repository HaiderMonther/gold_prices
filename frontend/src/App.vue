<template>
  <div class="font-sans" dir="rtl">
    <router-view />
    
    <!-- Luxury Toast Notifications -->
    <div class="fixed bottom-6 left-6 z-[100] flex flex-col gap-3">
      <transition-group 
        enter-active-class="transition duration-300 ease-out"
        enter-from-class="opacity-0 -translate-x-10 scale-95"
        enter-to-class="opacity-100 translate-x-0 scale-100"
        leave-active-class="transition duration-200 ease-in"
        leave-from-class="opacity-100 translate-x-0 scale-100"
        leave-to-class="opacity-0 -translate-x-10 scale-95"
      >
        <div
          v-for="toast in toastStore.toasts"
          :key="toast.id"
          :class="[
            'px-4 py-3 rounded-2xl shadow-xl flex items-center gap-3 min-w-[280px] border transition-all',
            toast.type === 'success' ? 'bg-emerald-600 border-emerald-500 text-white' :
            toast.type === 'error' ? 'bg-rose-600 border-rose-500 text-white' :
            'bg-slate-900 border-slate-800 text-white'
          ]"
        >
          <div class="shrink-0">
            <i v-if="toast.type === 'success'" data-lucide="check" class="w-5 h-5"></i>
            <i v-else-if="toast.type === 'error'" data-lucide="x" class="w-5 h-5"></i>
            <i v-else data-lucide="info" class="w-5 h-5"></i>
          </div>
          <span class="text-sm font-bold flex-1">{{ toast.message }}</span>
          <button @click="toastStore.removeToast(toast.id)" class="opacity-60 hover:opacity-100 transition-opacity">
            <i data-lucide="x" class="w-4 h-4"></i>
          </button>
        </div>
      </transition-group>
    </div>
  </div>
</template>

<script setup>
import { watch, nextTick, onMounted } from 'vue'
import { useToastStore } from './stores/toast'
import { useAuthStore } from './stores/auth'

const toastStore = useToastStore()
const authStore = useAuthStore()

// Helper to adjust color brightness
const adjustColor = (color, amount) => {
  return '#' + color.replace(/^#/, '').replace(/../g, color => ('0'+Math.min(255, Math.max(0, parseInt(color, 16) + amount)).toString(16)).substr(-2))
}

// Helper to convert hex to RGB triplet string
const hexToRgb = (hex) => {
  if (!hex) return '214 158 39'; // Default gold
  let c = hex.replace(/^#/, '');
  if (c.length === 3) c = c.split('').map(x => x + x).join('');
  const r = parseInt(c.slice(0, 2), 16);
  const g = parseInt(c.slice(2, 4), 16);
  const b = parseInt(c.slice(4, 6), 16);
  return `${r} ${g} ${b}`;
}

const applyTenantTheme = () => {
  const color = authStore.tenant?.primary_color || localStorage.getItem('gold_tenant_color')
  if (color && color !== '#D69E27') {
    document.documentElement.style.setProperty('--gold-400', hexToRgb(adjustColor(color, 20)))
    document.documentElement.style.setProperty('--gold-500', hexToRgb(color))
    document.documentElement.style.setProperty('--gold-600', hexToRgb(adjustColor(color, -20)))
  } else {
    document.documentElement.style.removeProperty('--gold-400')
    document.documentElement.style.removeProperty('--gold-500')
    document.documentElement.style.removeProperty('--gold-600')
  }
}

onMounted(() => {
  applyTenantTheme()
})

watch(() => authStore.tenant, () => {
  applyTenantTheme()
})

// Ensure icons are refreshed when new toasts appear
watch(() => toastStore.toasts.length, () => {
  nextTick(() => {
    if (window.refreshIcons) window.refreshIcons()
  })
})
</script>

<style>
/* Global Tailwind-compatible scrollbar */
.custom-scrollbar::-webkit-scrollbar { width: 5px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: #e2e8f0; border-radius: 20px; }
.custom-scrollbar::-webkit-scrollbar-thumb:hover { background: #cbd5e1; }
</style>
