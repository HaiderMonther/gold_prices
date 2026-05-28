<template>
  <div class="space-y-10 max-w-4xl mx-auto">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-black text-slate-900 tracking-tight">إعدادات النظام</h1>
        <p class="text-slate-400 font-bold mt-1 uppercase tracking-widest text-[10px]">System Settings & Preferences</p>
      </div>
      <button @click="save" :disabled="saving" class="luxury-button">
        <i data-lucide="save" class="w-5 h-5 stroke-[3]"></i>
        {{ saving ? 'جاري الحفظ...' : 'حفظ الإعدادات' }}
      </button>
    </div>

    <div class="grid grid-cols-1 gap-8">
      <!-- Print Settings -->
      <div class="luxury-card p-10 bg-white">
        <h3 class="text-[10px] font-black text-gold-600 uppercase tracking-[0.3em] mb-8 flex items-center gap-3">
          <div class="w-6 h-1 bg-gold-400 rounded-full" />
          Receipt & Print Configuration • إعدادات الطباعة والفواتير
        </h3>
        
        <div class="space-y-8">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div class="space-y-3">
              <label class="text-xs font-black text-slate-500 mr-1">اسم المحل (يظهر في الفاتورة)</label>
              <div class="relative group">
                <i data-lucide="store" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-gold-500 w-[18px] h-[18px]"></i>
                <input 
                  type="text" 
                  v-model="form.shopName" 
                  placeholder="مجوهرات الذهبي..." 
                  class="w-full bg-slate-50/50 border border-slate-100/50 rounded-2xl pr-12 pl-4 py-4 text-sm font-bold focus:ring-4 focus:ring-gold-500/5 outline-none transition-all" 
                />
              </div>
            </div>
            <div class="space-y-3">
              <label class="text-xs font-black text-slate-500 mr-1">العنوان</label>
              <div class="relative group">
                <i data-lucide="map-pin" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-gold-500 w-[18px] h-[18px]"></i>
                <input 
                  type="text" 
                  v-model="form.shopAddress" 
                  placeholder="المدينة، الشارع..." 
                  class="w-full bg-slate-50/50 border border-slate-100/50 rounded-2xl pr-12 pl-4 py-4 text-sm font-bold focus:ring-4 focus:ring-gold-500/5 outline-none transition-all" 
                />
              </div>
            </div>
          </div>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div class="space-y-3">
              <label class="text-xs font-black text-slate-500 mr-1">رقم الهاتف الأساسي</label>
              <div class="relative group">
                <i data-lucide="phone" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-gold-500 w-[18px] h-[18px]"></i>
                <input 
                  type="text" 
                  v-model="form.shopPhone"
                  dir="ltr"
                  placeholder="07XXXXXXXXX" 
                  class="w-full bg-slate-50/50 border border-slate-100/50 rounded-2xl pr-12 pl-4 py-4 text-sm font-bold focus:ring-4 focus:ring-gold-500/5 outline-none transition-all text-left" 
                />
              </div>
            </div>
            <div class="space-y-3">
              <label class="text-xs font-black text-slate-500 mr-1">شعار الفاتورة (ملاحظة أسفل الفاتورة)</label>
              <div class="relative group">
                <i data-lucide="message-square" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-gold-500 w-[18px] h-[18px]"></i>
                <input 
                  type="text" 
                  v-model="form.receiptFooter" 
                  placeholder="البضاعة المباعة لا ترد ولا تستبدل..." 
                  class="w-full bg-slate-50/50 border border-slate-100/50 rounded-2xl pr-12 pl-4 py-4 text-sm font-bold focus:ring-4 focus:ring-gold-500/5 outline-none transition-all" 
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- General Settings -->
      <div class="luxury-card p-10 bg-white">
        <h3 class="text-[10px] font-black text-gold-600 uppercase tracking-[0.3em] mb-8 flex items-center gap-3">
          <div class="w-6 h-1 bg-gold-400 rounded-full" />
          General Options • خيارات عامة
        </h3>
        
        <div class="space-y-8">
          <div class="flex items-center justify-between p-6 bg-slate-50 rounded-2xl border border-slate-100">
            <div>
              <div class="font-black text-slate-900 text-sm">الطباعة التلقائية</div>
              <div class="text-xs font-bold text-slate-400 mt-1">طباعة الفاتورة تلقائياً عند حفظها دون السؤال</div>
            </div>
            <label class="relative inline-flex items-center cursor-pointer">
              <input type="checkbox" v-model="form.autoPrint" class="sr-only peer">
              <div class="w-14 h-7 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-[100%] rtl:peer-checked:after:-translate-x-[100%] peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-6 after:w-6 after:transition-all peer-checked:bg-gold-500"></div>
            </label>
          </div>
          
          <div class="flex items-center justify-between p-6 bg-slate-50 rounded-2xl border border-slate-100">
            <div>
              <div class="font-black text-slate-900 text-sm">التنبيه بالصوت</div>
              <div class="text-xs font-bold text-slate-400 mt-1">تشغيل نغمة عند إتمام العمليات الناجحة</div>
            </div>
            <label class="relative inline-flex items-center cursor-pointer">
              <input type="checkbox" v-model="form.soundAlerts" class="sr-only peer">
              <div class="w-14 h-7 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-[100%] rtl:peer-checked:after:-translate-x-[100%] peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-6 after:w-6 after:transition-all peer-checked:bg-gold-500"></div>
            </label>
          </div>
        </div>
      </div>
      
      <!-- System Backup Section -->
      <div class="luxury-card p-10 bg-slate-900 text-white border-none">
        <h3 class="text-[10px] font-black text-rose-500 uppercase tracking-[0.3em] mb-8 flex items-center gap-3">
          <div class="w-6 h-1 bg-rose-500 rounded-full" />
          System Data • بيانات النظام
        </h3>
        
        <div class="flex items-center justify-between">
          <div class="space-y-2">
            <h4 class="text-lg font-black tracking-tight">نسخ احتياطي للبيانات</h4>
            <p class="text-slate-400 text-xs font-bold max-w-sm">قم بتحميل نسخة احتياطية من كافة قواعد البيانات والجداول بصيغة ملف مضغوط للحفاظ عليها من الضياع.</p>
          </div>
          <button @click="backupData" class="px-6 py-4 bg-white/5 hover:bg-white/10 border border-white/10 rounded-2xl font-black text-sm flex items-center gap-3 transition-colors">
            <i data-lucide="download-cloud" class="w-5 h-5 text-rose-400"></i>
            تحميل النسخة
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick } from 'vue'
import { useToastStore } from '../stores/toast'

const toast = useToastStore()
const saving = ref(false)

const form = ref({
  shopName: 'مجوهرات الذهبي',
  shopAddress: 'بغداد - الكاظمية',
  shopPhone: '07700000000',
  receiptFooter: 'البضاعة المباعة لا ترد ولا تستبدل',
  autoPrint: true,
  soundAlerts: true
})

onMounted(() => {
  const saved = localStorage.getItem('kimia_settings')
  if (saved) {
    try {
      form.value = { ...form.value, ...JSON.parse(saved) }
    } catch {}
  }
  nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
})

function save() {
  saving.value = true
  try {
    localStorage.setItem('kimia_settings', JSON.stringify(form.value))
    toast.success('تم حفظ الإعدادات بنجاح')
  } catch {
    toast.error('حدث خطأ أثناء الحفظ')
  } finally {
    setTimeout(() => saving.value = false, 500)
  }
}

function backupData() {
  // Mock backup function for Kimia demo
  toast.success('جاري تجهيز ملف النسخة الاحتياطية...')
  setTimeout(() => {
    toast.success('تم تنزيل النسخة الاحتياطية')
  }, 2000)
}
</script>
