<template>
  <div class="space-y-10 max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-black text-slate-900 tracking-tight">سجل الفواتير</h1>
        <p class="text-slate-400 font-bold mt-1 uppercase tracking-widest text-[10px]">Archive • Financial Records</p>
      </div>
      <router-link to="/invoices/new" class="luxury-button">
        <i data-lucide="plus" class="w-5 h-5 stroke-[3]"></i>
        فاتورة جديدة
      </router-link>
    </div>

    <!-- Summary Stats -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
      <div v-for="stat in summaryStats" :key="stat.label" class="luxury-card p-6 flex items-center gap-6">
        <div :class="['w-14 h-14 rounded-2xl flex items-center justify-center shadow-inner', stat.colorClass]">
          <i :data-lucide="stat.icon" class="w-6 h-6"></i>
        </div>
        <div>
          <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">{{ stat.label }}</div>
          <div class="text-xl font-black text-slate-900 tracking-tight">{{ stat.value }} <span class="text-[10px] opacity-30">د.ع</span></div>
        </div>
      </div>
    </div>

    <!-- Table Section -->
    <div class="luxury-card overflow-hidden bg-white">
      <div class="p-8 border-b border-slate-50 flex flex-wrap items-center justify-between gap-6">
        <div class="relative group flex-1 max-w-md">
          <i data-lucide="search" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-gold-500 transition-colors w-4 h-4"></i>
          <input 
            type="text" 
            v-model="search"
            placeholder="بحث برقم الفاتورة أو العميل..." 
            class="w-full bg-slate-50/50 border border-slate-100 rounded-2xl pr-12 pl-4 py-3 text-sm font-bold outline-none focus:ring-4 focus:ring-gold-500/5 transition-all" 
          />
        </div>
        <select v-model="filterType" class="bg-slate-50 text-xs px-6 py-3 rounded-2xl border-none font-black text-slate-600 focus:ring-4 focus:ring-gold-500/5 cursor-pointer">
          <option value="">جميع الأنواع</option>
          <option value="sale">مبيعات</option>
          <option value="return">إرجاع</option>
        </select>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full text-right border-collapse">
          <thead>
            <tr class="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] bg-slate-50/50">
              <th class="px-8 py-5 border-b border-slate-100">رقم الفاتورة</th>
              <th class="px-8 py-5 border-b border-slate-100">النوع</th>
              <th class="px-8 py-5 border-b border-slate-100">العميل</th>
              <th class="px-8 py-5 border-b border-slate-100">الإجمالي</th>
              <th class="px-8 py-5 border-b border-slate-100">المدفوع</th>
              <th class="px-8 py-5 border-b border-slate-100">التاريخ</th>
              <th class="px-8 py-5 border-b border-slate-100">تحكم</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-50">
            <tr v-if="loading">
              <td colspan="7" class="px-8 py-20 text-center">
                <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-gold-500 mx-auto"></div>
              </td>
            </tr>
            <tr v-else-if="filtered.length === 0" class="px-8 py-20 text-center text-slate-400 font-bold italic">
              <td colspan="7">لا توجد فواتير مطابقة</td>
            </tr>
            <tr 
              v-for="inv in filtered" 
              :key="inv.id"
              @click="selectedInvoice = inv"
              class="group transition-colors hover:bg-slate-50/50 cursor-pointer"
            >
              <td class="px-8 py-6">
                <div class="text-xs font-black text-gold-600 tracking-tighter">{{ inv.invoice_number }}</div>
              </td>
              <td class="px-8 py-6">
                <span :class="[
                  'text-[9px] px-3 py-1 rounded-full font-black uppercase tracking-[0.1em] ring-1',
                  inv.type === 'sale' ? 'bg-emerald-100/50 text-emerald-700 ring-emerald-500/20' : 'bg-indigo-100/50 text-indigo-700 ring-indigo-500/20'
                ]">
                  {{ inv.type === 'sale' ? 'بيع' : 'إرجاع' }}
                </span>
              </td>
              <td class="px-8 py-6">
                <div class="text-sm font-black text-slate-900">{{ inv.customer?.name || 'نقدي / عام' }}</div>
              </td>
              <td class="px-8 py-6">
                <div class="text-sm font-black text-slate-900">{{ formatRawPrice(inv.total_amount) }}</div>
              </td>
              <td class="px-8 py-6">
                <div class="text-sm font-black text-emerald-600">{{ formatRawPrice(inv.paid_amount) }}</div>
              </td>
              <td class="px-8 py-6">
                <div class="text-[10px] font-bold text-slate-400 uppercase">{{ formatDate(inv.created_at) }}</div>
              </td>
              <td class="px-8 py-6">
                <button class="p-2 text-slate-400 hover:text-gold-600 hover:bg-gold-50 rounded-xl transition-all opacity-0 group-hover:opacity-100">
                  <i data-lucide="eye" class="w-4 h-4"></i>
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Invoice Modal -->
    <div v-if="selectedInvoice" class="dialog-overlay">
      <div class="dialog-content max-w-4xl">
        <div class="dialog-header">
          <div>
            <h3 class="text-2xl font-black text-slate-900">تفاصيل الفاتورة</h3>
            <p class="text-gold-600 font-bold text-sm">{{ selectedInvoice.invoice_number }}</p>
          </div>
          <button @click="selectedInvoice = null" class="p-3 hover:bg-white rounded-full shadow-sm transition-all">
            <i data-lucide="x" class="w-6 h-6 text-slate-400"></i>
          </button>
        </div>
        
        <div class="dialog-body">
          <div class="grid grid-cols-2 md:grid-cols-4 gap-8">
            <div class="space-y-1">
              <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">العميل</div>
              <div class="font-black text-slate-900">{{ selectedInvoice.customer?.name || 'نقدي' }}</div>
            </div>
            <div class="space-y-1">
              <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">التاريخ</div>
              <div class="font-black text-slate-900">{{ formatDate(selectedInvoice.created_at) }}</div>
            </div>
            <div class="space-y-1">
              <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">المسؤول</div>
              <div class="font-black text-slate-900">{{ selectedInvoice.user?.name || '-' }}</div>
            </div>
            <div class="space-y-1">
              <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">الحالة</div>
              <div class="font-black text-emerald-600">مدفوع بالكامل</div>
            </div>
          </div>

          <div class="luxury-card border-slate-100 rounded-3xl overflow-hidden">
            <table class="w-full text-right">
              <thead>
                <tr class="bg-slate-50/80 text-[10px] font-black text-slate-400 uppercase tracking-widest">
                  <th class="px-6 py-4">القطعة</th>
                  <th class="px-6 py-4">العيار</th>
                  <th class="px-6 py-4">الوزن</th>
                  <th class="px-6 py-4">سعر الجرام</th>
                  <th class="px-6 py-4">الإجمالي</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-50">
                <tr v-for="item in selectedInvoice.items" :key="item.id">
                  <td class="px-6 py-4 font-black text-slate-900">{{ item.product?.name || 'قطعة ذهب' }}</td>
                  <td class="px-6 py-4">
                    <span class="bg-gold-50 text-gold-700 px-2 py-1 rounded text-[10px] font-black">K{{ item.karat }}</span>
                  </td>
                  <td class="px-6 py-4 font-bold text-slate-600">{{ parseFloat(item.weight).toFixed(3) }} ج</td>
                  <td class="px-6 py-4 text-sm">{{ formatRawPrice(item.price_per_gram) }}</td>
                  <td class="px-6 py-4 font-black text-gold-600">{{ formatRawPrice(item.total_price) }}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="flex justify-end pt-6 border-t border-slate-100">
            <div class="w-80 space-y-4">
              <div class="flex justify-between text-sm">
                <span class="text-slate-400 font-bold">المجموع الفرعي</span>
                <span class="font-black text-slate-900">{{ formatRawPrice(selectedInvoice.total_amount) }} د.ع</span>
              </div>
              <div class="flex justify-between text-xl border-t border-slate-100 pt-4">
                <span class="text-slate-900 font-black">الإجمالي النهائي</span>
                <span class="font-black text-gold-600">{{ formatRawPrice(selectedInvoice.total_amount) }} د.ع</span>
              </div>
            </div>
          </div>
        </div>
        
        <div class="dialog-footer no-print">
          <button @click="selectedInvoice = null" class="flex-1 py-4 font-black text-slate-400">إغلاق</button>
          <button @click="printInvoice" class="flex-1 gold-gradient-bg py-4 rounded-2xl text-white font-black shadow-lg shadow-gold-500/20 flex items-center justify-center gap-3">
            <i data-lucide="printer" class="w-5 h-5"></i>
            طباعة الفاتورة
          </button>
        </div>
      </div>
      
      <!-- Print Only Receipt Format -->
      <div v-if="selectedInvoice" class="hidden print:block absolute inset-0 bg-white p-8 font-sans w-[80mm] mx-auto text-black text-center" dir="rtl">
        <div class="border-b-2 border-black pb-4 mb-4 border-dashed">
          <h2 class="text-2xl font-black mb-1">{{ shopSettings.shopName || 'مجوهرات الذهبي' }}</h2>
          <p class="text-xs font-bold">{{ shopSettings.shopAddress || 'العنوان' }}</p>
          <p class="text-xs font-bold">هاتف: {{ shopSettings.shopPhone || '07XXXXXXXXX' }}</p>
        </div>
        
        <div class="text-right text-xs mb-4 font-bold border-b border-black pb-4">
          <p>رقم الفاتورة: {{ selectedInvoice.invoice_number }}</p>
          <p>التاريخ: {{ formatDate(selectedInvoice.created_at) }}</p>
          <p>العميل: {{ selectedInvoice.customer?.name || 'نقدي' }}</p>
        </div>
        
        <table class="w-full text-right text-xs mb-4 font-bold border-b border-black pb-4">
          <thead>
            <tr class="border-b border-black">
              <th class="py-1">القطعة</th>
              <th class="py-1">ع</th>
              <th class="py-1">و</th>
              <th class="py-1">المجموع</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in selectedInvoice.items" :key="item.id">
              <td class="py-1">{{ item.product?.name || item.item_name || 'قطعة ذهب' }}</td>
              <td class="py-1">{{ item.karat }}</td>
              <td class="py-1">{{ parseFloat(item.weight).toFixed(2) }}</td>
              <td class="py-1">{{ formatRawPrice(item.total_price) }}</td>
            </tr>
          </tbody>
        </table>
        
        <div class="text-left text-sm font-black mb-6">
          <p>الإجمالي: {{ formatRawPrice(selectedInvoice.total_amount) }} د.ع</p>
          <p>المدفوع: {{ formatRawPrice(selectedInvoice.paid_amount) }} د.ع</p>
          <p v-if="selectedInvoice.remaining > 0">المتبقي: {{ formatRawPrice(selectedInvoice.remaining) }} د.ع</p>
        </div>
        
        <div class="text-[10px] font-bold text-center border-t border-dashed border-black pt-4">
          <p>{{ shopSettings.receiptFooter || 'البضاعة المباعة لا ترد ولا تستبدل' }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import api from '../api/axios'

const invoices = ref([])
const loading = ref(true)
const search = ref('')
const filterType = ref('')
const selectedInvoice = ref(null)
const shopSettings = ref({})

onMounted(() => {
  const saved = localStorage.getItem('kimia_settings')
  if (saved) {
    try { shopSettings.value = JSON.parse(saved) } catch {}
  }
  load()
})

function printInvoice() {
  setTimeout(() => {
    window.print();
  }, 100);
}

const filtered = computed(() => invoices.value.filter(inv => {
  const s = search.value.toLowerCase()
  const match = !s || inv.invoice_number.toLowerCase().includes(s) || (inv.customer?.name || '').toLowerCase().includes(s)
  const type = !filterType.value || inv.type === filterType.value
  return match && type
}))

const summaryStats = computed(() => [
  {
    label: 'إجمالي المبيعات',
    value: formatRawPrice(filtered.value.filter(i => i.type === 'sale').reduce((s, i) => s + parseFloat(i.total_amount || 0), 0)),
    icon: 'shopping-cart',
    colorClass: 'bg-gold-50 text-gold-600'
  },
  {
    label: 'المبالغ المحصلة',
    value: formatRawPrice(filtered.value.reduce((s, i) => s + parseFloat(i.paid_amount || 0), 0)),
    icon: 'check-circle',
    colorClass: 'bg-emerald-50 text-emerald-600'
  },
  {
    label: 'إجمالي الوزن',
    value: filtered.value.reduce((s, i) => s + i.items.reduce((ss, ii) => ss + parseFloat(ii.weight), 0), 0).toFixed(2),
    icon: 'package',
    colorClass: 'bg-indigo-50 text-indigo-600'
  }
])

async function load() {
  loading.value = true
  try {
    const res = await api.get('/invoices')
    invoices.value = res.data
  } finally {
    loading.value = false
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  }
}

function formatRawPrice(v) {
  return new Intl.NumberFormat('ar-IQ').format(Math.round(v))
}

function formatDate(d) {
  return d ? new Date(d).toLocaleDateString('ar-IQ', { month: 'short', day: 'numeric', year: 'numeric' }) : ''
}
</script>

<style scoped>
.luxury-button {
  @apply gold-gradient-bg hover:shadow-gold-500/40 text-white px-6 py-3 rounded-2xl text-sm font-black shadow-xl shadow-gold-500/20 transition-all active:scale-95 flex items-center gap-2 overflow-hidden relative;
}
</style>
