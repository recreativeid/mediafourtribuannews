# Media Four Tribuan News — Portal Berita Nasional (Vue 3 + Golang)

**Aktual • Terpercaya • Independen**

Portal berita digital modern berorientasi **Mobile-First ("Mobile Verse")** lengkap dengan halaman pembaca, fitur pencarian, daftar simpan (bookmark offline), multimedia video & foto, serta **Panel Admin CMS Redaksi** yang dibangun dengan **Vue 3 + Tailwind CSS v4** dan backend **Golang** dengan penyimpanan persisten otomatis (`backend/data/mftn-db.json`).

---

## Struktur Proyek

```
Mediafourtribuannews/
├── backend/              # API Server Golang (Chi + JWT + SQLite / MySQL)
│   ├── main.go
│   ├── internal/         # db, models, middleware, handlers
│   ├── seed/             # 63 artikel berita awal siap pakai
│   └── uploads/          # Foto berita & logo
├── frontend/             # Frontend SPA Vue 3 + Vite + Tailwind CSS v4
│   ├── public/images/    # Logo Media Four Tribuan News
│   └── src/              # Layouts, Components, Views Publik & Admin CMS
└── start-portal.bat      # Launcher cepat Windows
```

## Akun Login Admin Default

Buka `/admin/login` lalu masuk menggunakan:
- **Email**: `admin@mediafourtribuannews.id`
- **Password**: `admin123`

Akun redaksi lain (default):
- **Editor**: `redaksi@mediafourtribuannews.id` / `editor123`
- **Reporter**: `reporter@mediafourtribuannews.id` / `editor123`

## Cara Menjalankan

### 1. Mode Produksi (1 Server Golang — Paling Cepat)
Backend Golang secara otomatis melayani API (`/api/*`), folder foto (`/uploads/*`), sekaligus hasil build Vue (`frontend/dist`):

```powershell
cd backend
go run .
```
Lalu buka **http://localhost:8080** di browser (atau klik ganda `start-portal.bat`).

### 2. Mode Pengembangan (Hot Reload Vue + API Golang)
Terminal 1 (Backend Golang — port `8080`):
```powershell
cd backend
go run .
```
Terminal 2 (Frontend Vue Vite — port `5173`):
```powershell
cd frontend
npm.cmd run dev
```
Lalu buka **http://localhost:5173** di browser.

## Beralih ke MySQL XAMPP (Opsional)

Secara default portal berjalan otomatis menggunakan **SQLite** (`backend/data/mftn.db`) tanpa setup tambahan. Jika ingin memakai **MySQL XAMPP**:
1. Buat database `mediafourtribuannews` di phpMyAdmin.
2. Set environment variable sebelum menjalankan backend:
   ```powershell
   $env:DB_DRIVER="mysql"
   $env:DB_DSN="root:@tcp(127.0.0.1:3306)/mediafourtribuannews?parseTime=true&charset=utf8mb4"
   cd backend
   go run .
   ```
   Tabel dan data awal akan dibuat & diisi otomatis!
