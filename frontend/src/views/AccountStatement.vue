<template>
  <div class="space-y-10 max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-black text-slate-900 tracking-tight">كشف الحساب</h1>
        <p class="text-slate-400 font-bold mt-1 uppercase tracking-widest text-[10px]">Account Statement • Kimia Style</p>
      </div>
      <button v-if="statement" @click="printStatement" class="luxury-button">
        <i data-lucide="printer" class="w-5 h-5 stroke-[3]"></i>
        طباعة الكشف
      </button>
    </div>

    <!-- Filters -->
    <div class="luxury-card p-8 bg-white">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-8 items-end">
        <div class="space-y-2">
          <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">اختر العميل / التاجر</label>
          <div class="relative group">
            <i data-lucide="user" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-gold-500 transition-colors w-5 h-5"></i>
            <select 
              v-model="selectedCustomerId"
              class="w-full bg-slate-50 border border-slate-100 rounded-2xl pr-12 pl-10 py-4 font-bold outline-none focus:ring-4 focus:ring-gold-500/5 transition-all appearance-none cursor-pointer"
            >
              <option value="">-- اختر الحساب --</option>
              <option v-for="c in customers" :key="c.id" :value="c.id">
                {{ c.name }} {{ c.type === 'trader' ? '(تاجر)' : c.type === 'workshop' ? '(ورشة)' : '' }}
              </option>
            </select>
            <i data-lucide="chevron-down" class="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300 pointer-events-none w-[18px] h-[18px]"></i>
          </div>
        </div>
        <div class="space-y-2">
          <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">من تاريخ</label>
          <input type="date" v-model="dateFrom" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none focus:ring-4 focus:ring-gold-500/5 transition-all" />
        </div>
        <div class="space-y-2">
          <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">إلى تاريخ</label>
          <input type="date" v-model="dateTo" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none focus:ring-4 focus:ring-gold-500/5 transition-all" />
        </div>
        <button 
          @click="loadStatement" 
          :disabled="!selectedCustomerId || loading"
          class="gold-gradient-bg text-white py-4 rounded-2xl font-black shadow-xl shadow-gold-500/20 hover:scale-[1.02] active:scale-95 transition-all disabled:opacity-50 flex items-center justify-center gap-2"
        >
          <i data-lucide="search" class="w-5 h-5"></i>
          عرض الكشف
        </button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex justify-center py-20">
      <div class="animate-spin rounded-full h-10 w-10 border-b-2 border-gold-500"></div>
    </div>

    <!-- Statement Results -->
    <template v-if="statement && !loading">
      <!-- Customer Info + Summary -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-8">
        <div class="luxury-card p-6 bg-slate-900 text-white border-none col-span-1">
          <div class="flex items-center gap-4 mb-4">
            <div class="w-14 h-14 rounded-2xl bg-white/10 flex items-center justify-center text-gold-400">
              <i data-lucide="user-circle" class="w-7 h-7"></i>
            </div>
            <div>
              <div class="text-lg font-black">{{ statement.customer.name }}</div>
              <div class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">
                {{ customerTypeLabel(statement.customer.type) }}
              </div>
            </div>
          </div>
          <div class="text-[10px] text-slate-500 font-bold" v-if="statement.customer.phone" dir="ltr">
            {{ statement.customer.phone }}
          </div>
        </div>

        <div class="luxury-card p-6 flex items-center gap-6">
          <div class="w-14 h-14 rounded-2xl bg-rose-50 text-rose-600 flex items-center justify-center shadow-inner">
            <i data-lucide="arrow-up-right" class="w-6 h-6"></i>
          </div>
          <div>
            <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">إجمالي المدين (عليه)</div>
            <div class="text-xl font-black text-rose-600 tracking-tight">{{ formatPrice(statement.summary.totalDebit) }} <span class="text-xs opacity-30">د.ع</span></div>
          </div>
        </div>

        <div class="luxury-card p-6 flex items-center gap-6">
          <div class="w-14 h-14 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center shadow-inner">
            <i data-lucide="arrow-down-left" class="w-6 h-6"></i>
          </div>
          <div>
            <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">إجمالي الدائن (له)</div>
            <div class="text-xl font-black text-emerald-600 tracking-tight">{{ formatPrice(statement.summary.totalCredit) }} <span class="text-xs opacity-30">د.ع</span></div>
          </div>
        </div>

        <div class="luxury-card p-6 flex items-center gap-6 border-2" :class="statement.summary.netBalance > 0 ? 'border-rose-200 bg-rose-50/30' : 'border-emerald-200 bg-emerald-50/30'">
          <div :class="['w-14 h-14 rounded-2xl flex items-center justify-center shadow-inner', statement.summary.netBalance > 0 ? 'bg-rose-100 text-rose-600' : 'bg-emerald-100 text-emerald-600']">
            <i data-lucide="scale" class="w-6 h-6"></i>
          </div>
          <div>
            <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">الرصيد الصافي</div>
            <div :class="['text-xl font-black tracking-tight', statement.summary.netBalance > 0 ? 'text-rose-600' : 'text-emerald-600']">
              {{ formatPrice(Math.abs(statement.summary.netBalance)) }} <span class="text-xs opacity-30">د.ع</span>
            </div>
            <div class="text-[9px] font-bold mt-0.5" :class="statement.summary.netBalance > 0 ? 'text-rose-400' : 'text-emerald-400'">
              {{ statement.summary.netBalance > 0 ? 'مدين (عليه للمحل)' : statement.summary.netBalance < 0 ? 'دائن (له عند المحل)' : 'لا رصيد' }}
            </div>
          </div>
        </div>
      </div>

      <!-- Statement Table -->
      <div id="printArea" class="luxury-card overflow-hidden bg-white">
        <!-- Print header (hidden on screen) -->
        <div class="hidden print:block p-8 text-center border-b border-slate-200">
          <h2 class="text-2xl font-black">كشف حساب - {{ statement.customer.name }}</h2>
          <p class="text-sm text-slate-500 mt-2">{{ dateFrom || 'بداية' }} → {{ dateTo || 'اليوم' }}</p>
        </div>
        
        <div class="overflow-x-auto">
          <table class="w-full text-right border-collapse">
            <thead>
              <tr class="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] bg-slate-50/50">
                <th class="px-6 py-5 border-b border-slate-100">التاريخ</th>
                <th class="px-6 py-5 border-b border-slate-100">البيان</th>
                <th class="px-6 py-5 border-b border-slate-100">الوزن (غ)</th>
                <th class="px-6 py-5 border-b border-slate-100">مدين (عليه)</th>
                <th class="px-6 py-5 border-b border-slate-100">دائن (له)</th>
                <th class="px-6 py-5 border-b border-slate-100">الرصيد</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-50">
              <tr v-if="statement.entries.length === 0">
                <td colspan="6" class="px-8 py-20 text-center text-slate-400 font-bold italic">لا توجد حركات مسجلة لهذا الحساب</td>
              </tr>
              <tr 
                v-for="(entry, idx) in statement.entries" 
                :key="idx" 
                class="group transition-colors hover:bg-slate-50/30"
              >
                <td class="px-6 py-5 text-[10px] font-bold text-slate-400 uppercase whitespace-nowrap">{{ formatDate(entry.date) }}</td>
                <td class="px-6 py-5">
                  <div class="flex items-center gap-3">
                    <div :class="['w-8 h-8 rounded-xl flex items-center justify-center shrink-0', entryColor(entry.type)]">
                      <i :data-lucide="entryIcon(entry.type)" class="w-4 h-4"></i>
                    </div>
                    <div>
                      <div class="text-sm font-black text-slate-900 tracking-tight">{{ entry.description }}</div>
                      <div v-if="entry.invoice_number" class="text-[9px] text-slate-400 font-bold">#{{ entry.invoice_number }}</div>
                    </div>
                  </div>
                </td>
                <td class="px-6 py-5 text-sm font-bold text-gold-600">{{ entry.weight ? parseFloat(entry.weight).toFixed(3) : '---' }}</td>
                <td class="px-6 py-5 text-sm font-black text-rose-600">{{ entry.debit > 0 ? formatPrice(entry.debit) : '---' }}</td>
                <td class="px-6 py-5 text-sm font-black text-emerald-600">{{ entry.credit > 0 ? formatPrice(entry.credit) : '---' }}</td>
                <td class="px-6 py-5">
                  <span :class="['text-sm font-black', entry.balance > 0 ? 'text-rose-600' : entry.balance < 0 ? 'text-emerald-600' : 'text-slate-400']">
                    {{ formatPrice(Math.abs(entry.balance)) }}
                    <span class="text-[8px] opacity-50 mr-1">{{ entry.balance > 0 ? 'مدين' : entry.balance < 0 ? 'دائن' : '' }}</span>
                  </span>
                </td>
              </tr>
            </tbody>
            <!-- Footer totals -->
            <tfoot v-if="statement.entries.length > 0">
              <tr class="bg-slate-50 font-black text-sm border-t-2 border-slate-200">
                <td colspan="3" class="px-6 py-5 text-gold-600">المجموع</td>
                <td class="px-6 py-5 text-rose-600">{{ formatPrice(statement.summary.totalDebit) }}</td>
                <td class="px-6 py-5 text-emerald-600">{{ formatPrice(statement.summary.totalCredit) }}</td>
                <td class="px-6 py-5" :class="statement.summary.netBalance > 0 ? 'text-rose-600' : 'text-emerald-600'">
                  {{ formatPrice(Math.abs(statement.summary.netBalance)) }}
                  <span class="text-[9px] opacity-50">{{ statement.summary.netBalance > 0 ? 'مدين' : 'دائن' }}</span>
                </td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>
    </template>

    <!-- Empty state -->
    <div v-if="!statement && !loading" class="luxury-card p-20 text-center bg-white">
      <div class="w-20 h-20 rounded-3xl bg-gold-50 flex items-center justify-center mx-auto mb-6">
        <i data-lucide="file-text" class="w-10 h-10 text-gold-400"></i>
      </div>
      <h3 class="text-xl font-black text-slate-900 mb-2">كشف الحساب</h3>
      <p class="text-sm text-slate-400 font-bold max-w-md mx-auto">اختر عميلاً أو تاجراً من القائمة أعلاه لعرض كشف حسابه المفصل بجميع الحركات المالية</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick } from 'vue'
import api from '../api/axios'
import { useToastStore } from '../stores/toast'

const toast = useToastStore()
const customers = ref([])
const selectedCustomerId = ref('')
const dateFrom = ref('')
const dateTo = ref('')
const statement = ref(null)
const loading = ref(false)

onMounted(async () => {
  try {
    customers.value = (await api.get('/customers')).data
  } finally {
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  }
})

async function loadStatement() {
  if (!selectedCustomerId.value) return
  loading.value = true
  statement.value = null
  try {
    const params = {}
    if (dateFrom.value) params.dateFrom = dateFrom.value
    if (dateTo.value) params.dateTo = dateTo.value
    const res = await api.get(`/reports/account-statement/${selectedCustomerId.value}`, { params })
    statement.value = res.data
  } catch (e) {
    toast.error('حدث خطأ في تحميل الكشف')
  } finally {
    loading.value = false
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  }
}

function printStatement() {
  window.print()
}

function customerTypeLabel(t) {
  return { client: 'عميل', trader: 'تاجر', workshop: 'ورشة' }[t] || 'عميل'
}

function entryIcon(type) {
  return {
    sale: 'shopping-cart', return: 'rotate-ccw', payment: 'banknote',
    transfer_out: 'arrow-up-right', transfer_in: 'arrow-down-left',
  }[type] || 'circle'
}

function entryColor(type) {
  return {
    sale: 'bg-gold-50 text-gold-600',
    return: 'bg-indigo-50 text-indigo-600',
    payment: 'bg-emerald-50 text-emerald-600',
    transfer_out: 'bg-rose-50 text-rose-600',
    transfer_in: 'bg-blue-50 text-blue-600',
  }[type] || 'bg-slate-50 text-slate-600'
}

function formatPrice(v) { return new Intl.NumberFormat('ar-IQ').format(Math.round(v)) }
function formatDate(d) { return d ? new Date(d).toLocaleDateString('ar-IQ', { year: 'numeric', month: 'short', day: 'numeric' }) : '' }
</script>

<style scoped>
.luxury-button {
  @apply gold-gradient-bg hover:shadow-gold-500/40 text-white px-6 py-3 rounded-2xl text-sm font-black shadow-xl shadow-gold-500/20 transition-all active:scale-95 flex items-center gap-2;
}
@media print {
  .luxury-button, nav, aside, header { display: none !important; }
  .luxury-card { box-shadow: none !important; border-radius: 0 !important; }
}
</style>
