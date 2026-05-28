<template>
  <div class="min-h-screen bg-slate-50 flex flex-col items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-6 bg-white p-10 rounded-3xl shadow-luxury text-center">
      
      <div v-if="isSuccess" class="space-y-4">
        <div class="w-20 h-20 bg-emerald-50 rounded-full flex items-center justify-center mx-auto mb-6">
          <i data-lucide="check-circle-2" class="w-10 h-10 text-emerald-500"></i>
        </div>
        <h2 class="text-2xl font-black text-slate-900">تم الدفع والاشتراك بنجاح!</h2>
        <p class="text-sm text-slate-500 font-bold leading-relaxed">
          شكراً لاشتراكك في النظام الذهبي. تم تفعيل حسابك (كود الشركة: <span class="text-gold-600 bg-gold-50 px-2 py-0.5 rounded">{{ tenantCode }}</span>) بنجاح.
        </p>
        <div class="pt-6">
          <router-link to="/login" class="luxury-button justify-center w-full py-4 text-base">
            الذهاب لتسجيل الدخول
          </router-link>
        </div>
      </div>

      <div v-else class="space-y-4">
        <div class="w-20 h-20 bg-rose-50 rounded-full flex items-center justify-center mx-auto mb-6">
          <i data-lucide="x-circle" class="w-10 h-10 text-rose-500"></i>
        </div>
        <h2 class="text-2xl font-black text-slate-900">فشلت عملية الدفع</h2>
        <p class="text-sm text-slate-500 font-bold">عذراً، لم نتمكن من إتمام عملية الدفع. يرجى المحاولة مرة أخرى أو التأكد من رصيد محفظة زين كاش.</p>
        <div class="pt-6">
          <router-link to="/register" class="luxury-button justify-center w-full py-4 text-base !bg-slate-900 !shadow-slate-900/20">
            العودة لصفحة التسجيل
          </router-link>
        </div>
      </div>

    </div>
  </div>
</template>

<script setup>
import { computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()
const isSuccess = computed(() => route.path.includes('success'))
const tenantCode = computed(() => route.query.tenant || '...')

onMounted(() => {
  if (window.lucide) {
    window.lucide.createIcons()
  }
})
</script>
