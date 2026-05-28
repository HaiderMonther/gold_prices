<template>
  <div class="space-y-10 max-w-7xl mx-auto">
    <!-- Luxury Pulse Bar -->
    <div class="luxury-card p-2 pr-6 flex items-center justify-between overflow-hidden relative group">
      <div class="absolute left-0 top-0 bottom-0 w-2 gold-gradient-bg" />
      <div class="flex items-center gap-6">
        <div class="w-14 h-14 bg-emerald-50 text-emerald-600 rounded-[20px] flex items-center justify-center relative shadow-inner">
          <i data-lucide="trending-up" class="w-6 h-6"></i>
          <span class="absolute -top-1 -right-1 w-4 h-4 bg-emerald-500 rounded-full border-4 border-white shadow-sm animate-pulse"></span>
        </div>
        <div class="space-y-1">
          <div class="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] leading-none">Market Pulse</div>
          <div class="text-base font-black text-slate-800 tracking-tight">سوق الذهب اليوم مستقر • <span class="text-emerald-600">تحديث لحظي</span></div>
        </div>
      </div>
      
      <div v-if="goldStore.latestPrice" class="flex items-center gap-10 pl-10 h-full">
         <div class="flex flex-col items-center gap-1">
           <span class="text-[10px] font-bold text-slate-400 uppercase">عـيار 24</span>
           <span class="text-2xl font-black text-slate-900 leading-none">{{ formatRawPrice(goldStore.latestPrice.price_24k) }} <span class="text-[10px] font-medium opacity-40">د.ع</span></span>
         </div>
         <div class="w-px h-10 bg-slate-100" />
         <div class="flex flex-col items-center gap-1">
           <span class="text-[10px] font-bold text-slate-400 uppercase">عـيار 21</span>
           <span class="text-2xl font-black text-slate-900 leading-none">{{ formatRawPrice(goldStore.latestPrice.price_21k) }} <span class="text-[10px] font-medium opacity-40">د.ع</span></span>
         </div>
      </div>
    </div>

    <!-- High-End Bento Stats -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6">
      <div v-for="stat in mainStats" :key="stat.label" class="luxury-card p-5 group cursor-pointer">
        <div class="flex items-center justify-between mb-4">
          <div :class="['w-10 h-10 rounded-2xl flex items-center justify-center shadow-inner', stat.colorClass]">
            <i :data-lucide="stat.icon" class="w-5 h-5"></i>
          </div>
          <div v-if="stat.trend" :class="['flex items-center gap-1 text-[10px] font-black px-2 py-1 rounded-lg', stat.trend.startsWith('↑') ? 'bg-emerald-50 text-emerald-600' : 'bg-rose-50 text-rose-600']">
            {{ stat.trend }}
          </div>
        </div>
        <div class="space-y-1">
          <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">{{ stat.label }}</div>
          <div class="flex items-baseline gap-1.5">
            <span class="text-xl font-black text-slate-900 tracking-tight">{{ stat.value }}</span>
            <span v-if="!stat.noUnit" class="text-xs font-bold text-slate-400">د.ع</span>
            <span v-else class="text-xs font-bold text-slate-400">{{ stat.unit }}</span>
          </div>
        </div>
        <div class="mt-3 pt-3 border-t border-slate-50 flex items-center gap-2">
          <div class="w-1.5 h-1.5 rounded-full bg-slate-200 group-hover:bg-gold-400 transition-colors" />
          <div class="text-[10px] font-medium text-slate-400">{{ stat.sub }}</div>
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-5 gap-10 mt-8">
      <!-- Activity Feed - Luxury Style -->
      <div class="lg:col-span-3 luxury-card overflow-hidden flex flex-col bg-white">
        <div class="p-8 border-b border-slate-50 flex items-center justify-between">
          <div class="flex items-center gap-3">
             <div class="w-1.5 h-6 bg-gold-400 rounded-full" />
             <h3 class="font-black text-slate-900 tracking-tight">آخر الفواتير</h3>
          </div>
          <div class="flex items-center gap-4">
            <button @click="resetSystem" class="text-[10px] font-black text-rose-500 hover:text-rose-600 transition-colors">تصفير النظام</button>
            <router-link to="/invoices" class="text-xs font-black text-gold-600 hover:text-gold-700 underline underline-offset-4 decoration-gold-200">عرض الكل</router-link>
          </div>
        </div>
        <div class="flex-1 divide-y divide-slate-50">
          <div 
            v-for="inv in recentInvoices" 
            :key="inv.id"
            class="flex gap-6 p-6 items-center cursor-default hover:bg-slate-50/50 transition-all"
          >
            <div class="w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 bg-emerald-50 text-emerald-600 shadow-sm">
               <i data-lucide="shopping-cart" class="w-5 h-5"></i>
            </div>
            <div class="flex-1">
              <div class="text-sm font-black text-slate-900 tracking-tight">فاتورة بيع #{{ inv.invoice_number }}</div>
              <div class="text-[10px] font-bold text-slate-400 mt-1 uppercase tracking-wider">
                {{ formatDate(inv.created_at) }} • العميل: <span class="text-slate-600">{{ inv.customer?.name || 'نقدي' }}</span>
              </div>
            </div>
            <div class="text-right">
               <div class="text-sm font-black text-slate-900">{{ formatRawPrice(inv.total_amount) }} <span class="text-[9px] font-bold opacity-30">د.ع</span></div>
               <div class="text-[9px] font-bold text-slate-400 uppercase mt-1">القيمة الإجمالية</div>
            </div>
          </div>
          <div v-if="recentInvoices.length === 0" class="p-12 text-center text-slate-400">
            لا توجد فواتير حديثة
          </div>
        </div>
      </div>

      <!-- Quick Market Monitor - Premium -->
      <div class="lg:col-span-2 luxury-card p-8 bg-slate-900 text-white relative overflow-hidden group" style="background-color: #0f172a;">
        <div class="absolute top-0 right-0 w-64 h-64 bg-gold-500/10 rounded-full -translate-y-1/2 translate-x-1/4 blur-3xl pointer-events-none" />
        <div class="relative z-10 space-y-8">
          <div class="flex items-center justify-between">
            <h3 class="font-black text-gold-500 tracking-tight text-lg">مؤشرات السوق</h3>
            <div class="flex items-center gap-2 bg-white/10 px-3 py-1.5 rounded-xl border border-white/10 backdrop-blur-md">
               <div class="w-1.5 h-1.5 bg-emerald-400 rounded-full animate-pulse" />
               <span class="text-[10px] font-black uppercase">Live Update</span>
            </div>
          </div>
          
          <div class="space-y-3">
            <div v-for="k in ['24', '21', '18']" :key="k" class="flex items-center justify-between p-4 bg-white/5 rounded-[18px] border border-white/5 hover:bg-white/10 transition-colors">
              <span class="text-xs text-slate-400 font-bold">عيار {{ k }}</span>
              <span class="text-xl font-black text-white leading-none tracking-tight">
                {{ formatRawPrice(goldStore.latestPrice ? goldStore.latestPrice['price_' + k + 'k'] : 0) }} 
                <span class="text-[10px] font-normal opacity-40">د.ع</span>
              </span>
            </div>
          </div>

          <!-- Quick Links -->
          <div class="space-y-2 pt-4 border-t border-white/5">
            <router-link to="/account-statement" class="flex items-center justify-between p-3 bg-white/5 rounded-xl hover:bg-white/10 transition-colors group/link">
              <span class="text-xs font-bold text-slate-400">كشف الحساب</span>
              <i data-lucide="chevron-left" class="w-4 h-4 text-gold-500 group-hover/link:-translate-x-1 transition-transform"></i>
            </router-link>
            <router-link to="/cash-box" class="flex items-center justify-between p-3 bg-white/5 rounded-xl hover:bg-white/10 transition-colors group/link">
              <span class="text-xs font-bold text-slate-400">الصندوق اليومي</span>
              <i data-lucide="chevron-left" class="w-4 h-4 text-gold-500 group-hover/link:-translate-x-1 transition-transform"></i>
            </router-link>
            <router-link to="/reports" class="flex items-center justify-between p-3 bg-white/5 rounded-xl hover:bg-white/10 transition-colors group/link">
              <span class="text-xs font-bold text-slate-400">التقارير التحليلية</span>
              <i data-lucide="chevron-left" class="w-4 h-4 text-gold-500 group-hover/link:-translate-x-1 transition-transform"></i>
            </router-link>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import api from '../api/axios'
import { useGoldStore } from '../stores/gold'

const goldStore = useGoldStore()
const stats = ref({})
const recentInvoices = ref([])
const cashBoxBalance = ref(0)
const inventoryLoaded = ref(false)

onMounted(async () => {
  try {
    const [statsRes, invoicesRes] = await Promise.all([
      api.get('/reports/dashboard'),
      api.get('/invoices'),
    ])
    stats.value = statsRes.data
    recentInvoices.value = invoicesRes.data.slice(0, 4)

    // Load cash box balance
    try {
      cashBoxBalance.value = (await api.get('/cash-box/balance')).data
    } catch { cashBoxBalance.value = 0 }
  } finally {
    inventoryLoaded.value = true
    nextTick(() => {
      if (window.refreshIcons) window.refreshIcons()
    })
  }
})

async function resetSystem() {
  if (!confirm('هل أنت متأكد من حذف جميع البيانات؟ لا يمكن التراجع عن هذه العملية.')) return
  try {
    await api.post('/reports/reset')
    window.location.reload()
  } catch {
    alert('فشل تصفير النظام')
  }
}

const mainStats = computed(() => [
  {
    label: 'مبيعات اليوم',
    value: formatRawPrice(stats.value.today?.total || 0),
    sub: `${stats.value.today?.count || 0} فواتير تم إصدارها اليوم`,
    icon: 'shopping-cart',
    colorClass: 'bg-gold-50 text-gold-600'
  },
  {
    label: 'أرباح المصنعية',
    value: formatRawPrice(stats.value.profit?.total || 0),
    sub: 'إجمالي أرباح الصياغة',
    icon: 'bar-chart-3',
    colorClass: 'bg-emerald-50 text-emerald-600',
    trend: '↑ حقيقي'
  },
  {
    label: 'رصيد الصندوق',
    value: formatRawPrice(cashBoxBalance.value || 0),
    sub: 'الرصيد النقدي الحالي',
    icon: 'wallet',
    colorClass: 'bg-blue-50 text-blue-600'
  },
  {
    label: 'إجمالي الوزن',
    value: availableWeight.value,
    noUnit: true,
    unit: 'غرام',
    sub: 'ذهب متاح في الخزنة',
    icon: 'package',
    colorClass: 'bg-indigo-50 text-indigo-600'
  },
  {
    label: 'ذمم مدينة',
    value: formatRawPrice(stats.value.debts?.total || 0),
    sub: `${stats.value.debts?.count || 0} ذمة بانتظار التحصيل`,
    icon: 'banknote',
    colorClass: 'bg-rose-50 text-rose-600'
  }
])

const availableWeight = computed(() => {
  const row = stats.value?.inventory?.find(i => i.status === 'available')
  return row ? parseFloat(row.total_weight || 0).toLocaleString('ar-IQ', { minimumFractionDigits: 2 }) : '0.00'
})

function formatRawPrice(v) {
  return new Intl.NumberFormat('ar-IQ').format(Math.round(v))
}

function formatDate(d) {
  return d ? new Date(d).toLocaleDateString('ar-IQ', { month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : ''
}
</script>
