@echo off
echo ============================================
echo    نظام مبيعات الذهب - Gold Sales System
echo ============================================

echo.
echo [1/3] تثبيت مكتبات Backend...
cd backend
call npm install
if %ERRORLEVEL% NEQ 0 (
    echo خطأ في تثبيت Backend
    pause
    exit /b 1
)

echo.
echo [2/3] تثبيت مكتبات Frontend...
cd ..\frontend
call npm install
if %ERRORLEVEL% NEQ 0 (
    echo خطأ في تثبيت Frontend
    pause
    exit /b 1
)

echo.
echo [3/3] الإعداد مكتمل!
echo.
echo لتشغيل النظام:
echo   Backend:  cd backend ^&^& npm run start:dev
echo   Frontend: cd frontend ^&^& npm run dev
echo.
echo قاعدة البيانات:
echo   اسم: gold_system
echo   يجب إنشاؤها في PostgreSQL قبل التشغيل
echo.
pause
