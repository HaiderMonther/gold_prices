<template>
  <div class="space-y-10 max-w-7xl mx-auto">
    <!-- Header -->
    <div>
      <h1 class="text-3xl font-black text-slate-900 tracking-tight">التقارير التحليلية</h1>
      <p class="text-slate-400 font-bold mt-1 uppercase tracking-widest text-[10px]">Analytics • Advanced Reports</p>
    </div>

    <!-- Report Tabs -->
    <div class="luxury-card p-2 flex gap-1 bg-white overflow-x-auto">
      <button 
        v-for="tab in tabs" :key="tab.id"
        @click="activeTab = tab.id"
        :class="[
          'px-5 py-3 text-xs font-black rounded-xl transition-all whitespace-nowrap flex items-center gap-2',
          activeTab === tab.id ? 'bg-gold-50 text-gold-600 shadow-sm' : 'text-slate-400 hover:text-slate-600 hover:bg-slate-50'
        ]"
      >
        <i :data-lucide="tab.icon" class="w-4 h-4"></i>
        {{ tab.label }}
      </button>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex justify-center py-20">
      <div class="animate-spin rounded-full h-10 w-10 border-b-2 border-gold-500"></div>
    </div>

    <!-- ============ Daily Trading ============ -->
    <template v-if="activeTab === 'daily' && !loading">
      <div class="luxury-card p-4 flex items-center gap-6 px-8 bg-white">
        <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest shrink-0">التاريخ</div>
        <input type="date" v-model="dailyDate" @change="loadDailyTrading" class="bg-slate-50 border border-slate-100 rounded-2xl px-6 py-3 font-bold outline-none" />
      </div>

      <div v-if="dailyData" class="grid grid-cols-1 md:grid-cols-3 gap-8">
        <div class="luxury-card p-6 flex items-center gap-6">
          <div class="w-14 h-14 rounded-2xl bg-gold-50 text-gold-600 flex items-center justify-center shadow-inner"><i data-lucide="shopping-cart" class="w-6 h-6"></i></div>
          <div>
            <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">مبيعات اليوم</div>
            <div class="text-xl font-black text-slate-900">{{ formatPrice(dailyData.sales.total) }} <span class="text-xs opacity-30">د.ع</span></div>
            <div class="text-[9px] text-slate-400 font-bold">{{ dailyData.sales.count }} فاتورة • {{ dailyData.sales.weight.toFixed(2) }} غرام</div>
          </div>
        </div>
        <div class="luxury-card p-6 flex items-center gap-6">
          <div class="w-14 h-14 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center shadow-inner"><i data-lucide="coins" class="w-6 h-6"></i></div>
          <div>
            <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">مشتريات اليوم</div>
            <div class="text-xl font-black text-slate-900">{{ formatPrice(dailyData.purchases.total) }} <span class="text-xs opacity-30">د.ع</span></div>
            <div class="text-[9px] text-slate-400 font-bold">{{ dailyData.purchases.count }} عملية • {{ dailyData.purchases.weight.toFixed(2) }} غرام</div>
          </div>
        </div>
        <div class="luxury-card p-6 bg-slate-900 text-white border-none">
          <div class="text-[10px] font-black text-gold-500 uppercase tracking-widest mb-1">صافي النقد</div>
          <div :class="['text-2xl font-black tracking-tight', dailyData.netCash >= 0 ? 'text-emerald-400' : 'text-rose-400']">
            {{ formatPrice(Math.abs(dailyData.netCash)) }} <span class="text-xs opacity-40">د.ع</span>
          </div>
          <div class="text-[9px] font-bold text-slate-400 mt-1">مصروفات: {{ formatPrice(dailyData.expenses.total) }}</div>
        </div>
      </div>
    </template>

    <!-- ============ Inventory Summary ============ -->
    <template v-if="activeTab === 'inventory' && !loading">
      <div v-if="inventoryData" class="space-y-8">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div class="luxury-card p-8 bg-white">
            <h3 class="text-sm font-black text-slate-900 mb-6 flex items-center gap-3">
              <div class="w-6 h-1 bg-gold-400 rounded-full"></div>
              الموجود حسب العيار
            </h3>
            <div class="space-y-4">
              <div v-for="k in inventoryData.byKarat" :key="k.karat" class="flex items-center justify-between p-5 bg-slate-50 rounded-2xl border border-slate-100">
                <div class="flex items-center gap-4">
                  <span class="text-[10px] font-black text-slate-500 bg-white px-3 py-1.5 rounded-lg border border-slate-100">K{{ k.karat }}</span>
                  <span class="text-xs font-bold text-slate-400">{{ k.count }} قطعة</span>
                </div>
                <span class="text-lg font-black text-gold-600">{{ parseFloat(k.total_weight).toFixed(2) }} <span class="text-[10px] opacity-50">غرام</span></span>
              </div>
              <div v-if="inventoryData.byKarat.length === 0" class="text-center py-8 text-slate-400 text-sm font-bold italic">لا توجد قطع متاحة</div>
            </div>
          </div>
          <div class="luxury-card p-8 bg-slate-900 text-white border-none relative overflow-hidden">
            <div class="absolute top-0 right-0 w-64 h-64 bg-gold-500/10 rounded-full -translate-y-1/2 translate-x-1/4 blur-3xl pointer-events-none"></div>
            <div class="relative z-10">
              <h3 class="text-sm font-black text-gold-500 mb-6">إجمالي الخزنة</h3>
              <div class="text-5xl font-black tracking-tight mb-2">{{ parseFloat(inventoryData.totals?.total_weight || 0).toFixed(2) }}</div>
              <div class="text-sm font-bold text-slate-400">غرام ذهب متاح</div>
              <div class="text-sm font-bold text-slate-500 mt-4">{{ inventoryData.totals?.count || 0 }} قطعة إجمالي</div>
            </div>
          </div>
        </div>
      </div>
    </template>

    <!-- ============ Sales vs Purchases ============ -->
    <template v-if="activeTab === 'balance' && !loading">
      <div class="luxury-card p-4 flex items-center gap-6 px-8 bg-white">
        <input type="date" v-model="balanceDateFrom" class="bg-slate-50 border border-slate-100 rounded-2xl px-6 py-3 font-bold outline-none" />
        <span class="text-sm text-slate-400 font-bold">→</span>
        <input type="date" v-model="balanceDateTo" class="bg-slate-50 border border-slate-100 rounded-2xl px-6 py-3 font-bold outline-none" />
        <button @click="loadBalance" class="bg-gold-50 text-gold-600 px-5 py-3 rounded-xl text-xs font-black">تحديث</button>
      </div>
      <div v-if="balanceData" class="grid grid-cols-1 md:grid-cols-2 gap-8">
        <div class="luxury-card p-8 bg-white space-y-6">
          <h3 class="text-sm font-black text-emerald-600 flex items-center gap-3"><div class="w-6 h-1 bg-emerald-400 rounded-full"></div>المبيعات</h3>
          <div class="grid grid-cols-2 gap-4">
            <div class="p-4 bg-emerald-50 rounded-2xl"><div class="text-[9px] font-black text-emerald-400 uppercase mb-1">المبلغ</div><div class="text-lg font-black text-emerald-600">{{ formatPrice(balanceData.sales.totalAmount) }}</div></div>
            <div class="p-4 bg-emerald-50 rounded-2xl"><div class="text-[9px] font-black text-emerald-400 uppercase mb-1">الوزن</div><div class="text-lg font-black text-emerald-600">{{ balanceData.sales.totalWeight.toFixed(2) }} غ</div></div>
            <div class="p-4 bg-gold-50 rounded-2xl"><div class="text-[9px] font-black text-gold-400 uppercase mb-1">أجور الصياغة</div><div class="text-lg font-black text-gold-600">{{ formatPrice(balanceData.sales.totalCraft) }}</div></div>
            <div class="p-4 bg-slate-50 rounded-2xl"><div class="text-[9px] font-black text-slate-400 uppercase mb-1">الفواتير</div><div class="text-lg font-black text-slate-700">{{ balanceData.sales.count }}</div></div>
          </div>
        </div>
        <div class="luxury-card p-8 bg-white space-y-6">
          <h3 class="text-sm font-black text-indigo-600 flex items-center gap-3"><div class="w-6 h-1 bg-indigo-400 rounded-full"></div>المشتريات</h3>
          <div class="grid grid-cols-2 gap-4">
            <div class="p-4 bg-indigo-50 rounded-2xl"><div class="text-[9px] font-black text-indigo-400 uppercase mb-1">المبلغ</div><div class="text-lg font-black text-indigo-600">{{ formatPrice(balanceData.purchases.totalAmount) }}</div></div>
            <div class="p-4 bg-indigo-50 rounded-2xl"><div class="text-[9px] font-black text-indigo-400 uppercase mb-1">الوزن</div><div class="text-lg font-black text-indigo-600">{{ balanceData.purchases.totalWeight.toFixed(2) }} غ</div></div>
            <div class="p-4 bg-slate-50 rounded-2xl col-span-2"><div class="text-[9px] font-black text-slate-400 uppercase mb-1">العمليات</div><div class="text-lg font-black text-slate-700">{{ balanceData.purchases.count }}</div></div>
          </div>
        </div>
      </div>
    </template>

    <!-- ============ Profit Report ============ -->
    <template v-if="activeTab === 'profit' && !loading">
      <div v-if="profitData" class="grid grid-cols-1 md:grid-cols-3 gap-8">
        <div class="luxury-card p-6 flex items-center gap-6">
          <div class="w-14 h-14 rounded-2xl bg-gold-50 text-gold-600 flex items-center justify-center shadow-inner"><i data-lucide="coins" class="w-6 h-6"></i></div>
          <div>
            <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">أرباح المصنعية</div>
            <div class="text-xl font-black text-gold-600">{{ formatPrice(profitData.craftProfit) }} <span class="text-xs opacity-30">د.ع</span></div>
          </div>
        </div>
        <div class="luxury-card p-6 flex items-center gap-6">
          <div class="w-14 h-14 rounded-2xl bg-rose-50 text-rose-600 flex items-center justify-center shadow-inner"><i data-lucide="receipt" class="w-6 h-6"></i></div>
          <div>
            <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">إجمالي المصروفات</div>
            <div class="text-xl font-black text-rose-600">{{ formatPrice(profitData.totalExpenses) }} <span class="text-xs opacity-30">د.ع</span></div>
          </div>
        </div>
        <div class="luxury-card p-6 bg-slate-900 text-white border-none">
          <div class="text-[10px] font-black text-gold-500 uppercase tracking-widest mb-1">صافي الربح</div>
          <div :class="['text-2xl font-black tracking-tight', profitData.netProfit >= 0 ? 'text-emerald-400' : 'text-rose-400']">
            {{ formatPrice(Math.abs(profitData.netProfit)) }} <span class="text-xs opacity-40">د.ع</span>
          </div>
          <div class="text-[9px] font-bold text-slate-500 mt-1">{{ profitData.invoiceCount }} فاتورة مبيعات</div>
        </div>
      </div>
    </template>

    <!-- ============ Debt Report ============ -->
    <template v-if="activeTab === 'debts' && !loading">
      <div v-if="debtData" class="space-y-8">
        <div class="luxury-card p-6 bg-rose-50 border-rose-200 flex items-center justify-between">
          <div class="flex items-center gap-4">
            <div class="w-14 h-14 rounded-2xl bg-rose-100 text-rose-600 flex items-center justify-center"><i data-lucide="alert-circle" class="w-6 h-6"></i></div>
            <div>
              <div class="text-[10px] font-black text-rose-400 uppercase tracking-widest">إجمالي الديون المتبقية</div>
              <div class="text-2xl font-black text-rose-600">{{ formatPrice(debtData.totalRemaining) }} <span class="text-xs opacity-30">د.ع</span></div>
            </div>
          </div>
          <div class="text-sm font-black text-rose-400">{{ debtData.totalCount }} ذمة</div>
        </div>

        <div v-for="group in debtData.groups" :key="group.customer?.id" class="luxury-card p-8 bg-white space-y-4">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-4">
              <div class="w-10 h-10 rounded-xl bg-gold-50 text-gold-700 flex items-center justify-center font-black text-xs border border-gold-100/50">{{ group.customer?.name?.slice(0, 2) }}</div>
              <div>
                <div class="font-black text-slate-900">{{ group.customer?.name }}</div>
                <div class="text-[10px] text-slate-400 font-bold">{{ group.debts.length }} ذمة مفتوحة</div>
              </div>
            </div>
            <div class="text-xl font-black text-rose-600">{{ formatPrice(group.remaining) }} <span class="text-xs opacity-30">د.ع</span></div>
          </div>
          <div class="space-y-2">
            <div v-for="d in group.debts" :key="d.id" class="flex items-center justify-between bg-slate-50 p-4 rounded-2xl text-sm">
              <div class="text-slate-600 font-bold">{{ d.invoice?.invoice_number || 'بدون فاتورة' }}</div>
              <div class="flex items-center gap-6">
                <span class="text-rose-500 font-black">{{ formatPrice(parseFloat(d.amount) - parseFloat(d.paid_amount)) }}</span>
                <span class="text-[10px] text-slate-400">{{ formatDate(d.created_at) }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, watch, onMounted, nextTick } from 'vue'
import api from '../api/axios'
import { useToastStore } from '../stores/toast'

const toast = useToastStore()
const activeTab = ref('daily')
const loading = ref(false)

// Tab definitions
const tabs = [
  { id: 'daily', label: 'التداول اليومي', icon: 'calendar' },
  { id: 'inventory', label: 'ملخص الموجود', icon: 'package' },
  { id: 'balance', label: 'موازنة بيع/شراء', icon: 'scale' },
  { id: 'profit', label: 'تقرير الأرباح', icon: 'trending-up' },
  { id: 'debts', label: 'تقرير الديون', icon: 'alert-circle' },
]

// Data
const dailyDate = ref(new Date().toISOString().split('T')[0])
const dailyData = ref(null)
const inventoryData = ref(null)
const balanceDateFrom = ref('')
const balanceDateTo = ref('')
const balanceData = ref(null)
const profitData = ref(null)
const debtData = ref(null)

watch(activeTab, () => {
  loadCurrentTab()
  nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
})

onMounted(() => { loadCurrentTab() })

async function loadCurrentTab() {
  loading.value = true
  try {
    switch (activeTab.value) {
      case 'daily': await loadDailyTrading(); break
      case 'inventory': await loadInventory(); break
      case 'balance': await loadBalance(); break
      case 'profit': await loadProfit(); break
      case 'debts': await loadDebts(); break
    }
  } catch {
    toast.error('حدث خطأ في تحميل التقرير')
  } finally {
    loading.value = false
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  }
}

async function loadDailyTrading() {
  dailyData.value = (await api.get('/reports/daily-trading', { params: { date: dailyDate.value } })).data
}

async function loadInventory() {
  inventoryData.value = (await api.get('/reports/inventory-summary')).data
}

async function loadBalance() {
  const params = {}
  if (balanceDateFrom.value) params.dateFrom = balanceDateFrom.value
  if (balanceDateTo.value) params.dateTo = balanceDateTo.value
  balanceData.value = (await api.get('/reports/sales-vs-purchases', { params })).data
}

async function loadProfit() {
  profitData.value = (await api.get('/reports/profit')).data
}

async function loadDebts() {
  debtData.value = (await api.get('/reports/debts')).data
}

function formatPrice(v) { return new Intl.NumberFormat('ar-IQ').format(Math.round(v)) }
function formatDate(d) { return d ? new Date(d).toLocaleDateString('ar-IQ', { month: 'short', day: 'numeric' }) : '' }
</script>
