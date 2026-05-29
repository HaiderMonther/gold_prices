<template>
  <div class="space-y-10 max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-black text-slate-900 tracking-tight">إدارة العملاء</h1>
        <p class="text-slate-400 font-bold mt-1 uppercase tracking-widest text-[10px]">CRM • Customer Relationship</p>
      </div>
      <button @click="showAdd = true" class="luxury-button">
        <i data-lucide="user-plus" class="w-5 h-5 stroke-[3]"></i>
        إضافة عميل جديد
      </button>
    </div>

    <!-- Stats/Filters Row -->
    <div class="grid grid-cols-1 lg:grid-cols-4 gap-8">
      <div class="lg:col-span-1 luxury-card p-6 flex flex-col justify-center">
        <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">إجمالي العملاء</div>
        <div class="text-3xl font-black text-slate-900 tracking-tight">{{ customers.length }}</div>
      </div>
      
      <div class="lg:col-span-3 luxury-card p-4 flex items-center px-8">
        <div class="relative group flex-1">
          <i data-lucide="search" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-gold-500 transition-colors w-5 h-5"></i>
          <input 
            type="text" 
            v-model="search"
            placeholder="بحث عن عميل بالاسم أو رقم الهاتف..." 
            class="w-full bg-slate-50/50 border border-slate-100 rounded-2xl pr-12 pl-4 py-4 text-sm font-bold outline-none focus:ring-4 focus:ring-gold-500/5 transition-all" 
          />
        </div>
      </div>
    </div>

    <!-- Customers Table -->
    <div class="luxury-card overflow-hidden bg-white">
      <div class="overflow-x-auto">
        <table class="w-full text-right border-collapse">
          <thead>
            <tr class="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] bg-slate-50/50">
              <th class="px-8 py-5 border-b border-slate-100">الاسم الكامل</th>
              <th class="px-8 py-5 border-b border-slate-100">النوع</th>
              <th class="px-8 py-5 border-b border-slate-100">رقم الهاتف</th>
              <th class="px-8 py-5 border-b border-slate-100">العنوان</th>
              <th class="px-8 py-5 border-b border-slate-100">رصيد الديون</th>
              <th class="px-8 py-5 border-b border-slate-100">تاريخ الانضمام</th>
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
              <td colspan="7">لا يوجد عملاء مطابقين للبحث</td>
            </tr>
            <tr 
              v-for="c in filtered" 
              :key="c.id" 
              class="group transition-colors hover:bg-slate-50/30"
            >
              <td class="px-8 py-6">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-xl bg-gold-50 text-gold-700 flex items-center justify-center font-black text-xs border border-gold-100/50">
                    {{ c.name.slice(0, 2) }}
                  </div>
                  <div class="font-black text-slate-900 text-sm tracking-tight">{{ c.name }}</div>
                </div>
              </td>
              <td class="px-8 py-6">
                <span :class="[
                  'text-[9px] px-3 py-1 rounded-full font-black uppercase tracking-[0.1em] ring-1',
                  c.type === 'trader' ? 'bg-indigo-100/50 text-indigo-700 ring-indigo-500/20' :
                  c.type === 'workshop' ? 'bg-amber-100/50 text-amber-700 ring-amber-500/20' :
                  'bg-emerald-100/50 text-emerald-700 ring-emerald-500/20'
                ]">
                  {{ typeLabel(c.type) }}
                </span>
              </td>
              <td class="px-8 py-6 text-sm font-bold text-slate-600" dir="ltr">{{ c.phone || '---' }}</td>
              <td class="px-8 py-6 text-xs text-slate-400 font-medium">{{ c.address || 'غير محدد' }}</td>
              <td class="px-8 py-6">
                <div :class="['text-sm font-black', parseFloat(c.debt_balance) > 0 ? 'text-rose-600' : 'text-emerald-600']">
                  {{ formatRawPrice(c.debt_balance) }} <span class="text-[10px] opacity-30">د.ع</span>
                </div>
              </td>
              <td class="px-8 py-6 text-[10px] font-bold text-slate-400 uppercase">{{ formatDate(c.created_at) }}</td>
              <td class="px-8 py-6">
                <div class="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-all translate-x-2 group-hover:translate-x-0">
                  <button @click="editCustomer(c)" class="p-2 text-slate-400 hover:text-gold-600 hover:bg-gold-50 rounded-xl transition-all"><i data-lucide="edit-2" class="w-4 h-4"></i></button>
                  <button @click="deleteCustomer(c)" class="p-2 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-xl transition-all"><i data-lucide="trash-2" class="w-4 h-4"></i></button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Add/Edit Modal -->
    <div v-if="showAdd || editItem" class="dialog-overlay">
      <div class="dialog-content">
        <div class="dialog-header">
          <h3 class="text-2xl font-black text-slate-900">{{ editItem ? 'تعديل بيانات العميل' : 'إضافة عميل جديد' }}</h3>
          <button @click="showAdd = false; editItem = null" class="p-3 hover:bg-white rounded-full shadow-sm transition-all"><i data-lucide="x" class="w-6 h-6 text-slate-400"></i></button>
        </div>
        <div class="dialog-body">
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">الاسم الكامل</label>
            <div class="relative group">
              <i data-lucide="user" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-gold-500 transition-colors w-5 h-5"></i>
              <input v-model="form.name" class="w-full bg-slate-50 border border-slate-100 rounded-2xl pr-12 pl-4 py-4 font-bold outline-none focus:ring-4 focus:ring-gold-500/5 transition-all" placeholder="أدخل اسم العميل..." />
            </div>
          </div>
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">نوع الحساب</label>
            <div class="flex bg-slate-100/50 p-1.5 rounded-2xl">
              <button v-for="t in [{v:'client',l:'عميل'},{v:'trader',l:'تاجر'},{v:'workshop',l:'ورشة'}]" :key="t.v" @click="form.type = t.v" :class="['flex-1 py-3 text-xs font-black rounded-xl transition-all', form.type === t.v ? 'bg-white shadow-xl text-gold-600' : 'text-slate-400']">
                {{ t.l }}
              </button>
            </div>
          </div>
          <div class="grid grid-cols-2 gap-6">
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">رقم الهاتف</label>
              <div class="relative group">
                <i data-lucide="phone" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-gold-500 transition-colors w-5 h-5"></i>
                <input v-model="form.phone" dir="ltr" class="w-full bg-slate-50 border border-slate-100 rounded-2xl pr-12 pl-4 py-4 font-bold outline-none focus:ring-4 focus:ring-gold-500/5 transition-all" placeholder="07XXXXXXXXX" />
              </div>
            </div>
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">العنوان</label>
              <div class="relative group">
                <i data-lucide="map-pin" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-gold-500 transition-colors w-5 h-5"></i>
                <input v-model="form.address" class="w-full bg-slate-50 border border-slate-100 rounded-2xl pr-12 pl-4 py-4 font-bold outline-none focus:ring-4 focus:ring-gold-500/5 transition-all" placeholder="المدينة، المنطقة..." />
              </div>
            </div>
          </div>
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">ملاحظات</label>
            <input v-model="form.notes" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none focus:ring-4 focus:ring-gold-500/5 transition-all" placeholder="ملاحظات إضافية..." />
          </div>
        </div>
        <div class="dialog-footer">
          <button @click="showAdd = false; editItem = null" class="flex-1 py-4 font-black text-slate-400 hover:text-slate-600 transition-colors">إلغاء</button>
          <button @click="save" :disabled="saving" class="flex-[2] gold-gradient-bg py-4 rounded-2xl text-white font-black shadow-lg shadow-gold-500/20 hover:scale-[1.02] active:scale-95 transition-all">
            {{ saving ? 'جاري الحفظ...' : (editItem ? 'تحديث العميل' : 'حفظ البيانات') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick, watch } from 'vue'
import { useRoute } from 'vue-router'
import api from '../api/axios'
import { useToastStore } from '../stores/toast'

const route = useRoute()
const toast = useToastStore()
const customers = ref([])
const loading = ref(true)
const saving = ref(false)
const search = ref('')
const showAdd = ref(false)
const editItem = ref(null)
const form = ref({ name: '', phone: '', address: '', type: 'client', notes: '' })

async function load() {
  loading.value = true
  try { customers.value = (await api.get('/customers')).data } 
  finally { 
    loading.value = false 
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  }
}

const filtered = computed(() => customers.value.filter(c =>
  !search.value || c.name.toLowerCase().includes(search.value.toLowerCase()) || (c.phone || '').includes(search.value)
))

function editCustomer(c) { 
  editItem.value = c; 
  form.value = { name: c.name, phone: c.phone || '', address: c.address || '', type: c.type || 'client', notes: c.notes || '' } 
  nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
}

function closeModal() { 
  showAdd.value = false; editItem.value = null; 
  form.value = { name: '', phone: '', address: '', type: 'client', notes: '' } 
}

async function save() {
  if (!form.value.name) return toast.error('الاسم مطلوب')
  saving.value = true
  try {
    if (editItem.value) { 
      await api.put(`/customers/${editItem.value.id}`, form.value); 
      toast.success('تم تحديث بيانات العميل بنجاح') 
    } else { 
      await api.post('/customers', form.value); 
      toast.success('تمت إضافة العميل الجديد بنجاح') 
    }
    closeModal(); load()
  } catch { 
    toast.error('حدث خطأ أثناء حفظ البيانات') 
  } finally { saving.value = false }
}

async function deleteCustomer(c) {
  if (!confirm(`هل أنت متأكد من حذف العميل "${c.name}"؟`)) return
  try { 
    await api.delete(`/customers/${c.id}`); 
    toast.success('تم حذف العميل بنجاح'); 
    load() 
  } catch { 
    toast.error('فشل عملية الحذف') 
  }
}

function typeLabel(t) { return { client: 'عميل', trader: 'تاجر', workshop: 'ورشة' }[t] || 'عميل' }
function formatRawPrice(v) { return new Intl.NumberFormat('ar-IQ').format(Math.round(v)) }
function formatDate(d) { return d ? new Date(d).toLocaleDateString('ar-IQ', { month: 'short', day: 'numeric' }) : '' }

onMounted(() => {
  if (route.query.search) {
    search.value = route.query.search
  }
  load()
})

watch(() => route.query.search, (newVal) => {
  if (newVal !== undefined) {
    search.value = newVal
  }
})
</script>

<style scoped>
.luxury-button {
  @apply gold-gradient-bg hover:shadow-gold-500/40 text-white px-6 py-3 rounded-2xl text-sm font-black shadow-xl shadow-gold-500/20 transition-all active:scale-95 flex items-center gap-2 overflow-hidden relative;
}
</style>
