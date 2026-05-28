import { defineStore } from 'pinia'
import api from '../api/axios'

export const useNotificationsStore = defineStore('notifications', {
  state: () => ({
    notifications: [],
    loading: false,
    error: null,
  }),
  getters: {
    unreadCount: (state) => state.notifications.filter(n => !n.is_read).length,
  },
  actions: {
    async fetchNotifications() {
      this.loading = true
      try {
        const response = await api.get('/notifications')
        this.notifications = response.data.map(n => ({
          ...n,
          time: new Date(n.created_at).toLocaleString('ar-IQ', { hour: '2-digit', minute: '2-digit', day: 'numeric', month: 'short' }),
          read: n.is_read
        }))
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
