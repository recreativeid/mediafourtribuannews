# Media Four Tribuan News — Portal Berita Nasional (Vue 3 + Supabase + Golang)

**Aktual • Terpercaya • Independen**

Portal berita digital modern berorientasi **Mobile-First ("Mobile Verse")** lengkap dengan halaman pembaca, fitur pencarian, daftar simpan (bookmark offline), multimedia video & foto, serta **Panel Admin CMS Redaksi** yang dibangun dengan **Vue 3 + Tailwind CSS v4**, didukung database cloud serverless **Supabase**, penyimpanan persisten cerdas, dan opsi backend **Golang**.

---

## 🌐 Live Portal di GitHub Pages
- **Portal Publik**: [https://recreativeid.github.io/mediafourtribuannews/](https://recreativeid.github.io/mediafourtribuannews/)
- **Login Admin**: [https://recreativeid.github.io/mediafourtribuannews/admin/login](https://recreativeid.github.io/mediafourtribuannews/admin/login)

*(Tombol panel admin sengaja disembunyikan dari halaman publik demi privasi dan keamanan redaksi).*

---

## 🔐 Akun Login Admin Default
Buka `/admin/login` lalu masukkan:
- **Email**: `admin@mediafourtribuannews.id`
- **Kata Sandi**: `admin123`

*(Form login dibuka dalam keadaan bersih/kosong tanpa auto-fill sesuai standar keamanan. Terdapat fitur ganti email & password di menu **Akun Saya**, serta auto-logout setelah 20 menit).*

---

## ⚡ Integrasi Database Cloud Supabase (Serverless)

Portal ini sudah dilengkapi dukungan penuh **Supabase** (`@supabase/supabase-js`) sehingga dapat berjalan 100% serverless di **GitHub Pages** tanpa perlu hosting server Golang terpisah!

### Langkah Mudah Menghubungkan Supabase:
1. Buat proyek baru secara gratis di [https://supabase.com](https://supabase.com).
2. Masuk ke menu **SQL Editor** di dashboard Supabase Anda.
3. Buka file [`supabase_schema.sql`](./supabase_schema.sql) di proyek ini, salin seluruh isinya, lalu klik **Run** di Supabase SQL Editor.
   *(Skrip ini otomatis membuat tabel `articles`, `categories`, `videos`, `comments`, `editorial_team`, `ads`, `settings`, `admin_users`, kebijakan RLS, Storage Bucket `mftn-uploads`, dan mengisikan seluruh 63 berita & kategori awal).*
4. Buka menu **Project Settings -> API** di Supabase, lalu salin:
   - **Project URL** (`https://xxxxxxxx.supabase.co`)
   - **Project API Key (anon / public)** (`eyJhbGci...`)
5. Buka Panel Admin MFTN di menu **Pengaturan Portal** -> bagian **Integrasi Database Supabase**, tempelkan URL & Anon Key, lalu klik **Simpan Kredensial Supabase** dan **Uji Koneksi**!

> **Catatan Offline/Fallback:** Jika Supabase belum dihubungkan, portal otomatis menggunakan penyimpanan lokal peramban (Local Store) dengan 63 berita lengkap bawaan sehingga situs tetap tampil sempurna dan dapat langsung digunakan!

---

## 📁 Struktur Proyek

```
Mediafourtribuannews/
├── index.html            # Entrypoint utama GitHub Pages
├── 404.html              # SPA Router fallback untuk GitHub Pages
├── .nojekyll             # Mencegah Jekyll mengabaikan aset Vite
├── assets/               # Bundled JS & CSS Vue 3
├── images/               # Logo Media Four Tribuan News
├── uploads/              # Foto berita lengkap
├── docs/                 # Salinan mirror untuk opsi deploy GitHub Pages /docs
├── supabase_schema.sql   # Skrip DDL & Seed Supabase lengkap (63 berita)
├── .github/workflows/    # CI/CD otomatis GitHub Actions untuk GitHub Pages
├── backend/              # API Server Golang (Chi + JWT + Data Store)
│   ├── main.go
│   ├── internal/         # db, models, middleware, handlers
│   └── seed/             # 63 artikel berita awal
├── frontend/             # Sumber kode SPA Vue 3 + Tailwind CSS v4
│   ├── src/api/          # client.js & supabase.js
│   ├── src/views/        # Halaman publik & panel admin
│   └── src/router/       # Vue Router dengan BASE_URL support
└── start-portal.bat      # Launcher lokal Windows cepat
```

---

## 💻 Menjalankan Secara Lokal (Opsional)

### Jalankan dengan Golang Backend:
```powershell
cd backend
go run .
```
Buka **http://localhost:8080** di browser.

### Jalankan Mode Hot Reload Frontend:
```powershell
cd frontend
npm.cmd run dev
```
Buka **http://localhost:5173** di browser.
