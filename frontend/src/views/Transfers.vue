<template>
  <div class="space-y-10 max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-black text-slate-900 tracking-tight">الحوالات</h1>
        <p class="text-slate-400 font-bold mt-1 uppercase tracking-widest text-[10px]">Transfers • Money Movement</p>
      </div>
      <button @click="showAdd = true" class="luxury-button">
        <i data-lucide="send" class="w-5 h-5 stroke-[3]"></i>
        حوالة جديدة
      </button>
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
      <div class="luxury-card p-6 flex items-center gap-6">
        <div class="w-14 h-14 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center shadow-inner">
          <i data-lucide="send" class="w-6 h-6"></i>
        </div>
        <div>
          <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">عدد الحوالات</div>
          <div class="text-xl font-black text-slate-900 tracking-tight">{{ transfers.length }}</div>
        </div>
      </div>
      <div class="luxury-card p-6 flex items-center gap-6">
        <div class="w-14 h-14 rounded-2xl bg-gold-50 text-gold-600 flex items-center justify-center shadow-inner">
          <i data-lucide="banknote" class="w-6 h-6"></i>
        </div>
        <div>
          <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">إجمالي المبالغ</div>
          <div class="text-xl font-black text-slate-900 tracking-tight">{{ formatPrice(totalAmount) }} <span class="text-xs opacity-30">د.ع</span></div>
        </div>
      </div>
      <div class="luxury-card p-6 bg-slate-900 text-white border-none">
        <div class="text-[10px] font-black text-gold-500 uppercase tracking-widest mb-1">آخر حوالة</div>
        <div class="text-sm font-black text-white">{{ transfers[0]?.description || 'لا توجد حوالات' }}</div>
      </div>
    </div>

    <!-- Table -->
    <div class="luxury-card overflow-hidden bg-white">
      <div class="overflow-x-auto">
        <table class="w-full text-right border-collapse">
          <thead>
            <tr class="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] bg-slate-50/50">
              <th class="px-8 py-5 border-b border-slate-100">من</th>
              <th class="px-8 py-5 border-b border-slate-100">إلى</th>
              <th class="px-8 py-5 border-b border-slate-100">المبلغ</th>
              <th class="px-8 py-5 border-b border-slate-100">العملة</th>
              <th class="px-8 py-5 border-b border-slate-100">الوصف</th>
              <th class="px-8 py-5 border-b border-slate-100">التاريخ</th>
              <th class="px-8 py-5 border-b border-slate-100">تحكم</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-50">
            <tr v-if="loading">
              <td colspan="7" class="px-8 py-20 text-center"><div class="animate-spin rounded-full h-8 w-8 border-b-2 border-gold-500 mx-auto"></div></td>
            </tr>
            <tr v-else-if="transfers.length === 0">
              <td colspan="7" class="px-8 py-20 text-center text-slate-400 font-bold italic">لا توجد حوالات</td>
            </tr>
            <tr v-for="t in transfers" :key="t.id" class="group transition-colors hover:bg-slate-50/30">
              <td class="px-8 py-6 text-sm font-black text-slate-900">{{ t.from_customer?.name || 'المحل' }}</td>
              <td class="px-8 py-6 text-sm font-black text-slate-900">{{ t.to_customer?.name || 'المحل' }}</td>
              <td class="px-8 py-6 text-sm font-black text-gold-600">{{ formatPrice(t.amount) }}</td>
              <td class="px-8 py-6">
                <span class="text-[9px] px-3 py-1 rounded-full font-black uppercase ring-1 bg-slate-100/50 text-slate-700 ring-slate-500/20">{{ t.currency }}</span>
              </td>
              <td class="px-8 py-6 text-xs text-slate-500 font-bold max-w-[200px] truncate">{{ t.description || '---' }}</td>
              <td class="px-8 py-6 text-[10px] font-bold text-slate-400 uppercase">{{ formatDate(t.created_at) }}</td>
              <td class="px-8 py-6">
                <button @click="del(t)" class="p-2 text-slate-300 hover:text-rose-600 hover:bg-rose-50 rounded-xl transition-all opacity-0 group-hover:opacity-100">
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
          <h3 class="text-2xl font-black text-slate-900">حوالة جديدة</h3>
          <button @click="showAdd = false" class="p-3 hover:bg-white rounded-full shadow-sm transition-all"><i data-lucide="x" class="w-6 h-6 text-slate-400"></i></button>
        </div>
        <div class="dialog-body">
          <div class="grid grid-cols-2 gap-8">
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">من (المرسل)</label>
              <select v-model="form.from_customer_id" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none appearance-none cursor-pointer">
                <option value="">المحل (نقدي)</option>
                <option v-for="c in customers" :key="c.id" :value="c.id">{{ c.name }}</option>
              </select>
            </div>
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">إلى (المستلم)</label>
              <select v-model="form.to_customer_id" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none appearance-none cursor-pointer">
                <option value="">المحل (نقدي)</option>
                <option v-for="c in customers" :key="c.id" :value="c.id">{{ c.name }}</option>
              </select>
            </div>
          </div>
          <div class="grid grid-cols-2 gap-8">
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">المبلغ</label>
              <input v-model.number="form.amount" type="number" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-black text-xl text-gold-600 outline-none" />
            </div>
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">العملة</label>
              <div class="flex bg-slate-100/50 p-1.5 rounded-2xl">
                <button @click="form.currency = 'IQD'" :class="['flex-1 py-3 text-xs font-black rounded-xl transition-all', form.currency === 'IQD' ? 'bg-white shadow-xl text-gold-600' : 'text-slate-400']">دينار عراقي</button>
                <button @click="form.currency = 'USD'" :class="['flex-1 py-3 text-xs font-black rounded-xl transition-all', form.currency === 'USD' ? 'bg-white shadow-xl text-emerald-600' : 'text-slate-400']">دولار أمريكي</button>
              </div>
            </div>
          </div>
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">الوصف</label>
            <input v-model="form.description" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none" placeholder="وصف الحوالة..." />
          </div>
        </div>
        <div class="dialog-footer">
          <button @click="showAdd = false" class="flex-1 py-4 font-black text-slate-400 hover:text-slate-600 transition-colors">إلغاء</button>
          <button @click="save" :disabled="saving" class="flex-[2] gold-gradient-bg py-4 rounded-2xl text-white font-black shadow-lg shadow-gold-500/20 hover:scale-[1.02] active:scale-95 transition-all">
            {{ saving ? 'جاري التنفيذ...' : 'تثبيت الحوالة' }}
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
const transfers = ref([])
const customers = ref([])
const loading = ref(true)
const saving = ref(false)
const showAdd = ref(false)
const form = ref({ from_customer_id: '', to_customer_id: '', amount: 0, currency: 'IQD', description: '' })

const totalAmount = computed(() => transfers.value.reduce((s, t) => s + parseFloat(t.amount), 0))

async function load() {
  loading.value = true
  try {
    const [tRes, cRes] = await Promise.all([
      api.get('/transfers'),
      api.get('/customers'),
    ])
    transfers.value = tRes.data
    customers.value = cRes.data
  } finally {
    loading.value = false
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  }
}

async function save() {
  if (!form.value.amount) return toast.error('المبلغ مطلوب')
  saving.value = true
  try {
    await api.post('/transfers', {
      ...form.value,
      from_customer_id: form.value.from_customer_id || null,
      to_customer_id: form.value.to_customer_id || null,
    })
    toast.success('تم تسجيل الحوالة بنجاح')
    showAdd.value = false
    form.value = { from_customer_id: '', to_customer_id: '', amount: 0, currency: 'IQD', description: '' }
    load()
  } catch { toast.error('حدث خطأ') }
  finally { saving.value = false }
}

async function del(t) {
  if (!confirm('حذف هذه الحوالة؟')) return
  try { await api.delete(`/transfers/${t.id}`); toast.success('تم الحذف'); load() }
  catch { toast.error('فشلت العملية') }
}

function formatPrice(v) { return new Intl.NumberFormat('ar-IQ').format(Math.round(v)) }
function formatDate(d) { return d ? new Date(d).toLocaleDateString('ar-IQ', { month: 'short', day: 'numeric' }) : '' }

onMounted(load)
</script>

<style scoped>
.luxury-button {
  @apply gold-gradient-bg hover:shadow-gold-500/40 text-white px-6 py-3 rounded-2xl text-sm font-black shadow-xl shadow-gold-500/20 transition-all active:scale-95 flex items-center gap-2;
}
</style>
