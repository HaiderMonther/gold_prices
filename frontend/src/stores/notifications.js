import { defineStore } from 'pinia'
import api from '../api/axios'
import { useToastStore } from './toast'

export const useNotificationsStore = defineStore('notifications', {
  state: () => ({
    notifications: [],
    loading: false,
    error: null,
    isFirstFetch: true,
  }),
  getters: {
    unreadCount: (state) => state.notifications.filter(n => !n.is_read).length,
  },
  actions: {
    async fetchNotifications() {
      this.loading = true
      try {
        const response = await api.get('/notifications')
        const newNotifs = response.data.map(n => ({
          ...n,
          time: new Date(n.created_at).toLocaleString('ar-IQ', { hour: '2-digit', minute: '2-digit', day: 'numeric', month: 'short' }),
          read: n.is_read
        }))
        
        if (!this.isFirstFetch) {
          const oldIds = new Set(this.notifications.map(n => n.id))
          const incomingUnread = newNotifs.filter(n => !oldIds.has(n.id) && !n.is_read)
          
          if (incomingUnread.length > 0) {
            const toastStore = useToastStore();
            // Reversing so oldest new comes first if there are multiple
            [...incomingUnread].reverse().forEach(n => {
              if (n.type === 'success') toastStore.success(`${n.title} - ${n.message}`)
              else if (n.type === 'error') toastStore.error(`${n.title} - ${n.message}`)
              else toastStore.show(`${n.title} - ${n.message}`, n.type || 'info')
            })
          }
        }
        
        this.notifications = newNotifs
        this.isFirstFetch = false
      } catch (err) {
        this.error = err.message
      } finally {
        this.loading = false
      }
    },
    async markAllAsRead() {
      try {
        await api.put('/notifications/read-all')
        this.notifications.forEach(n => {
          n.is_read = true
          n.read = true
        })
      } catch (err) {
        console.error('Failed to mark all as read', err)
      }
    },
    async markAsRead(id) {
      try {
        const notif = this.notifications.find(n => n.id === id)
        if (!notif || notif.is_read) return

        notif.is_read = true
        notif.read = true
        await api.put(`/notifications/${id}/read`)
      } catch (err) {
        console.error('Failed to mark as read', err)
        // Rollback on failure
        const notif = this.notifications.find(n => n.id === id)
        if (notif) {
          notif.is_read = false
          notif.read = false
        }
      }
    }
  }
})
