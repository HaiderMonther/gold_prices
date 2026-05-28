<template>
  <div class="grid grid-cols-1 xl:grid-cols-3 gap-12 items-start max-w-7xl mx-auto">
    <div class="xl:col-span-2 space-y-8">
      <!-- Premium Input Sections -->
      <div class="luxury-card p-10 space-y-12 bg-white">
        <!-- Trader Details -->
        <section>
          <h3 class="text-[10px] font-black text-indigo-600 uppercase tracking-[0.3em] mb-8 flex items-center gap-3">
            <div class="w-6 h-1 bg-indigo-400 rounded-full" />
            Vendor Details • بيانات التاجر
          </h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div class="space-y-3">
              <label class="text-xs font-black text-slate-500 mr-1">اختر التاجر / الورشة</label>
              <div class="relative group">
                <i data-lucide="store" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-indigo-500 w-[18px] h-[18px]"></i>
                <select 
                  v-model="customerId" 
                  class="w-full bg-slate-50/50 border border-slate-100/50 rounded-2xl pr-12 pl-10 py-4 text-sm font-bold focus:ring-4 focus:ring-indigo-500/5 focus:border-indigo-300 outline-none transition-all appearance-none cursor-pointer"
                >
                  <option value="">اختر التاجر...</option>
                  <option v-for="c in traders" :key="c.id" :value="c.id">{{ c.name }}</option>
                </select>
                <i data-lucide="chevron-down" class="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300 pointer-events-none w-[18px] h-[18px]"></i>
              </div>
            </div>
            <div class="space-y-3">
              <label class="text-xs font-black text-slate-500 mr-1">سعر الجرام الأساسي (د.ع)</label>
              <div class="relative group">
                <i data-lucide="trending-up" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-indigo-500 w-[18px] h-[18px]"></i>
                <input 
                  type="number" 
                  v-model.number="basePricePerGram" 
                  class="w-full bg-slate-50/50 border border-slate-100/50 rounded-2xl pr-12 pl-4 py-4 text-sm font-bold focus:ring-4 focus:ring-indigo-500/5 outline-none transition-all text-indigo-600" 
                />
              </div>
            </div>
          </div>
        </section>

        <!-- Product Details -->
        <section>
          <h3 class="text-[10px] font-black text-indigo-600 uppercase tracking-[0.3em] mb-8 flex items-center gap-3">
            <div class="w-6 h-1 bg-indigo-400 rounded-full" />
            New Items • القطع المشتراة
          </h3>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-8 mb-8">
            <div class="space-y-3">
              <label class="text-xs font-black text-slate-500 mr-1">اسم القطعة أو الموديل</label>
              <div class="relative group">
                <i data-lucide="tag" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-indigo-500 w-[18px] h-[18px]"></i>
                <input 
                  type="text" 
                  v-model="itemForm.item_name" 
                  placeholder="مثال: طقم لازوردي عيار 21..." 
                  class="w-full bg-slate-50/50 border border-slate-100/50 rounded-2xl pr-12 pl-4 py-4 text-sm font-bold focus:ring-4 focus:ring-indigo-500/5 outline-none transition-all" 
                />
              </div>
            </div>
            <div class="space-y-3">
              <label class="text-xs font-black text-slate-500 mr-1">العيار</label>
              <div class="flex bg-slate-100/50 p-1.5 rounded-2xl">
                <div 
                  v-for="k in [24, 21, 18]" 
                  :key="k"
                  @click="itemForm.karat = k"
                  :class="[
                    'flex-1 py-3 text-center text-xs font-black rounded-xl transition-all cursor-pointer hover:bg-white/50',
                    itemForm.karat == k ? 'bg-white shadow-md text-indigo-600' : 'text-slate-400'
                  ]"
                >
                  K{{ k }}
                </div>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-8 mb-8">
            <div class="space-y-3">
              <label class="text-xs font-black text-slate-500 mr-1">الوزن الصافي (غرام)</label>
              <input 
                type="number" step="0.001" 
                v-model.number="itemForm.weight"
                class="w-full bg-slate-50/50 border border-slate-100/50 rounded-2xl px-6 py-4 text-xl font-black focus:ring-4 focus:ring-indigo-500/5 outline-none transition-all text-indigo-600" 
              />
            </div>
            <div class="space-y-3">
              <label class="text-xs font-black text-slate-500 mr-1">أجور الصياغة (للقطعة كاملاً)</label>
              <input 
                type="number" 
                v-model.number="itemForm.craft_price"
                class="w-full bg-slate-50/50 border border-slate-100/50 rounded-2xl px-6 py-4 text-xl font-black focus:ring-4 focus:ring-indigo-500/5 outline-none transition-all" 
              />
            </div>
          </div>
          
          <div class="mt-8 flex justify-end">
            <button 
              @click="addItem" 
              :disabled="!canAddItem"
              class="bg-indigo-600 hover:bg-indigo-700 text-white px-8 py-4 rounded-2xl font-black shadow-xl shadow-indigo-500/20 hover:scale-105 active:scale-95 disabled:opacity-50 disabled:scale-100 transition-all flex items-center gap-3"
            >
              <i data-lucide="plus" class="w-5 h-5 stroke-[3]"></i>
              إضافة إلى الفاتورة
            </button>
          </div>
        </section>
      </div>

      <!-- Added Items List -->
      <div v-if="items.length > 0" class="luxury-card p-10 bg-white space-y-8">
        <h3 class="text-[10px] font-black text-indigo-600 uppercase tracking-[0.3em] flex items-center gap-3">
          <div class="w-6 h-1 bg-indigo-400 rounded-full" />
          Added Items • القطع المضافة
        </h3>
        <div class="overflow-x-auto">
          <table class="w-full text-right border-collapse">
            <thead>
              <tr class="border-b border-slate-100 text-xs font-black text-slate-400 uppercase tracking-wider">
                <th class="pb-4">القطعة</th>
                <th class="pb-4">الوزن</th>
                <th class="pb-4">العيار</th>
                <th class="pb-4">سعر الجرام</th>
                <th class="pb-4">أجور الصياغة</th>
                <th class="pb-4 text-left">المجموع</th>
                <th class="pb-4 w-12"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-50 text-sm font-bold text-slate-700">
              <tr v-for="(item, idx) in items" :key="idx" class="group/table-item">
                <td class="py-4 text-slate-900">{{ item.item_name }}</td>
                <td class="py-4">{{ item.weight }} جرام</td>
                <td class="py-4">K{{ item.karat }}</td>
                <td class="py-4">{{ formatRawPrice(item.price_per_gram) }} د.ع</td>
                <td class="py-4 text-indigo-600">{{ formatRawPrice(item.craft_price) }} د.ع</td>
                <td class="py-4 text-left font-black text-slate-900">{{ formatRawPrice(item.total_price) }} د.ع</td>
                <td class="py-4 text-left">
                  <button 
                    type="button" 
                    @click="removeItem(idx)"
                    class="text-rose-500 hover:text-rose-700 transition-colors p-1"
                  >
                    <i data-lucide="trash-2" class="w-4 h-4"></i>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
 
      <!-- Checkout Section -->
      <div class="luxury-card p-10 bg-slate-900 text-white relative shadow-2xl shadow-indigo-900/40 overflow-hidden" style="background-color: #0f172a;">
        <div class="absolute top-0 right-0 w-40 h-40 bg-indigo-500 opacity-20 rounded-full blur-3xl" />
        <div class="grid grid-cols-1 md:grid-cols-2 gap-10 items-center">
          <div class="space-y-6">
            <div class="space-y-2">
              <span class="text-[10px] font-black text-indigo-400 uppercase tracking-widest leading-none">Checkout • الدفع للمورد</span>
              <h2 class="text-3xl font-black tracking-tight leading-none">إتمام العملية</h2>
            </div>
            
            <div class="grid grid-cols-2 gap-4">
              <div class="space-y-3">
                <label class="text-xs font-bold text-slate-400">الخصم المكتسب (د.ع)</label>
                <input 
                  type="number" 
                  v-model.number="discount"
                  class="w-full bg-white/5 border border-white/10 rounded-2xl px-4 py-4 text-xl font-black text-emerald-400 outline-none focus:bg-white/10 focus:ring-4 focus:ring-indigo-500/20 transition-all"
                />
              </div>
              <div class="space-y-3">
                <label class="text-xs font-bold text-slate-400">المبلغ المدفوع للتاجر</label>
                <input 
                  type="number" 
                  v-model.number="paidAmount"
                  class="w-full bg-white/5 border border-white/10 rounded-2xl px-4 py-4 text-xl font-black text-indigo-400 outline-none focus:bg-white/10 focus:ring-4 focus:ring-indigo-500/20 transition-all"
                />
              </div>
            </div>
            
            <div class="flex gap-4">
              <button @click="$router.push('/dashboard')" class="flex-1 bg-white/5 hover:bg-white/10 text-white py-4 rounded-2xl font-black text-xs transition-all ring-1 ring-white/10">إلغاء</button>
              <button 
                @click="submitInvoice"
                :disabled="items.length === 0 || !customerId || saving"
                class="flex-[2] bg-indigo-600 hover:bg-indigo-500 py-4 rounded-2xl font-black text-xs text-white shadow-xl shadow-indigo-500/20 transition-all hover:scale-105 active:scale-95 disabled:opacity-50 disabled:scale-100"
              >
                {{ saving ? 'جاري الحفظ...' : 'تثبيت فاتورة الشراء' }}
              </button>
            </div>
          </div>
          
          <div class="bg-white/5 rounded-3xl p-8 border border-white/5 relative overflow-hidden backdrop-blur-xl">
            <div class="space-y-6 relative z-10">
              <div class="flex justify-between items-center text-xs opacity-40 font-bold italic">PRO-ACCOUNTING SYSTEM</div>
              <div class="space-y-4">
                <div class="flex justify-between text-slate-400 text-sm">
                  <span>قيمة الذهب</span>
                  <span class="font-bold text-white">{{ formatRawPrice(totalGoldValue) }}</span>
                </div>
                <div class="flex justify-between text-slate-400 text-sm">
                  <span>إجمالي الأجور</span>
                  <span class="font-bold text-white">{{ formatRawPrice(totalCraftValue) }}</span>
                </div>
                <div v-if="discount > 0" class="flex justify-between text-emerald-400 text-sm">
                  <span>الخصم المكتسب</span>
                  <span class="font-bold">- {{ formatRawPrice(discount) }}</span>
                </div>
              </div>
              <div class="pt-6 border-t border-white/5 space-y-4">
                <div class="flex justify-between items-baseline">
                  <span class="text-indigo-400 font-black text-sm">المجموع المطلوب</span>
                  <span class="text-4xl font-black tracking-tight">{{ formatRawPrice(totalAmount) }} <span class="text-xs font-normal opacity-30">د.ع</span></span>
                </div>
                <div class="flex justify-between items-baseline bg-rose-500/10 p-4 rounded-2xl border border-rose-500/20">
                  <span class="text-rose-500 font-black text-xs uppercase tracking-widest">المتبقي (دين للتاجر)</span>
                  <span class="text-2xl font-black text-rose-400 tracking-tight">{{ formatRawPrice(remainingAmount) }} <span class="text-[10px] font-normal opacity-40">د.ع</span></span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick, watch } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api/axios'
import { useToastStore } from '../stores/toast'
import { useGoldStore } from '../stores/gold'

const router = useRouter()
const toast = useToastStore()
const goldStore = useGoldStore()

const customerId = ref('')
const paidAmount = ref(0)
const discount = ref(0)
const items = ref([])
const traders = ref([])
const saving = ref(false)
const basePricePerGram = ref(0)

const itemForm = ref({ item_name: '', weight: 0, karat: 21, craft_price: 0 })

onMounted(async () => {
  try {
    const custRes = await api.get('/customers')
    traders.value = custRes.data.filter(c => c.type === 'trader' || c.type === 'workshop')
    
    // Set default price from store
    if (goldStore.latestPrice) {
      basePricePerGram.value = goldStore.latestPrice.price_21k
    }
  } finally {
    nextTick(() => {
      if (window.refreshIcons) window.refreshIcons()
    })
  }
})

// Adjust price per gram based on karat
const adjustedPricePerGram = computed(() => {
  if (itemForm.value.karat === 21) return basePricePerGram.value
  return (basePricePerGram.value / 21) * itemForm.value.karat
})

const itemSubtotal = computed(() => {
  return (itemForm.value.weight * adjustedPricePerGram.value) + (itemForm.value.craft_price || 0)
})

const canAddItem = computed(() => itemForm.value.item_name && itemForm.value.weight > 0)

const totalAmount = computed(() => items.value.reduce((s, i) => s + i.total_price, 0) - (discount.value || 0))
const totalGoldValue = computed(() => items.value.reduce((s, i) => s + (i.weight * i.price_per_gram), 0))
const totalCraftValue = computed(() => items.value.reduce((s, i) => s + i.craft_price, 0))
const remainingAmount = computed(() => Math.max(0, totalAmount.value - (paidAmount.value || 0)))

function addItem() {
  items.value.push({
    item_name: itemForm.value.item_name,
    weight: itemForm.value.weight,
    karat: itemForm.value.karat,
    price_per_gram: adjustedPricePerGram.value,
    craft_price: itemForm.value.craft_price,
    total_price: itemSubtotal.value,
  })
  
  itemForm.value = { item_name: '', weight: 0, karat: 21, craft_price: 0 }
  nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
}

function removeItem(idx) {
  items.value.splice(idx, 1)
  nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
}

async function submitInvoice() {
  if (items.value.length === 0 || !customerId.value) return
  saving.value = true
  try {
    await api.post('/invoices', {
      type: 'purchase',
      status: 'completed',
      customer_id: customerId.value,
      paid_amount: paidAmount.value || 0,
      discount: discount.value || 0,
      notes: 'فاتورة شراء مجوهرات من تاجر',
      items: items.value.map(i => ({
        item_name: i.item_name,
        weight: i.weight,
        karat: i.karat,
        price_per_gram: i.price_per_gram,
        craft_price: i.craft_price,
      })),
    })
    toast.success('تم إنشاء فاتورة الشراء وتحديث المخزون بنجاح')
    router.push('/products')
  } catch (e) {
    toast.error(e.response?.data?.message || 'حدث خطأ أثناء الحفظ')
  } finally { saving.value = false }
}

function formatRawPrice(v) {
  return new Intl.NumberFormat('ar-IQ').format(Math.round(v))
}
</script>
