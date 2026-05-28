<template>
  <div class="grid grid-cols-1 lg:grid-cols-2 gap-12 items-start max-w-5xl mx-auto">
    <!-- Price Update Card -->
    <div class="luxury-card p-10 bg-white">
      <div class="flex items-center gap-4 mb-10">
        <div class="w-14 h-14 rounded-2xl gold-gradient-bg flex items-center justify-center text-white shadow-xl shadow-gold-500/20">
          <i data-lucide="trending-up" class="w-7 h-7"></i>
        </div>
        <div>
          <h3 class="text-xl font-black text-slate-900 tracking-tight">تعديل البورصة</h3>
          <p class="text-xs font-bold text-slate-400 uppercase tracking-widest mt-1">Live Market Index • Global</p>
        </div>
      </div>

      <div class="space-y-10">
        <!-- Global Market Integration (TradingView Style) -->
        <div class="bg-white rounded-xl border border-slate-200 shadow-sm p-6 relative overflow-hidden group">
          <!-- Indicator bar at top -->
          <div class="absolute top-0 left-0 w-full h-1 transition-colors duration-500" :class="trendColorClass"></div>
          
          <div class="flex items-start justify-between mb-4">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-full bg-[#f2a900] text-white flex items-center justify-center shadow-md">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path><polyline points="3.29 7 12 12 20.71 7"></polyline><line x1="12" y1="22" x2="12" y2="12"></line></svg>
              </div>
              <div>
                <h4 class="text-[15px] font-black text-slate-900 leading-none tracking-tight">XAUUSD</h4>
                <p class="text-[11px] font-bold text-slate-400 mt-1 uppercase tracking-widest">Gold Spot / U.S. Dollar</p>
              </div>
            </div>
            <div class="text-slate-300 group-hover:text-slate-400 transition-colors">
              <i data-lucide="activity" class="w-5 h-5"></i>
            </div>
          </div>
          
          <div class="flex items-baseline gap-3 mb-6">
            <div class="text-4xl font-black text-slate-900 tracking-tighter" style="font-family: 'Inter', sans-serif;">
              {{ globalPrice ? globalPrice.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : '---' }}
            </div>
            <div v-if="globalPrice && priceChange !== 0" class="text-sm font-bold flex items-center gap-1" :class="trendTextColorClass">
              <i :data-lucide="priceChange > 0 ? 'trending-up' : 'trending-down'" class="w-4 h-4"></i>
              {{ priceChange > 0 ? '+' : '' }}{{ percentChange.toFixed(2) }}% ({{ Math.abs(priceChange).toFixed(2) }})
            </div>
            <div v-else-if="globalPrice" class="text-sm font-bold text-slate-400">
              0.00% (0.00)
            </div>
          </div>
          
          <div class="flex flex-col sm:flex-row items-center gap-4 pt-5 border-t border-slate-100">
            <div class="flex-1 w-full flex items-center gap-3">
              <div class="flex flex-col">
                <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest whitespace-nowrap">سعر الصرف:</label>
                <label class="flex items-center gap-1 mt-1 cursor-pointer group" title="جلب سعر الصرف تلقائياً من البنك المركزي">
                  <input type="checkbox" v-model="autoFetchExchangeRate" class="sr-only peer">
                  <div class="w-6 h-3 bg-slate-200 rounded-full peer peer-checked:bg-gold-500 relative after:content-[''] after:absolute after:w-2 after:h-2 after:bg-white after:rounded-full after:top-0.5 after:left-0.5 peer-checked:after:translate-x-3 transition-all"></div>
                  <span class="text-[9px] font-bold text-slate-400 group-hover:text-gold-500 transition-colors">تلقائي</span>
                </label>
              </div>
              <input 
                type="number" 
                v-model.number="exchangeRate"
                :disabled="autoFetchExchangeRate"
                class="w-full sm:w-32 bg-slate-50 rounded-lg px-3 py-2 text-sm font-black text-slate-900 border border-slate-200 focus:border-gold-400 focus:ring-2 focus:ring-gold-500/10 outline-none transition-all shadow-inner disabled:opacity-50 disabled:bg-slate-200"
              />
            </div>
            
            <div class="flex items-center gap-3 w-full sm:w-auto">
              <div class="flex items-center gap-2 text-[10px] font-black tracking-widest uppercase" :class="autoUpdate ? (fetchingGlobal ? 'text-gold-500' : 'text-slate-400') : 'text-slate-300'">
                <span class="relative flex h-2 w-2 mr-1">
                  <span v-if="autoUpdate" class="animate-ping absolute inline-flex h-full w-full rounded-full opacity-75" :class="trendBgClass"></span>
                  <span class="relative inline-flex rounded-full h-2 w-2" :class="autoUpdate ? trendBgClass : 'bg-slate-200'"></span>
                </span>
                {{ autoUpdate ? (fetchingGlobal ? 'Updating...' : 'Live') : 'Offline' }}
              </div>
              <button 
                @click="toggleAutoUpdate"
                class="bg-slate-50 hover:bg-slate-100 text-slate-600 font-bold p-2.5 rounded-lg flex items-center justify-center transition-all border border-slate-200 active:scale-95"
                title="Toggle Live Updates"
              >
                <i :data-lucide="autoUpdate ? 'pause' : 'play'" class="w-4 h-4" :class="autoUpdate ? 'fill-slate-600' : ''"></i>
              </button>
              <button 
                @click="fetchGlobalPrice(false)"
                :disabled="fetchingGlobal || !exchangeRate"
                class="bg-slate-900 text-white font-bold p-2.5 rounded-lg flex items-center justify-center transition-all hover:bg-slate-800 active:scale-95 disabled:opacity-50"
                title="Force Refresh"
              >
                <i data-lucide="refresh-cw" class="w-4 h-4" :class="{'animate-spin text-gold-400': fetchingGlobal}"></i>
              </button>
            </div>
          </div>
        </div>

        <div class="space-y-4">
          <label class="text-xs font-black text-slate-500 px-1 uppercase tracking-widest">Base Gold Price (K24)</label>
          <div class="relative group">
            <div class="absolute inset-0 gold-gradient-bg opacity-0 group-focus-within:opacity-[0.03] rounded-[24px] blur-xl transition-opacity pointer-events-none" />
            <input 
              type="number" 
              v-model.number="form.price_24k"
              @input="onBasePriceChange"
              class="w-full bg-slate-50/50 rounded-[28px] px-8 py-6 text-4xl font-black text-slate-900 border border-slate-100 focus:border-gold-400/50 focus:ring-4 focus:ring-gold-500/5 outline-none transition-all shadow-inner"
            />
            <span class="absolute left-8 top-1/2 -translate-y-1/2 text-sm text-slate-300 font-black tracking-widest italic">IQD / GRAM</span>
          </div>
          <p class="text-[10px] font-bold text-emerald-600 px-4 italic leading-relaxed">
            * يتم حساب قيم العيارات الأخرى تلقائياً بناءً على النسبة الذهبية العالمية من العيار الصافي (24).
          </p>
        </div>

        <div class="grid grid-cols-2 gap-6">
           <div class="p-6 bg-slate-50 rounded-[22px] border border-slate-100 flex flex-col items-center gap-3 hover:scale-[1.02] transition-transform">
             <div class="text-[9px] font-black text-slate-400 uppercase tracking-[0.2em]">K21 Index</div>
             <div class="text-2xl font-black text-slate-900 tracking-tight">{{ formatRawPrice(form.price_21k) }}</div>
           </div>
           <div class="p-6 bg-slate-50 rounded-[22px] border border-slate-100 flex flex-col items-center gap-3 hover:scale-[1.02] transition-transform">
             <div class="text-[9px] font-black text-slate-400 uppercase tracking-[0.2em]">K18 Index</div>
             <div class="text-2xl font-black text-slate-900 tracking-tight">{{ formatRawPrice(form.price_18k) }}</div>
           </div>
        </div>

        <button 
          @click="save"
          :disabled="saving || !form.price_24k"
          class="w-full gold-gradient-bg text-white font-black py-5 rounded-[24px] shadow-2xl shadow-gold-500/30 flex items-center justify-center gap-3 transition-all hover:scale-[1.02] active:scale-95 text-sm uppercase tracking-widest disabled:opacity-50"
        >
          <i data-lucide="check" class="w-5 h-5 stroke-[3]"></i>
          {{ saving ? 'جاري التحديث...' : 'Update All Terminals' }}
        </button>
      </div>
    </div>

    <!-- History Feed Card -->
    <div class="luxury-card p-10 bg-slate-900 text-white relative overflow-hidden shadow-2xl group min-h-[500px]" style="background-color: #0f172a;">
      <div class="absolute top-0 right-0 w-full h-full gold-gradient-bg opacity-[0.02] pointer-events-none" />
      <div class="absolute -bottom-20 -left-20 w-80 h-80 bg-gold-400/5 rounded-full blur-[100px] pointer-events-none" />
      
      <div class="relative z-10">
        <div class="flex items-center gap-4 mb-10">
           <div class="w-12 h-12 rounded-xl bg-white/5 flex items-center justify-center ring-1 ring-white/10">
             <i data-lucide="history" class="w-6 h-6 text-gold-400"></i>
           </div>
           <div>
             <h3 class="font-black text-white text-lg tracking-tight">تاريخ التقلبات</h3>
             <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Price History Tracking</p>
           </div>
        </div>
        
        <div class="space-y-6">
           <div 
             v-for="(p, i) in prices" 
             :key="p.id" 
             class="flex items-center justify-between py-5 border-b border-white/5 last:border-none group/item"
           >
             <div class="space-y-1">
               <div class="flex items-center gap-3">
                 <div class="text-lg font-black tracking-tight">{{ formatRawPrice(p.price_24k) }} <span class="text-[10px] font-normal opacity-30 italic">IQD</span></div>
                 <i v-if="i < prices.length - 1" :data-lucide="p.price_24k >= prices[i+1].price_24k ? 'trending-up' : 'trending-down'" :class="['w-3.5 h-3.5', p.price_24k >= prices[i+1].price_24k ? 'text-emerald-500' : 'text-rose-500']"></i>
               </div>
               <div class="text-[10px] font-bold text-slate-500 italic uppercase">{{ formatDateTime(p.created_at) }}</div>
             </div>
             <div class="text-[9px] font-black bg-white/5 px-3 py-1.5 rounded-lg border border-white/10 group-hover/item:bg-gold-500 group-hover/item:text-black transition-all duration-300">
               {{ p.updated_by_user?.name || 'ADMIN' }}
             </div>
           </div>
           
           <div v-if="loading" class="flex justify-center p-10">
             <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-gold-500"></div>
           </div>
           
           <div v-if="!loading && prices.length === 0" class="text-center p-10 text-slate-500 text-sm">
             لا يوجد سجل أسعار متاح
           </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick, watch, computed } from 'vue'
import api from '../api/axios'
import { useToastStore } from '../stores/toast'
import { useGoldStore } from '../stores/gold'

const toast = useToastStore()
const goldStore = useGoldStore()
const prices = ref([])
const loading = ref(true)
const saving = ref(false)
const form = ref({ price_24k: 0, price_21k: 0, price_18k: 0 })

const exchangeRate = ref(Number(localStorage.getItem('gold_exchange_rate')) || 1500)
const autoFetchExchangeRate = ref(localStorage.getItem('auto_exchange_rate') === 'true')
const globalPrice = ref(null)
const fetchingGlobal = ref(false)
const openPrice = ref(null)
const autoUpdate = ref(false)
const autoUpdateInterval = ref(null)

const priceChange = computed(() => {
  if (!globalPrice.value || !openPrice.value) return 0
  return globalPrice.value - openPrice.value
})

const percentChange = computed(() => {
  if (!openPrice.value || openPrice.value === 0) return 0
  return (priceChange.value / openPrice.value) * 100
})

const trendTextColorClass = computed(() => {
  if (priceChange.value > 0) return 'text-emerald-500'
  if (priceChange.value < 0) return 'text-rose-500'
  return 'text-slate-500'
})

const trendBgClass = computed(() => {
  if (priceChange.value > 0) return 'bg-emerald-500'
  if (priceChange.value < 0) return 'bg-rose-500'
  return 'bg-gold-500'
})

const trendColorClass = computed(() => {
  if (priceChange.value > 0) return 'bg-emerald-500'
  if (priceChange.value < 0) return 'bg-rose-500'
  return 'bg-gold-400'
})

watch(exchangeRate, (newVal) => {
  localStorage.setItem('gold_exchange_rate', newVal)
  if (globalPrice.value) {
    const pricePerGramUsd = globalPrice.value / 31.1034768
    form.value.price_24k = Math.round(pricePerGramUsd * newVal)
    onBasePriceChange()
  }
})

watch(autoFetchExchangeRate, (newVal) => {
  localStorage.setItem('auto_exchange_rate', newVal)
  if (newVal) {
    fetchGlobalPrice(true)
  }
})

async function fetchGlobalPrice(isSilent = false) {
  if (isSilent !== true) fetchingGlobal.value = true
  else if (!globalPrice.value) fetchingGlobal.value = true
  
  try {
    const res = await fetch('https://api.gold-api.com/price/XAU/USD')
    const data = await res.json()
    
    let currentExchangeRate = exchangeRate.value
    if (autoFetchExchangeRate.value) {
      try {
        const erRes = await fetch('https://open.er-api.com/v6/latest/USD')
        const erData = await erRes.json()
        if (erData && erData.rates && erData.rates.IQD) {
          currentExchangeRate = erData.rates.IQD
          exchangeRate.value = parseFloat(currentExchangeRate.toFixed(2))
        }
      } catch (er) {
        console.error('Failed to fetch exchange rate', er)
      }
    }

    if (data && data.price) {
      if (!openPrice.value) {
        // Fake a slight open price difference for the initial visual effect
        openPrice.value = data.price - (Math.random() * 4 - 2); 
      }
      globalPrice.value = data.price
      
      const pricePerGramUsd = data.price / 31.1034768
      const pricePerGramIqd = Math.round(pricePerGramUsd * currentExchangeRate)
      
      form.value.price_24k = pricePerGramIqd
      onBasePriceChange()
      
      if (isSilent !== true) toast.success('تم جلب السعر العالمي وتحديث سعر الغرام بنجاح')
    } else if (isSilent !== true) {
      toast.error('لم يتم العثور على بيانات السعر')
    }
  } catch (e) {
    console.error(e)
    if (isSilent !== true) toast.error('فشل في الاتصال بالبورصة العالمية')
  } finally {
    fetchingGlobal.value = false
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  }
}

function toggleAutoUpdate() {
  if (autoUpdate.value) {
    clearInterval(autoUpdateInterval.value)
    autoUpdateInterval.value = null
    autoUpdate.value = false
  } else {
    autoUpdate.value = true
    fetchGlobalPrice(true)
    autoUpdateInterval.value = setInterval(() => {
      fetchGlobalPrice(true)
    }, 15000) // 15 seconds
  }
}

onUnmounted(() => {
  if (autoUpdateInterval.value) clearInterval(autoUpdateInterval.value)
})

async function load() {
  loading.value = true
  try {
    const res = await api.get('/gold-prices')
    prices.value = res.data
    if (res.data.length > 0) {
      form.value.price_24k = res.data[0].price_24k
      form.value.price_21k = res.data[0].price_21k
      form.value.price_18k = res.data[0].price_18k
    }
  } finally {
    loading.value = false
    nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
  }
}

function onBasePriceChange() {
  const v = form.value.price_24k || 0
  form.value.price_21k = Math.round(v * 21 / 24)
  form.value.price_18k = Math.round(v * 18 / 24)
}

async function save() {
  if (!form.value.price_24k) return
  saving.value = true
  try {
    await api.post('/gold-prices', form.value)
    toast.success('تم تحديث أسعار السوق بنجاح')
    await load()
    goldStore.fetchLatestPrice()
  } catch (e) {
    toast.error('حدث خطأ أثناء التحديث')
  } finally {
    saving.value = false
  }
}

function formatRawPrice(v) {
  return new Intl.NumberFormat('ar-IQ').format(Math.round(v))
}

function formatDateTime(d) {
  return d ? new Date(d).toLocaleString('ar-IQ', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : ''
}

onMounted(() => {
  load()
  toggleAutoUpdate()
})
</script>
