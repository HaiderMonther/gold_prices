import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '../api/axios'

// -------------------------------------------------------
// خريطة الصلاحيات لكل دور — تتطابق مع الـ seed في الـ backend
// -------------------------------------------------------
const ROLE_PERMISSIONS = {
  super_admin: ['*'], // كل الصلاحيات
  admin: ['*'],       // كل الصلاحيات
  accountant: [
    'view_invoices',
    'view_purchases',
    'view_expenses', 'create_expenses',
    'view_reports', 'export_reports',
    'view_cashbox', 'manage_cashbox',
    'view_transfers', 'create_transfers',
    'view_debts', 'manage_debts',
    'view_customers',
    'view_gold_prices',
    'view_settings',
  ],
  cashier: [
    'view_invoices', 'create_invoices',
    'view_products',
    'view_customers', 'create_customers',
    'view_gold_prices',
  ],
}

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('gold_token') || '')
  const user = ref(JSON.parse(localStorage.getItem('gold_user') || 'null'))
  const tenant = ref(JSON.parse(localStorage.getItem('gold_tenant') || 'null'))

  const isAuthenticated = computed(() => !!token.value)
  const isAdmin = computed(() => ['admin', 'super_admin'].includes(user.value?.role))
  const isSuperAdmin = computed(() => user.value?.role === 'super_admin')
  const isAccountant = computed(() => ['admin', 'super_admin', 'accountant'].includes(user.value?.role))

  // دالة للتحقق من صلاحية معيّنة بناءً على الدور الحالي
  function can(permission) {
    const role = user.value?.role
    if (!role) return false
    const perms = ROLE_PERMISSIONS[role] || []
    return perms.includes('*') || perms.includes(permission)
  }

  // التحقق من قائمة صلاحيات (يرجع true إذا كان لديه واحدة على الأقل)
  function canAny(...permissions) {
    return permissions.some(p => can(p))
  }

  async function login(username, password, tenantCode) {
    const res = await api.post('/auth/login', { username, password, tenant_code: tenantCode || '' })
    token.value = res.data.access_token
    user.value = res.data.user
    tenant.value = res.data.tenant

    localStorage.setItem('gold_token', token.value)
    localStorage.setItem('gold_user', JSON.stringify(user.value))
    localStorage.setItem('gold_tenant', JSON.stringify(tenant.value))

    // Store branding for layout
    if (res.data.tenant) {
      localStorage.setItem('gold_tenant_name', res.data.tenant.name)
      localStorage.setItem('gold_tenant_logo', res.data.tenant.logo_url || '')
      localStorage.setItem('gold_tenant_color', res.data.tenant.primary_color || '')
    } else {
      // Super admin - clear tenant branding
      localStorage.removeItem('gold_tenant_name')
      localStorage.removeItem('gold_tenant_logo')
      localStorage.removeItem('gold_tenant_color')
    }
  }

  function logout() {
    token.value = ''
    user.value = null
    tenant.value = null
    localStorage.removeItem('gold_token')
    localStorage.removeItem('gold_user')
    localStorage.removeItem('gold_tenant')
    localStorage.removeItem('gold_tenant_name')
    localStorage.removeItem('gold_tenant_logo')
    localStorage.removeItem('gold_tenant_color')
  }

  return { token, user, tenant, isAuthenticated, isAdmin, isSuperAdmin, isAccountant, can, canAny, login, logout }
})

