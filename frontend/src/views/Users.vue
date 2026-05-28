<template>
  <div class="space-y-10 max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-black text-slate-900 tracking-tight">إدارة الطاقم</h1>
        <p class="text-slate-400 font-bold mt-1 uppercase tracking-widest text-[10px]">Staff • User Permissions</p>
      </div>
      <button @click="showAdd = true" class="luxury-button">
        <i data-lucide="user-plus" class="w-5 h-5 stroke-[3]"></i>
        إضافة مستخدم جديد
      </button>
    </div>

    <!-- Users Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
      <div 
        v-for="u in users" 
        :key="u.id" 
        class="luxury-card p-8 bg-white group hover:scale-[1.02] transition-all relative overflow-hidden"
      >
        <div class="absolute top-0 left-0 w-2 h-full" :class="u.is_active ? 'bg-emerald-500' : 'bg-slate-200'" />
        
        <div class="flex items-center gap-5 mb-8">
          <div class="w-16 h-16 rounded-2xl bg-gold-50 text-gold-700 flex items-center justify-center font-black text-xl shadow-inner border border-gold-100/50">
            {{ u.name.slice(0, 1) }}
          </div>
          <div class="flex-1 min-w-0">
            <h3 class="text-lg font-black text-slate-900 truncate tracking-tight">{{ u.name }}</h3>
            <div class="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-0.5">@{{ u.username }}</div>
          </div>
        </div>

        <div class="space-y-4">
          <div class="flex items-center justify-between p-4 bg-slate-50 rounded-2xl border border-slate-100/50">
            <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest">الدور الوظيفي</span>
            <span :class="['text-xs font-black px-3 py-1 rounded-xl ring-1', roleBadge(u.role)]">
              {{ roleLabels[u.role] || u.role }}
            </span>
          </div>
          
          <div class="flex items-center justify-between p-4 bg-slate-50 rounded-2xl border border-slate-100/50">
            <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest">تاريخ الانضمام</span>
            <span class="text-xs font-bold text-slate-600">{{ formatDate(u.created_at) }}</span>
          </div>
        </div>

        <div class="mt-8 pt-8 border-t border-slate-50 flex items-center justify-between">
          <div class="flex items-center gap-2">
            <div :class="['w-2 h-2 rounded-full animate-pulse', u.is_active ? 'bg-emerald-500' : 'bg-slate-300']" />
            <span class="text-[10px] font-black uppercase text-slate-400 tracking-widest">{{ u.is_active ? 'Active' : 'Locked' }}</span>
          </div>
          <div class="flex items-center gap-2">
            <button @click="editUser(u)" class="p-2.5 text-slate-400 hover:text-gold-600 hover:bg-gold-50 rounded-xl transition-all">
              <i data-lucide="edit-2" class="w-4 h-4"></i>
            </button>
            <button @click="toggleUser(u)" :class="['p-2.5 rounded-xl transition-all', u.is_active ? 'text-slate-400 hover:text-rose-600 hover:bg-rose-50' : 'text-emerald-600 bg-emerald-50']">
              <i :data-lucide="u.is_active ? 'lock' : 'unlock'" class="w-4 h-4"></i>
            </button>
          </div>
        </div>
      </div>
      
      <!-- Loading State -->
      <template v-if="loading">
        <div v-for="n in 3" :key="'skeleton-'+n" class="luxury-card p-8 bg-white animate-pulse">
          <div class="flex items-center gap-5 mb-8">
            <div class="w-16 h-16 rounded-2xl bg-slate-100" />
            <div class="flex-1 space-y-2">
              <div class="h-4 bg-slate-100 rounded w-2/3" />
              <div class="h-3 bg-slate-100 rounded w-1/2" />
            </div>
          </div>
          <div class="space-y-4">
            <div class="h-12 bg-slate-100 rounded-2xl" />
            <div class="h-12 bg-slate-100 rounded-2xl" />
          </div>
        </div>
      </template>
    </div>

    <!-- User Modal -->
    <div v-if="showAdd || editItem" class="dialog-overlay">
      <div class="dialog-content">
        <div class="dialog-header">
          <h3 class="text-2xl font-black text-slate-900">{{ editItem ? 'تعديل موظف' : 'إضافة موظف' }}</h3>
          <button @click="showAdd = false; editItem = null" class="p-3 hover:bg-white rounded-full shadow-sm transition-all"><i data-lucide="x" class="w-6 h-6 text-slate-400"></i></button>
        </div>
        <div class="dialog-body">
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">الاسم الكامل</label>
            <input v-model="form.name" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none focus:ring-4 focus:ring-gold-500/5 transition-all" />
          </div>
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">اسم المستخدم (Login ID)</label>
            <input v-model="form.username" dir="ltr" :disabled="!!editItem" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none disabled:opacity-50" />
          </div>
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">{{ editItem ? 'كلمة المرور الجديدة' : 'كلمة المرور' }}</label>
            <input v-model="form.password" type="password" dir="ltr" class="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 font-bold outline-none" />
          </div>
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest mr-2">الدور / الصلاحيات</label>
            <div class="flex bg-slate-100/50 p-1.5 rounded-2xl gap-1">
              <button 
                v-for="(label, role) in roleLabels" 
                :key="role"
                @click="form.role = role"
                :class="['flex-1 py-3 text-[11px] font-black rounded-xl transition-all', form.role === role ? 'bg-white shadow-xl text-gold-600' : 'text-slate-400']"
              >
                {{ label }}
              </button>
            </div>
          </div>
        </div>
        <div class="dialog-footer">
          <button @click="showAdd = false; editItem = null" class="flex-1 py-4 font-black text-slate-400 hover:text-slate-600 transition-colors">إلغاء</button>
          <button @click="save" :disabled="saving" class="flex-[2] gold-gradient-bg py-4 rounded-2xl text-white font-black shadow-lg shadow-gold-500/20 hover:scale-[1.02] active:scale-95 transition-all">
            {{ saving ? 'جاري الحفظ...' : (editItem ? 'تحديث الحساب' : 'إنشاء الحساب') }}
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
const users = ref([])
const loading = ref(true)
const saving = ref(false)
const showAdd = ref(false)
const editItem = ref(null)
const form = ref({ name: '', username: '', password: '', role: 'cashier' })

const roleLabels = { admin: 'مدير', cashier: 'كاشير', accountant: 'محاسب' }

async function load() {
  loading.value = true
  try { users.value = (await api.get('/users')).data } 
  finally { 
    loading.value = false 
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  }
}

function editUser(u) { 
  editItem.value = u; 
  form.value = { name: u.name, username: u.username, password: '', role: u.role } 
  nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
}

function closeModal() { 
  showAdd.value = false; editItem.value = null; 
  form.value = { name: '', username: '', password: '', role: 'cashier' } 
}

async function save() {
  if (!form.value.name || !form.value.username) return toast.error('الاسم واسم المستخدم مطلوبان')
  saving.value = true
  try {
    if (editItem.value) {
      const d = { name: form.value.name, role: form.value.role }
      if (form.value.password) d.password = form.value.password
      await api.put(`/users/${editItem.value.id}`, d)
      toast.success('تم تحديث بيانات المستخدم')
    } else {
      if (!form.value.password) return toast.error('كلمة المرور مطلوبة للمستخدم الجديد')
      await api.post('/users', form.value)
      toast.success('تم إنشاء الحساب الجديد بنجاح')
    }
    closeModal(); load()
  } catch (e) { 
    toast.error(e.response?.data?.message || 'حدث خطأ أثناء حفظ البيانات') 
  } finally { saving.value = false }
}

async function toggleUser(u) {
  try { 
    await api.put(`/users/${u.id}`, { is_active: !u.is_active })
    toast.success(u.is_active ? 'تم تعطيل الحساب' : 'تم تفعيل الحساب')
    load() 
  } catch { toast.error('فشل تغيير حالة المستخدم') }
}

function roleBadge(r) { 
  return { 
    admin: 'bg-gold-50 text-gold-700 ring-gold-500/20', 
    cashier: 'bg-emerald-50 text-emerald-700 ring-emerald-500/20', 
    accountant: 'bg-indigo-50 text-indigo-700 ring-indigo-500/20' 
  }[r] || 'bg-slate-50 text-slate-500 ring-slate-500/20' 
}

function formatDate(d) { return d ? new Date(d).toLocaleDateString('ar-IQ', { month: 'short', year: 'numeric' }) : '' }
onMounted(load)
</script>

<style scoped>
.luxury-button {
  @apply gold-gradient-bg hover:shadow-gold-500/40 text-white px-6 py-3 rounded-2xl text-sm font-black shadow-xl shadow-gold-500/20 transition-all active:scale-95 flex items-center gap-2 overflow-hidden relative;
}
</style>
