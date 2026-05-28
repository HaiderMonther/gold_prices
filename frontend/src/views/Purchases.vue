<template>
  <div class="space-y-10 max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-black text-slate-900 tracking-tight">شراء الذهب</h1>
        <p class="text-slate-400 font-bold mt-1 uppercase tracking-widest text-[10px]">Purchasing • Inbound Gold Inventory</p>
      </div>
      <button @click="showAdd = true" class="luxury-button">
        <i data-lucide="plus" class="w-5 h-5 stroke-[3]"></i>
        عملية شراء جديدة
      </button>
    </div>

    <!-- Stats Grid -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
      <div class="luxury-card p-6 flex items-center gap-6">
        <div class="w-14 h-14 rounded-2xl bg-gold-50 text-gold-600 flex items-center justify-center shadow-inner">
          <i data-lucide="shopping-cart" class="w-6 h-6"></i>
        </div>
        <div>
          <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">إجمالي المشتريات</div>
          <div class="text-xl font-black text-slate-900 tracking-tight">{{ purchases.length }} عملية</div>
        </div>
      </div>
      
      <div class="luxury-card p-6 flex items-center gap-6">
        <div class="w-14 h-14 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center shadow-inner">
          <i data-lucide="package" class="w-6 h-6"></i>
        </div>
        <div>
          <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">الوزن الكلي المشترى</div>
          <div class="text-xl font-black text-slate-900 tracking-tight">{{ totalWeight.toFixed(2) }} <span class="text-xs opacity-30">غرام</span></div>
        </div>
      </div>

      <div class="luxury-card p-6 bg-slate-900 text-white border-none">
        <div class="text-[10px] font-black text-gold-500 uppercase tracking-widest mb-1">المبالغ المدفوعة</div>
        <div class="text-xl font-black tracking-tight">{{ formatRawPrice(totalPaid) }} <span class="text-xs opacity-40">د.ع</span></div>
      </div>
    </div>

    <!-- Purchases Table -->
    <div class="luxury-card overflow-hidden bg-white">
      <div class="overflow-x-auto">
        <table class="w-full text-right border-collapse">
          <thead>
            <tr class="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] bg-slate-50/50">
              <th class="px-8 py-5 border-b border-slate-100">البائع / المصدر</th>
              <th class="px-8 py-5 border-b border-slate-100">نوع الذهب</th>
              <th class="px-8 py-5 border-b border-slate-100">الوزن (غ)</th>
              <th class="px-8 py-5 border-b border-slate-100">العيار</th>
              <th class="px-8 py-5 border-b border-slate-100">سعر السوق</th>
              <th class="px-8 py-5 border-b border-slate-100">المدفوع</th>
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
            <tr v-else-if="purchases.length === 0" class="px-8 py-20 text-center text-slate-400 font-bold italic">
              <td colspan="8">لا توجد عمليات شراء مسجلة</td>
            </tr>
            <tr v-for="p in purchases" :key="p.id" class="group transition-colors hover:bg-slate-50/30">
              <td class="px-8 py-6">
                <div class="font-black text-slate-900 text-sm tracking-tight">{{ p.seller_name }}</div>
              </td>
              <td class="px-8 py-6">
                <span :class="[
                  'text-[9px] px-3 py-1 rounded-full font-black uppercase tracking-[0.1em] ring-1',
                  p.gold_type === 'new' ? 'bg-gold-100/50 text-gold-700 ring-gold-500/20' :
                  p.gold_type === 'used' ? 'bg-indigo-100/50 text-indigo-700 ring-indigo-500/20' :
                  'bg-slate-100/50 text-slate-700 ring-slate-500/20'
                ]">
                  {{ goldTypeLabel(p.gold_type) }}
                </span>
              </td>
              <td class="px-8 py-6 text-sm font-black text-gold-600">{{ parseFloat(p.weight).toFixed(3) }} ج</td>
              <td class="px-8 py-6">
                <span class="text-[10px] font-black text-slate-500 bg-slate-50 px-2 py-1 rounded border border-slate-100">K{{ p.karat }}</span>
              </td>
              <td class="px-8 py-6 text-xs text-slate-400 font-bold">{{ formatRawPrice(p.market_price) }}</td>
              <td class="px-8 py-6 text-sm font-black text-emerald-600">{{ formatRawPrice(p.paid_amount) }}</td>
              <td class="px-8 py-6 text-[10px] font-bold text-slate-400 uppercase">{{ formatDate(p.created_at) }}</td>
              <td class="px-8 py-6">
                <button @click="del(p)" class="p-2 text-slate-300 hover:text-rose-600 hover:bg-rose-50 rounded-xl transition-all opacity-0 group-hover:opacity-100">
                  <i data-lucide="trash-2" class="w-4 h-4"></i>
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Purchase Modal -->
    <div v-if="showAdd" class="dialog-overlay">
      <div class="dialog-content">
        <div class="dialog-header">
          <h3 class="text-2xl font-black text-slate-900">عملية شراء ذهب جديدة</h3>
          <button @click="showAdd = false" class="p-3 hover:bg-white rounded-full shadow-sm transition-all"><i data-lucide="x" class="w-6 h-6 text-slate-400"></i></button>
        </div>
        <div class="dialog-body">
          <div class="grid grid-cols-2 gap-8">
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">اسم البائع</label>
              <input v-model="form.seller_name" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none focus:ring-4 focus:ring-gold-500/5 transition-all" placeholder="اسم المصدر أو الشخص..." />
            </div>
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">نوع الذهب</label>
              <select v-model="form.gold_type" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none appearance-none cursor-pointer">
                <option value="new">ذهب جديد</option>
                <option value="used">مستعمل</option>
                <option value="scrap">كسر / خردة</option>
              </select>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-8">
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">الوزن (جرام)</label>
              <input v-model.number="form.weight" type="number" step="0.001" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-black text-gold-600 outline-none focus:ring-4 focus:ring-gold-500/5" />
            </div>
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">العيار</label>
              <div class="flex bg-slate-100/50 p-1.5 rounded-2xl">
                <button v-for="k in [24, 21, 18]" :key="k" @click="form.karat = k" :class="['flex-1 py-3 text-xs font-black rounded-xl transition-all', form.karat === k ? 'bg-white shadow-xl text-gold-600' : 'text-slate-400']">
                  K{{ k }}
                </button>
              </div>
            </div>
          </div>

          <div class="p-6 bg-gold-50 rounded-3xl border border-gold-100/50 flex justify-between items-center">
            <div class="text-[11px] font-black text-gold-600 uppercase tracking-widest">المعادل الصافي (عيار 24)</div>
            <div class="text-2xl font-black text-gold-700 tracking-tight">{{ eq24.toFixed(3) }} <span class="text-xs opacity-50">غرام</span></div>
          </div>

          <div class="grid grid-cols-2 gap-8">
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">سعر السوق الحالي (للجرام)</label>
              <input v-model.number="form.market_price" type="number" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none" />
            </div>
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">المبلغ المدفوع</label>
              <input v-model.number="form.paid_amount" type="number" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-black text-emerald-600 outline-none" />
            </div>
          </div>
        </div>
        <div class="dialog-footer">
          <button @click="showAdd = false" class="flex-1 py-4 font-black text-slate-400 hover:text-slate-600 transition-colors">إلغاء</button>
          <button @click="save" :disabled="saving" class="flex-[2] gold-gradient-bg py-4 rounded-2xl text-white font-black shadow-lg shadow-gold-500/20 hover:scale-[1.02] active:scale-95 transition-all">
            {{ saving ? 'جاري التنفيذ...' : 'تثبيت عملية الشراء' }}
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
const purchases = ref([])
const loading = ref(true)
const saving = ref(false)
const showAdd = ref(false)
const form = ref({ seller_name: '', gold_type: 'used', weight: 0, karat: 21, market_price: 0, paid_amount: 0, discount_percent: 0 })

const eq24 = computed(() => ((form.value.weight || 0) * (form.value.karat || 21)) / 24)
const totalWeight = computed(() => purchases.value.reduce((s, p) => s + parseFloat(p.weight), 0))
const totalPaid = computed(() => purchases.value.reduce((s, p) => s + parseFloat(p.paid_amount), 0))

async function load() {
  loading.value = true
  try { purchases.value = (await api.get('/purchases')).data } 
  finally { 
    loading.value = false 
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  }
}

async function save() {
  if (!form.value.seller_name) return toast.error('اسم البائع مطلوب')
  saving.value = true
  try { 
    await api.post('/purchases', form.value); 
    toast.success('تمت عملية الشراء بنجاح')
    showAdd.value = false; 
    load() 
  }
  catch { toast.error('حدث خطأ أثناء الحفظ') } 
  finally { saving.value = false }
}

async function del(p) {
  if (!confirm('حذف هذه العملية؟')) return
  try { await api.delete(`/purchases/${p.id}`); toast.success('تم الحذف'); load() } 
  catch { toast.error('فشل العملية') }
}

function goldTypeLabel(t) { return { new: 'ذهب جديد', used: 'مستعمل', scrap: 'كسر' }[t] || t }
function formatRawPrice(v) { return new Intl.NumberFormat('ar-IQ').format(Math.round(v)) }
function formatDate(d) { return d ? new Date(d).toLocaleDateString('ar-IQ', { month: 'short', day: 'numeric' }) : '' }
onMounted(load)
</script>

<style scoped>
.luxury-button {
  @apply gold-gradient-bg hover:shadow-gold-500/40 text-white px-6 py-3 rounded-2xl text-sm font-black shadow-xl shadow-gold-500/20 transition-all active:scale-95 flex items-center gap-2 overflow-hidden relative;
}
</style>
