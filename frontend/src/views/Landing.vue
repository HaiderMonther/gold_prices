<template>
  <div class="min-h-screen bg-slate-50 flex flex-col items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8 bg-white p-10 rounded-3xl shadow-luxury">
      <div class="text-center">
        <i data-lucide="gem" class="w-16 h-16 text-gold-500 mx-auto mb-4"></i>
        <h2 class="text-3xl font-black text-slate-900 mb-2">النظام الذهبي لإدارة المبيعات</h2>
        <p class="text-sm text-slate-500 font-bold">الحل المتكامل لإدارة محلات الذهب والمجوهرات</p>
      </div>
      
      <div class="space-y-4 pt-6">
        <div class="flex items-center p-4 bg-slate-50 rounded-2xl border border-slate-100">
          <div class="shrink-0 w-12 h-12 bg-white rounded-xl shadow-sm flex items-center justify-center ml-4">
            <i data-lucide="shield-check" class="w-6 h-6 text-emerald-500"></i>
          </div>
          <div>
            <h4 class="font-black text-slate-800">أمان وحماية عالية</h4>
            <p class="text-xs text-slate-500 mt-1">نسخ احتياطي يومي وحماية لبيانات عملائك</p>
          </div>
        </div>
        
        <div class="flex items-center p-4 bg-slate-50 rounded-2xl border border-slate-100">
          <div class="shrink-0 w-12 h-12 bg-white rounded-xl shadow-sm flex items-center justify-center ml-4">
            <i data-lucide="bar-chart-3" class="w-6 h-6 text-blue-500"></i>
          </div>
          <div>
            <h4 class="font-black text-slate-800">تقارير مالية دقيقة</h4>
            <p class="text-xs text-slate-500 mt-1">حساب الأرباح والمصنعية والمخزون بضغطة زر</p>
          </div>
        </div>

        <div class="flex items-center p-4 bg-slate-50 rounded-2xl border border-slate-100">
          <div class="shrink-0 w-12 h-12 bg-white rounded-xl shadow-sm flex items-center justify-center ml-4">
            <i data-lucide="smartphone" class="w-6 h-6 text-purple-500"></i>
          </div>
          <div>
            <h4 class="font-black text-slate-800">تطبيق هاتف خاص بك</h4>
            <p class="text-xs text-slate-500 mt-1">تطبيق للعملاء بهويتك وألوانك الخاصة</p>
          </div>
        </div>
      </div>

      <div class="pt-8 flex flex-col gap-3">
        <router-link to="/register" class="luxury-button justify-center text-lg w-full">
          ابـدأ اشتـراكك الآن
          <i data-lucide="arrow-left" class="w-5 h-5 mr-2"></i>
        </router-link>
        <router-link to="/login" class="text-center py-3 text-sm font-bold text-slate-500 hover:text-gold-600 transition-colors">
          لدي حساب بالفعل، تسجيل الدخول
        </router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'

onMounted(() => {
  if (window.lucide) {
    window.lucide.createIcons()
  }
})
</script>
