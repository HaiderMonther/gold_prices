<template>
  <div class="space-y-8 max-w-7xl mx-auto" dir="rtl">

    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-3xl font-black text-slate-900 tracking-tight">إدارة الصلاحيات</h1>
        <p class="text-slate-400 font-bold mt-1 uppercase tracking-widest text-[10px]">Roles & Permissions Management</p>
      </div>
      <button v-if="activeTab === 'roles'" @click="openCreateRole" class="perm-luxury-btn">
        <i data-lucide="shield-plus" class="w-5 h-5 stroke-[2.5]"></i>
        دور جديد
      </button>
    </div>

    <!-- Tab Bar -->
    <div class="flex bg-white border border-slate-100 rounded-2xl p-1.5 gap-1.5 shadow-sm w-fit">
      <button
        v-for="tab in tabs"
        :key="tab.id"
        @click="activeTab = tab.id"
        :class="[
          'flex items-center gap-2 px-5 py-2.5 rounded-xl text-sm font-black transition-all duration-300',
          activeTab === tab.id
            ? 'gold-gradient-bg text-white shadow-lg shadow-gold-500/20'
            : 'text-slate-400 hover:text-slate-700 hover:bg-slate-50'
        ]"
      >
        <i :data-lucide="tab.icon" class="w-4 h-4"></i>
        {{ tab.label }}
        <span
          v-if="tab.count !== null"
          :class="['text-[10px] px-2 py-0.5 rounded-full font-black', activeTab === tab.id ? 'bg-white/20 text-white' : 'bg-slate-100 text-slate-500']"
        >
          {{ tab.count }}
        </span>
      </button>
    </div>

    <!-- ===== TAB: الأدوار ===== -->
    <transition name="tab-fade" mode="out-in">
      <div v-if="activeTab === 'roles'" key="roles">

        <!-- Loading Skeleton -->
        <div v-if="loadingRoles" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div v-for="n in 3" :key="n" class="perm-card p-8 animate-pulse">
            <div class="flex items-center gap-4 mb-6">
              <div class="w-14 h-14 rounded-2xl bg-slate-100"></div>
              <div class="flex-1 space-y-2">
                <div class="h-4 bg-slate-100 rounded w-2/3"></div>
                <div class="h-3 bg-slate-100 rounded w-1/2"></div>
              </div>
            </div>
            <div class="space-y-2">
              <div class="h-8 bg-slate-100 rounded-xl"></div>
              <div class="h-8 bg-slate-100 rounded-xl"></div>
            </div>
          </div>
        </div>

        <!-- Roles Grid -->
        <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div
            v-for="role in roles"
            :key="role.id"
            class="perm-card p-8 group"
          >
            <!-- Role Header -->
            <div class="flex items-start gap-4 mb-6">
              <div :class="['w-14 h-14 rounded-2xl flex items-center justify-center shrink-0 shadow-inner', roleColor(role.name).bg]">
                <i :data-lucide="roleIcon(role.name)" :class="['w-7 h-7', roleColor(role.name).icon]"></i>
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2 flex-wrap">
                  <h3 class="text-lg font-black text-slate-900 tracking-tight">{{ role.display_name }}</h3>
                  <span v-if="role.is_system" class="text-[9px] font-black px-2 py-0.5 rounded-full bg-gold-50 text-gold-600 ring-1 ring-gold-200/50">نظام</span>
                </div>
                <p class="text-[11px] text-slate-400 font-medium mt-0.5 leading-relaxed">{{ role.description || '—' }}</p>
              </div>
            </div>

            <!-- Permissions Count -->
            <div class="p-4 bg-slate-50 rounded-2xl border border-slate-100/60 mb-6">
              <div class="flex items-center justify-between mb-3">
                <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest">الصلاحيات المُعيّنة</span>
                <span class="text-sm font-black text-gold-600">{{ role.permissions?.length || 0 }}</span>
              </div>
              <!-- Mini permission pills -->
              <div class="flex flex-wrap gap-1.5 max-h-16 overflow-hidden">
                <span
                  v-for="p in (role.permissions || []).slice(0, 6)"
                  :key="p.id"
                  class="text-[9px] font-bold px-2 py-0.5 bg-white rounded-lg border border-slate-200/60 text-slate-500 whitespace-nowrap"
                >
                  {{ p.display_name }}
                </span>
                <span
                  v-if="(role.permissions?.length || 0) > 6"
                  class="text-[9px] font-black px-2 py-0.5 bg-gold-50 rounded-lg border border-gold-100 text-gold-600"
                >
                  +{{ role.permissions.length - 6 }}
                </span>
              </div>
            </div>

            <!-- Actions -->
            <div class="flex items-center gap-2">
              <button @click="openEditRole(role)" class="flex-1 flex items-center justify-center gap-2 py-2.5 bg-slate-50 hover:bg-gold-50 text-slate-500 hover:text-gold-600 rounded-xl text-xs font-black transition-all border border-slate-100/60 hover:border-gold-100">
                <i data-lucide="shield-check" class="w-4 h-4"></i>
                تعديل الصلاحيات
              </button>
              <button
                v-if="!role.is_system"
                @click="confirmDeleteRole(role)"
                class="p-2.5 text-slate-300 hover:text-rose-500 hover:bg-rose-50 rounded-xl transition-all border border-transparent hover:border-rose-100"
              >
                <i data-lucide="trash-2" class="w-4 h-4"></i>
              </button>
            </div>
          </div>

          <!-- Empty State -->
          <div v-if="!loadingRoles && roles.length === 0" class="col-span-full perm-card p-16 text-center">
            <div class="w-20 h-20 rounded-3xl bg-slate-50 flex items-center justify-center mx-auto mb-5">
              <i data-lucide="shield-off" class="w-10 h-10 text-slate-300"></i>
            </div>
            <p class="text-slate-400 font-bold text-lg">لا توجد أدوار بعد</p>
            <p class="text-slate-300 text-sm mt-1">أنشئ دوراً جديداً للبدء</p>
          </div>
        </div>
      </div>

      <!-- ===== TAB: الصلاحيات ===== -->
      <div v-else-if="activeTab === 'permissions'" key="permissions">

        <div v-if="loadingPermissions" class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div v-for="n in 6" :key="n" class="perm-card p-6 animate-pulse">
            <div class="h-5 bg-slate-100 rounded w-1/3 mb-4"></div>
            <div class="space-y-2">
              <div class="h-10 bg-slate-100 rounded-xl"></div>
              <div class="h-10 bg-slate-100 rounded-xl"></div>
            </div>
          </div>
        </div>

        <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div
            v-for="(perms, group) in groupedPermissions"
            :key="group"
            class="perm-card p-6"
          >
            <div class="flex items-center gap-3 mb-5">
              <div class="w-8 h-8 rounded-xl gold-gradient-bg flex items-center justify-center shrink-0">
                <i :data-lucide="groupIcon(group)" class="w-4 h-4 text-white"></i>
              </div>
              <h3 class="font-black text-slate-900 text-sm">{{ group }}</h3>
              <span class="mr-auto text-[10px] font-black px-2 py-0.5 rounded-full bg-slate-100 text-slate-400">{{ perms.length }}</span>
            </div>
            <div class="space-y-2">
              <div
                v-for="perm in perms"
                :key="perm.id"
                class="flex items-center justify-between p-3 bg-slate-50 rounded-xl border border-slate-100/60 hover:border-gold-100 hover:bg-gold-50/30 transition-all group"
              >
                <span class="text-[12px] font-bold text-slate-700 group-hover:text-slate-900">{{ perm.display_name }}</span>
                <code class="text-[9px] font-mono text-slate-400 bg-white px-2 py-0.5 rounded-lg border border-slate-100">{{ perm.name }}</code>
              </div>
            </div>
          </div>
        </div>
      </div>
    </transition>

    <!-- ===================== Modal: إنشاء / تعديل دور ===================== -->
    <transition name="modal-fade">
      <div v-if="showRoleModal" class="dialog-overlay" @click.self="closeModal">
        <div class="dialog-content !max-w-3xl" @click.stop>

          <div class="dialog-header">
            <div>
              <h3 class="text-2xl font-black text-slate-900">{{ isEditMode ? 'تعديل الدور' : 'إنشاء دور جديد' }}</h3>
              <p class="text-[11px] text-slate-400 font-bold mt-0.5 uppercase tracking-widest">
                {{ isEditMode ? editingRole?.display_name : 'Role Creation' }}
              </p>
            </div>
            <button @click="closeModal" class="p-3 hover:bg-slate-100 rounded-2xl transition-all">
              <i data-lucide="x" class="w-5 h-5 text-slate-400"></i>
            </button>
          </div>

          <div class="dialog-body !space-y-6">

            <!-- Role Info -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div class="space-y-2">
                <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest">اسم الدور (عربي)</label>
                <input
                  v-model="roleForm.display_name"
                  placeholder="مثال: مدير الفرع"
                  class="w-full bg-slate-50 border border-slate-200 rounded-2xl px-5 py-3.5 font-bold text-sm outline-none focus:ring-4 focus:ring-gold-500/10 focus:border-gold-300 transition-all"
                />
              </div>
              <div class="space-y-2">
                <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest">المعرف (إنجليزي)</label>
                <input
                  v-model="roleForm.name"
                  :disabled="isEditMode"
                  dir="ltr"
                  placeholder="branch_manager"
                  class="w-full bg-slate-50 border border-slate-200 rounded-2xl px-5 py-3.5 font-bold text-sm outline-none focus:ring-4 focus:ring-gold-500/10 focus:border-gold-300 transition-all disabled:opacity-50"
                />
              </div>
              <div class="sm:col-span-2 space-y-2">
                <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest">الوصف (اختياري)</label>
                <input
                  v-model="roleForm.description"
                  placeholder="وصف مختصر لمهام هذا الدور..."
                  class="w-full bg-slate-50 border border-slate-200 rounded-2xl px-5 py-3.5 font-bold text-sm outline-none focus:ring-4 focus:ring-gold-500/10 focus:border-gold-300 transition-all"
                />
              </div>
            </div>

            <!-- Divider -->
            <div class="flex items-center gap-4">
              <div class="flex-1 h-px bg-slate-100"></div>
              <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest">اختيار الصلاحيات</span>
              <div class="flex-1 h-px bg-slate-100"></div>
            </div>

            <!-- Select All -->
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <span class="text-sm font-black text-slate-700">الصلاحيات المحددة:</span>
                <span class="text-sm font-black text-gold-600">{{ roleForm.permission_ids.length }}</span>
                <span class="text-sm text-slate-400 font-medium">/ {{ allPermissions.length }}</span>
              </div>
              <div class="flex items-center gap-2">
                <button @click="selectAll" class="text-[11px] font-black text-gold-600 hover:text-gold-700 transition-colors px-3 py-1.5 rounded-lg hover:bg-gold-50">
                  تحديد الكل
                </button>
                <button @click="clearAll" class="text-[11px] font-black text-slate-400 hover:text-slate-600 transition-colors px-3 py-1.5 rounded-lg hover:bg-slate-50">
                  مسح الكل
                </button>
              </div>
            </div>

            <!-- Permission Groups -->
            <div class="space-y-4 max-h-96 overflow-y-auto custom-scrollbar pr-1">
              <div
                v-for="(perms, group) in groupedPermissions"
                :key="group"
                class="border border-slate-100 rounded-2xl overflow-hidden"
              >
                <!-- Group Header -->
                <div class="flex items-center justify-between p-4 bg-slate-50/70 cursor-pointer hover:bg-slate-100/50 transition-colors" @click="toggleGroup(group)">
                  <div class="flex items-center gap-3">
                    <div class="w-7 h-7 rounded-xl gold-gradient-bg flex items-center justify-center shrink-0">
                      <i :data-lucide="groupIcon(group)" class="w-3.5 h-3.5 text-white"></i>
                    </div>
                    <span class="font-black text-slate-800 text-[13px]">{{ group }}</span>
                    <span class="text-[9px] font-bold px-2 py-0.5 rounded-full bg-white text-slate-400 border border-slate-200">{{ perms.length }}</span>
                  </div>
                  <div class="flex items-center gap-3">
                    <span class="text-[10px] font-bold text-gold-600">{{ countSelected(perms) }}/{{ perms.length }}</span>
                    <button
                      @click.stop="toggleGroupAll(group, perms)"
                      :class="['text-[9px] font-black px-2 py-1 rounded-lg transition-all', isGroupAllSelected(perms) ? 'bg-gold-100 text-gold-700' : 'bg-slate-100 text-slate-400 hover:bg-gold-50 hover:text-gold-600']"
                    >
                      {{ isGroupAllSelected(perms) ? 'إلغاء' : 'الكل' }}
                    </button>
                  </div>
                </div>

                <!-- Permissions Checkboxes -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-0 divide-y divide-x-0 divide-slate-50">
                  <label
                    v-for="perm in perms"
                    :key="perm.id"
                    :for="`perm-${perm.id}`"
                    class="flex items-center gap-3 p-3.5 cursor-pointer hover:bg-gold-50/30 transition-colors"
                  >
                    <div class="relative flex items-center justify-center">
                      <input
                        :id="`perm-${perm.id}`"
                        type="checkbox"
                        :value="perm.id"
                        v-model="roleForm.permission_ids"
                        class="sr-only peer"
                      />
                      <div :class="['w-5 h-5 rounded-lg border-2 flex items-center justify-center transition-all', roleForm.permission_ids.includes(perm.id) ? 'bg-gold-500 border-gold-500' : 'border-slate-200 bg-white']">
                        <i v-if="roleForm.permission_ids.includes(perm.id)" data-lucide="check" class="w-3 h-3 text-white stroke-[3]"></i>
                      </div>
                    </div>
                    <span :class="['text-[12px] font-bold flex-1', roleForm.permission_ids.includes(perm.id) ? 'text-slate-800' : 'text-slate-500']">
                      {{ perm.display_name }}
                    </span>
                  </label>
                </div>
              </div>
            </div>
          </div>

          <div class="dialog-footer">
            <button @click="closeModal" class="flex-1 py-4 font-black text-slate-400 hover:text-slate-600 transition-colors rounded-2xl hover:bg-slate-50">
              إلغاء
            </button>
            <button
              @click="saveRole"
              :disabled="saving || !roleForm.display_name || !roleForm.name"
              class="flex-[2] gold-gradient-bg py-4 rounded-2xl text-white font-black shadow-lg shadow-gold-500/20 hover:scale-[1.02] active:scale-95 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <span v-if="saving" class="flex items-center justify-center gap-2">
                <i data-lucide="loader-2" class="w-4 h-4 animate-spin"></i>
                جاري الحفظ...
              </span>
              <span v-else>{{ isEditMode ? 'حفظ التغييرات' : 'إنشاء الدور' }}</span>
            </button>
          </div>
        </div>
      </div>
    </transition>

    <!-- Delete Confirm Modal -->
    <transition name="modal-fade">
      <div v-if="showDeleteConfirm" class="dialog-overlay" @click.self="showDeleteConfirm = false">
        <div class="bg-white rounded-3xl shadow-2xl w-full max-w-md mx-auto p-8 text-center" @click.stop>
          <div class="w-16 h-16 rounded-2xl bg-rose-50 flex items-center justify-center mx-auto mb-5">
            <i data-lucide="alert-triangle" class="w-8 h-8 text-rose-500"></i>
          </div>
          <h3 class="text-xl font-black text-slate-900 mb-2">حذف الدور</h3>
          <p class="text-slate-400 text-sm font-medium mb-8">
            هل أنت متأكد من حذف دور <strong class="text-slate-700">{{ deletingRole?.display_name }}</strong>؟ لا يمكن التراجع عن هذا الإجراء.
          </p>
          <div class="flex gap-3">
            <button @click="showDeleteConfirm = false" class="flex-1 py-3 font-black text-slate-400 hover:text-slate-600 transition-colors bg-slate-50 rounded-2xl">
              إلغاء
            </button>
            <button @click="deleteRole" :disabled="deleting" class="flex-1 py-3 font-black text-white bg-rose-500 hover:bg-rose-600 rounded-2xl transition-all shadow-lg shadow-rose-500/20 active:scale-95 disabled:opacity-50">
              {{ deleting ? 'جاري الحذف...' : 'حذف نهائياً' }}
            </button>
          </div>
        </div>
      </div>
    </transition>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import { rolesApi } from '../api/roles'
import { useToastStore } from '../stores/toast'

const toast = useToastStore()

// ============= State =============
const activeTab = ref('roles')
const roles = ref([])
const allPermissions = ref([])
const loadingRoles = ref(true)
const loadingPermissions = ref(true)
const saving = ref(false)
const deleting = ref(false)
const showRoleModal = ref(false)
const showDeleteConfirm = ref(false)
const editingRole = ref(null)
const deletingRole = ref(null)
const isEditMode = ref(false)

const roleForm = ref({
  name: '',
  display_name: '',
  description: '',
  permission_ids: [],
})

// ============= Computed =============
const tabs = computed(() => [
  { id: 'roles', label: 'الأدوار', icon: 'shield', count: roles.value.length },
  { id: 'permissions', label: 'الصلاحيات', icon: 'key-round', count: allPermissions.value.length },
])

const groupedPermissions = computed(() => {
  const groups = {}
  for (const p of allPermissions.value) {
    if (!groups[p.group]) groups[p.group] = []
    groups[p.group].push(p)
  }
  return groups
})

// ============= Data Loading =============
async function loadRoles() {
  loadingRoles.value = true
  try {
    roles.value = (await rolesApi.getRoles()).data
  } catch (e) {
    toast.error('فشل تحميل الأدوار')
  } finally {
    loadingRoles.value = false
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  }
}

async function loadPermissions() {
  loadingPermissions.value = true
  try {
    allPermissions.value = (await rolesApi.getPermissions()).data
  } catch (e) {
    toast.error('فشل تحميل الصلاحيات')
  } finally {
    loadingPermissions.value = false
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  }
}

// ============= Modal Helpers =============
function openCreateRole() {
  isEditMode.value = false
  editingRole.value = null
  roleForm.value = { name: '', display_name: '', description: '', permission_ids: [] }
  showRoleModal.value = true
  nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
}

function openEditRole(role) {
  isEditMode.value = true
  editingRole.value = role
  roleForm.value = {
    name: role.name,
    display_name: role.display_name,
    description: role.description || '',
    permission_ids: (role.permissions || []).map(p => p.id),
  }
  showRoleModal.value = true
  nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
}

function closeModal() {
  showRoleModal.value = false
  editingRole.value = null
}

function confirmDeleteRole(role) {
  deletingRole.value = role
  showDeleteConfirm.value = true
  nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
}

// ============= Permission Checkbox Helpers =============
function selectAll() {
  roleForm.value.permission_ids = allPermissions.value.map(p => p.id)
}

function clearAll() {
  roleForm.value.permission_ids = []
}

function toggleGroup(group) {
  // Optional: expand/collapse - currently groups are always expanded
}

function toggleGroupAll(group, perms) {
  const ids = perms.map(p => p.id)
  const allSelected = ids.every(id => roleForm.value.permission_ids.includes(id))
  if (allSelected) {
    roleForm.value.permission_ids = roleForm.value.permission_ids.filter(id => !ids.includes(id))
  } else {
    const combined = new Set([...roleForm.value.permission_ids, ...ids])
    roleForm.value.permission_ids = [...combined]
  }
}

function countSelected(perms) {
  return perms.filter(p => roleForm.value.permission_ids.includes(p.id)).length
}

function isGroupAllSelected(perms) {
  return perms.every(p => roleForm.value.permission_ids.includes(p.id))
}

// ============= CRUD =============
async function saveRole() {
  if (!roleForm.value.display_name || !roleForm.value.name) {
    return toast.error('الاسم والمعرف مطلوبان')
  }
  saving.value = true
  try {
    if (isEditMode.value) {
      await rolesApi.updateRole(editingRole.value.id, {
        display_name: roleForm.value.display_name,
        description: roleForm.value.description,
        permission_ids: roleForm.value.permission_ids,
      })
      toast.success('تم تحديث الدور بنجاح')
    } else {
      await rolesApi.createRole(roleForm.value)
      toast.success('تم إنشاء الدور الجديد بنجاح')
    }
    closeModal()
    await loadRoles()
  } catch (e) {
    toast.error(e.response?.data?.message || 'حدث خطأ أثناء الحفظ')
  } finally {
    saving.value = false
  }
}

async function deleteRole() {
  if (!deletingRole.value) return
  deleting.value = true
  try {
    await rolesApi.deleteRole(deletingRole.value.id)
    toast.success('تم حذف الدور')
    showDeleteConfirm.value = false
    deletingRole.value = null
    await loadRoles()
  } catch (e) {
    toast.error(e.response?.data?.message || 'فشل حذف الدور')
  } finally {
    deleting.value = false
  }
}

// ============= Style Helpers =============
function roleColor(name) {
  const map = {
    admin: { bg: 'bg-gold-50 border border-gold-100/50', icon: 'text-gold-600' },
    cashier: { bg: 'bg-emerald-50 border border-emerald-100/50', icon: 'text-emerald-600' },
    accountant: { bg: 'bg-indigo-50 border border-indigo-100/50', icon: 'text-indigo-600' },
  }
  return map[name] || { bg: 'bg-slate-50 border border-slate-100', icon: 'text-slate-400' }
}

function roleIcon(name) {
  const map = {
    admin: 'shield-check',
    cashier: 'shopping-cart',
    accountant: 'calculator',
  }
  return map[name] || 'user-cog'
}

function groupIcon(group) {
  const map = {
    'الفواتير': 'receipt',
    'المنتجات': 'package',
    'العملاء': 'users',
    'المشتريات': 'shopping-bag',
    'المصروفات': 'banknote',
    'التقارير': 'bar-chart-3',
    'الصندوق': 'wallet',
    'الحوالات': 'send',
    'الديون': 'clipboard-list',
    'الجرد': 'package-search',
    'أسعار الذهب': 'trending-up',
    'المستخدمون': 'user-cog',
    'الإعدادات': 'settings',
  }
  return map[group] || 'key-round'
}

onMounted(async () => {
  await Promise.all([loadRoles(), loadPermissions()])
})
</script>

<style scoped>
.perm-luxury-btn {
  @apply gold-gradient-bg hover:shadow-gold-500/40 text-white px-6 py-3 rounded-2xl text-sm font-black shadow-xl shadow-gold-500/20 transition-all active:scale-95 flex items-center gap-2 overflow-hidden relative;
}

.perm-luxury-btn::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(120deg, transparent, rgba(255,255,255,0.3), transparent);
  transition: all 0.6s;
}
.perm-luxury-btn:hover::before { left: 100%; }
.perm-luxury-btn:hover { @apply -translate-y-0.5 shadow-2xl shadow-gold-500/40; }

.perm-card {
  background: white;
  border-radius: 24px;
  border: 1px solid rgba(241, 245, 249, 0.7);
  box-shadow: 0 4px 24px -8px rgba(0,0,0,0.04), 0 1px 4px -1px rgba(0,0,0,0.03);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.perm-card:hover {
  box-shadow: 0 12px 40px -12px rgba(0,0,0,0.08), 0 4px 12px -2px rgba(184,115,0,0.06);
  transform: translateY(-3px);
}

/* Tab Transition */
.tab-fade-enter-active, .tab-fade-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}
.tab-fade-enter-from {
  opacity: 0;
  transform: translateY(8px);
}
.tab-fade-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

/* Modal Transition */
.modal-fade-enter-active { animation: modal-in 0.3s cubic-bezier(0.16, 1, 0.3, 1); }
.modal-fade-leave-active { animation: modal-out 0.2s ease-in; }

@keyframes modal-in {
  from { opacity: 0; }
  to { opacity: 1; }
}
@keyframes modal-out {
  from { opacity: 1; }
  to { opacity: 0; }
}
</style>
