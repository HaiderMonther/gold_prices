import { defineStore } from 'pinia'
import { ref } from 'vue'
import api from '../api/axios'

export const useGoldStore = defineStore('gold', () => {
  const latestPrice = ref(null)

  async function fetchLatestPrice() {
    try {
      const res = await api.get('/gold-prices/latest')
      latestPrice.value = res.data
    } catch {}
  }

  return { latestPrice, fetchLatestPrice }
})
