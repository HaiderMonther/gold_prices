<template>
  <div class="space-y-8 max-w-5xl mx-auto">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-2xl font-black text-slate-900 tracking-tight">جميع الإشعارات</h2>
        <p class="text-sm font-bold text-slate-400 mt-1">عرض وإدارة كافة التنبيهات الخاصة بحسابك</p>
      </div>
      <button 
        @click="markAllAsRead"
        v-if="unreadCount > 0"
        class="bg-gold-50 text-gold-600 px-4 py-2 rounded-xl text-sm font-bold hover:bg-gold-100 transition-colors flex items-center gap-2"
      >
        <i data-lucide="check-check" class="w-4 h-4"></i>
        تحديد الكل كمقروء
      </button>
    </div>

    <!-- Notifications List -->
    <div class="luxury-card overflow-hidden bg-white">
      <div v-if="notifications.length === 0" class="p-16 text-center">
        <div class="w-16 h-16 bg-slate-50 rounded-full flex items-center justify-center mx-auto mb-4">
          <i data-lucide="bell-off" class="w-8 h-8 text-slate-300"></i>
        </div>
        <div class="text-lg font-black text-slate-900">لا توجد إشعارات</div>
        <div class="text-sm text-slate-400 mt-1">أنت على اطلاع بكل جديد</div>
      </div>
      
      <div class="divide-y divide-slate-50">
        <div 
          v-for="notif in notifications" 
          :key="notif.id"
          @click="markAsRead(notif)"
          :class="[
            'p-6 flex gap-6 items-start transition-all cursor-pointer group hover:bg-slate-50/50',
            !notif.read ? 'bg-white' : 'bg-slate-50/30'
          ]"
        >
          <div :class="`w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 shadow-sm ${
            notif.type === 'success' ? 'bg-emerald-50 text-emerald-600' : 
            notif.type === 'warning' ? 'bg-amber-50 text-amber-600' : 'bg-blue-50 text-blue-600'
          }`">
            <i :data-lucide="notif.icon" class="w-6 h-6"></i>
          </div>
          
          <div class="flex-1 min-w-0">
            <div class="flex items-start justify-between gap-4 mb-1">
              <h3 :class="['text-base font-black', !notif.read ? 'text-slate-900' : 'text-slate-700']">
                {{ notif.title }}
              </h3>
              <span class="text-xs font-bold text-slate-400 shrink-0 bg-slate-50 px-2.5 py-1 rounded-lg">
                {{ notif.time }}
              </span>
            </div>
            <p :class="['text-sm leading-relaxed', !notif.read ? 'text-slate-600 font-medium' : 'text-slate-500']">
              {{ notif.message }}
            </p>
          </div>
          
          <div class="shrink-0 w-3 flex justify-end">
            <div v-if="!notif.read" class="w-2 h-2 bg-rose-500 rounded-full mt-2 shadow-sm shadow-rose-200"></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, nextTick } from 'vue'
import { useNotificationsStore } from '../stores/notifications'

const notificationsStore = useNotificationsStore()

const notifications = computed(() => notificationsStore.notifications)
const unreadCount = computed(() => notificationsStore.unreadCount)

const markAllAsRead = () => {
  notificationsStore.markAllAsRead()
}

const markAsRead = (notif) => {
  notificationsStore.markAsRead(notif.id)
}

onMounted(() => {
  notificationsStore.fetchNotifications()
  nextTick(() => {
    if (window.refreshIcons) window.refreshIcons()
  })
})
</script>
