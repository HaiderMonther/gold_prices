<template>
  <div class="space-y-10 max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-black text-slate-900 tracking-tight">المصروفات اليومية</h1>
        <p class="text-slate-400 font-bold mt-1 uppercase tracking-widest text-[10px]">Expenses • Cash Flow Tracking</p>
      </div>
      <button @click="showAdd = true" class="luxury-button">
        <i data-lucide="plus-circle" class="w-5 h-5 stroke-[3]"></i>
        إضافة مصروف جديد
      </button>
    </div>

    <!-- Category Stats -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
      <div 
        v-for="(total, cat) in categoryTotals" 
        :key="cat" 
        class="luxury-card p-6 flex flex-col group cursor-default hover:border-gold-200 transition-all"
      >
        <div class="flex items-center justify-between mb-4">
          <div class="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center shadow-inner group-hover:scale-110 transition-transform">
            <i data-lucide="banknote" class="w-5 h-5"></i>
          </div>
          <div class="text-[9px] font-black text-indigo-400 uppercase tracking-widest">Category</div>
        </div>
        <div class="space-y-1">
          <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">{{ cat }}</div>
          <div class="text-xl font-black text-slate-900 tracking-tight">
            {{ formatRawPrice(total) }} <span class="text-[10px] opacity-30 font-medium">د.ع</span>
          </div>
        </div>
      </div>
      
      <!-- Total Counter -->
      <div class="luxury-card p-6 bg-slate-900 text-white flex flex-col justify-center border-none shadow-xl shadow-slate-200/50">
        <div class="text-[10px] font-black text-gold-500 uppercase tracking-[0.2em] mb-1">إجمالي المصروفات</div>
        <div class="text-2xl font-black tracking-tight">
          {{ formatRawPrice(totalExpenses) }} <span class="text-xs opacity-40 font-medium">د.ع</span>
        </div>
      </div>
    </div>

    <!-- Expenses Table -->
    <div class="luxury-card overflow-hidden bg-white">
      <div class="overflow-x-auto">
        <table class="w-full text-right border-collapse">
          <thead>
            <tr class="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] bg-slate-50/50">
              <th class="px-8 py-5 border-b border-slate-100">الوصف</th>
              <th class="px-8 py-5 border-b border-slate-100">الفئة</th>
              <th class="px-8 py-5 border-b border-slate-100">المبلغ</th>
              <th class="px-8 py-5 border-b border-slate-100">بواسطة</th>
              <th class="px-8 py-5 border-b border-slate-100">التاريخ</th>
              <th class="px-8 py-5 border-b border-slate-100">تحكم</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-50">
            <tr v-if="loading">
              <td colspan="6" class="px-8 py-20 text-center">
                <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-gold-500 mx-auto"></div>
              </td>
            </tr>
            <tr v-else-if="expenses.length === 0" class="px-8 py-20 text-center text-slate-400 font-bold italic">
              <td colspan="6">لا توجد مصروفات مسجلة حالياً</td>
            </tr>
            <tr 
              v-for="e in expenses" 
              :key="e.id" 
              class="group transition-colors hover:bg-slate-50/30"
            >
              <td class="px-8 py-6">
                <div class="font-black text-slate-900 text-sm tracking-tight">{{ e.description }}</div>
              </td>
              <td class="px-8 py-6">
                <span class="text-[10px] px-3 py-1 rounded-xl font-black bg-indigo-50 text-indigo-700 border border-indigo-200/50 uppercase tracking-wider">
                  {{ e.category || 'عام' }}
                </span>
              </td>
              <td class="px-8 py-6">
                <div class="text-sm font-black text-rose-600">
                  - {{ formatRawPrice(e.amount) }} <span class="text-[10px] opacity-30">د.ع</span>
                </div>
              </td>
              <td class="px-8 py-6 text-xs text-slate-500 font-bold">{{ e.user?.name || '-' }}</td>
              <td class="px-8 py-6 text-[10px] font-bold text-slate-400 uppercase">{{ formatDate(e.created_at) }}</td>
              <td class="px-8 py-6">
                <button @click="del(e)" class="p-2 text-slate-300 hover:text-rose-600 hover:bg-rose-50 rounded-xl transition-all opacity-0 group-hover:opacity-100">
                  <i data-lucide="trash-2" class="w-4 h-4"></i>
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Add Modal -->
    <div v-if="showAdd" class="dialog-overlay">
      <div class="dialog-content">
        <div class="dialog-header">
          <h3 class="text-2xl font-black text-slate-900">تسجيل مصروف جديد</h3>
          <button @click="showAdd = false" class="p-3 hover:bg-white rounded-full shadow-sm transition-all"><i data-lucide="x" class="w-6 h-6 text-slate-400"></i></button>
        </div>
        <div class="dialog-body">
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">وصف المصروف</label>
            <div class="relative group">
              <i data-lucide="file-text" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-gold-500 transition-colors w-5 h-5"></i>
              <input v-model="form.description" class="w-full bg-slate-50 border border-slate-100 rounded-2xl pr-12 pl-4 py-4 font-bold outline-none focus:ring-4 focus:ring-gold-500/5 transition-all" placeholder="مثلاً: صيانة المحل، فاتورة كهرباء..." />
            </div>
          </div>
          
          <div class="grid grid-cols-2 gap-8">
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">المبلغ (د.ع)</label>
              <div class="relative group">
                <i data-lucide="dollar-sign" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-rose-500 transition-colors w-5 h-5"></i>
                <input v-model.number="form.amount" type="number" class="w-full bg-slate-50 border border-slate-100 rounded-2xl pr-12 pl-4 py-4 font-bold outline-none focus:ring-4 focus:ring-rose-500/5 transition-all" placeholder="0" />
              </div>
            </div>
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">الفئة</label>
              <select v-model="form.category" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none appearance-none cursor-pointer">
                <option value="">عام / غير مصنف</option>
                <option value="إيجار">إيجار</option>
                <option value="رواتب">رواتب</option>
                <option value="صيانة">صيانة</option>
                <option value="كهرباء وماء">كهرباء وماء</option>
                <option value="تسويق">تسويق</option>
                <option value="أخرى">أخرى</option>
              </select>
            </div>
          </div>
        </div>
        <div class="dialog-footer">
          <button @click="showAdd = false" class="flex-1 py-4 font-black text-slate-400 hover:text-slate-600 transition-colors">إلغاء</button>
          <button @click="save" :disabled="saving" class="flex-[2] gold-gradient-bg py-4 rounded-2xl text-white font-black shadow-lg shadow-gold-500/20 hover:scale-[1.02] active:scale-95 transition-all">
            {{ saving ? 'جاري الحفظ...' : 'تسجيل المصروف' }}
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
const expenses = ref([])
const loading = ref(true)
const saving = ref(false)
const showAdd = ref(false)
const form = ref({ description: '', amount: 0, category: '' })

const categoryTotals = computed(() => {
  const totals = {}
  expenses.value.forEach(e => {
    const cat = e.category || 'أخرى'
    totals[cat] = (totals[cat] || 0) + parseFloat(e.amount)
  })
  return totals
})

const totalExpenses = computed(() => Object.values(categoryTotals.value).reduce((s, v) => s + v, 0))

async function load() {
  loading.value = true
  try { expenses.value = (await api.get('/expenses')).data } 
  finally { 
    loading.value = false 
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  }
}

async function save() {
  if (!form.value.description || !form.value.amount) return toast.error('الوصف والمبلغ مطلوبان')
  saving.value = true
  try { 
    await api.post('/expenses', form.value); 
    toast.success('تم تسجيل المصروف بنجاح')
    showAdd.value = false; 
    form.value = { description: '', amount: 0, category: '' }
    load() 
  }
  catch { toast.error('حدث خطأ أثناء حفظ البيانات') } 
  finally { saving.value = false }
}

async function del(e) {
  if (!confirm('هل أنت متأكد من حذف هذا المصروف؟')) return
  try { 
    await api.delete(`/expenses/${e.id}`); 
    toast.success('تم حذف المصروف بنجاح'); 
    load() 
  } 
  catch { toast.error('فشل عملية الحذف') }
}

function formatRawPrice(v) { return new Intl.NumberFormat('ar-IQ').format(Math.round(v)) }
function formatDate(d) { return d ? new Date(d).toLocaleDateString('ar-IQ', { month: 'short', day: 'numeric' }) : '' }
onMounted(load)
</script>

<style scoped>
.luxury-button {
  @apply gold-gradient-bg hover:shadow-gold-500/40 text-white px-6 py-3 rounded-2xl text-sm font-black shadow-xl shadow-gold-500/20 transition-all active:scale-95 flex items-center gap-2 overflow-hidden relative;
}
</style>
