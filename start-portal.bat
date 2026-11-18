@echo off
title Media Four Tribuan News Server (Golang + Vue 3)
echo ====================================================
echo   MEDIA FOUR TRIBUAN NEWS - PORTAL BERITA NASIONAL
echo   Aktual * Terpercaya * Independen
echo ====================================================
echo.
echo Menjalankan server di http://localhost:8080 ...
echo Login Admin: http://localhost:8080/admin/login
echo.
cd /d "%~dp0backend"
if exist "mftn-server.exe" (
  mftn-server.exe
) else (
  "C:\Program Files\Go\bin\go.exe" run .
)
pause
