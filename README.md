# نظام مبيعات الذهب 💎
## Gold Jewelry Management System

نظام متكامل لإدارة محلات الذهب مبني على Vue 3 + NestJS + PostgreSQL

---

## 🏗️ هيكل المشروع

```
gold_prices/
├── backend/           # NestJS API (منفذ 3000)
├── frontend/          # Vue 3 + Vite (منفذ 5173)
└── setup.bat          # سكريبت الإعداد
```

---

## ⚡ متطلبات التشغيل

1. **Node.js** v18 أو أحدث
2. **PostgreSQL** v14 أو أحدث
3. **npm** v9+

---

## 🚀 خطوات التشغيل

### 1. إنشاء قاعدة البيانات
```sql
CREATE DATABASE gold_system;
```

### 2. إعداد Backend
```bash
cd backend
# تعديل ملف .env بمعلومات قاعدة البيانات
# DB_USERNAME=postgres
# DB_PASSWORD=your_password
# DB_DATABASE=gold_system

npm install
npm run start:dev
```

### 3. إعداد Frontend
```bash
cd frontend
npm install
npm run dev
```

### 4. الدخول للنظام
- الرابط: http://localhost:5173
- المستخدم: `admin`
- كلمة المرور: `admin123`

---

## 🔧 الإعدادات (backend/.env)

```env
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_DATABASE=gold_system
JWT_SECRET=your_secret_key
JWT_EXPIRES_IN=7d
PORT=3000
```

---

## 📋 الميزات

| الميزة | الوصف |
|--------|-------|
| 🔐 نظام صلاحيات | Admin / Cashier / Accountant |
| 💍 إدارة المخزون | إضافة وتتبع قطع الذهب |
| 🧾 الفواتير | بيع وإرجاع مع ربط العملاء |
| 👥 العملاء | قاعدة بيانات العملاء مع رصيد الديون |
| 🛒 المشتريات | شراء الذهب المستعمل والكسر |
| 💸 المصروفات | تتبع المصروفات بالفئات |
| 📋 الديون | متابعة وسداد ديون العملاء |
| 📈 أسعار الذهب | سجل تاريخي للأسعار |
| 📦 الجرد | مقارنة المخزون الفعلي بالنظام |
| 📊 التقارير | إحصائيات شاملة |

---

## 🌐 نقاط API الرئيسية

```
POST   /api/auth/login
GET    /api/products
POST   /api/invoices
GET    /api/reports/dashboard
GET    /api/gold-prices/latest
```
