<template>
  <div class="min-h-screen bg-slate-50 flex flex-col items-center py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-xl w-full space-y-8 bg-white p-8 sm:p-12 rounded-3xl shadow-luxury">
      
      <div class="flex items-center gap-4 mb-8">
        <router-link to="/" class="w-10 h-10 rounded-full bg-slate-50 border border-slate-100 flex items-center justify-center text-slate-400 hover:text-gold-500 transition-colors">
          <i data-lucide="arrow-right" class="w-5 h-5"></i>
        </router-link>
        <div>
          <h2 class="text-2xl font-black text-slate-900">إنشاء حساب جديد</h2>
          <p class="text-xs text-slate-500 mt-1">اشترك الآن وابدأ في إدارة محلك باحترافية</p>
        </div>
      </div>

      <form @submit.prevent="handleRegister" class="space-y-6">
        
        <div class="space-y-2">
          <label class="text-xs font-bold text-slate-700">اسم المحل (الشركة) <span class="text-rose-500">*</span></label>
          <input v-model="form.tenant_name" type="text" required
                 class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-gold-500/20 focus:border-gold-500 outline-none" 
                 placeholder="مجوهرات النخيل">
        </div>

        <div class="space-y-2">
          <label class="text-xs font-bold text-slate-700">
            كود الشركة <span class="text-rose-500">*</span>
          </label>
          <div class="relative">
            <input v-model="form.tenant_code" type="text" dir="ltr" required
                   class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-gold-500/20 focus:border-gold-500 outline-none font-mono font-bold pr-10" 
                   placeholder="nakheel2024" 
                   @input="form.tenant_code = form.tenant_code.toLowerCase().replace(/[^a-z0-9]/g, '')">
            <i data-lucide="key" class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400"></i>
          </div>
          <p class="text-[10px] text-slate-400">يستخدمه موظفوك وعملاؤك لتسجيل الدخول، أحرف إنجليزية وأرقام فقط</p>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-2">
            <label class="text-xs font-bold text-slate-700">اسم مستخدم المشرف <span class="text-rose-500">*</span></label>
            <input v-model="form.admin_username" type="text" dir="ltr" required
                   class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-gold-500/20 focus:border-gold-500 outline-none" 
                   placeholder="admin">
          </div>
          <div class="space-y-2">
            <label class="text-xs font-bold text-slate-700">كلمة المرور <span class="text-rose-500">*</span></label>
            <input v-model="form.admin_password" type="password" dir="ltr" required
                   class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-gold-500/20 focus:border-gold-500 outline-none" 
                   placeholder="••••••••">
          </div>
        </div>

        <div class="space-y-3 pt-4 border-t border-slate-100">
          <label class="text-xs font-bold text-slate-700">خطة الاشتراك</label>
          <div class="grid grid-cols-2 gap-4">
            <div @click="form.plan = 'monthly'" 
                 :class="form.plan === 'monthly' ? 'border-gold-500 bg-gold-50 ring-2 ring-gold-500/20' : 'border-slate-200 bg-white opacity-60'"
                 class="border-2 rounded-2xl p-4 cursor-pointer transition-all">
              <div class="flex justify-between items-start mb-2">
                <span class="text-sm font-black text-slate-900">شهري</span>
                <i v-if="form.plan === 'monthly'" data-lucide="check-circle-2" class="w-5 h-5 text-gold-500"></i>
              </div>
              <div class="text-gold-600 font-bold">50,000 د.ع</div>
            </div>
            
            <div @click="form.plan = 'yearly'" 
                 :class="form.plan === 'yearly' ? 'border-gold-500 bg-gold-50 ring-2 ring-gold-500/20' : 'border-slate-200 bg-white opacity-60'"
                 class="border-2 rounded-2xl p-4 cursor-pointer transition-all relative overflow-hidden">
              <div class="absolute -right-6 top-3 bg-rose-500 text-white text-[10px] font-bold px-8 py-1 rotate-45">توفير 17%</div>
              <div class="flex justify-between items-start mb-2">
                <span class="text-sm font-black text-slate-900">سنوي</span>
                <i v-if="form.plan === 'yearly'" data-lucide="check-circle-2" class="w-5 h-5 text-gold-500"></i>
              </div>
              <div class="text-gold-600 font-bold">500,000 د.ع</div>
            </div>
          </div>
        </div>

        <div class="pt-6">
          <button type="submit" :disabled="loading" class="w-full luxury-button justify-center py-4 text-base">
            <i v-if="loading" data-lucide="loader-2" class="w-5 h-5 animate-spin"></i>
            <span v-else>الدفع عبر ZainCash والاشتراك</span>
          </button>
        </div>
      </form>
      
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api/axios'

const router = useRouter()
const loading = ref(false)
const form = ref({
  tenant_name: '',
  tenant_code: '',
  admin_username: '',
  admin_password: '',
  plan: 'yearly'
})

const handleRegister = async () => {
  loading.value = true
  try {
    // 1. Create the tenant and admin user in inactive state
    const res = await api.post('/auth/register', form.value)
    const tenantId = res.data.tenantId

    // 2. Initiate ZainCash Payment
    const paymentRes = await api.post('/payments/checkout', {
      tenantId: tenantId,
      plan: form.value.plan
    })

    // 3. Redirect to ZainCash URL
    if (paymentRes.data?.paymentUrl) {
      window.location.href = paymentRes.data.paymentUrl
    } else {
      alert('فشل في بدء عملية الدفع')
      loading.value = false
    }

  } catch (error) {
    alert(error.response?.data?.message || 'حدث خطأ أثناء إنشاء الحساب، قد يكون كود الشركة مستخدماً.')
    loading.value = false
  }
}

onMounted(() => {
  if (window.lucide) {
    window.lucide.createIcons()
  }
})
</script>
