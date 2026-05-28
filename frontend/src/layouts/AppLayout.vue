<template>
  <div class="flex h-screen bg-[#F8F9FA] font-sans" dir="rtl">
    <!-- Sidebar -->
    <aside class="w-72 bg-white/70 backdrop-blur-xl border-l border-slate-200/60 flex flex-col shrink-0 z-30 shadow-[4px_0_24px_rgba(0,0,0,0.02)]">
      <div class="p-8 mb-4">
        <div class="flex items-center gap-4">
          <!-- Tenant Logo or Default -->
          <div v-if="tenantLogo" class="w-12 h-12 rounded-[18px] overflow-hidden shadow-xl border border-slate-100 shrink-0">
            <img :src="tenantLogo" alt="شعار" class="w-full h-full object-contain" />
          </div>
          <div v-else class="gold-gradient-bg w-12 h-12 rounded-[18px] flex items-center justify-center text-white shadow-xl shadow-gold-500/20 transition-all hover:scale-105 hover:rotate-6 shrink-0">
            <i data-lucide="diamond" class="w-6 h-6"></i>
          </div>
          <div class="space-y-0.5 min-w-0">
            <div class="text-xl font-black text-slate-900 tracking-tight gold-text-gradient truncate">{{ tenantName }}</div>
            <div class="text-[9px] font-black text-slate-400 uppercase tracking-[0.2em] leading-none">The Gold Hub</div>
          </div>
        </div>
      </div>

      <div class="px-5 pb-8 flex-1 overflow-y-auto space-y-6 custom-scrollbar">
        <section v-for="section in navSections" :key="section.title">
          <div class="px-4 py-2 text-[10px] font-black text-slate-400 uppercase tracking-[0.15em] mb-2 opacity-60">
            {{ section.title }}
          </div>
          <div class="space-y-1">
            <router-link 
              v-for="item in section.items.filter(i => (!i.adminOnly || auth.isAdmin) && (!i.superAdminOnly || auth.isSuperAdmin))" 
              :key="item.to"
              :to="item.to"
              class="flex items-center gap-3 w-full px-4 py-3 rounded-2xl text-[13px] transition-all duration-300 group relative overflow-hidden text-slate-500 hover:bg-slate-50 hover:text-slate-900 nav-link"
              active-class="bg-gold-50 text-gold-700 font-bold shadow-sm shadow-gold-100/50 active-nav-link"
            >
              <div class="active-indicator absolute right-0 top-1/4 w-1 h-1/2 bg-gold-500 rounded-full opacity-0"></div>
              <i :data-lucide="item.icon" class="w-[19px] h-[19px] text-slate-400 group-hover:text-gold-500 nav-icon"></i>
              <span class="flex-1 text-right">{{ item.label }}</span>
              <span v-if="item.shortcut" class="text-[9px] px-1.5 py-0.5 rounded border border-slate-200 transition-opacity opacity-0 group-hover:opacity-100 shortcut-badge">
                {{ item.shortcut }}
              </span>
              <span v-if="item.badge" class="bg-gold-500 text-white text-[9px] px-2 py-0.5 rounded-full font-bold shadow-sm">
                {{ item.badge }}
              </span>
            </router-link>
          </div>
        </section>
      </div>

      <div class="p-6 border-t border-slate-100/60 bg-white/40">
        <div class="flex items-center gap-3 p-3 luxury-card !rounded-2xl bg-white shadow-sm ring-1 ring-slate-100">
          <div class="w-10 h-10 rounded-xl bg-gold-50 text-gold-700 flex items-center justify-center font-black text-sm border border-gold-100/50">
            {{ userInitials }}
          </div>
          <div class="flex-1 min-w-0">
            <div class="text-xs font-black text-slate-900 truncate">{{ auth.user?.name }}</div>
            <div class="text-[10px] font-bold text-slate-400 truncate mt-0.5">{{ roleLabel }}</div>
          </div>
          <i data-lucide="settings" class="w-3.5 h-3.5 text-slate-300 hover:text-gold-500 cursor-pointer transition-colors" @click="$router.push('/settings')"></i>
        </div>
      </div>
    </aside>

    <!-- Main Content -->
    <main class="flex-1 flex flex-col overflow-hidden">
      <!-- Header -->
      <header class="h-20 bg-white/60 backdrop-blur-md border-b border-slate-200/50 flex items-center justify-between px-10 gap-6 z-20">
        <div class="flex items-center gap-4">
          <div class="w-1 h-8 bg-gold-400 rounded-full" />
          <h1 class="text-xl font-black text-slate-900 tracking-tight">{{ pageTitle }}</h1>
        </div>
        
        <div class="flex items-center gap-4 flex-1 max-w-md mx-auto relative search-area">
          <div class="relative w-full group">
            <div class="absolute inset-0 bg-gold-400/5 rounded-2xl blur-xl opacity-0 group-focus-within:opacity-100 transition-opacity" />
            <i data-lucide="search" class="absolute right-4 top-1/2 -translate-y-1/2 w-[18px] h-[18px] text-slate-400 group-focus-within:text-gold-500 transition-colors"></i>
            <input 
              v-model="searchQuery"
              @input="handleSearch"
              @focus="isSearching = true"
              type="text" 
              placeholder="ابحث عن باركود، عميل، أو صفحة..."
              class="w-full bg-white border border-slate-100 rounded-2xl pr-12 pl-12 py-3 text-sm focus:ring-4 focus:ring-gold-500/5 focus:border-gold-300 outline-none transition-all shadow-sm font-bold"
            />
            <button v-if="searchQuery" @click="clearSearch" class="absolute left-12 top-1/2 -translate-y-1/2 text-slate-300 hover:text-rose-500">
              <i data-lucide="x" class="w-4 h-4"></i>
            </button>
            <div class="absolute left-4 top-1/2 -translate-y-1/2 flex items-center gap-1.5 opacity-40 pointer-events-none">
              <i data-lucide="command" class="w-3 h-3"></i>
              <span class="text-[10px] font-bold">K</span>
            </div>
          </div>

          <!-- Search Results Dropdown -->
          <transition name="fade">
            <div v-if="isSearching && (searchQuery || searchResults.length > 0)" class="absolute top-full right-0 left-0 mt-3 bg-white/90 backdrop-blur-xl border border-slate-100 rounded-3xl shadow-2xl z-50 overflow-hidden">
              <div class="p-4 border-b border-slate-50 flex items-center justify-between">
                <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest">نتائج البحث</span>
                <span class="text-[10px] text-gold-600 font-bold">{{ searchResults.length }} نتائج</span>
              </div>
              <div class="max-h-[300px] overflow-y-auto p-2">
                <router-link 
                  v-for="result in searchResults" 
                  :key="result.to"
                  :to="result.to"
                  @click="isSearching = false"
                  class="flex items-center gap-3 p-3 rounded-2xl hover:bg-gold-50 transition-colors group"
                >
                  <div class="w-10 h-10 rounded-xl bg-slate-50 flex items-center justify-center text-slate-400 group-hover:bg-white group-hover:text-gold-500 transition-all">
                    <i :data-lucide="result.icon" class="w-5 h-5"></i>
                  </div>
                  <div>
                    <div class="text-sm font-bold text-slate-900">{{ result.label }}</div>
                    <div class="text-[10px] text-slate-400">انتقال سريع إلى {{ result.label }}</div>
                  </div>
                </router-link>
                <div v-if="searchResults.length === 0" class="p-8 text-center">
                  <div class="w-12 h-12 bg-slate-50 rounded-2xl flex items-center justify-center mx-auto mb-3">
                    <i data-lucide="search-x" class="w-6 h-6 text-slate-300"></i>
                  </div>
                  <div class="text-sm font-bold text-slate-400">لا توجد نتائج لـ "{{ searchQuery }}"</div>
                </div>
              </div>
            </div>
          </transition>
        </div>

        <div class="flex items-center gap-3">
          <div class="flex items-center bg-white border border-slate-100 rounded-2xl p-1 gap-1 shadow-sm notification-area relative">
            <button 
              @click="showNotifications = !showNotifications"
              class="p-2.5 text-slate-400 hover:text-gold-600 hover:bg-gold-50 rounded-xl transition-all relative"
            >
              <i data-lucide="bell" class="w-5 h-5"></i>
              <span v-if="unreadCount > 0" class="absolute top-2.5 right-2.5 w-2 h-2 bg-rose-500 rounded-full border-2 border-white shadow-sm"></span>
            </button>

            <!-- Notifications Dropdown -->
            <transition name="fade">
              <div v-if="showNotifications" class="absolute top-full left-0 mt-3 w-80 bg-white border border-slate-100 rounded-3xl shadow-2xl z-50 overflow-hidden">
                <div class="p-5 border-b border-slate-50 flex items-center justify-between bg-gold-50/30">
                  <span class="text-sm font-black text-slate-900">الإشعارات</span>
                  <button @click="markAllAsRead" v-if="unreadCount > 0" class="text-[10px] font-bold text-gold-600 hover:underline">تحديد الكل كمقروء</button>
                </div>
                <div class="max-h-[400px] overflow-y-auto">
                  <div 
                    v-for="notif in notificationsStore.notifications.slice(0, 5)" 
                    :key="notif.id"
                    @click="markAsRead(notif)"
                    :class="[
                      'p-4 border-b border-slate-50 hover:bg-slate-50 transition-colors cursor-pointer flex gap-4',
                      !notif.read ? 'bg-white' : 'bg-slate-50/50 opacity-70'
                    ]"
                  >
                    <div :class="`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${
                      notif.type === 'success' ? 'bg-emerald-50 text-emerald-600' : 
                      notif.type === 'warning' ? 'bg-amber-50 text-amber-600' : 'bg-blue-50 text-blue-600'
                    }`">
                      <i :data-lucide="notif.icon" class="w-5 h-5"></i>
                    </div>
                    <div class="flex-1 min-w-0">
                      <div class="text-[13px] font-bold text-slate-900 mb-0.5">{{ notif.title }}</div>
                      <div class="text-[11px] text-slate-500 leading-relaxed mb-1">{{ notif.message }}</div>
                      <div class="text-[10px] text-slate-400">{{ notif.time }}</div>
                    </div>
                  </div>
                </div>
                <div class="p-3 text-center border-t border-slate-50">
                  <router-link to="/notifications" @click="showNotifications = false" class="text-xs font-bold text-slate-500 hover:text-gold-600 transition-colors">عرض جميع الإشعارات</router-link>
                </div>
              </div>
            </transition>

            <div class="w-px h-6 bg-slate-100" />
            <button 
              @click="$router.push('/settings')"
              class="p-2.5 text-slate-400 hover:text-slate-900 hover:bg-slate-50 rounded-xl transition-all"
              title="الإعدادات"
            >
              <i data-lucide="settings" class="w-5 h-5"></i>
            </button>
            <button 
              @click="logout"
              class="p-2.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-xl transition-all"
              title="تسجيل الخروج"
            >
              <i data-lucide="log-out" class="w-5 h-5"></i>
            </button>
          </div>

          <router-link to="/invoices/new" class="luxury-button group">
            <i data-lucide="plus" class="w-5 h-5 stroke-[3] transition-transform group-hover:rotate-90"></i>
            <span>فاتورة بيع</span>
          </router-link>
        </div>
      </header>

      <!-- Page Content -->
      <div class="flex-1 overflow-y-auto p-10 custom-scrollbar scroll-smooth">
        <router-view :key="route.fullPath" />
      </div>
    </main>
  </div>
</template>

<script setup>
import { computed, onMounted, nextTick, watch, ref, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { useGoldStore } from '../stores/gold'
import { useNotificationsStore } from '../stores/notifications'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const goldStore = useGoldStore()
const notificationsStore = useNotificationsStore()

const searchQuery = ref('')
const showNotifications = ref(false)
const showUserMenu = ref(false)
const searchResults = ref([])
const isSearching = ref(false)
const tenantName = ref(auth.tenant?.name || localStorage.getItem('gold_tenant_name') || 'ذهـبي')
const tenantLogo = ref(auth.tenant?.logo_url || localStorage.getItem('gold_tenant_logo') || '')

const unreadCount = computed(() => notificationsStore.unreadCount)

const markAllAsRead = () => {
  notificationsStore.markAllAsRead()
}

const markAsRead = (notif) => {
  notificationsStore.markAsRead(notif.id)
}

const handleSearch = () => {
  if (!searchQuery.value) {
    searchResults.value = []
    isSearching.value = false
    return
  }
  
  isSearching.value = true
  // Mock search results based on navigation and some keywords
  const allItems = navSections.flatMap(s => s.items)
  searchResults.value = allItems.filter(item => 
    item.label.includes(searchQuery.value) || 
    item.to.includes(searchQuery.value)
  ).slice(0, 5)
}

const clearSearch = () => {
  searchQuery.value = ''
  searchResults.value = []
  isSearching.value = false
}

const logout = () => {
  auth.logout()
  router.push('/login')
}

// Close dropdowns on click outside
const closeDropdowns = (e) => {
  if (!e.target.closest('.notification-area')) showNotifications.value = false
  if (!e.target.closest('.search-area')) isSearching.value = false
}

const handleKeydown = (e) => {
  if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
    e.preventDefault()
    const input = document.querySelector('.search-area input')
    if (input) input.focus()
  }
}

onMounted(() => {
  window.addEventListener('click', closeDropdowns)
  window.addEventListener('keydown', handleKeydown)
  goldStore.fetchLatestPrice()
  notificationsStore.fetchNotifications()
  if (window.refreshIcons) window.refreshIcons()
})

// Polling for notifications every 30 seconds
let notifInterval
onMounted(() => {
  notifInterval = setInterval(() => {
    notificationsStore.fetchNotifications()
  }, 30000)
})

onUnmounted(() => {
  window.removeEventListener('click', closeDropdowns)
  window.removeEventListener('keydown', handleKeydown)
  clearInterval(notifInterval)
})

// Refresh icons whenever the route changes
watch(() => route.path, () => {
  nextTick(() => {
    if (window.refreshIcons) window.refreshIcons()
  })
})

const pageTitle = computed(() => route.meta?.title || 'الرئيسية')

const userInitials = computed(() => {
  const name = auth.user?.name || 'أ ح'
  return name.split(' ').map(n => n[0]).join('').slice(0, 2)
})

const roleLabels = { super_admin: 'المدير العام', admin: 'مدير النظام', cashier: 'كاشير', accountant: 'محاسب' }
const roleLabel = computed(() => roleLabels[auth.user?.role] || 'المدير التنفيذي')

const navSections = [
  {
    title: 'الرئيسية',
    items: [
      { to: '/dashboard', label: 'لوحة التحكم', icon: 'layout-dashboard', shortcut: 'Alt+D' },
      { to: '/gold-prices', label: 'أسعار الذهب', icon: 'trending-up', badge: 'مباشر' }
    ]
  },
  {
    title: 'التجارة',
    items: [
      { to: '/invoices/new', label: 'بيع مصوغات', icon: 'shopping-cart', shortcut: 'Alt+N' },
      { to: '/purchases/new', label: 'شراء مصوغات', icon: 'shopping-bag' },
      { to: '/purchases', label: 'شراء كسر (خردة)', icon: 'coins' },
      { to: '/products', label: 'المخزون', icon: 'package' },
      { to: '/inventory', label: 'الجرد الدوري', icon: 'package-search' }
    ]
  },
  {
    title: 'الحسابات',
    items: [
      { to: '/account-statement', label: 'كشف الحساب', icon: 'file-text', badge: 'جديد' },
      { to: '/cash-box', label: 'الصندوق اليومي', icon: 'wallet', badge: 'جديد' },
      { to: '/invoices', label: 'الفواتير', icon: 'receipt' },
      { to: '/customers', label: 'العملاء والتجار', icon: 'users' },
      { to: '/debts', label: 'الديون', icon: 'clipboard-list' },
      { to: '/transfers', label: 'الحوالات', icon: 'send' },
      { to: '/expenses', label: 'المصروفات', icon: 'banknote' }
    ]
  },
  {
    title: 'التحليلات',
    items: [
      { to: '/reports', label: 'التقارير', icon: 'bar-chart-3', badge: 'جديد' }
    ]
  },
  {
    title: 'الإدارة',
    items: [
      { to: '/tenants', label: 'العملاء (SaaS)', icon: 'building', superAdminOnly: true },
      { to: '/users', label: 'الموظفين', icon: 'user-cog', adminOnly: true },
      { to: '/settings', label: 'الإعدادات', icon: 'settings' }
    ]
  }
]
</script>

<style scoped>
.luxury-button {
  @apply gold-gradient-bg text-white px-8 py-4 rounded-[22px] text-sm font-black shadow-[0_20px_50px_-12px_rgba(214,158,39,0.35)] transition-all duration-500 active:scale-95 flex items-center gap-3 overflow-hidden relative border border-white/20;
}

.luxury-button::before {
  content: '';
  position: absolute;
  top: 0;
  left: -150%;
  width: 150%;
  height: 100%;
  background: linear-gradient(
    120deg,
    transparent,
    rgba(255, 255, 255, 0.5),
    transparent
  );
  transition: all 0.8s cubic-bezier(0.19, 1, 0.22, 1);
}

.luxury-button:hover::before {
  left: 100%;
}

.luxury-button:hover {
  @apply -translate-y-1.5 shadow-[0_25px_60px_-12px_rgba(214,158,39,0.5)] scale-[1.03];
}

.luxury-button i {
  @apply drop-shadow-md;
}


.active-nav-link .active-indicator {
  opacity: 1;
}

.active-nav-link .nav-icon {
  @apply text-gold-600;
}

.active-nav-link .shortcut-badge {
  @apply opacity-100 border-gold-200 text-gold-500;
}

/* Transitions */
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}

.search-area input::placeholder {
  @apply text-slate-400 font-medium;
}

.custom-scrollbar::-webkit-scrollbar {
  width: 4px;
}
</style>
