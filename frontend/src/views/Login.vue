<template>
  <div class="min-h-screen bg-[#F8F9FA] flex items-center justify-center p-6 relative overflow-hidden font-sans" dir="rtl">
    <!-- Abstract Background Elements -->
    <div class="absolute top-[-10%] right-[-10%] w-[500px] h-[500px] rounded-full blur-[120px] pointer-events-none" 
         :style="`background: ${brandColor}15`" />
    <div class="absolute bottom-[-10%] left-[-10%] w-[400px] h-[400px] rounded-full blur-[100px] pointer-events-none"
         :style="`background: ${brandColor}20`" />
    
    <div class="w-full max-w-md relative z-10">
      <!-- Logo Section -->
      <div class="text-center mb-10">
        <!-- Tenant Logo or Default Icon -->
        <div v-if="tenantInfo?.logo_url" class="w-20 h-20 mx-auto mb-6 rounded-[32px] overflow-hidden shadow-2xl">
          <img :src="tenantInfo.logo_url" class="w-full h-full object-contain" alt="شعار الشركة" />
        </div>
        <div v-else class="gold-gradient-bg w-20 h-20 rounded-[32px] flex items-center justify-center text-white shadow-2xl shadow-gold-500/30 mx-auto mb-6 transform hover:scale-110 hover:rotate-6 transition-all duration-500">
          <i data-lucide="diamond" class="w-10 h-10 fill-white"></i>
        </div>
        <h1 class="text-4xl font-black text-slate-900 tracking-tight gold-text-gradient mb-2">
          {{ tenantInfo?.name || 'ذهـبي' }}
        </h1>
        <p class="text-[10px] font-black text-slate-400 uppercase tracking-[0.4em]">The Gold Hub Management</p>
      </div>

      <!-- Login Card -->
      <div class="luxury-card p-10 bg-white/80 backdrop-blur-xl border border-white">
        <div class="mb-8">
          <h2 class="text-2xl font-black text-slate-900 tracking-tight">تسجيل الدخول</h2>
          <p class="text-slate-400 text-sm font-bold mt-1">أدخل بياناتك للوصول إلى لوحة التحكم الفاخرة</p>
        </div>

        <div v-if="error" class="bg-rose-50 text-rose-600 p-4 rounded-2xl border border-rose-100 text-xs font-bold mb-6 flex items-center gap-3">
          <i data-lucide="info" class="w-4 h-4"></i>
          {{ error }}
        </div>

        <form @submit.prevent="handleLogin" class="space-y-5">
          <!-- Tenant Code Field -->
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">كود الشركة</label>
            <div class="relative group">
              <i data-lucide="building" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-gold-500 transition-colors w-5 h-5"></i>
              <input 
                v-model="tenantCode" 
                type="text"
                dir="ltr"
                placeholder="أدخل كود شركتك (مثال: gold123)"
                class="w-full bg-slate-50/50 border border-slate-100 rounded-2xl pr-12 pl-4 py-4 font-bold text-slate-900 focus:ring-4 focus:ring-gold-500/5 focus:border-gold-300 outline-none transition-all"
                @blur="fetchTenantInfo"
                @keyup.enter="fetchTenantInfo"
              />
              <div v-if="tenantLoading" class="absolute left-4 top-1/2 -translate-y-1/2">
                <div class="w-4 h-4 border-2 border-gold-500 border-t-transparent rounded-full animate-spin"></div>
              </div>
              <div v-else-if="tenantInfo" class="absolute left-4 top-1/2 -translate-y-1/2">
                <i data-lucide="check-circle" class="w-4 h-4 text-emerald-500"></i>
              </div>
            </div>
            <!-- Tenant Preview -->
            <div v-if="tenantInfo" class="flex items-center gap-2 px-3 py-2 bg-emerald-50 rounded-xl border border-emerald-100">
              <i data-lucide="building-2" class="w-4 h-4 text-emerald-600 shrink-0"></i>
              <span class="text-xs font-black text-emerald-700">{{ tenantInfo.name }}</span>
              <span class="text-[10px] text-emerald-500 mr-auto font-bold">✓ تم التحقق</span>
            </div>
          </div>

          <!-- Username -->
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">اسم المستخدم</label>
            <div class="relative group">
              <i data-lucide="user" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-gold-500 transition-colors w-5 h-5"></i>
              <input 
                v-model="username" 
                type="text" 
                placeholder="أدخل اسم المستخدم..."
                class="w-full bg-slate-50/50 border border-slate-100 rounded-2xl pr-12 pl-4 py-4 font-bold text-slate-900 focus:ring-4 focus:ring-gold-500/5 focus:border-gold-300 outline-none transition-all"
                required
              />
            </div>
          </div>

          <!-- Password -->
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">كلمة المرور</label>
            <div class="relative group">
              <i data-lucide="lock" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-gold-500 transition-colors w-5 h-5"></i>
              <input 
                v-model="password" 
                :type="showPass ? 'text' : 'password'"
                placeholder="••••••••"
                class="w-full bg-slate-50/50 border border-slate-100 rounded-2xl pr-12 pl-12 py-4 font-bold text-slate-900 focus:ring-4 focus:ring-gold-500/5 focus:border-gold-300 outline-none transition-all"
                required
              />
              <button 
                type="button" 
                @click="showPass = !showPass"
                class="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300 hover:text-slate-600 transition-colors"
              >
                <i :data-lucide="showPass ? 'eye-off' : 'eye'" class="w-5 h-5"></i>
              </button>
            </div>
          </div>

          <button 
            type="submit" 
            :disabled="loading"
            class="w-full gold-gradient-bg py-5 rounded-2xl text-white font-black shadow-xl shadow-gold-500/20 hover:shadow-gold-500/40 hover:scale-[1.02] active:scale-95 transition-all flex items-center justify-center gap-3 mt-2"
          >
            <span v-if="loading" class="animate-spin rounded-full h-5 w-5 border-2 border-white/30 border-t-white"></span>
            <span v-else>دخول للنظام</span>
          </button>
        </form>

        <div class="mt-8 pt-8 border-t border-slate-50 text-center">
          <p class="text-[10px] font-bold text-slate-300 uppercase tracking-[0.2em]">Luxury Management System v2.0</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import api from '../api/axios'

const router = useRouter()
const auth = useAuthStore()

const tenantCode = ref('')
const username = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)
const showPass = ref(false)
const tenantInfo = ref(null)
const tenantLoading = ref(false)

const brandColor = computed(() => tenantInfo.value?.primary_color || '#D69E27')

onMounted(() => {
  if (window.refreshIcons) window.refreshIcons()
})

async function fetchTenantInfo() {
  if (!tenantCode.value || tenantCode.value.length < 2) {
    tenantInfo.value = null
    return
  }
  tenantLoading.value = true
  error.value = ''
  try {
    const res = await api.get(`/auth/tenant/${tenantCode.value.trim()}`)
    tenantInfo.value = res.data
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  } catch (e) {
    tenantInfo.value = null
    if (tenantCode.value) {
      error.value = 'كود الشركة غير صحيح أو غير موجود'
    }
  } finally {
    tenantLoading.value = false
  }
}

async function handleLogin() {
  error.value = ''
  loading.value = true
  try {
    await auth.login(username.value, password.value, tenantCode.value.trim())
    router.push('/dashboard')
  } catch (e) {
    error.value = e.response?.data?.message || 'حدث خطأ في الاتصال بالسيرفر'
  } finally {
    loading.value = false
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  }
}
</script>
