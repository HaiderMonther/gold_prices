<template>
  <div class="luxury-card overflow-hidden min-h-[600px] bg-white max-w-7xl mx-auto">
    <div class="p-10 border-b border-slate-50 flex flex-wrap items-center justify-between gap-6">
      <div>
        <h3 class="text-xl font-black text-slate-900 tracking-tight">المخزون المركزي</h3>
        <p class="text-xs font-bold text-slate-400 mt-1 uppercase tracking-wider">Stock • Portfolio Management</p>
      </div>
      <div class="flex items-center gap-4">
        <div class="relative group">
          <i data-lucide="search" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-gold-500 transition-colors w-4 h-4"></i>
          <input 
            type="text" 
            v-model="search"
            placeholder="بحث مديّم..." 
            class="bg-slate-50/50 border border-slate-100 rounded-2xl pr-12 pl-4 py-3 text-sm font-bold outline-none w-64 focus:ring-4 focus:ring-gold-500/5 transition-all" 
          />
        </div>
        <select v-model="filterKarat" class="bg-slate-50 text-xs px-4 py-3 rounded-2xl border-none font-black text-slate-600 focus:ring-4 focus:ring-gold-500/5 cursor-pointer">
          <option value="">جميع العيارات</option>
          <option value="24">24 قيراط</option>
          <option value="21">21 قيراط</option>
          <option value="18">18 قيراط</option>
        </select>
        <button 
          @click="showAdd = true"
          class="gold-gradient-bg text-white px-6 py-3 rounded-2xl text-xs font-black shadow-xl shadow-gold-500/20 flex items-center gap-2 transition-all hover:scale-105 active:scale-95"
        >
          <i data-lucide="plus" class="w-4 h-4 stroke-[3]"></i> إضافة للمخزون
        </button>
      </div>
    </div>

    <div class="overflow-x-auto">
      <table class="w-full text-right border-collapse">
        <thead>
          <tr class="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] bg-slate-50/50">
            <th class="px-8 py-5 border-b border-slate-100">الباركود</th>
            <th class="px-8 py-5 border-b border-slate-100">القطعة</th>
            <th class="px-8 py-5 border-b border-slate-100">الوزن الصافي</th>
            <th class="px-8 py-5 border-b border-slate-100 font-black text-gold-600">القيراط</th>
            <th class="px-8 py-5 border-b border-slate-100">المصنعية</th>
            <th class="px-8 py-5 border-b border-slate-100 text-center">الحالة</th>
            <th class="px-8 py-5 border-b border-slate-100">تحكم</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-50">
          <tr v-if="loading">
            <td colspan="7" class="px-8 py-10 text-center">
              <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-gold-500 mx-auto"></div>
            </td>
          </tr>
          <tr v-else-if="filtered.length === 0" class="px-8 py-10 text-center">
            <td colspan="7" class="py-20 text-slate-400 font-bold italic">لا توجد قطع مطابقة للبحث</td>
          </tr>
          <tr 
            v-for="p in filtered" 
            :key="p.id" 
            class="group transition-colors hover:bg-slate-50/30"
          >
            <td class="px-8 py-6 text-xs font-black text-slate-400 tracking-tighter">{{ p.barcode || 'NO-CODE' }}</td>
            <td class="px-8 py-6">
              <div class="font-black text-slate-900 text-sm tracking-tight">{{ p.name }}</div>
            </td>
            <td class="px-8 py-6 text-sm font-black text-slate-600 tracking-tight">{{ parseFloat(p.weight).toFixed(3) }} ج</td>
            <td class="px-8 py-6">
              <span :class="[
                'text-[10px] px-3 py-1 rounded-xl font-black border uppercase tracking-wider',
                p.karat == 24 ? 'bg-emerald-50 text-emerald-700 border-emerald-200/50 shadow-sm' :
                p.karat == 21 ? 'bg-gold-50 text-gold-700 border-gold-200/50' :
                'bg-indigo-50 text-indigo-700 border-indigo-200/50'
              ]">
                K{{ p.karat }}
              </span>
            </td>
            <td class="px-8 py-6 text-xs font-bold text-slate-500">{{ formatRawPrice(p.craft_price) }}</td>
            <td class="px-8 py-6 text-center">
              <span :class="[
                'text-[9px] px-3 py-1 rounded-full font-black uppercase tracking-[0.1em] ring-1',
                p.status === 'available' ? 'bg-emerald-100/50 text-emerald-700 ring-emerald-500/20' :
                p.status === 'sold' ? 'bg-rose-100/50 text-rose-700 ring-rose-500/20' :
                'bg-amber-100/50 text-amber-700 ring-amber-500/20'
              ]">
                {{ statusLabel(p.status) }}
              </span>
            </td>
            <td class="px-8 py-6">
              <div class="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-all translate-x-2 group-hover:translate-x-0">
                <button @click="editProduct(p)" class="p-2 text-slate-400 hover:text-gold-600 hover:bg-gold-50 rounded-xl transition-all"><i data-lucide="edit-2" class="w-4 h-4"></i></button>
                <button @click="deleteProduct(p)" class="p-2 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-xl transition-all"><i data-lucide="trash-2" class="w-4 h-4"></i></button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="p-10 border-t border-slate-50 flex items-center justify-between text-[11px] font-black text-slate-400 uppercase tracking-widest">
      <span>Active Storage: {{ filtered.length }} SKU Units</span>
      <div class="flex gap-3">
         <button class="px-4 py-2 border border-slate-200 rounded-xl hover:bg-slate-50 transition-all">Previous</button>
         <button class="px-4 py-2 bg-slate-900 text-white rounded-xl hover:bg-slate-800 transition-all">Next Page</button>
      </div>
    </div>

    <!-- Add Modal -->
    <div v-if="showAdd || editItem" class="dialog-overlay">
      <div class="dialog-content">
        <div class="dialog-header">
          <h3 class="text-2xl font-black text-slate-900">{{ editItem ? 'تعديل قطعة ذهب' : 'إضافة قطعة ذهب' }}</h3>
          <button @click="showAdd = false; editItem = null" class="p-3 hover:bg-white rounded-full shadow-sm transition-all"><i data-lucide="x" class="w-6 h-6 text-slate-400"></i></button>
        </div>
        <div class="dialog-body">
          <div class="space-y-2">
            <label class="text-xs font-black text-slate-500 uppercase tracking-widest">اسم القطعة</label>
            <input v-model="form.name" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none focus:ring-4 focus:ring-gold-500/5 transition-all" />
          </div>
          <div class="grid grid-cols-2 gap-6">
            <div class="space-y-2">
              <label class="text-xs font-black text-slate-500 uppercase tracking-widest">العيار</label>
              <select v-model="form.karat" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none appearance-none cursor-pointer">
                <option value="24">24 قيراط</option>
                <option value="21">21 قيراط</option>
                <option value="18">18 قيراط</option>
              </select>
            </div>
            <div class="space-y-2">
              <label class="text-xs font-black text-slate-500 uppercase tracking-widest">الوزن (جرام)</label>
              <input v-model.number="form.weight" type="number" step="0.001" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none focus:ring-4 focus:ring-gold-500/5" />
            </div>
          </div>
          <div class="grid grid-cols-2 gap-6">
            <div class="space-y-2">
              <label class="text-xs font-black text-slate-500 uppercase tracking-widest">أجرة الصنعة</label>
              <input v-model.number="form.craft_price" type="number" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none" />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-black text-slate-500 uppercase tracking-widest">الباركود</label>
              <input v-model="form.barcode" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none" />
            </div>
          </div>
          <div v-if="editItem" class="space-y-2">
            <label class="text-xs font-black text-slate-500 uppercase tracking-widest">الحالة</label>
            <select v-model="form.status" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none">
              <option value="available">متاح</option>
              <option value="sold">مباع</option>
              <option value="reserved">محجوز</option>
            </select>
          </div>
        </div>
        <div class="dialog-footer">
          <button @click="showAdd = false; editItem = null" class="flex-1 py-4 font-black text-slate-400 hover:text-slate-600 transition-colors">إلغاء</button>
          <button @click="saveProduct" :disabled="saving" class="flex-[2] gold-gradient-bg py-4 rounded-2xl text-white font-black shadow-lg shadow-gold-500/20 hover:scale-[1.02] active:scale-95 transition-all">
            {{ saving ? 'جاري الحفظ...' : (editItem ? 'تحديث القطعة' : 'إضافة للمخزون') }}
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
const products = ref([])
const loading = ref(true)
const saving = ref(false)
const search = ref('')
const filterKarat = ref('')
const showAdd = ref(false)
const editItem = ref(null)

const form = ref({ name: '', karat: 21, weight: '', craft_price: 0, barcode: '', status: 'available' })

async function load() {
  loading.value = true
  try {
    const res = await api.get('/products')
    products.value = res.data
  } finally {
    loading.value = false
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  }
}

const filtered = computed(() => {
  return products.value.filter(p => {
    const matchSearch = !search.value || p.name.toLowerCase().includes(search.value.toLowerCase()) || (p.barcode || '').toLowerCase().includes(search.value.toLowerCase())
    const matchKarat = !filterKarat.value || p.karat == filterKarat.value
    return matchSearch && matchKarat
  })
})

function editProduct(p) {
  editItem.value = p
  form.value = { name: p.name, karat: p.karat, weight: p.weight, craft_price: p.craft_price, barcode: p.barcode || '', status: p.status }
  nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
}

function closeModal() { 
  showAdd.value = false; editItem.value = null; 
  form.value = { name: '', karat: 21, weight: '', craft_price: 0, barcode: '', status: 'available' } 
}

async function saveProduct() {
  if (!form.value.name || !form.value.weight) return toast.error('الاسم والوزن مطلوبان')
  saving.value = true
  try {
    if (editItem.value) {
      await api.put(`/products/${editItem.value.id}`, form.value)
      toast.success('تم تحديث القطعة')
    } else {
      await api.post('/products', form.value)
      toast.success('تمت إضافة القطعة')
    }
    closeModal(); load()
  } catch (e) {
    toast.error(e.response?.data?.message || 'حدث خطأ')
  } finally { saving.value = false }
}

async function deleteProduct(p) {
  if (!confirm(`هل تريد حذف "${p.name}"؟`)) return
  try { await api.delete(`/products/${p.id}`); toast.success('تم الحذف'); load() }
  catch { toast.error('فشل الحذف') }
}

function statusLabel(s) { return { available: 'متاح', sold: 'مباع', reserved: 'محجوز' }[s] || s }
function formatRawPrice(v) { return new Intl.NumberFormat('ar-IQ').format(Math.round(v)) + ' د.ع' }
onMounted(load)
</script>
