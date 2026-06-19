<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-xl font-black text-slate-900">العملاء (SaaS Tenants)</h2>
        <p class="text-sm text-slate-500 mt-1">إدارة الشركات والعملاء المشتركين في النظام</p>
      </div>
      <button @click="openAddModal" class="luxury-button">
        <i data-lucide="plus" class="w-5 h-5"></i>
        <span>إضافة عميل جديد</span>
      </button>
    </div>

    <!-- Stats Row -->
    <div class="grid grid-cols-3 gap-4">
      <div class="bg-white rounded-2xl p-4 border border-slate-100 shadow-sm text-center">
        <div class="text-2xl font-black text-slate-900">{{ tenants.length }}</div>
        <div class="text-xs font-bold text-slate-400 mt-1">إجمالي العملاء</div>
      </div>
      <div class="bg-emerald-50 rounded-2xl p-4 border border-emerald-100 text-center">
        <div class="text-2xl font-black text-emerald-600">{{ tenants.filter(t => t.is_active).length }}</div>
        <div class="text-xs font-bold text-emerald-500 mt-1">حسابات نشطة</div>
      </div>
      <div class="bg-rose-50 rounded-2xl p-4 border border-rose-100 text-center">
        <div class="text-2xl font-black text-rose-500">{{ tenants.filter(t => !t.is_active).length }}</div>
        <div class="text-xs font-bold text-rose-400 mt-1">حسابات متوقفة</div>
      </div>
    </div>

    <!-- Tenants Grid -->
    <div v-if="loading" class="flex justify-center py-12">
      <div class="w-8 h-8 border-4 border-gold-500 border-t-transparent rounded-full animate-spin"></div>
    </div>
    <div v-else-if="tenants.length === 0" class="text-center py-16 text-slate-400">
      <i data-lucide="building" class="w-12 h-12 mx-auto mb-4 opacity-30"></i>
      <p class="font-bold">لا يوجد عملاء مضافين بعد</p>
    </div>
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="tenant in tenants" :key="tenant.id" 
           class="bg-white rounded-3xl p-6 shadow-sm border border-slate-100 flex flex-col hover:shadow-lg transition-shadow">
        <div class="flex justify-between items-start mb-4">
          <div class="w-14 h-14 rounded-2xl overflow-hidden border border-slate-100 bg-slate-50 flex items-center justify-center">
            <img v-if="tenant.logo_url" :key="tenant.logo_url" :src="getLogoUrl(tenant.logo_url)" class="w-full h-full object-contain" alt="شعار" 
                 @error="(e) => e.target.style.display='none'"
                 @load="(e) => e.target.style.display='block'" />
            <i v-else data-lucide="building" class="w-7 h-7 text-slate-300"></i>
          </div>
          <span :class="tenant.is_active ? 'bg-emerald-50 text-emerald-600 border-emerald-100' : 'bg-rose-50 text-rose-600 border-rose-100'" 
                class="px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-wider border">
            {{ tenant.is_active ? 'نشط' : 'متوقف' }}
          </span>
        </div>
        <h3 class="text-lg font-black text-slate-900 mb-1">{{ tenant.name }}</h3>
        <div class="flex items-center gap-1.5 mb-3">
          <i data-lucide="key" class="w-4 h-4 text-gold-500"></i>
          <span class="text-sm font-mono font-bold text-gold-600 bg-gold-50 px-2 py-0.5 rounded-lg">{{ tenant.tenant_code }}</span>
        </div>
        <div v-if="tenant.primary_color" class="flex items-center gap-1.5 mb-2 text-xs text-slate-400">
          <span class="w-4 h-4 rounded-full border border-slate-200 shrink-0" :style="`background:${tenant.primary_color}`"></span>
          {{ tenant.primary_color }}
        </div>
        
        <div class="mt-auto pt-4 border-t border-slate-50 flex gap-2">
          <button @click="toggleStatus(tenant)" 
                  class="flex-1 py-2 rounded-xl text-xs font-bold transition-colors" 
                  :class="tenant.is_active ? 'bg-rose-50 text-rose-600 hover:bg-rose-100' : 'bg-emerald-50 text-emerald-600 hover:bg-emerald-100'">
            {{ tenant.is_active ? 'إيقاف' : 'تفعيل' }}
          </button>
          <button @click="editTenant(tenant)" class="px-4 py-2 rounded-xl text-xs font-bold bg-slate-50 text-slate-600 hover:bg-slate-100 transition-colors flex items-center gap-1">
            <i data-lucide="pencil" class="w-3.5 h-3.5"></i>
            تعديل
          </button>
        </div>
      </div>
    </div>

    <!-- Add/Edit Modal -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-slate-900/40 backdrop-blur-sm" @click="showModal = false"></div>
      <div class="bg-white rounded-3xl w-full max-w-lg relative z-10 shadow-2xl overflow-hidden max-h-[90vh] flex flex-col">
        <!-- Modal Header -->
        <div class="p-6 border-b border-slate-100 flex items-center justify-between bg-slate-50/50 shrink-0">
          <h3 class="text-lg font-black text-slate-900">{{ isEditing ? 'تعديل العميل' : 'إضافة عميل جديد' }}</h3>
          <button @click="showModal = false" class="w-8 h-8 rounded-full bg-white flex items-center justify-center text-slate-400 hover:text-rose-500 shadow-sm transition-colors">
            <i data-lucide="x" class="w-4 h-4"></i>
          </button>
        </div>
        
        <div class="overflow-y-auto flex-1">
          <form @submit.prevent="saveForm" class="p-6 space-y-5">
            
            <!-- Logo Upload Section -->
            <div class="space-y-3">
              <label class="text-xs font-bold text-slate-700">شعار الشركة</label>
              
              <!-- Current / Preview logo -->
              <div class="flex items-center gap-4">
                <div class="w-20 h-20 rounded-2xl border-2 border-dashed border-slate-200 bg-slate-50 flex items-center justify-center overflow-hidden shrink-0 relative group cursor-pointer"
                     @click="triggerFileInput">
                  <img v-if="logoPreview" :src="logoPreview" class="w-full h-full object-contain" alt="معاينة" />
                  <i v-else data-lucide="image-plus" class="w-8 h-8 text-slate-300 group-hover:text-gold-500 transition-colors"></i>
                  <div v-if="logoPreview" class="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                    <i data-lucide="camera" class="w-6 h-6 text-white"></i>
                  </div>
                </div>
                <div class="flex-1">
                  <p class="text-sm font-bold text-slate-700 mb-2">رفع صورة الشعار</p>
                  <p class="text-xs text-slate-400 mb-3">PNG, JPG, SVG, WEBP (حجم أقصى 5MB)</p>
                  <div class="flex gap-2">
                    <button type="button" @click="triggerFileInput" 
                            class="px-4 py-2 bg-gold-50 text-gold-700 rounded-xl text-xs font-bold border border-gold-200 hover:bg-gold-100 transition-colors flex items-center gap-1.5">
                      <i data-lucide="upload" class="w-3.5 h-3.5"></i>
                      اختر صورة
                    </button>
                    <button v-if="logoPreview" type="button" @click="removeLogo"
                            class="px-4 py-2 bg-rose-50 text-rose-600 rounded-xl text-xs font-bold border border-rose-100 hover:bg-rose-100 transition-colors">
                      حذف
                    </button>
                  </div>
                </div>
              </div>
              
              <!-- Hidden file input -->
              <input 
                ref="fileInput"
                type="file" 
                accept="image/*" 
                class="hidden"
                @change="handleFileSelect"
              />
              
              <!-- Upload progress -->
              <div v-if="uploadingLogo" class="flex items-center gap-2 text-xs text-gold-600">
                <div class="w-3 h-3 border-2 border-gold-500 border-t-transparent rounded-full animate-spin"></div>
                جارٍ رفع الصورة...
              </div>
            </div>

            <div class="border-t border-slate-100"></div>

            <!-- Name -->
            <div class="space-y-2">
              <label class="text-xs font-bold text-slate-700">اسم الشركة / العميل <span class="text-rose-500">*</span></label>
              <input v-model="form.name" type="text" required 
                     class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-gold-500/20 focus:border-gold-500 outline-none font-medium" 
                     placeholder="مجوهرات النخيل">
            </div>
            
            <!-- Tenant Code -->
            <div class="space-y-2">
              <label class="text-xs font-bold text-slate-700">
                كود الشركة <span class="text-rose-500">*</span>
                <span class="text-[10px] text-slate-400 font-normal mr-1">(يدخله المستخدم عند تسجيل الدخول)</span>
              </label>
              <div class="relative">
                <input v-model="form.tenant_code" type="text" dir="ltr" required
                       class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-gold-500/20 focus:border-gold-500 outline-none font-mono font-bold pr-10" 
                       placeholder="nakheel2024" 
                       @input="form.tenant_code = form.tenant_code.toLowerCase().replace(/[^a-z0-9]/g, '')">
                <i data-lucide="key" class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gold-400"></i>
              </div>
              <p class="text-[10px] text-slate-400 flex items-center gap-1">
                <i data-lucide="info" class="w-3 h-3"></i>
                أحرف إنجليزية صغيرة وأرقام فقط، بدون مسافات
              </p>
            </div>

            <!-- Primary Color -->
            <div class="space-y-2">
              <label class="text-xs font-bold text-slate-700">اللون الرئيسي (اختياري)</label>
              <div class="flex items-center gap-3">
                <input v-model="form.primary_color" type="color" 
                       class="w-12 h-12 rounded-xl border-2 border-slate-200 cursor-pointer p-1 bg-white" />
                <div class="flex-1 relative">
                  <input v-model="form.primary_color" type="text" dir="ltr" 
                         class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-sm font-mono focus:ring-2 focus:ring-gold-500/20 focus:border-gold-500 outline-none" 
                         placeholder="#D69E27" />
                </div>
                <!-- Color presets -->
                <div class="flex gap-1.5">
                  <button v-for="c in colorPresets" :key="c" type="button"
                          @click="form.primary_color = c"
                          class="w-7 h-7 rounded-lg border-2 transition-transform hover:scale-110"
                          :class="form.primary_color === c ? 'border-slate-400 scale-110' : 'border-transparent'"
                          :style="`background: ${c}`"></button>
                </div>
              </div>
            </div>
            
            <div class="pt-2 pb-1">
              <button type="submit" :disabled="saving || uploadingLogo" class="w-full luxury-button justify-center py-3.5">
                <i v-if="saving" data-lucide="loader-2" class="w-5 h-5 animate-spin"></i>
                <span v-else>{{ isEditing ? 'حفظ التعديلات' : 'إنشاء الحساب' }}</span>
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick } from 'vue'
import api from '../../api/axios'

const API_BASE = import.meta.env.VITE_API_URL?.replace('/api', '') || ''

const tenants = ref([])
const loading = ref(true)
const showModal = ref(false)
const isEditing = ref(false)
const saving = ref(false)
const editingId = ref(null)
const fileInput = ref(null)
const logoPreview = ref(null)
const selectedFile = ref(null)
const uploadingLogo = ref(false)

const form = ref({ name: '', tenant_code: '', logo_url: '', primary_color: '#D69E27' })

const colorPresets = ['#D69E27', '#3B82F6', '#10B981', '#8B5CF6', '#EF4444', '#F97316', '#1E293B']

// Build correct URL for logos (relative API paths or external URLs)
const getLogoUrl = (url) => {
  if (!url) return ''
  if (url.startsWith('http')) return url
  // If it's a relative API path like /api/tenants/logo/xxx
  return `${API_BASE}${url}`
}

const fetchTenants = async () => {
  try {
    const res = await api.get(`/tenants?_t=${Date.now()}`)
    tenants.value = res.data
  } catch (error) {
    console.error('Error fetching tenants:', error)
  } finally {
    loading.value = false
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  }
}

const openAddModal = () => {
  isEditing.value = false
  editingId.value = null
  form.value = { name: '', tenant_code: '', logo_url: '', primary_color: '#D69E27' }
  logoPreview.value = null
  selectedFile.value = null
  showModal.value = true
  nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
}

const editTenant = (tenant) => {
  isEditing.value = true
  editingId.value = tenant.id
  form.value = {
    name: tenant.name,
    tenant_code: tenant.tenant_code,
    logo_url: tenant.logo_url || '',
    primary_color: tenant.primary_color || '#D69E27',
  }
  logoPreview.value = tenant.logo_url ? getLogoUrl(tenant.logo_url) : null
  selectedFile.value = null
  showModal.value = true
  nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
}

const triggerFileInput = () => {
  fileInput.value?.click()
}

const handleFileSelect = (event) => {
  const file = event.target.files[0]
  if (!file) return
  
  selectedFile.value = file
  
  const reader = new FileReader()
  reader.onload = (e) => {
    logoPreview.value = e.target.result
  }
  reader.readAsDataURL(file)
}

const removeLogo = () => {
  logoPreview.value = null
  selectedFile.value = null
  form.value.logo_url = ''
  if (fileInput.value) fileInput.value.value = ''
}

const uploadLogoFile = async (tenantId) => {
  if (!selectedFile.value) return null
  
  uploadingLogo.value = true
  try {
    const formData = new FormData()
    formData.append('logo', selectedFile.value)
    const res = await api.post(`/tenants/${tenantId}/logo`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
    return res.data.logo_url
  } catch (error) {
    console.error('Logo upload error:', error)
    return null
  } finally {
    uploadingLogo.value = false
  }
}

const saveForm = async () => {
  if (!form.value.name || !form.value.tenant_code) return
  
  saving.value = true
  try {
    let savedId = editingId.value

    if (isEditing.value) {
      await api.put(`/tenants/${savedId}`, {
        name: form.value.name,
        tenant_code: form.value.tenant_code,
        primary_color: form.value.primary_color || null,
        // logo_url updated separately via file upload
        ...(form.value.logo_url === '' ? { logo_url: null } : {}),
      })
    } else {
      const res = await api.post('/tenants', {
        name: form.value.name,
        tenant_code: form.value.tenant_code,
        primary_color: form.value.primary_color || null,
      })
      savedId = res.data.id
    }

    // Upload logo file if one was selected
    if (selectedFile.value && savedId) {
      const newLogoUrl = await uploadLogoFile(savedId)
      if (newLogoUrl) {
        // Manually update the local form and tenant to ensure reactivity
        form.value.logo_url = newLogoUrl
        const idx = tenants.value.findIndex(t => t.id === savedId)
        if (idx !== -1) tenants.value[idx].logo_url = newLogoUrl
      }
    }

    showModal.value = false
    await fetchTenants()
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  } catch (error) {
    alert(error.response?.data?.message || 'حدث خطأ، قد يكون الكود مستخدماً مسبقاً')
  } finally {
    saving.value = false
  }
}

const toggleStatus = async (tenant) => {
  try {
    await api.put(`/tenants/${tenant.id}`, { is_active: !tenant.is_active })
    tenant.is_active = !tenant.is_active
  } catch (error) {
    console.error('Error toggling status:', error)
  }
}

onMounted(() => {
  fetchTenants()
  if (window.refreshIcons) setTimeout(() => window.refreshIcons(), 100)
})
</script>

<style scoped>
.luxury-button {
  @apply bg-gradient-to-l from-gold-500 to-gold-400 text-white px-6 py-3 rounded-2xl text-sm font-black shadow-lg shadow-gold-500/30 transition-all hover:scale-105 active:scale-95 flex items-center gap-2;
}
</style>
