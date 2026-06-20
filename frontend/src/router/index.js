import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

// Import views directly to resolve potential dynamic import issues during navigation
import Dashboard from '../views/Dashboard.vue'
import Products from '../views/Products.vue'
import Invoices from '../views/Invoices.vue'
import NewInvoice from '../views/NewInvoice.vue'
import Customers from '../views/Customers.vue'
import Purchases from '../views/Purchases.vue'
import PurchaseInvoice from '../views/PurchaseInvoice.vue'
import Expenses from '../views/Expenses.vue'
import Settings from '../views/Settings.vue'
import GoldPrices from '../views/GoldPrices.vue'
import Debts from '../views/Debts.vue'
import Inventory from '../views/Inventory.vue'
import Users from '../views/Users.vue'
import Login from '../views/Login.vue'
import Landing from '../views/Landing.vue'
import Register from '../views/Register.vue'
import PaymentResult from '../views/PaymentResult.vue'
import AppLayout from '../layouts/AppLayout.vue'
import Notifications from '../views/Notifications.vue'

// New Kimia-style views
import AccountStatement from '../views/AccountStatement.vue'
import CashBox from '../views/CashBox.vue'
import Reports from '../views/Reports.vue'
import Transfers from '../views/Transfers.vue'
import TenantsList from '../views/admin/TenantsList.vue'
import Permissions from '../views/Permissions.vue'

const routes = [
  { path: '/welcome', component: Landing, meta: { public: true } },
  { path: '/register', component: Register, meta: { public: true } },
  { path: '/payment/success', component: PaymentResult, meta: { public: true } },
  { path: '/payment/failed', component: PaymentResult, meta: { public: true } },
  { path: '/login', component: Login, meta: { public: true } },
  {
    path: '/',
    component: AppLayout,
    meta: { requiresAuth: true },
    children: [
      { path: '', redirect: '/dashboard' },
      { path: 'dashboard', component: Dashboard, meta: { title: 'لوحة التحكم' } },
      { path: 'products', component: Products, meta: { title: 'المخزون', permission: 'view_products' } },
      { path: 'invoices', component: Invoices, meta: { title: 'الفواتير', permission: 'view_invoices' } },
      { path: 'invoices/new', component: NewInvoice, meta: { title: 'فاتورة جديدة', permission: 'create_invoices' } },
      { path: 'customers', component: Customers, meta: { title: 'العملاء', permission: 'view_customers' } },
      { path: 'purchases', component: Purchases, meta: { title: 'مشتريات الكسر', permission: 'view_purchases' } },
      { path: 'purchases/new', component: PurchaseInvoice, meta: { title: 'شراء مصوغات', permission: 'create_purchases' } },
      { path: 'expenses', component: Expenses, meta: { title: 'المصروفات', permission: 'view_expenses' } },
      { path: 'gold-prices', component: GoldPrices, meta: { title: 'أسعار الذهب', permission: 'view_gold_prices' } },
      { path: 'debts', component: Debts, meta: { title: 'الديون', permission: 'view_debts' } },
      { path: 'inventory', component: Inventory, meta: { title: 'الجرد', permission: 'view_inventory' } },
      { path: 'users', component: Users, meta: { title: 'المستخدمون', adminOnly: true } },
      { path: 'permissions', component: Permissions, meta: { title: 'الصلاحيات والأدوار', adminOnly: true } },
      { path: 'tenants', component: TenantsList, meta: { title: 'العملاء (SaaS)', superAdminOnly: true } },
      // New Kimia-style routes
      { path: 'account-statement', component: AccountStatement, meta: { title: 'كشف الحساب', permission: 'view_invoices' } },
      { path: 'cash-box', component: CashBox, meta: { title: 'الصندوق اليومي', permission: 'view_cashbox' } },
      { path: 'reports', component: Reports, meta: { title: 'التقارير', permission: 'view_reports' } },
      { path: 'transfers', component: Transfers, meta: { title: 'الحوالات', permission: 'view_transfers' } },
      { path: 'settings', component: Settings, meta: { title: 'الإعدادات', permission: 'view_settings' } },
      { path: 'notifications', component: Notifications, meta: { title: 'الإشعارات' } },
    ],
  },
  { path: '/:pathMatch(.*)*', redirect: '/' },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to) => {
  const auth = useAuthStore()

  // يجب تسجيل الدخول للوصول للصفحات المحمية
  if (to.meta.requiresAuth && !auth.isAuthenticated) return '/welcome'

  // إعادة توجيه المستخدم المسجّل من صفحات العامة
  if (to.meta.public && auth.isAuthenticated && (to.path === '/login' || to.path === '/register' || to.path === '/welcome')) {
    return '/dashboard'
  }

  // حماية صفحات المدير
  if (to.meta.adminOnly && !auth.isAdmin) return '/dashboard'

  // حماية صفحات المدير العام
  if (to.meta.superAdminOnly && !auth.isSuperAdmin) return '/dashboard'

  // حماية الصفحات بالصلاحيات — إذا لم يملك الصلاحية يُعاد للداشبورد
  if (to.meta.permission && !auth.can(to.meta.permission)) return '/dashboard'
})

export default router
