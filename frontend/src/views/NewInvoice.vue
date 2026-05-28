<template>
  <div class="grid grid-cols-1 xl:grid-cols-3 gap-12 items-start max-w-7xl mx-auto">
    <div class="xl:col-span-2 space-y-8">
      <!-- Premium Input Sections -->
      <div class="luxury-card p-10 space-y-12 bg-white">
        <!-- Customer Details -->
        <section>
          <h3 class="text-[10px] font-black text-gold-600 uppercase tracking-[0.3em] mb-8 flex items-center gap-3">
            <div class="w-6 h-1 bg-gold-400 rounded-full" />
            Identity • بيانات العميل
          </h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div class="space-y-3">
              <label class="text-xs font-black text-slate-500 mr-1">اختر العميل</label>
              <div class="relative group">
                <i data-lucide="user-plus" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-gold-500 w-[18px] h-[18px]"></i>
                <select 
                  v-model="customerId" 
                  class="w-full bg-slate-50/50 border border-slate-100/50 rounded-2xl pr-12 pl-10 py-4 text-sm font-bold focus:ring-4 focus:ring-gold-500/5 focus:border-gold-300 outline-none transition-all appearance-none cursor-pointer"
                >
                  <option value="">نقدي / عام</option>
                  <option v-for="c in customers" :key="c.id" :value="c.id">{{ c.name }}</option>
                </select>
                <i data-lucide="chevron-down" class="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300 pointer-events-none w-[18px] h-[18px]"></i>
              </div>
            </div>
            <div class="space-y-3">
              <label class="text-xs font-black text-slate-500 mr-1">نوع العملية</label>
              <div class="flex bg-slate-100/50 p-1.5 rounded-2xl">
                <button 
                  v-for="t in ['sale', 'return']" 
                  :key="t"
                  @click="invoiceType = t"
                  :class="[
                    'flex-1 py-3 text-xs font-black rounded-xl transition-all',
                    invoiceType === t ? 'bg-white shadow-xl text-gold-600 scale-105' : 'text-slate-400 hover:text-slate-600'
                  ]"
                >
                  {{ t === 'sale' ? 'بـيع' : 'إرجاع' }}
                </button>
              </div>
            </div>
          </div>
        </section>

        <!-- Product Selection -->
        <section>
          <h3 class="text-[10px] font-black text-gold-600 uppercase tracking-[0.3em] mb-8 flex items-center gap-3">
            <div class="w-6 h-1 bg-gold-400 rounded-full" />
            Diamond Details • تفاصيل القطعة
          </h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-8 mb-10">
            <div class="space-y-3">
              <label class="text-xs font-black text-slate-500 mr-1">اختر القطعة أو أضف قطعة حرة</label>
              <div class="flex items-center gap-4 bg-slate-100/50 p-1.5 rounded-2xl mb-2">
                 <button @click="isFreePiece = false" :class="['flex-1 py-2 text-[10px] font-black rounded-xl transition-all', !isFreePiece ? 'bg-white shadow-sm text-gold-600' : 'text-slate-400']">من المخزون</button>
                 <button @click="isFreePiece = true" :class="['flex-1 py-2 text-[10px] font-black rounded-xl transition-all', isFreePiece ? 'bg-white shadow-sm text-gold-600' : 'text-slate-400']">قطعة حرة (بدون مخزون)</button>
              </div>

              <div v-if="!isFreePiece" class="relative group">
                <select 
                  v-model="selectedProductId" 
                  @change="onProductSelect"
                  class="w-full bg-slate-50/50 border border-slate-100/50 rounded-2xl pr-6 pl-10 py-4 text-sm font-bold focus:ring-4 focus:ring-gold-500/5 outline-none transition-all appearance-none cursor-pointer"
                >
                  <option value="">-- ابحث عن قطعة --</option>
                  <option v-for="p in availableProducts" :key="p.id" :value="p.id">
                    {{ p.name }} | {{ p.karat }}ك | {{ p.weight }}ج
                  </option>
                </select>
                <i data-lucide="chevron-down" class="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300 pointer-events-none w-[18px] h-[18px]"></i>
              </div>
              <div v-else class="relative group">
                <i data-lucide="tag" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-gold-500 w-[18px] h-[18px]"></i>
                <input 
                  type="text" 
                  v-model="itemForm.item_name" 
                  placeholder="اسم القطعة (مثال: خاتم ذهب حر)..." 
                  class="w-full bg-slate-50/50 border border-slate-100/50 rounded-2xl pr-12 pl-4 py-4 text-sm font-bold focus:ring-4 focus:ring-gold-500/5 outline-none transition-all" 
                />
              </div>
            </div>
            <div class="space-y-3">
              <label class="text-xs font-black text-slate-500 mr-1">سعر الجرام الحالي (د.ع)</label>
              <div class="relative group">
                <i data-lucide="trending-up" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-gold-500 w-[18px] h-[18px]"></i>
                <input 
                  type="number" 
                  v-model.number="itemForm.price_per_gram" 
                  placeholder="أدخل السعر..." 
                  class="w-full bg-slate-50/50 border border-slate-100/50 rounded-2xl pr-12 pl-4 py-4 text-sm font-bold focus:ring-4 focus:ring-gold-500/5 outline-none transition-all" 
                />
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-8 items-end">
            <div class="space-y-3">
              <label class="text-xs font-black text-slate-500 mr-1">العيار</label>
              <div class="flex bg-slate-100/50 p-1.5 rounded-2xl">
                <div 
                  v-for="k in [24, 21, 18]" 
                  :key="k"
                  :class="[
                    'flex-1 py-3 text-center text-xs font-black rounded-xl transition-all',
                    itemForm.karat == k ? 'bg-white shadow-xl text-gold-600' : 'text-slate-400'
                  ]"
                >
                  K{{ k }}
                </div>
              </div>
            </div>
            <div class="space-y-3">
              <label class="text-xs font-black text-slate-500 mr-1">الوزن الصافي (غرام)</label>
              <input 
                type="number" step="0.001" 
                v-model.number="itemForm.weight"
                :readonly="!isFreePiece"
                :class="['w-full bg-slate-100/50 border border-slate-100/50 rounded-2xl px-6 py-4 text-xl font-black focus:ring-4 focus:ring-gold-500/5 outline-none transition-all', !isFreePiece ? 'cursor-not-allowed opacity-70' : 'bg-white text-gold-600 shadow-inner border-gold-100']" 
              />
            </div>
            <div class="space-y-3">
              <label class="text-xs font-black text-slate-500 mr-1">أجور الصياغة (للقطعة)</label>
              <input 
                type="number" 
                v-model.number="itemForm.craft_price"
                class="w-full bg-slate-50/50 border border-slate-100/50 rounded-2xl px-6 py-4 text-xl font-black text-gold-600 focus:ring-4 focus:ring-gold-500/5 outline-none transition-all" 
              />
            </div>
          </div>
          
          <div class="mt-8 flex justify-end">
            <button 
              @click="addItem" 
              :disabled="!canAddItem"
              class="gold-gradient-bg text-white px-8 py-4 rounded-2xl font-black shadow-xl shadow-gold-500/20 hover:scale-105 active:scale-95 disabled:opacity-50 disabled:scale-100 transition-all flex items-center gap-3"
            >
              <i data-lucide="plus" class="w-5 h-5 stroke-[3]"></i>
              إضافة إلى الفاتورة
            </button>
          </div>
        </section>
      </div>

      <!-- Added Items List (Visible on all screens) -->
      <div v-if="items.length > 0" class="luxury-card p-10 bg-white space-y-8">
        <h3 class="text-[10px] font-black text-gold-600 uppercase tracking-[0.3em] flex items-center gap-3">
          <div class="w-6 h-1 bg-gold-400 rounded-full" />
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
                <td class="py-4 text-slate-900">{{ item.productName }}</td>
                <td class="py-4">{{ item.weight }} جرام</td>
                <td class="py-4">K{{ item.karat }}</td>
                <td class="py-4">{{ formatRawPrice(item.price_per_gram) }} د.ع</td>
                <td class="py-4 text-gold-600">{{ formatRawPrice(item.craft_price) }} د.ع</td>
                <td class="py-4 text-left font-black text-slate-900">{{ formatRawPrice(item.total_price) }} د.ع</td>
                <td class="py-4 text-left">
                  <button 
                    type="button" 
                    @click="removeItem(idx)"
                    class="text-rose-500 hover:text-rose-700 transition-colors p-1"
                    title="حذف القطعة"
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
        <div class="absolute top-0 right-0 w-40 h-40 gold-gradient-bg opacity-10 rounded-full blur-3xl" />
        <div class="grid grid-cols-1 md:grid-cols-2 gap-10 items-center">
          <div class="space-y-6">
            <div class="space-y-2">
              <span class="text-[10px] font-black text-gold-500 uppercase tracking-widest leading-none">Checkout • الدفع</span>
              <h2 class="text-3xl font-black tracking-tight leading-none">إتمام العملية</h2>
            </div>
            
            <div class="grid grid-cols-2 gap-4">
              <div class="space-y-3">
                <label class="text-xs font-bold text-slate-400">الخصم (د.ع)</label>
                <input 
                  type="number" 
                  v-model.number="discount"
                  class="w-full bg-white/5 border border-white/10 rounded-2xl px-4 py-4 text-xl font-black text-emerald-400 outline-none focus:bg-white/10 focus:ring-4 focus:ring-gold-500/20 transition-all"
                />
              </div>
              <div class="space-y-3">
                <label class="text-xs font-bold text-slate-400">المبلغ المدفوع من العميل</label>
                <input 
                  type="number" 
                  v-model.number="paidAmount"
                  class="w-full bg-white/5 border border-white/10 rounded-2xl px-4 py-4 text-xl font-black text-gold-400 outline-none focus:bg-white/10 focus:ring-4 focus:ring-gold-500/20 transition-all"
                />
              </div>
            </div>
            <div class="flex gap-4">
              <button @click="$router.push('/dashboard')" class="flex-1 bg-white/5 hover:bg-white/10 text-white py-4 rounded-2xl font-black text-[10px] transition-all ring-1 ring-white/10">إلغاء</button>
              <button 
                @click="submitInvoice('draft')"
                :disabled="items.length === 0 || saving"
                class="flex-1 bg-indigo-500/20 hover:bg-indigo-500/30 text-indigo-300 py-4 rounded-2xl font-black text-[10px] transition-all disabled:opacity-50"
              >
                حفظ مسودة
              </button>
              <button 
                @click="submitInvoice('completed')"
                :disabled="items.length === 0 || saving"
                class="flex-[2] gold-gradient-bg py-4 rounded-2xl font-black text-xs text-white shadow-xl shadow-gold-500/20 transition-all hover:scale-105 active:scale-95 disabled:opacity-50 disabled:scale-100"
              >
                {{ saving ? 'جاري...' : 'تثبيت وطباعة' }}
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
                  <span>الخصم الممنوح</span>
                  <span class="font-bold">- {{ formatRawPrice(discount) }}</span>
                </div>
              </div>
              <div class="pt-6 border-t border-white/5 space-y-4">
                <div class="flex justify-between items-baseline">
                  <span class="text-gold-500 font-black text-sm">المجموع النهائي</span>
                  <span class="text-4xl font-black tracking-tight">{{ formatRawPrice(totalAmount) }} <span class="text-xs font-normal opacity-30">د.ع</span></span>
                </div>
                <div class="flex justify-between items-baseline bg-emerald-500/10 p-4 rounded-2xl border border-emerald-500/20">
                  <span class="text-emerald-500 font-black text-xs uppercase tracking-widest">التغيير (الباقي)</span>
                  <span class="text-2xl font-black text-emerald-400 tracking-tight">{{ formatRawPrice(changeAmount) }} <span class="text-[10px] font-normal opacity-40">د.ع</span></span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Receipt Preview Sidebar -->
    <div class="sticky top-10 hidden xl:block">
      <div class="bg-white rounded-[32px] shadow-[0_40px_100px_-20px_rgba(0,0,0,0.1)] p-10 border border-slate-100 border-t-[12px] border-t-gold-500 relative">
        <div class="absolute top-0 right-1/2 translate-x-1/2 -translate-y-1/2 w-48 h-10 bg-white border border-slate-100 rounded-full shadow-lg flex items-center justify-center p-1">
           <div class="w-full h-full bg-slate-50 rounded-full flex items-center justify-center gap-2">
             <div class="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-pulse" />
             <span class="text-[8px] font-black text-slate-400 uppercase tracking-widest">Verified Receipt Preview</span>
           </div>
        </div>

        <div class="text-center pb-10 mb-10 border-b border-dashed border-slate-200">
           <i data-lucide="diamond" class="mx-auto text-gold-500 mb-4 w-8 h-8 fill-gold-500"></i>
           <h2 class="text-2xl font-black tracking-tight text-slate-900 italic">{{ shopSettings.shopName || 'مجوهرات الذهبي' }}</h2>
           <p class="text-[10px] font-bold text-slate-400 uppercase tracking-wider mt-1 opacity-60">Fine Jewelry & luxury Watch Retailer</p>
        </div>

        <div class="space-y-6">
           <div class="flex justify-between items-center text-[11px] font-black uppercase text-slate-300 tracking-widest">
             <span>Voucher #</span>
             <span class="text-slate-900">PREVIEW-MODE</span>
           </div>
           
           <div class="space-y-4 pt-4 border-t border-slate-50 min-h-[100px]">
              <div v-for="(item, idx) in items" :key="idx" class="flex justify-between items-center bg-slate-50 p-4 rounded-2xl group/receipt-item">
                <div class="space-y-0.5">
                  <div class="text-xs font-black text-slate-900">{{ item.productName }}</div>
                  <div class="text-[9px] font-bold text-slate-400 italic">{{ item.weight }} g • {{ formatRawPrice(item.price_per_gram) }} / g</div>
                </div>
                <div class="flex items-center gap-3">
                  <div class="text-sm font-black text-slate-900">{{ formatRawPrice(item.total_price) }}</div>
                  <button 
                    type="button" 
                    @click="removeItem(idx)"
                    class="text-rose-500 hover:text-rose-700 opacity-0 group-hover/receipt-item:opacity-100 transition-opacity p-1"
                    title="حذف القطعة"
                  >
                    <i data-lucide="trash-2" class="w-3.5 h-3.5"></i>
                  </button>
                </div>
              </div>
              <div v-if="items.length === 0" class="text-center py-6 text-slate-300 text-xs italic">لا توجد قطع مضافة</div>
            </div>

           <div class="pt-20 space-y-4">
             <div class="flex justify-between text-2xl font-black text-slate-900 uppercase">
               <span class="tracking-tighter">Total Due</span>
               <span>{{ formatRawPrice(totalAmount) }}</span>
             </div>
             <div class="text-center">
                <div class="inline-block p-4 bg-slate-50 rounded-3xl border border-slate-100 grayscale hover:grayscale-0 transition-all cursor-pointer">
                  <div class="w-32 h-32 bg-white rounded-2xl border border-slate-200 flex flex-col items-center justify-center gap-2">
                     <div class="w-20 h-1 bg-slate-900 rounded-full" />
                     <div class="w-16 h-1 bg-slate-900 rounded-full" />
                     <div class="w-24 h-1 bg-gold-400 rounded-full" />
                     <span class="text-[8px] font-black text-slate-300 mt-2">QR VERIFY</span>
                  </div>
                </div>
             </div>
           </div>
        </div>

        <div class="mt-12 text-center text-[9px] font-bold text-slate-300 uppercase tracking-[0.3em]">
          Non-Refundable • Auth Dealer
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api/axios'
import { useToastStore } from '../stores/toast'
import { useGoldStore } from '../stores/gold'

const router = useRouter()
const toast = useToastStore()
const goldStore = useGoldStore()

const invoiceType = ref('sale')
const customerId = ref('')
const paidAmount = ref(0)
const discount = ref(0)
const notes = ref('')
const items = ref([])
const customers = ref([])
const availableProducts = ref([])
const selectedProductId = ref('')
const saving = ref(false)
const isFreePiece = ref(false)

const itemForm = ref({ product_id: '', item_name: '', weight: 0, karat: 21, price_per_gram: 0, craft_price: 0 })
const shopSettings = ref({})

onMounted(async () => {
  try {
    const [custRes, prodRes] = await Promise.all([
      api.get('/customers'),
      api.get('/products?status=available'),
    ])
    customers.value = custRes.data
    availableProducts.value = prodRes.data
    
    // Set default price from store
    if (goldStore.latestPrice) {
      itemForm.value.price_per_gram = goldStore.latestPrice.price_21k
    }

    const savedSettings = localStorage.getItem('kimia_settings')
    if (savedSettings) {
      try {
        shopSettings.value = JSON.parse(savedSettings)
      } catch (e) {}
    }
  } finally {
    nextTick(() => {
      if (window.refreshIcons) window.refreshIcons()
    })
  }
})

const itemSubtotal = computed(() => {
  return (itemForm.value.weight * itemForm.value.price_per_gram) + (itemForm.value.craft_price || 0)
})

const canAddItem = computed(() => {
  if (isFreePiece.value) {
    return itemForm.value.item_name && itemForm.value.weight > 0 && itemForm.value.price_per_gram > 0
  }
  return selectedProductId.value && itemForm.value.price_per_gram > 0
})

const totalAmount = computed(() => items.value.reduce((s, i) => s + i.total_price, 0) - (discount.value || 0))
const totalGoldValue = computed(() => items.value.reduce((s, i) => s + (i.weight * i.price_per_gram), 0))
const totalCraftValue = computed(() => items.value.reduce((s, i) => s + i.craft_price, 0))
const changeAmount = computed(() => Math.max(0, (paidAmount.value || 0) - totalAmount.value))

function onProductSelect() {
  const p = availableProducts.value.find(x => x.id === selectedProductId.value)
  if (p) {
    itemForm.value.product_id = p.id
    itemForm.value.weight = parseFloat(p.weight)
    itemForm.value.karat = p.karat
    itemForm.value.craft_price = parseFloat(p.craft_price || 0)
    
    // Auto-update price per gram based on karat
    if (goldStore.latestPrice) {
      const karatKey = `price_${p.karat}k`
      itemForm.value.price_per_gram = goldStore.latestPrice[karatKey] || goldStore.latestPrice.price_21k
    }
  }
}

function addItem() {
  if (isFreePiece.value) {
    items.value.push({
      product_id: null,
      item_name: itemForm.value.item_name,
      productName: itemForm.value.item_name,
      weight: itemForm.value.weight,
      karat: itemForm.value.karat,
      price_per_gram: itemForm.value.price_per_gram,
      craft_price: itemForm.value.craft_price,
      total_price: itemSubtotal.value,
      rawProduct: null,
    })
  } else {
    const p = availableProducts.value.find(x => x.id === selectedProductId.value)
    if (!p) return
    items.value.push({
      product_id: p.id,
      item_name: p.name,
      productName: p.name,
      weight: itemForm.value.weight,
      karat: itemForm.value.karat,
      price_per_gram: itemForm.value.price_per_gram,
      craft_price: itemForm.value.craft_price,
      total_price: itemSubtotal.value,
      rawProduct: p,
    })
    availableProducts.value = availableProducts.value.filter(x => x.id !== p.id)
  }
  
  selectedProductId.value = ''
  itemForm.value = { 
    product_id: '', item_name: '', weight: 0, karat: 21, 
    price_per_gram: goldStore.latestPrice?.price_21k || 0, 
    craft_price: 0 
  }
  nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
}

function removeItem(idx) {
  const item = items.value[idx]
  if (item.rawProduct) {
    availableProducts.value.push(item.rawProduct)
  }
  items.value.splice(idx, 1)
  nextTick(() => { if (window.refreshIcons) window.refreshIcons() })
}

async function submitInvoice(status = 'completed') {
  if (items.value.length === 0) return
  saving.value = true
  try {
    await api.post('/invoices', {
      type: invoiceType.value,
      status: status,
      customer_id: customerId.value || undefined,
      paid_amount: paidAmount.value || 0,
      discount: discount.value || 0,
      notes: notes.value,
      items: items.value.map(i => ({
        product_id: i.product_id,
        item_name: i.item_name,
        weight: i.weight,
        karat: i.karat,
        price_per_gram: i.price_per_gram,
        craft_price: i.craft_price,
      })),
    })
    toast.success('تم الحفظ بنجاح')
    router.push('/invoices')
  } catch (e) {
    toast.error(e.response?.data?.message || 'حدث خطأ أثناء الحفظ')
  } finally { saving.value = false }
}

function formatRawPrice(v) {
  return new Intl.NumberFormat('ar-IQ').format(Math.round(v))
}
</script>
