<template>
  <div class="space-y-10 max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-black text-slate-900 tracking-tight">الصندوق اليومي</h1>
        <p class="text-slate-400 font-bold mt-1 uppercase tracking-widest text-[10px]">Daily Cash Box • Ledger</p>
      </div>
      <button @click="showAdd = true" class="luxury-button">
        <i data-lucide="plus" class="w-5 h-5 stroke-[3]"></i>
        إيداع / سحب يدوي
      </button>
    </div>

    <!-- Balance + Summary Cards -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-8">
      <div class="luxury-card p-6 bg-slate-900 text-white border-none col-span-1 relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-gold-500/10 rounded-full -translate-y-1/2 translate-x-1/4 blur-3xl pointer-events-none"></div>
        <div class="relative z-10">
          <div class="text-[10px] font-black text-gold-500 uppercase tracking-widest mb-2">رصيد الصندوق الحالي</div>
          <div class="text-3xl font-black tracking-tight text-white">{{ formatPrice(dailySummary?.balance || 0) }}</div>
          <div class="text-[10px] text-slate-400 font-bold mt-1">د.ع</div>
        </div>
      </div>

      <div class="luxury-card p-6 flex items-center gap-6">
        <div class="w-14 h-14 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center shadow-inner">
          <i data-lucide="arrow-down-left" class="w-6 h-6"></i>
        </div>
        <div>
          <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">وارد اليوم</div>
          <div class="text-xl font-black text-emerald-600 tracking-tight">{{ formatPrice(dailySummary?.deposits || 0) }} <span class="text-xs opacity-30">د.ع</span></div>
        </div>
      </div>

      <div class="luxury-card p-6 flex items-center gap-6">
        <div class="w-14 h-14 rounded-2xl bg-rose-50 text-rose-600 flex items-center justify-center shadow-inner">
          <i data-lucide="arrow-up-right" class="w-6 h-6"></i>
        </div>
        <div>
          <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">صادر اليوم</div>
          <div class="text-xl font-black text-rose-600 tracking-tight">{{ formatPrice(dailySummary?.withdrawals || 0) }} <span class="text-xs opacity-30">د.ع</span></div>
        </div>
      </div>

      <div class="luxury-card p-6 flex items-center gap-6">
        <div class="w-14 h-14 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center shadow-inner">
          <i data-lucide="trending-up" class="w-6 h-6"></i>
        </div>
        <div>
          <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">صافي اليوم</div>
          <div :class="['text-xl font-black tracking-tight', (dailySummary?.net || 0) >= 0 ? 'text-emerald-600' : 'text-rose-600']">
            {{ formatPrice(Math.abs(dailySummary?.net || 0)) }} <span class="text-xs opacity-30">د.ع</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Date Filter -->
    <div class="luxury-card p-4 flex items-center gap-6 px-8 bg-white">
      <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest shrink-0">تاريخ اليوم</div>
      <input type="date" v-model="selectedDate" @change="loadDaily" class="bg-slate-50 border border-slate-100 rounded-2xl px-6 py-3 font-bold outline-none focus:ring-4 focus:ring-gold-500/5 transition-all" />
      <button @click="goToday" class="text-xs font-black text-gold-600 hover:text-gold-700 underline underline-offset-4">اليوم</button>
    </div>

    <!-- Entries Table -->
    <div class="luxury-card overflow-hidden bg-white">
      <div class="overflow-x-auto">
        <table class="w-full text-right border-collapse">
          <thead>
            <tr class="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] bg-slate-50/50">
              <th class="px-8 py-5 border-b border-slate-100">الوقت</th>
              <th class="px-8 py-5 border-b border-slate-100">النوع</th>
              <th class="px-8 py-5 border-b border-slate-100">البيان</th>
              <th class="px-8 py-5 border-b border-slate-100">المبلغ</th>
              <th class="px-8 py-5 border-b border-slate-100">الرصيد بعد</th>
              <th class="px-8 py-5 border-b border-slate-100">المرجع</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-50">
            <tr v-if="loading">
              <td colspan="6" class="px-8 py-20 text-center">
                <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-gold-500 mx-auto"></div>
              </td>
            </tr>
            <tr v-else-if="entries.length === 0">
              <td colspan="6" class="px-8 py-20 text-center text-slate-400 font-bold italic">لا توجد حركات في هذا اليوم</td>
            </tr>
            <tr v-for="e in entries" :key="e.id" class="group transition-colors hover:bg-slate-50/30">
              <td class="px-8 py-6 text-[10px] font-bold text-slate-400 whitespace-nowrap">{{ formatTime(e.created_at) }}</td>
              <td class="px-8 py-6">
                <span :class="[
                  'text-[9px] px-3 py-1 rounded-full font-black uppercase tracking-[0.1em] ring-1',
                  e.type === 'deposit' ? 'bg-emerald-100/50 text-emerald-700 ring-emerald-500/20' : 'bg-rose-100/50 text-rose-700 ring-rose-500/20'
                ]">
                  {{ e.type === 'deposit' ? 'وارد' : 'صادر' }}
                </span>
              </td>
              <td class="px-8 py-6">
                <div class="text-sm font-black text-slate-900 tracking-tight">{{ e.description }}</div>
                <div class="text-[9px] font-bold text-slate-400 mt-0.5 uppercase">{{ refTypeLabel(e.reference_type) }}</div>
              </td>
              <td class="px-8 py-6">
                <span :class="['text-sm font-black', e.type === 'deposit' ? 'text-emerald-600' : 'text-rose-600']">
                  {{ e.type === 'deposit' ? '+' : '-' }}{{ formatPrice(e.amount) }}
                </span>
              </td>
              <td class="px-8 py-6 text-sm font-black text-slate-700">{{ formatPrice(e.balance_after) }}</td>
              <td class="px-8 py-6 text-[10px] font-bold text-slate-300">{{ e.user?.name || '---' }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Add Manual Entry Modal -->
    <div v-if="showAdd" class="dialog-overlay">
      <div class="dialog-content">
        <div class="dialog-header">
          <h3 class="text-2xl font-black text-slate-900">إضافة حركة يدوية</h3>
          <button @click="showAdd = false" class="p-3 hover:bg-white rounded-full shadow-sm transition-all"><i data-lucide="x" class="w-6 h-6 text-slate-400"></i></button>
        </div>
        <div class="dialog-body">
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">نوع العملية</label>
            <div class="flex bg-slate-100/50 p-1.5 rounded-2xl">
              <button 
                @click="form.type = 'deposit'" 
                :class="['flex-1 py-3 text-xs font-black rounded-xl transition-all', form.type === 'deposit' ? 'bg-white shadow-xl text-emerald-600' : 'text-slate-400']"
              >إيداع (وارد)</button>
              <button 
                @click="form.type = 'withdrawal'" 
                :class="['flex-1 py-3 text-xs font-black rounded-xl transition-all', form.type === 'withdrawal' ? 'bg-white shadow-xl text-rose-600' : 'text-slate-400']"
              >سحب (صادر)</button>
            </div>
          </div>
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">المبلغ (د.ع)</label>
            <input v-model.number="form.amount" type="number" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-black text-2xl outline-none focus:ring-4 focus:ring-gold-500/5 transition-all" />
          </div>
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">البيان / الوصف</label>
            <input v-model="form.description" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none focus:ring-4 focus:ring-gold-500/5 transition-all" placeholder="مثال: إيداع رأس مال..." />
          </div>
        </div>
        <div class="dialog-footer">
          <button @click="showAdd = false" class="flex-1 py-4 font-black text-slate-400 hover:text-slate-600 transition-colors">إلغاء</button>
          <button @click="saveEntry" :disabled="saving" class="flex-[2] gold-gradient-bg py-4 rounded-2xl text-white font-black shadow-lg shadow-gold-500/20 hover:scale-[1.02] active:scale-95 transition-all">
            {{ saving ? 'جاري التنفيذ...' : 'تثبيت العملية' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick } from 'vue'
import api from '../api/axios'
import { useToastStore } from '../stores/toast'

const toast = useToastStore()
const entries = ref([])
const dailySummary = ref(null)
const loading = ref(true)
const saving = ref(false)
const showAdd = ref(false)
const selectedDate = ref(new Date().toISOString().split('T')[0])
const form = ref({ type: 'deposit', amount: 0, description: '' })

async function loadDaily() {
  loading.value = true
  try {
    const res = await api.get('/cash-box/daily', { params: { date: selectedDate.value } })
    dailySummary.value = res.data
    entries.value = res.data.entries || []
  } catch {
    entries.value = []
    dailySummary.value = { balance: 0, deposits: 0, withdrawals: 0, net: 0 }
  } finally {
    loading.value = false
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  }
}

function goToday() {
  selectedDate.value = new Date().toISOString().split('T')[0]
  loadDaily()
}

async function saveEntry() {
  if (!form.value.amount || !form.value.description) return toast.error('المبلغ والبيان مطلوبان')
  saving.value = true
  try {
    await api.post('/cash-box', form.value)
    toast.success('تم تسجيل العملية بنجاح')
    showAdd.value = false
    form.value = { type: 'deposit', amount: 0, description: '' }
    loadDaily()
  } catch {
    toast.error('حدث خطأ أثناء الحفظ')
  } finally { saving.value = false }
}

function refTypeLabel(t) {
  return {
    sale: 'فاتورة بيع', purchase: 'شراء', expense: 'مصروف',
    debt_payment: 'سداد دين', transfer: 'حوالة', manual: 'يدوي', opening_balance: 'رصيد افتتاحي',
  }[t] || t
}

function formatPrice(v) { return new Intl.NumberFormat('ar-IQ').format(Math.round(v)) }
function formatTime(d) { return d ? new Date(d).toLocaleTimeString('ar-IQ', { hour: '2-digit', minute: '2-digit' }) : '' }

onMounted(loadDaily)
</script>

<style scoped>
.luxury-button {
  @apply gold-gradient-bg hover:shadow-gold-500/40 text-white px-6 py-3 rounded-2xl text-sm font-black shadow-xl shadow-gold-500/20 transition-all active:scale-95 flex items-center gap-2;
}
</style>
