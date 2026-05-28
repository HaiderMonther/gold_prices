<template>
  <div class="space-y-10 max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-black text-slate-900 tracking-tight">جرد المخزون</h1>
        <p class="text-slate-400 font-bold mt-1 uppercase tracking-widest text-[10px]">Stock Count • Audit Log</p>
      </div>
      <button @click="showAdd = true" class="luxury-button">
        <i data-lucide="package-search" class="w-5 h-5 stroke-[3]"></i>
        بدء جرد جديد
      </button>
    </div>

    <!-- Inventory History Table -->
    <div class="luxury-card overflow-hidden bg-white">
      <div class="p-8 border-b border-slate-50">
        <h3 class="text-sm font-black text-slate-900 uppercase tracking-widest flex items-center gap-2">
          <i data-lucide="history" class="w-4 h-4 text-gold-500"></i>
          سجلات التدقيق والجرد
        </h3>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full text-right border-collapse">
          <thead>
            <tr class="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] bg-slate-50/50">
              <th class="px-8 py-5 border-b border-slate-100">وزن النظام</th>
              <th class="px-8 py-5 border-b border-slate-100">الوزن الفعلي</th>
              <th class="px-8 py-5 border-b border-slate-100">الفرق</th>
              <th class="px-8 py-5 border-b border-slate-100">ملاحظات التدقيق</th>
              <th class="px-8 py-5 border-b border-slate-100">المسؤول</th>
              <th class="px-8 py-5 border-b border-slate-100">التاريخ</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-50">
            <tr v-if="loading">
              <td colspan="6" class="px-8 py-20 text-center">
                <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-gold-500 mx-auto"></div>
              </td>
            </tr>
            <tr v-else-if="checks.length === 0" class="px-8 py-20 text-center text-slate-400 font-bold italic">
              <td colspan="6">لم يتم إجراء أي عمليات جرد حتى الآن</td>
            </tr>
            <tr 
              v-for="c in checks" 
              :key="c.id" 
              class="group transition-colors hover:bg-slate-50/30"
            >
              <td class="px-8 py-6 text-sm font-bold text-slate-600 tracking-tight">{{ parseFloat(c.system_weight).toFixed(3) }} ج</td>
              <td class="px-8 py-6 text-sm font-black text-slate-900 tracking-tight">{{ parseFloat(c.actual_weight).toFixed(3) }} ج</td>
              <td class="px-8 py-6">
                <div :class="[
                  'text-sm font-black px-3 py-1 rounded-xl inline-block',
                  parseFloat(c.difference) < 0 ? 'bg-rose-50 text-rose-600' : 
                  parseFloat(c.difference) > 0 ? 'bg-emerald-50 text-emerald-600' : 'bg-slate-50 text-slate-400'
                ]">
                  {{ parseFloat(c.difference) > 0 ? '+' : '' }}{{ parseFloat(c.difference).toFixed(3) }}
                </div>
              </td>
              <td class="px-8 py-6 text-xs text-slate-400 font-medium max-w-xs truncate">{{ c.notes || 'لا يوجد ملاحظات' }}</td>
              <td class="px-8 py-6 text-[10px] font-black text-slate-900 uppercase">{{ c.user?.name || '-' }}</td>
              <td class="px-8 py-6 text-[10px] font-bold text-slate-400 uppercase">{{ formatDate(c.created_at) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Add Check Modal -->
    <div v-if="showAdd" class="dialog-overlay">
      <div class="dialog-content">
        <div class="dialog-header">
          <h3 class="text-2xl font-black text-slate-900">عملية جرد جديدة</h3>
          <button @click="showAdd = false" class="p-3 hover:bg-white rounded-full shadow-sm transition-all"><i data-lucide="x" class="w-6 h-6 text-slate-400"></i></button>
        </div>
        <div class="dialog-body">
          <div class="bg-amber-50 border border-amber-100 rounded-3xl p-6 flex gap-4">
             <i data-lucide="info" class="w-6 h-6 text-amber-500 shrink-0"></i>
             <p class="text-xs font-bold text-amber-700 leading-relaxed">
               سيقوم النظام بحساب الوزن الإجمالي الحالي المسجل في قاعدة البيانات ومقارنته بالوزن الذي ستدخله الآن.
             </p>
          </div>
          
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">الوزن الفعلي الحالي (غرام)</label>
            <div class="relative group">
              <i data-lucide="package" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-gold-500 transition-colors w-6 h-6"></i>
              <input v-model.number="form.actual_weight" type="number" step="0.001" class="w-full bg-slate-50 border border-slate-100 rounded-2xl pr-14 pl-4 py-5 text-2xl font-black text-slate-900 outline-none focus:ring-4 focus:ring-gold-500/5 transition-all" placeholder="0.000" />
            </div>
          </div>
          
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">ملاحظات الجرد</label>
            <textarea v-model="form.notes" rows="3" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none focus:ring-4 focus:ring-gold-500/5 transition-all" placeholder="اكتب أي ملاحظات حول حالة الجرد هنا..."></textarea>
          </div>
        </div>
        <div class="dialog-footer">
          <button @click="showAdd = false" class="flex-1 py-4 font-black text-slate-400 hover:text-slate-600 transition-colors">إلغاء</button>
          <button @click="save" :disabled="saving" class="flex-[2] gold-gradient-bg py-4 rounded-2xl text-white font-black shadow-lg shadow-gold-500/20 hover:scale-[1.02] active:scale-95 transition-all">
            {{ saving ? 'جاري الحفظ...' : 'تثبيت الجرد' }}
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
const checks = ref([])
const loading = ref(true)
const saving = ref(false)
const showAdd = ref(false)
const form = ref({ actual_weight: 0, notes: '' })

async function load() {
  loading.value = true
  try { 
    const res = await api.get('/inventory')
    checks.value = res.data 
  } finally { 
    loading.value = false 
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  }
}

async function save() {
  if (!form.value.actual_weight) return toast.error('الوزن الفعلي مطلوب')
  saving.value = true
  try { 
    await api.post('/inventory', form.value); 
    toast.success('تم تسجيل عملية الجرد بنجاح')
    showAdd.value = false; 
    form.value = { actual_weight: 0, notes: '' }
    load() 
  }
  catch { toast.error('حدث خطأ أثناء الحفظ') } 
  finally { saving.value = false }
}

function formatDate(d) { return d ? new Date(d).toLocaleDateString('ar-IQ', { month: 'long', day: 'numeric', year: 'numeric' }) : '' }
onMounted(load)
</script>

<style scoped>
.luxury-button {
  @apply gold-gradient-bg hover:shadow-gold-500/40 text-white px-6 py-3 rounded-2xl text-sm font-black shadow-xl shadow-gold-500/20 transition-all active:scale-95 flex items-center gap-2 overflow-hidden relative;
}
</style>
