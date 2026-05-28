<template>
  <div class="space-y-10 max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-black text-slate-900 tracking-tight">سجل الديون</h1>
        <p class="text-slate-400 font-bold mt-1 uppercase tracking-widest text-[10px]">Ledger • Outstanding Debts</p>
      </div>
      <div class="flex items-center gap-4 bg-white p-2 rounded-2xl border border-slate-100 shadow-sm">
        <button 
          @click="showUnpaidOnly = false"
          :class="['px-5 py-2 text-xs font-black rounded-xl transition-all', !showUnpaidOnly ? 'bg-gold-50 text-gold-600' : 'text-slate-400']"
        >
          الكل
        </button>
        <button 
          @click="showUnpaidOnly = true"
          :class="['px-5 py-2 text-xs font-black rounded-xl transition-all', showUnpaidOnly ? 'bg-rose-50 text-rose-600' : 'text-slate-400']"
        >
          غير المدفوعة
        </button>
      </div>
    </div>

    <!-- Debt Stats -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
      <div class="luxury-card p-6 flex items-center gap-6 border-rose-100">
        <div class="w-14 h-14 rounded-2xl bg-rose-50 text-rose-600 flex items-center justify-center shadow-inner">
          <i data-lucide="alert-circle" class="w-6 h-6"></i>
        </div>
        <div>
          <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">إجمالي الديون</div>
          <div class="text-xl font-black text-slate-900 tracking-tight">{{ formatRawPrice(totalDebts) }} <span class="text-xs opacity-30">د.ع</span></div>
        </div>
      </div>
      
      <div class="luxury-card p-6 flex items-center gap-6 border-emerald-100">
        <div class="w-14 h-14 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center shadow-inner">
          <i data-lucide="check-circle" class="w-6 h-6"></i>
        </div>
        <div>
          <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">المبالغ المحصلة</div>
          <div class="text-xl font-black text-slate-900 tracking-tight">{{ formatRawPrice(totalPaid) }} <span class="text-xs opacity-30">د.ع</span></div>
        </div>
      </div>

      <div class="luxury-card p-6 bg-slate-900 text-white border-none shadow-xl shadow-rose-900/10">
        <div class="text-[10px] font-black text-gold-500 uppercase tracking-widest mb-1">صافي المتبقي</div>
        <div class="text-xl font-black tracking-tight text-gold-400">{{ formatRawPrice(totalRemaining) }} <span class="text-xs opacity-40">د.ع</span></div>
      </div>
    </div>

    <!-- Debts Table -->
    <div class="luxury-card overflow-hidden bg-white">
      <div class="overflow-x-auto">
        <table class="w-full text-right border-collapse">
          <thead>
            <tr class="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] bg-slate-50/50">
              <th class="px-8 py-5 border-b border-slate-100">العميل</th>
              <th class="px-8 py-5 border-b border-slate-100">مبلغ الدين</th>
              <th class="px-8 py-5 border-b border-slate-100">المدفوع</th>
              <th class="px-8 py-5 border-b border-slate-100">المتبقي</th>
              <th class="px-8 py-5 border-b border-slate-100 text-center">الحالة</th>
              <th class="px-8 py-5 border-b border-slate-100">رقم الفاتورة</th>
              <th class="px-8 py-5 border-b border-slate-100">التاريخ</th>
              <th class="px-8 py-5 border-b border-slate-100">تحكم</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-50">
            <tr v-if="loading">
              <td colspan="8" class="px-8 py-20 text-center">
                <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-gold-500 mx-auto"></div>
              </td>
            </tr>
            <tr v-else-if="filtered.length === 0" class="px-8 py-20 text-center text-slate-400 font-bold italic">
              <td colspan="8">لا توجد ديون مسجلة حالياً</td>
            </tr>
            <tr 
              v-for="d in filtered" 
              :key="d.id" 
              class="group transition-colors hover:bg-slate-50/30"
            >
              <td class="px-8 py-6">
                <div class="font-black text-slate-900 text-sm tracking-tight">{{ d.customer?.name }}</div>
              </td>
              <td class="px-8 py-6 text-sm font-black text-rose-600">{{ formatRawPrice(d.amount) }}</td>
              <td class="px-8 py-6 text-sm font-bold text-emerald-600">{{ formatRawPrice(d.paid_amount) }}</td>
              <td class="px-8 py-6">
                <div :class="['text-sm font-black', (parseFloat(d.amount)-parseFloat(d.paid_amount)) > 0 ? 'text-gold-600' : 'text-slate-400']">
                  {{ formatRawPrice(parseFloat(d.amount) - parseFloat(d.paid_amount)) }}
                </div>
              </td>
              <td class="px-8 py-6 text-center">
                <span :class="[
                  'text-[9px] px-3 py-1 rounded-full font-black uppercase tracking-[0.1em] ring-1',
                  d.is_paid ? 'bg-emerald-100/50 text-emerald-700 ring-emerald-500/20' : 'bg-rose-100/50 text-rose-700 ring-rose-500/20'
                ]">
                  {{ d.is_paid ? 'مدفوع' : 'غير مدفوع' }}
                </span>
              </td>
              <td class="px-8 py-6 text-xs text-slate-400 font-black tracking-tighter">{{ d.invoice?.invoice_number || '---' }}</td>
              <td class="px-8 py-6 text-[10px] font-bold text-slate-400 uppercase">{{ formatDate(d.created_at) }}</td>
              <td class="px-8 py-6">
                <button 
                  v-if="!d.is_paid" 
                  @click="payDebt(d)"
                  class="bg-slate-900 text-white text-[10px] font-black px-4 py-2 rounded-xl shadow-lg shadow-slate-900/10 hover:scale-105 active:scale-95 transition-all"
                >
                  سداد الآن
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Payment Modal -->
    <div v-if="payingDebt" class="dialog-overlay">
      <div class="dialog-content">
        <div class="dialog-header">
          <h3 class="text-2xl font-black text-slate-900">تسديد دفعة من الدين</h3>
          <button @click="payingDebt = null" class="p-3 hover:bg-white rounded-full shadow-sm transition-all"><i data-lucide="x" class="w-6 h-6 text-slate-400"></i></button>
        </div>
        <div class="dialog-body">
          <div class="flex items-center gap-4 bg-slate-50 p-6 rounded-3xl border border-slate-100">
             <div class="w-12 h-12 rounded-2xl bg-white flex items-center justify-center text-gold-600 shadow-sm">
                <i data-lucide="user" class="w-6 h-6"></i>
             </div>
             <div>
               <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">العميل المستحق</div>
               <div class="text-lg font-black text-slate-900">{{ payingDebt.customer?.name }}</div>
             </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
             <div class="p-5 bg-rose-50 rounded-2xl border border-rose-100/50">
                <div class="text-[9px] font-black text-rose-400 uppercase tracking-widest mb-1">المتبقي المطلوب</div>
                <div class="text-xl font-black text-rose-600">{{ formatRawPrice(parseFloat(payingDebt.amount) - parseFloat(payingDebt.paid_amount)) }}</div>
             </div>
             <div class="p-5 bg-emerald-50 rounded-2xl border border-emerald-100/50">
                <div class="text-[9px] font-black text-emerald-400 uppercase tracking-widest mb-1">إجمالي ما دفعه</div>
                <div class="text-xl font-black text-emerald-600">{{ formatRawPrice(payingDebt.paid_amount) }}</div>
             </div>
          </div>

          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">مبلغ التحصيل (د.ع)</label>
            <div class="relative group">
              <i data-lucide="banknote" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-emerald-500 transition-colors w-6 h-6"></i>
              <input v-model.number="payAmount" type="number" class="w-full bg-slate-50 border border-slate-100 rounded-2xl pr-14 pl-4 py-5 text-2xl font-black text-slate-900 outline-none focus:ring-4 focus:ring-emerald-500/5 transition-all" :max="parseFloat(payingDebt.amount)-parseFloat(payingDebt.paid_amount)" />
            </div>
          </div>
        </div>
        <div class="dialog-footer">
          <button @click="payingDebt = null" class="flex-1 py-4 font-black text-slate-400 hover:text-slate-600 transition-colors">إلغاء</button>
          <button @click="confirmPay" :disabled="saving" class="flex-[2] gold-gradient-bg py-4 rounded-2xl text-white font-black shadow-lg shadow-gold-500/20 hover:scale-[1.02] active:scale-95 transition-all">
            {{ saving ? 'جاري التنفيذ...' : 'تأكيد عملية السداد' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import api from '../api/axios'
import { useToastStore } from '../stores/toast'

const toast = useToastStore()
const debts = ref([])
const loading = ref(true)
const saving = ref(false)
const showUnpaidOnly = ref(false)
const payingDebt = ref(null)
const payAmount = ref(0)

async function load() {
  loading.value = true
  try { 
    const res = await api.get('/debts')
    debts.value = res.data 
  } finally { 
    loading.value = false 
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  }
}

const filtered = computed(() => debts.value.filter(d => !showUnpaidOnly.value || !d.is_paid))
const totalDebts = computed(() => debts.value.reduce((s, d) => s + parseFloat(d.amount), 0))
const totalPaid = computed(() => debts.value.reduce((s, d) => s + parseFloat(d.paid_amount), 0))
const totalRemaining = computed(() => totalDebts.value - totalPaid.value)

function payDebt(d) { 
  payingDebt.value = d
  payAmount.value = parseFloat(d.amount) - parseFloat(d.paid_amount)
  nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
}

async function confirmPay() {
  if (!payAmount.value || payAmount.value <= 0) return
  saving.value = true
  try {
    await api.post(`/debts/${payingDebt.value.id}/pay`, { amount: payAmount.value })
    toast.success('تم تسجيل عملية الدفع بنجاح')
    payingDebt.value = null; 
    load()
  } catch { 
    toast.error('حدث خطأ أثناء معالجة الدفع') 
  } finally { 
    saving.value = false 
  }
}

function formatRawPrice(v) { return new Intl.NumberFormat('ar-IQ').format(Math.round(v)) }
function formatDate(d) { return d ? new Date(d).toLocaleDateString('ar-IQ', { month: 'short', day: 'numeric' }) : '' }
onMounted(load)
</script>
