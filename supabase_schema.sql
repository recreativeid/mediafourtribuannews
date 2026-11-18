-- =====================================================================
-- MEDIA FOUR TRIBUAN NEWS (MFTN) — SUPABASE DATABASE SCHEMA & SEED
-- Portal Berita Digital Nasional (Mobile-First)
-- Dibuat otomatis untuk integrasi Supabase + GitHub Pages
-- =====================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. DROP EXISTING TABLES (OPSIONAL JIKA RESET)
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS articles CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS videos CASCADE;
DROP TABLE IF EXISTS editorial_team CASCADE;
DROP TABLE IF EXISTS ads CASCADE;
DROP TABLE IF EXISTS settings CASCADE;
DROP TABLE IF EXISTS admin_users CASCADE;

-- 3. CREATE TABLES
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    color VARCHAR(20) DEFAULT '#0B2563',
    icon VARCHAR(50) DEFAULT 'newspaper',
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE articles (
    id SERIAL PRIMARY KEY,
    title VARCHAR(300) NOT NULL,
    slug VARCHAR(350) UNIQUE NOT NULL,
    excerpt TEXT,
    content TEXT,
    thumbnail TEXT,
    category_id INT REFERENCES categories(id) ON DELETE SET NULL,
    category_name VARCHAR(100),
    category_slug VARCHAR(100),
    author_name VARCHAR(100) DEFAULT 'Redaksi MFTN',
    author_role VARCHAR(100) DEFAULT 'Redaksi',
    status VARCHAR(20) DEFAULT 'published',
    is_headline BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    is_popular BOOLEAN DEFAULT FALSE,
    is_breaking BOOLEAN DEFAULT FALSE,
    views INT DEFAULT 0,
    read_time VARCHAR(20) DEFAULT '3 mnt',
    tags JSONB DEFAULT '[]'::jsonb,
    published_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE videos (
    id SERIAL PRIMARY KEY,
    title VARCHAR(300) NOT NULL,
    slug VARCHAR(350),
    youtube_id VARCHAR(50) NOT NULL,
    duration VARCHAR(20),
    thumbnail TEXT,
    category_name VARCHAR(100),
    views INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    article_id INT,
    article_slug VARCHAR(350),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150),
    content TEXT NOT NULL,
    is_approved BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE editorial_team (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(100) NOT NULL,
    bio TEXT,
    avatar TEXT,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE ads (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    position VARCHAR(50) NOT NULL,
    type VARCHAR(50) DEFAULT 'banner',
    image_url TEXT,
    target_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE settings (
    key VARCHAR(100) PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE admin_users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    role VARCHAR(50) DEFAULT 'Administrator',
    status VARCHAR(20) DEFAULT 'active',
    avatar TEXT,
    bio TEXT,
    password_hash TEXT NOT NULL,
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE editorial_team ENABLE ROW LEVEL SECURITY;
ALTER TABLE ads ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Allow Public Read for All Public Facing Tables
CREATE POLICY "Public Read Categories" ON categories FOR SELECT USING (true);
CREATE POLICY "Public Read Articles" ON articles FOR SELECT USING (true);
CREATE POLICY "Public Read Videos" ON videos FOR SELECT USING (true);
CREATE POLICY "Public Read Comments" ON comments FOR SELECT USING (is_approved = true);
CREATE POLICY "Public Read Editorial" ON editorial_team FOR SELECT USING (true);
CREATE POLICY "Public Read Ads" ON ads FOR SELECT USING (true);
CREATE POLICY "Public Read Settings" ON settings FOR SELECT USING (true);

-- Allow Public Write for Comments
CREATE POLICY "Public Insert Comments" ON comments FOR INSERT WITH CHECK (true);

-- Allow All Operations for Anon & Authenticated on Articles, Categories, etc. (untuk CMS Admin Serverless)
CREATE POLICY "Admin Full Access Categories" ON categories FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Admin Full Access Articles" ON articles FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Admin Full Access Videos" ON videos FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Admin Full Access Comments" ON comments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Admin Full Access Editorial" ON editorial_team FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Admin Full Access Ads" ON ads FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Admin Full Access Settings" ON settings FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Admin Full Access Users" ON admin_users FOR ALL USING (true) WITH CHECK (true);

-- 5. STORAGE BUCKET FOR UPLOADS
INSERT INTO storage.buckets (id, name, public) 
VALUES ('mftn-uploads', 'mftn-uploads', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public Read Uploads" ON storage.objects FOR SELECT USING (bucket_id = 'mftn-uploads');
CREATE POLICY "Public Insert Uploads" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'mftn-uploads');
CREATE POLICY "Public Update Uploads" ON storage.objects FOR UPDATE USING (bucket_id = 'mftn-uploads');

-- 6. SEED DATA INSERTION

-- Inisialisasi Settings
INSERT INTO settings (key, value) VALUES ('company_name', 'PT Media Four Tribuan Nusantara') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO settings (key, value) VALUES ('facebook_url', 'https://facebook.com') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO settings (key, value) VALUES ('hotline_phone', '0812-3456-7890') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO settings (key, value) VALUES ('instagram_url', 'https://instagram.com') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO settings (key, value) VALUES ('office_address', 'Gedung Graha Tribuan Pers Lt. 3, Jl. Merdeka Nasional No. 44, Jakarta Pusat, Indonesia') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO settings (key, value) VALUES ('redaksi_email', 'redaksi@mediafourtribuannews.id') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO settings (key, value) VALUES ('site_description', 'Portal Berita Nasional Media Four Tribuan News menyajikan kabar aktual, terpercaya, dan independen seputar nasional, daerah, politik, hukum, ekonomi, olahraga, dan teknologi.') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO settings (key, value) VALUES ('site_subtitle', 'NASIONAL') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO settings (key, value) VALUES ('site_tagline', 'Aktual • Terpercaya • Independen') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO settings (key, value) VALUES ('site_title', 'Media Four Tribuan News') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO settings (key, value) VALUES ('twitter_url', 'https://x.com') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO settings (key, value) VALUES ('whatsapp_number', '6281234567890') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO settings (key, value) VALUES ('youtube_url', 'https://youtube.com') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- Inisialisasi Admin Users
INSERT INTO admin_users (id, name, email, role, status, avatar, bio, password_hash)
VALUES (1, 'Admin Redaksi', 'admin@mediafourtribuannews.id', 'Administrator', 'active', '/uploads/logo/logo-mftn.jpg', 'Administrator & Penanggung Jawab Portal Media Four Tribuan News Nasional.', '$2a$10$kJqkYCiaXyAAiWtP29PlM.AYAv2WpzFZHK.3yPIX2SduQvKspFELS')
ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email, password_hash = EXCLUDED.password_hash;
INSERT INTO admin_users (id, name, email, role, status, avatar, bio, password_hash)
VALUES (2, 'Rama Pratama', 'redaksi@mediafourtribuannews.id', 'Editor', 'active', '/uploads/logo/logo-mftn.jpg', 'Redaktur Pelaksana Nasional Media Four Tribuan News.', '$2a$10$rcSguJbMAuh0T8e.1AdrEuSXtkO2zt4vAwitwuRFf2jYWsuamTiy6')
ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email, password_hash = EXCLUDED.password_hash;
INSERT INTO admin_users (id, name, email, role, status, avatar, bio, password_hash)
VALUES (3, 'Siti Rahmawati', 'reporter@mediafourtribuannews.id', 'Reporter', 'active', '/uploads/logo/logo-mftn.jpg', 'Koresponden Lapangan Nasional & Daerah.', '$2a$10$rcSguJbMAuh0T8e.1AdrEuSXtkO2zt4vAwitwuRFf2jYWsuamTiy6')
ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email, password_hash = EXCLUDED.password_hash;

-- Inisialisasi Kategori Berita
INSERT INTO categories (id, name, slug, description, color, icon, sort_order)
VALUES (1, 'Nasional', 'nasional', 'Berita peristiwa nasional, pemerintahan, kebijakan publik, dan kenegaraan', NULL, NULL, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO categories (id, name, slug, description, color, icon, sort_order)
VALUES (2, 'Daerah', 'daerah', 'Kabar kedaerahan, otonomi daerah, dan laporan biro wilayah nusantara', NULL, NULL, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO categories (id, name, slug, description, color, icon, sort_order)
VALUES (3, 'Politik', 'politik', 'Dinamika parlemen, demokrasi, pemilu, dan kebijakan strategis', NULL, NULL, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO categories (id, name, slug, description, color, icon, sort_order)
VALUES (4, 'Hukum', 'hukum', 'Liputan penegakan hukum, kepolisian, peradilan, dan keamanan masyarakat', NULL, NULL, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO categories (id, name, slug, description, color, icon, sort_order)
VALUES (5, 'Ekonomi', 'ekonomi', 'Makroekonomi, fiskal, inflasi, komoditas, dan perbankan', NULL, NULL, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO categories (id, name, slug, description, color, icon, sort_order)
VALUES (6, 'Bisnis', 'bisnis', 'Pergerakan pasar, korporasi, UMKM, dan investasi', NULL, NULL, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO categories (id, name, slug, description, color, icon, sort_order)
VALUES (7, 'Pendidikan', 'pendidikan', 'Dunia kampus, sekolah, beasiswa, dan inovasi kurikulum', NULL, NULL, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO categories (id, name, slug, description, color, icon, sort_order)
VALUES (8, 'Teknologi', 'teknologi', 'Transformasi digital, sains terapan, AI, dan telekomunikasi', NULL, NULL, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO categories (id, name, slug, description, color, icon, sort_order)
VALUES (9, 'Olahraga', 'olahraga', 'Kompetisi olahraga nasional, sepak bola, dan prestasi atlet', NULL, NULL, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO categories (id, name, slug, description, color, icon, sort_order)
VALUES (10, 'Internasional', 'internasional', 'Diplomasi dunia, geopolitik global, dan kabar mancanegara', NULL, NULL, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO categories (id, name, slug, description, color, icon, sort_order)
VALUES (11, 'Opini', 'opini', 'Kolom gagasan, analisis kritis akademisi, dan ruang pandang publik', NULL, NULL, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO categories (id, name, slug, description, color, icon, sort_order)
VALUES (12, 'Editorial', 'editorial', 'Tajuk rencana dan sikap resmi dewan redaksi Media Four Tribuan News', NULL, NULL, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO categories (id, name, slug, description, color, icon, sort_order)
VALUES (13, 'Foto', 'foto', 'Galeri visual jurnalistik lensa peristiwa terkini', NULL, NULL, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO categories (id, name, slug, description, color, icon, sort_order)
VALUES (14, 'Video', 'video', 'Kanal tayangan liputan multimedia Media Four Tribuan News', NULL, NULL, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO categories (id, name, slug, description, color, icon, sort_order)
VALUES (15, 'Tokoh', 'tokoh', 'Profil figur inspiratif, pemimpin publik, dan cendekiawan', NULL, NULL, 0)
ON CONFLICT (id) DO NOTHING;

-- Inisialisasi 63 Berita Awal
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    1,
    'Kebijakan Anggaran Besar Tak Berbanding dengan Dampak',
    'kebijakan-anggaran-besar-tak-berbanding-dengan-dampak',
    'Sudah saatnya pemerintah dan seluruh pemangku kepentingan memiliki ukuran mekanisme pengelolaan anggaran, agar setiap rupiah benar-benar memberi manfaat nyata bagi masyarakat.',
    '<p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">Sudah saatnya pemerintah dan seluruh pemangku kepentingan memiliki ukuran mekanisme pengelolaan anggaran yang terukur dan akuntabel, agar setiap rupiah dana publik benar-benar memberi manfaat nyata bagi masyarakat luas.</p><p class="mb-4 text-gray-700 leading-relaxed">Transparansi alokasi belanja modal dan efisiensi birokrasi harus menjadi prioritas mutlak demi keberlanjutan pemulihan ekonomi daerah.</p>',
    '/uploads/berita/pendidikan/kurikulum-merdeka-smk.jpg',
    12,
    'Editorial',
    'editorial',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    TRUE,
    FALSE,
    FALSE,
    25400,
    '4 menit baca',
    'Editorial, Tajuk Rencana, Media Four Tribuan News',
    '2026-11-18T18:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    2,
    'Pemerintah Percepat Pembangunan Infrastruktur Strategis Penghubung Pusat Pertumbuhan Ekonomi Baru',
    'pemerintah-percepat-pembangunan-infrastruktur-strategis-penghubung-pusat-pertumbuhan-ekonomi-baru',
    'NUSANTARA — Kementerian Pekerjaan Umum melaporkan kemajuan signifikan dalam penyelesaian jaringan jalan tol lingkar dan fasilitas konektivitas logistik pendukung Ibu Kota Nusantara (IKN) dan kawasan p...',
    '
      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>NUSANTARA</strong> — Kementerian Pekerjaan Umum melaporkan kemajuan signifikan dalam penyelesaian jaringan jalan tol lingkar dan fasilitas konektivitas logistik pendukung Ibu Kota Nusantara (IKN) dan kawasan penyangga sekitarnya.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Presiden menekankan bahwa percepatan pembangunan infrastruktur nasional ini diarahkan untuk memeratakan kue pembangunan ekonomi luar Pulau Jawa dan menciptakan efisiensi rantai distribusi nasional.
      </p>',
    '/uploads/berita/nasional/pembangunan-ikn-nusantara.jpg',
    1,
    'Nasional',
    'nasional',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    TRUE,
    FALSE,
    FALSE,
    2340,
    '3 menit baca',
    'Nasional, Media Four Tribuan News, Terkini',
    '2026-11-18T15:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    3,
    '[VIDEO] Dokumentasi Sains Kampus: Inovasi Olahan Kulit Manggis Jadi Penjernih Air Gambut',
    'video-dokumentasi-sains-kampus-inovasi-olahan-kulit-manggis-jadi-penjernih-air-gambut',
    'BANDA ACEH — Kanal video sains dan teknologi Media Four Tribuan News menayangkan secara mendalam proses riset terapan mahasiswa dalam menyulap limbah organik kulit manggis menjadi karbon aktif penyerap logam ber...',
    '
      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>BANDA ACEH</strong> — Kanal video sains dan teknologi Media Four Tribuan News menayangkan secara mendalam proses riset terapan mahasiswa dalam menyulap limbah organik kulit manggis menjadi karbon aktif penyerap logam berat dan kekeruhan air gambut.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Melalui uji laboratorium bertahap, prototipe reaktor filtrasi sederhana ini terbukti mampu mengalirkan air jernih dengan standar baku mutu kesehatan untuk komunitas perdesaan di lahan basah.
      </p>
      <div class="my-6 p-4 rounded-2xl bg-slate-900 text-white flex flex-col items-center justify-center text-center space-y-3">
        <div class="w-16 h-16 rounded-full bg-mftn-red flex items-center justify-center shadow-lg animate-pulse cursor-pointer">
          <svg class="w-8 h-8 text-white ml-1" fill="currentColor" viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>
        </div>
        <p class="text-sm font-semibold">Tonton Dokumenter Riset Sains Terapan</p>
        <span class="text-xs text-slate-400">Durasi: 08:15 WIB &bull; Resolusi HD 1080p</span>
      </div>',
    '/uploads/berita/teknologi/peluncuran-satelit-indonesia.jpg',
    14,
    'Video',
    'video',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    TRUE,
    FALSE,
    FALSE,
    1980,
    '3 menit baca',
    'Video, Media Four Tribuan News, Terkini',
    '2026-11-18T12:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    4,
    'Ekspansi Jaringan Satelit Komunikasi Buka Konektivitas Internet Sekolah di Wilayah Pelosok 3T',
    'ekspansi-jaringan-satelit-komunikasi-buka-konektivitas-internet-sekolah-di-wilayah-pelosok-3t',
    'JAKARTA — Pengoperasian penuh satelit komunikasi kapasitas tinggi buatan nasional kini telah menghubungkan ribuan titik layanan fasilitas pendidikan dan puskesmas di wilayah terdepan, terluar, dan ter...',
    '
      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>JAKARTA</strong> — Pengoperasian penuh satelit komunikasi kapasitas tinggi buatan nasional kini telah menghubungkan ribuan titik layanan fasilitas pendidikan dan puskesmas di wilayah terdepan, terluar, dan tertinggal (3T) dengan jaringan pita lebar berkecepatan tinggi.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Pemerataan akses konektivitas digital ini memungkinkan para guru dan siswa di pedalaman memanfaatkan materi pembelajaran berbasis cloud dan mengikuti asesmen nasional secara mandiri tanpa kendala sinyal.
      </p>',
    '/uploads/berita/teknologi/peluncuran-satelit-komunikasi.jpg',
    8,
    'Teknologi',
    'teknologi',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    TRUE,
    FALSE,
    FALSE,
    1670,
    '3 menit baca',
    'Teknologi, Media Four Tribuan News, Terkini',
    '2026-11-18T09:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    5,
    'Ganda Putra Indonesia Tembus Partai Puncak Final Kejuaraan Bulutangkis Dunia BWF',
    'ganda-putra-indonesia-tembus-partai-puncak-final-kejuaraan-bulutangkis-dunia-bwf',
    'JAKARTA — Pasangan bulutangkis ganda putra Indonesia berhasil memastikan satu tiket di partai final kejuaraan bergengsi BWF World Tour setelah menaklukkan rival tangguh asal Asia Timur lewat duel dram...',
    '
      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>JAKARTA</strong> — Pasangan bulutangkis ganda putra Indonesia berhasil memastikan satu tiket di partai final kejuaraan bergengsi BWF World Tour setelah menaklukkan rival tangguh asal Asia Timur lewat duel dramatis rubber game berdurasi 78 menit.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Permainan agresif di depan net dan smes tajam yang variatif menjadi kunci kemenangan wakil Merah Putih di gim penentuan. Kemenangan ini memperpanjang tren positif skuad bulutangkis nasional di panggung internasional musim 2026.
      </p>
      <blockquote class="my-6 p-4 border-l-4 border-mftn-red bg-red-50 italic text-gray-800 font-serif text-lg">
        "Kemenangan ini kami persembahkan untuk seluruh pecinta bulutangkis di Tanah Air yang tak henti memberikan doa dan dukungan semangat dari tribun maupun layar kaca," ucap atlet usai laga semifinal.
      </blockquote>',
    '/uploads/berita/olahraga/final-bulutangkis-dunia.jpg',
    9,
    'Olahraga',
    'olahraga',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    TRUE,
    FALSE,
    FALSE,
    2410,
    '3 menit baca',
    'Olahraga, Media Four Tribuan News, Terkini',
    '2026-11-18T06:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    6,
    'Nilai Ekspor Komoditas Perkebunan dan Kelautan Melonjak, Sumbang Devisa Positif di Pesisir Barat',
    'nilai-ekspor-komoditas-perkebunan-dan-kelautan-melonjak-sumbang-devisa-positif-di-pesisir-barat',
    'MEULABOH — Badan Pusat Statistik (BPS) merilis data kinerja neraca perdagangan yang mencatat lonjakan signifikan volume ekspor produk kelapa sawit, biji kopi Gayo, serta komoditas perikanan tangkap da...',
    '
      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>MEULABOH</strong> — Badan Pusat Statistik (BPS) merilis data kinerja neraca perdagangan yang mencatat lonjakan signifikan volume ekspor produk kelapa sawit, biji kopi Gayo, serta komoditas perikanan tangkap dari pelabuhan regional menuju pasar Asia dan Timur Tengah.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Peningkatan nilai ekspor ini berdampak langsung terhadap perbaikan Nilai Tukar Petani (NTP) dan terbukanya peluang investasi hilirisasi industri pengolahan di kawasan pesisir nusantara.
      </p>',
    '/uploads/berita/ekonomi/ekspor-komoditas-sawit.jpg',
    5,
    'Ekonomi',
    'ekonomi',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1540,
    '3 menit baca',
    'Ekonomi, Media Four Tribuan News, Terkini',
    '2026-11-18T03:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    7,
    'Konsolidasi Lintas Fraksi Partai Sepakati Agenda Prioritas Pengentasan Kemiskinan Ekstrem',
    'konsolidasi-lintas-fraksi-partai-sepakati-agenda-prioritas-pengentasan-kemiskinan-ekstrem',
    'BANDA ACEH — Pimpinan fraksi-fraksi partai politik di parlemen daerah menyepakati nota kesepahaman agenda legislasi prioritas yang menitikberatkan pada percepatan intervensi kemiskinan ekstrem dan pem...',
    '
      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>BANDA ACEH</strong> — Pimpinan fraksi-fraksi partai politik di parlemen daerah menyepakati nota kesepahaman agenda legislasi prioritas yang menitikberatkan pada percepatan intervensi kemiskinan ekstrem dan pembukaan lapangan kerja produktif.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Kesepakatan bersama ini menjadi sinyal positif stabilitas politik lokal menjelang penyusunan rencana kerja pemerintah daerah tahun anggaran berikutnya, di mana harmonisasi antara eksekutif dan legislatif menjadi prasyarat percepatan realisasi program.
      </p>',
    '/uploads/berita/politik/koalisi-partai-politik.jpg',
    3,
    'Politik',
    'politik',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    980,
    '3 menit baca',
    'Politik, Media Four Tribuan News, Terkini',
    '2026-11-18T00:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    8,
    'Patroli Siber Polda Deteksi Modus Penipuan Online Baru Jelang Ramadhan, Masyarakat Diimbau Waspada',
    'patroli-siber-polda-deteksi-modus-penipuan-online-baru-jelang-ramadhan-masyarakat-diimbau-waspada',
    'BANDA ACEH — Unit Cyber Crime Ditreskrimsus Polda mengimbau masyarakat untuk meningkatkan kewaspadaan terhadap modus baru penipuan digital bermotif link undangan elektronik dan paket belanja online ya...',
    '
      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>BANDA ACEH</strong> — Unit Cyber Crime Ditreskrimsus Polda mengimbau masyarakat untuk meningkatkan kewaspadaan terhadap modus baru penipuan digital bermotif link undangan elektronik dan paket belanja online yang disisipi malware pencuri data rekening.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Berdasarkan pemantauan patroli siber, sindikat pelaku kerap menyebarkan berkas instalasi (.apk) melalui pesan singkat instan yang meminta korban mengunduh file untuk verifikasi transaksi palsu.
      </p>
      <blockquote class="my-6 p-4 border-l-4 border-mftn-red bg-red-50 italic text-gray-800 font-serif text-lg">
        "Jangan pernah menekan tautan atau memasang aplikasi dari sumber yang tidak resmi. Pastikan selalu memverifikasi informasi perbankan ke kanal aduan resmi kepolisian," imbuh pimpinan patroli siber.
      </blockquote>',
    '/uploads/berita/kriminal/razia-cyber-crime.jpg',
    4,
    'Hukum',
    'hukum',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    960,
    '3 menit baca',
    'Hukum, Media Four Tribuan News, Terkini',
    '2026-11-17T21:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    9,
    'Kiprah Ulama Kharismatik Pesisir Barat: Menjaga Kesejukan Dakwah dan Moderasi Umat di Era Digital',
    'kiprah-ulama-kharismatik-pesisir-barat-menjaga-kesejukan-dakwah-dan-moderasi-umat-di-era-digital',
    'BANDA ACEH — Menghadapi derasnya arus informasi dan polarisasi media sosial di era modern, keteladanan para pimpinan dayah dan ulama kharismatik terus menjadi oase penyejuk yang menjaga kerukunan dan ...',
    '
      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>BANDA ACEH</strong> — Menghadapi derasnya arus informasi dan polarisasi media sosial di era modern, keteladanan para pimpinan dayah dan ulama kharismatik terus menjadi oase penyejuk yang menjaga kerukunan dan persatuan umat.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Kiprah pembinaan moral para santri yang dipadukan dengan wawasan kebangsaan serta kemandirian ekonomi agrobisnis di lingkungan pesantren membuktikan bahwa tradisi keilmuan klasik mampu bertransformasi menjawab tantangan zaman tanpa kehilangan akar identitas religiusnya.
      </p>
      <blockquote class="my-6 p-4 border-l-4 border-mftn-red bg-red-50 italic text-gray-800 font-serif text-lg">
        "Nasihat yang tulus dan keteladanan budi pekerti luhur selalu lebih berbobot daripada ribuan bantahan lisan di ruang publik. Jaga persaudaraan dan rawat kedamaian negeri," pesan ulama kharismatik dalam tausiyah kebangsaan.
      </blockquote>',
    '/uploads/berita/nasional/konferensi-pers-istana.jpg',
    15,
    'Tokoh',
    'tokoh',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1620,
    '3 menit baca',
    'Tokoh, Media Four Tribuan News, Terkini',
    '2026-11-17T18:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    10,
    'KTT Diplomasi Global Sepakati Resolusi Perlindungan Korban Sipil dan Koridor Kemanusiaan',
    'ktt-diplomasi-global-sepakati-resolusi-perlindungan-korban-sipil-dan-koridor-kemanusiaan',
    'JENEWA — Pertemuan tingkat tinggi para pemimpin diplomasi internasional di Markas PBB menghasilkan kesepakatan resolusi darurat mengenai perlindungan tanpa syarat bagi warga sipil dan fasilitas medis ...',
    '
      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>JENEWA</strong> — Pertemuan tingkat tinggi para pemimpin diplomasi internasional di Markas PBB menghasilkan kesepakatan resolusi darurat mengenai perlindungan tanpa syarat bagi warga sipil dan fasilitas medis di wilayah konflik bersenjata global.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Delegasi Indonesia menyerukan pentingnya penegakan hukum humaniter internasional serta pembukaan akses bantuan logistik pangan dan obat-obatan secara berkelanjutan bagi jutaan pengungsi yang terdampak krisis kemanusiaan.
      </p>',
    '/uploads/berita/internasional/diplomasi-ktt-global.jpg',
    10,
    'Internasional',
    'internasional',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    2050,
    '3 menit baca',
    'Internasional, Media Four Tribuan News, Terkini',
    '2026-11-17T15:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    11,
    '[VIDEO] Liputan Khusus: Apel Kesiapsiagaan Satgas Linmas dan Pengamanan Terpadu Gampong',
    'video-liputan-khusus-apel-kesiapsiagaan-satgas-linmas-dan-pengamanan-terpadu-gampong',
    'MEULABOH — Redaksi Multimedia Media Four Tribuan News menyajikan rangkuman liputan video eksklusif perihal apel siaga gelar pasukan Satuan Perlindungan Masyarakat (Satlinmas) dan relawan Pageu Gampong di halaman...',
    '
      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>MEULABOH</strong> — Redaksi Multimedia Media Four Tribuan News menyajikan rangkuman liputan video eksklusif perihal apel siaga gelar pasukan Satuan Perlindungan Masyarakat (Satlinmas) dan relawan Pageu Gampong di halaman Setdakab Aceh Barat.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Simak dokumentasi kesiapan personel, simulasi evakuasi tanggap darurat bencana, serta instruksi langsung jajaran pimpinan daerah dalam memperkokoh ketenteraman lingkungan warga.
      </p>
      <div class="my-6 p-4 rounded-2xl bg-slate-900 text-white flex flex-col items-center justify-center text-center space-y-3">
        <div class="w-16 h-16 rounded-full bg-mftn-red flex items-center justify-center shadow-lg animate-pulse cursor-pointer">
          <svg class="w-8 h-8 text-white ml-1" fill="currentColor" viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>
        </div>
        <p class="text-sm font-semibold">Tonton Tayangan Video Eksklusif (Kanal YouTube Resmi Media Four Tribuan News)</p>
        <span class="text-xs text-slate-400">Durasi: 05:42 WIB &bull; Resolusi HD 1080p</span>
      </div>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Sinergi aparat keamanan dan aparatur gampong merupakan pilar utama kenyamanan investasi dan stabilitas sosial masyarakat pesisir barat selatan Aceh.
      </p>',
    '/uploads/berita/daerah/festival-budaya-palembang.jpg',
    14,
    'Video',
    'video',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    2890,
    '3 menit baca',
    'Video, Media Four Tribuan News, Terkini',
    '2026-11-17T12:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    12,
    'Kontingen Atlet Daerah Matangkan Pemusatan Latihan Menuju Pekan Olahraga Nasional',
    'kontingen-atlet-daerah-matangkan-pemusatan-latihan-menuju-pekan-olahraga-nasional',
    'BANDA ACEH — Komite Olahraga Nasional Indonesia (KONI) bersama dinas pemuda dan olahraga terus menggenjot pemusatan latihan daerah (Pelatda) bagi ratusan atlet dari berbagai cabang olahraga unggulan m...',
    '
      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>BANDA ACEH</strong> — Komite Olahraga Nasional Indonesia (KONI) bersama dinas pemuda dan olahraga terus menggenjot pemusatan latihan daerah (Pelatda) bagi ratusan atlet dari berbagai cabang olahraga unggulan menyongsong ajang bergengsi Pekan Olahraga Nasional (PON).
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Sejumlah cabang olahraga prioritas seperti atletik, bela diri, panahan, dan dayung menunjukkan peningkatan performa signifikan berkat penerapan teknologi sport science modern serta dukungan nutrisi terpadu di bawah bimbingan pelatih berlisensi internasional.
      </p>
      <blockquote class="my-6 p-4 border-l-4 border-mftn-red bg-red-50 italic text-gray-800 font-serif text-lg">
        "Disiplin, mentalitas juara, dan sportivitas tinggi adalah kunci utama meraih podium emas. Kami optimistis para atlet mampu mengukir sejarah prestasi terbaik," terang perwakilan KONI.
      </blockquote>
      <h3 class="text-xl font-bold text-black mt-6 mb-3">Uji Tanding dan Kebugaran Atlet</h3>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Selama bulan ini, rangkaian uji tanding internal dan simulasi pertandingan dengan protokol kompetisi resmi digelar untuk mengasah ketahanan fisik dan kematangan taktik atlet di arena.
      </p>',
    '/uploads/berita/olahraga/pekan-olahraga-nasional.jpg',
    9,
    'Olahraga',
    'olahraga',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1750,
    '3 menit baca',
    'Olahraga, Media Four Tribuan News, Terkini',
    '2026-11-17T09:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    13,
    'Pusat Keamanan Siber Wilayah Diperkuat Guna Lindungi Data Layanan Publik Terpadu',
    'pusat-keamanan-siber-wilayah-diperkuat-guna-lindungi-data-layanan-publik-terpadu',
    'JAKARTA — Kementerian Komunikasi dan Digital bersama Badan Siber dan Sandi Negara (BSSN) meresmikan Computer Security Incident Response Team (CSIRT) regional untuk memproteksi infrastruktur server dan...',
    '
      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>JAKARTA</strong> — Kementerian Komunikasi dan Digital bersama Badan Siber dan Sandi Negara (BSSN) meresmikan Computer Security Incident Response Team (CSIRT) regional untuk memproteksi infrastruktur server dan basis data administrasi kependudukan daerah dari serangan peretasan.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Penerapan arsitektur Zero Trust Security dan pemantauan ancaman secara otomatis 24 jam nonstop diharapkan menjamin keamanan transaksi layanan digital publik di era kecerdasan buatan.
      </p>',
    '/uploads/berita/teknologi/pusat-keamanan-siber.jpg',
    8,
    'Teknologi',
    'teknologi',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1430,
    '3 menit baca',
    'Teknologi, Media Four Tribuan News, Terkini',
    '2026-11-17T06:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    14,
    'Polda Berhasil Bongkar Jaringan Sindikat Narkotika Lintas Provinsi, Puluhan Kilogram Barang Bukti Diamankan',
    'polda-berhasil-bongkar-jaringan-sindikat-narkotika-lintas-provinsi-puluhan-kilogram-barang-bukti-diamankan',
    'BANDA ACEH — Tim gabungan Ditresnarkoba Polda berhasil menggagalkan upaya penyelundupan narkotika jaringan lintas provinsi setelah melakukan pengintaian intensif di jalur pesisir timur dan perbatasan ...',
    '
      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>BANDA ACEH</strong> — Tim gabungan Ditresnarkoba Polda berhasil menggagalkan upaya penyelundupan narkotika jaringan lintas provinsi setelah melakukan pengintaian intensif di jalur pesisir timur dan perbatasan wilayah.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Dalam operasi penindakan terukur tersebut, aparat mengamankan puluhan kilogram barang bukti kemasan teh cina dan membekuk tiga orang tersangka yang berperan sebagai kurir sekaligus pengendali lapangan. Kapolda mengapresiasi partisipasi proaktif masyarakat yang memberikan informasi awal pergerakan mencurigakan di area pelabuhan tikus.
      </p>
      <blockquote class="my-6 p-4 border-l-4 border-mftn-red bg-red-50 italic text-gray-800 font-serif text-lg">
        "Polri tidak akan memberikan ruang sedikit pun bagi pelaku kejahatan narkotika yang merusak masa depan generasi bangsa. Kami terus perketat pengawasan jalur darat, laut, dan udara," tegas perwira humas dalam konferensi pers.
      </blockquote>
      <h3 class="text-xl font-bold text-black mt-6 mb-3">Ancaman Hukuman Maksimal</h3>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Para tersangka kini ditahan di sel Mapolda guna penyidikan mendalam dan dijerat Pasal 114 ayat (2) Jo Pasal 112 ayat (2) UU Narkotika Nomor 35 Tahun 2009 dengan ancaman pidana mati atau penjara seumur hidup.
      </p>',
    '/uploads/berita/kriminal/penangkapan-sindikat-narkoba.jpg',
    4,
    'Hukum',
    'hukum',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1890,
    '3 menit baca',
    'Hukum, Media Four Tribuan News, Terkini',
    '2026-11-17T03:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    15,
    'Bank Indonesia Catat Inflasi Daerah Terkendali Berkat Kelancaran Rantai Pasok Komoditas Pangan',
    'bank-indonesia-catat-inflasi-daerah-terkendali-berkat-kelancaran-rantai-pasok-komoditas-pangan',
    'BANDA ACEH — Kantor Perwakilan Bank Indonesia melaporkan laju inflasi indeks harga konsumen (IHK) di tingkat provinsi dan kabupaten tetap berada dalam sasaran target 2,5 ± 1 persen berkat konsistensi ...',
    '
      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>BANDA ACEH</strong> — Kantor Perwakilan Bank Indonesia melaporkan laju inflasi indeks harga konsumen (IHK) di tingkat provinsi dan kabupaten tetap berada dalam sasaran target 2,5 ± 1 persen berkat konsistensi operasi pasar terpadu Tim Pengendalian Inflasi Daerah (TPID).
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Kelancaran pasokan komoditas strategis seperti beras, cabai merah, dan minyak goreng di pasar tradisional berhasil meredam potensi gejolak harga pangan menjelang periode hari besar keagamaan nasional.
      </p>',
    '/uploads/berita/ekonomi/inflasi-bank-indonesia.jpg',
    5,
    'Ekonomi',
    'ekonomi',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1280,
    '3 menit baca',
    'Ekonomi, Media Four Tribuan News, Terkini',
    '2026-11-17T00:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    16,
    'Bupati Tarmizi Tegaskan Satlinmas dan Pageu Gampong Ujung Tombak Keamanan Masyarakat',
    'bupati-tarmizi-tegaskan-satlinmas-dan-pageu-gampong-ujung-tombak-keamanan-masyarakat',
    'MEULABOH — Bupati Aceh Barat Tarmizi SP menegaskan bahwa Satuan Perlindungan Masyarakat (Satlinmas) dan relawan Satgas Pageu Gampong memegang peranan krusial sebagai ujung tombak pemeliharaan keamanan...',
    '      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>MEULABOH</strong> — Bupati Aceh Barat Tarmizi SP menegaskan bahwa Satuan Perlindungan Masyarakat (Satlinmas) dan relawan Satgas Pageu Gampong memegang peranan krusial sebagai ujung tombak pemeliharaan keamanan, ketenteraman, dan kenyamanan warga di tingkat akar rumput gampong.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Pernyataan tersebut ditekankan Bupati Tarmizi saat memimpin langsung apel siaga gelar pasukan di halaman Setdakab Aceh Barat yang dihadiri ratusan personel Linmas, keuchik, tuha peut, serta jajaran Forkopimda. Sinergi antara kearifan lokal ''Pageu Gampong'' dan sistem perlindungan sipil terbukti menjadi benteng paling efektif dalam meredam potensi konflik sosial dan bencana lingkungan.
      </p>
      <blockquote class="my-6 p-4 border-l-4 border-mftn-red bg-red-50 italic text-gray-800 font-serif text-lg">
        "Keamanan gampong adalah pondasi utama pembangunan daerah. Jika gampong aman, tenteram, dan kompak, roda ekonomi warga pasti bergerak cepat dan barokah," tegas Al Bahri mengutip arahan Bupati Tarmizi.
      </blockquote>
      <h3 class="text-xl font-bold text-black mt-6 mb-3">Penguatan Fasilitas dan Pembinaan Berkelanjutan</h3>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Pemerintah Kabupaten berkomitmen mengalokasikan dukungan sarana penunjang operasional serta pelatihan kebencanaan terpadu bersama BPBD dan TNI-Polri. Langkah ini diapresiasi oleh seluruh aparatur gampong demi menyukseskan iklim investasi dan pariwisata yang damai di pesisir barat selatan Aceh.
      </p>',
    '/uploads/berita/daerah/festival-budaya-palembang.jpg',
    2,
    'Daerah',
    'daerah',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    42800,
    '3 menit baca',
    'Daerah, Media Four Tribuan News, Terkini',
    '2026-11-16T21:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    17,
    'DPRK Bahas Rancangan Regulasi Penguatan Transparansi Anggaran Pembangunan Daerah',
    'dprk-bahas-rancangan-regulasi-penguatan-transparansi-anggaran-pembangunan-daerah',
    'MEULABOH — Dewan Perwakilan Rakyat Kabupaten (DPRK) menggelar sidang paripurna masa sidang II dalam rangka pembahasan rancangan qanun/peraturan daerah mengenai penguatan transparansi dan akuntabilitas...',
    '
      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>MEULABOH</strong> — Dewan Perwakilan Rakyat Kabupaten (DPRK) menggelar sidang paripurna masa sidang II dalam rangka pembahasan rancangan qanun/peraturan daerah mengenai penguatan transparansi dan akuntabilitas sistem perencanaan penganggaran daerah.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Seluruh fraksi di parlemen menyepakati bahwa keterbukaan informasi alokasi belanja modal dan bantuan sosial gampong harus dapat diakses secara mudah oleh publik melalui platform portal satu data daerah terintegrasi.
      </p>
      <blockquote class="my-6 p-4 border-l-4 border-mftn-red bg-red-50 italic text-gray-800 font-serif text-lg">
        "Legislatif berkewajiban mengawal setiap rupiah dana rakyat agar tepat sasaran menjawab prioritas infrastruktur dasar dan pelayanan kesehatan," tutur pimpinan sidang.
      </blockquote>',
    '/uploads/berita/politik/sidang-paripurna-dpr.jpg',
    3,
    'Politik',
    'politik',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1120,
    '3 menit baca',
    'Politik, Media Four Tribuan News, Terkini',
    '2026-11-16T18:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    18,
    'Kapolri Mutasi 424 Pati dan Pamen Polri, Sejumlah Jabatan Strategis Berganti',
    'kapolri-mutasi-424-pati-dan-pamen-polri-sejumlah-jabatan-strategis-berganti',
    'JAKARTA — Kapolri Jenderal Polisi Listyo Sigit Prabowo resmi mengeluarkan surat telegram mutasi terhadap 424 perwira tinggi (Pati) dan perwira menengah (Pamen). Langkah strategis ini ditempuh dalam ra...',
    '      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>JAKARTA</strong> — Kapolri Jenderal Polisi Listyo Sigit Prabowo resmi mengeluarkan surat telegram mutasi terhadap 424 perwira tinggi (Pati) dan perwira menengah (Pamen). Langkah strategis ini ditempuh dalam rangka regenerasi kepemimpinan, promosi jabatan prestasi, dan penyegaran institusi korps Bhayangkara.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Kepala Divisi Humas Polri menyampaikan bahwa rotasi berkala adalah mekanisme lumrah dalam struktur organisasi penegakan hukum modern. Prioritas kepemimpinan baru difokuskan pada pemantapan perlindungan masyarakat, penindakan kejahatan siber, serta pengamanan agenda pembangunan nasional.
      </p>',
    '/uploads/berita/kriminal/rilis-mabes-polri.jpg',
    4,
    'Hukum',
    'hukum',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    39500,
    '3 menit baca',
    'Hukum, Media Four Tribuan News, Terkini',
    '2026-11-16T15:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    19,
    'Inspirasi Kak Na: Penggerak Edukasi Gizi Keluarga yang Membangkitkan Gemar Makan Ikan Generasi Muda',
    'inspirasi-kak-na-penggerak-edukasi-gizi-keluarga-yang-membangkitkan-gemar-makan-ikan-generasi-muda',
    'MEULABOH — Sosok Kak Na dikenal luas oleh kaum ibu di gampong-gampong pesisir sebagai figur penggerak kesehatan keluarga yang tak kenal lelah mengkampanyekan pentingnya konsumsi pangan bernutrisi seim...',
    '
      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>MEULABOH</strong> — Sosok Kak Na dikenal luas oleh kaum ibu di gampong-gampong pesisir sebagai figur penggerak kesehatan keluarga yang tak kenal lelah mengkampanyekan pentingnya konsumsi pangan bernutrisi seimbang berbahan baku lokal.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Melalui program pelatihan kreasi olahan serba ikan yang higienis dan variatif seperti nugget ikan, bakso ikan tenggiri, hingga abon tuna, ribuan anak usia dini berhasil dibebaskan dari ancaman malnutrisi dan stunting. Pendekatan ramah dan interaktif yang diterapkannya membuat para orang tua lebih termotivasi menyajikan menu sehat setiap hari.
      </p>
      <blockquote class="my-6 p-4 border-l-4 border-mftn-red bg-red-50 italic text-gray-800 font-serif text-lg">
        "Anak-anak adalah masa depan peradaban kita. Memberi mereka gizi terbaik dari hasil laut nusantara adalah investasi terbesar bagi kecerdasan dan masa depan bangsa," ujar Kak Na dengan penuh ketulusan.
      </blockquote>',
    '/uploads/berita/daerah/festival-budaya-palembang.jpg',
    15,
    'Tokoh',
    'tokoh',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1350,
    '3 menit baca',
    'Tokoh, Media Four Tribuan News, Terkini',
    '2026-11-16T12:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    20,
    'Penguatan Kurikulum Merdeka di Sekolah Kejuruan Dorong Daya Saing dan Keterampilan Lulusan',
    'penguatan-kurikulum-merdeka-di-sekolah-kejuruan-dorong-daya-saing-dan-keterampilan-lulusan',
    'BANDA ACEH — Dinas Pendidikan Provinsi memperluas kemitraan strategis antara SMK unggulan dan dunia industri manufaktur terkemuka guna menyelaraskan kurikulum vokasi dengan kebutuhan riil pasar tenaga...',
    '
      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>BANDA ACEH</strong> — Dinas Pendidikan Provinsi memperluas kemitraan strategis antara SMK unggulan dan dunia industri manufaktur terkemuka guna menyelaraskan kurikulum vokasi dengan kebutuhan riil pasar tenaga kerja era teknologi.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Program magang industri bersertifikasi kompetensi nasional dan fasilitas teaching factory terbukti meningkatkan serapan kerja lulusan sekolah kejuruan hingga mencapai angka rekor di awal tahun ini.
      </p>',
    '/uploads/berita/pendidikan/kurikulum-merdeka-nasional.jpg',
    7,
    'Pendidikan',
    'pendidikan',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1240,
    '3 menit baca',
    'Pendidikan, Media Four Tribuan News, Terkini',
    '2026-11-16T09:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    21,
    'Prabowo Tegaskan Tidak Boleh Ada Anak-Anak Bertarung Nyawa saat ke Sekolah',
    'prabowo-tegaskan-tidak-boleh-ada-anak-anak-bertarung-nyawa-saat-ke-sekolah',
    'JAKARTA — Presiden RI Prabowo Subianto menegaskan pemerintah tidak akan mentolerir adanya situasi di mana anak-anak sekolah di pelosok desa harus mempertaruhkan nyawa menyeberangi jeram sungai deras d...',
    '      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>JAKARTA</strong> — Presiden RI Prabowo Subianto menegaskan pemerintah tidak akan mentolerir adanya situasi di mana anak-anak sekolah di pelosok desa harus mempertaruhkan nyawa menyeberangi jeram sungai deras demi menuntut ilmu.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Presiden memerintahkan Kementerian Pekerjaan Umum bekerja sama dengan Satuan Zeni TNI dan jajaran kepolisian untuk segera memetakan seluruh titik lintasan rawan di pedalaman Sumatra, Kalimantan, Sulawesi, hingga Papua. Pembangunan jembatan gantung perintis harus diselesaikan dengan standar keselamatan tinggi dan waktu pengerjaan cepat.
      </p>',
    '/uploads/berita/nasional/konferensi-pers-istana.jpg',
    1,
    'Nasional',
    'nasional',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    35200,
    '3 menit baca',
    'Nasional, Media Four Tribuan News, Terkini',
    '2026-11-16T06:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    22,
    'USK Sambut 8.000-an Mahasiswa Baru dalam PAKARMARU 2026 di Gelanggang USK',
    'usk-sambut-8000-an-mahasiswa-baru-dalam-pakarmaru-2026',
    'BANDA ACEH — Gelanggang Mahasiswa Universitas Syiah Kuala (USK) Darussalam dipadati ribuan mahasiswa baru lintas fakultas dalam pembukaan agenda tahunan Pembinaan Akademik dan Karakter Mahasiswa Baru ...',
    '      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>BANDA ACEH</strong> — Gelanggang Mahasiswa Universitas Syiah Kuala (USK) Darussalam dipadati ribuan mahasiswa baru lintas fakultas dalam pembukaan agenda tahunan Pembinaan Akademik dan Karakter Mahasiswa Baru (PAKARMARU) tahun akademik 2026.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Rektor USK berpesan kepada seluruh civitas akademika muda agar menjadikan momentum perkuliahan sebagai ruang pengasahan karakter moral, daya saing sains, serta kepedulian sosial terhadap kemajuan masyarakat Aceh dan Indonesia.
      </p>',
    '/uploads/berita/pendidikan/wisuda-universitas-negeri.jpg',
    7,
    'Pendidikan',
    'pendidikan',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    26700,
    '3 menit baca',
    'Pendidikan, Media Four Tribuan News, Terkini',
    '2026-11-16T03:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    23,
    'Mahasiswa di Aceh Ubah Limbah Kulit Manggis Jadi Teknologi Pengolahan Air Bersih',
    'mahasiswa-di-aceh-ubah-limbah-kulit-manggis-jadi-teknologi-pengolahan-air',
    'MEULABOH — Limbah kulit manggis yang kerap dibuang sia-sia berhasil disulap oleh tim peneliti muda mahasiswa di Aceh menjadi media adsorpsi karbon aktif canggih penjernih air rawa dan gambut. Teknolog...',
    '      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>MEULABOH</strong> — Limbah kulit manggis yang kerap dibuang sia-sia berhasil disulap oleh tim peneliti muda mahasiswa di Aceh menjadi media adsorpsi karbon aktif canggih penjernih air rawa dan gambut.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Teknologi ramah lingkungan berbiaya murah ini terbukti mampu mengikat logam berat dan menurunkan tingkat keasaman (pH) air sehingga aman untuk kebutuhan harian masyarakat di kawasan perairan payau dan pesisir.
      </p>',
    '/uploads/berita/teknologi/peluncuran-satelit-indonesia.jpg',
    8,
    'Teknologi',
    'teknologi',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    31400,
    '3 menit baca',
    'Teknologi, Media Four Tribuan News, Terkini',
    '2026-11-16T00:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    24,
    'Pemkab Aceh Barat Eksekusi Aset Pelabuhan Jetty, Kantor PT MPM Dikosongkan',
    'pemkab-aceh-barat-eksekusi-aset-pelabuhan-jetty-kantor-pt-mpm-dikosongkan',
    'MEULABOH — Tim penertiban aset Pemkab Aceh Barat didampingi aparat kepolisian dan Satpol PP berhasil menuntaskan proses pengosongan areal fasilitas perkantoran di Pelabuhan Jetty Suak Indrapuri Meulab...',
    '      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>MEULABOH</strong> — Tim penertiban aset Pemkab Aceh Barat didampingi aparat kepolisian dan Satpol PP berhasil menuntaskan proses pengosongan areal fasilitas perkantoran di Pelabuhan Jetty Suak Indrapuri Meulaboh secara tertib dan kondusif.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Langkah tegas ini merupakan tindak lanjut kepastian hukum penguasaan aset milik daerah guna menjamin pemasukan retribusi yang optimal bagi kemajuan pembangunan masyarakat lokal.
      </p>',
    '/uploads/berita/daerah/revitalisasi-pelabuhan-banyuasin.jpg',
    2,
    'Daerah',
    'daerah',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    23100,
    '3 menit baca',
    'Daerah, Media Four Tribuan News, Terkini',
    '2026-11-15T21:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    25,
    'Fiskal Terbatas, Wabup Said Fadheil Minta Perubahan APBD 2026 Harus Fokus pada Prioritas Daerah',
    'fiskal-terbatas-wabup-said-fadheil-minta-perubahan-apbd-2026-harus-fokus-pada-prioritas-daerah',
    'MEULABOH — Di tengah tantangan ruang fiskal daerah, Wakil Bupati Aceh Barat Said Fadheil menekankan kepada pimpinan Satuan Kerja Perangkat Kabupaten (SKPK) agar meniadakan program seremonial dan mempr...',
    '      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>MEULABOH</strong> — Di tengah tantangan ruang fiskal daerah, Wakil Bupati Aceh Barat Said Fadheil menekankan kepada pimpinan Satuan Kerja Perangkat Kabupaten (SKPK) agar meniadakan program seremonial dan memprioritaskan anggaran pada penanganan kemiskinan ekstrem, stunting, dan infrastruktur tani.
      </p>',
    '/uploads/berita/ekonomi/bursa-efek-perdagangan.jpg',
    5,
    'Ekonomi',
    'ekonomi',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    21500,
    '3 menit baca',
    'Ekonomi, Media Four Tribuan News, Terkini',
    '2026-11-15T18:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    26,
    'PAN Aceh Barat Kebut Penguatan Struktur DPC, SK Pengurus Periode 2024-2029 Direkomendasikan',
    'pan-aceh-barat-kebut-penguatan-struktur-dpc-sk-pengurus-periode-direkomendasikan',
    'MEULABOH — Jajaran DPD PAN Aceh Barat menggelar konsolidasi menyeluruh guna memfinalisasi pengesahan surat keputusan pengurus Dewan Pimpinan Cabang (DPC) se-kabupaten demi memastikan soliditas kepengu...',
    '      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>MEULABOH</strong> — Jajaran DPD PAN Aceh Barat menggelar konsolidasi menyeluruh guna memfinalisasi pengesahan surat keputusan pengurus Dewan Pimpinan Cabang (DPC) se-kabupaten demi memastikan soliditas kepengurusan hingga tingkat gampong.
      </p>',
    '/uploads/berita/politik/koalisi-partai-politik.jpg',
    3,
    'Politik',
    'politik',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    18200,
    '3 menit baca',
    'Politik, Media Four Tribuan News, Terkini',
    '2026-11-15T15:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    27,
    'MK Kabulkan Gugatan Kuota Hangus, Sisa Data Wajib Bisa Dipakai Sampai Habis',
    'mk-kabulkan-gugatan-kuota-hangus-sisa-data-wajib-bisa-dipakai-sampai-habis',
    'JAKARTA — Kabar gembira bagi ratusan juta pengguna ponsel di tanah air. Mahkamah Konstitusi Republik Indonesia mengabulkan sebagian permohonan uji materi terkait regulasi paket kuota data internet ope...',
    '      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>JAKARTA</strong> — Kabar gembira bagi ratusan juta pengguna ponsel di tanah air. Mahkamah Konstitusi Republik Indonesia mengabulkan sebagian permohonan uji materi terkait regulasi paket kuota data internet operator telekomunikasi seluler.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Dalam pertimbangan hukumnya, majelis hakim menyatakan bahwa kuota data yang telah dibeli konsumen merupakan hak kepemilikan bernilai ekonomis yang tidak boleh dihanguskan sepihak hanya karena berakhirnya masa tenggang waktu tertentu.
      </p>',
    '/uploads/berita/teknologi/regulasi-ai-indonesia.jpg',
    6,
    'Bisnis',
    'bisnis',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    46100,
    '3 menit baca',
    'Bisnis, Media Four Tribuan News, Terkini',
    '2026-11-15T12:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    28,
    'Pemkab Nagan Raya Terima Dividen Rp1,63 Miliar dan Dana Zakat Rp400 Juta dari Bank Aceh Syariah',
    'pemkab-nagan-raya-terima-dividen-rp163-miliar-dan-dana-zakat-bank-aceh-syariah',
    'SUKA MAKMUE — Bank Aceh Syariah Kantor Cabang Nagan Raya secara resmi menyerahkan dividen atas penyertaan modal pemerintah daerah senilai Rp1,63 miliar beserta dana zakat sebesar Rp400 juta. Pemerinta...',
    '      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>SUKA MAKMUE</strong> — Bank Aceh Syariah Kantor Cabang Nagan Raya secara resmi menyerahkan dividen atas penyertaan modal pemerintah daerah senilai Rp1,63 miliar beserta dana zakat sebesar Rp400 juta.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Pemerintah daerah mengapresiasi kontribusi konsisten perbankan syariah kebanggaan masyarakat Aceh dalam mendongkrak penerimaan asli daerah sekaligus menyantuni ribuan mustahik di pelosok pedesaan.
      </p>',
    '/uploads/berita/ekonomi/pertumbuhan-umkm-digital.jpg',
    6,
    'Bisnis',
    'bisnis',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    22300,
    '3 menit baca',
    'Bisnis, Media Four Tribuan News, Terkini',
    '2026-11-15T09:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    29,
    'Bupati Tarmizi Lantik Dr. Kurdi Sebagai Sekda Aceh Barat Definitif',
    'bupati-tarmizi-lantik-dr-kurdi-sebagai-sekda-aceh-barat-definitif',
    'MEULABOH — Aula Bappeda Aceh Barat menjadi saksi pelantikan Dr. Kurdi, S.T., M.T. sebagai Sekretaris Daerah Kabupaten Aceh Barat definitif oleh Bupati Tarmizi SP. Dengan rekam jejak teknis dan kepemim...',
    '      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>MEULABOH</strong> — Aula Bappeda Aceh Barat menjadi saksi pelantikan Dr. Kurdi, S.T., M.T. sebagai Sekretaris Daerah Kabupaten Aceh Barat definitif oleh Bupati Tarmizi SP.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Dengan rekam jejak teknis dan kepemimpinan yang matang, Sekda baru diharapkan mampu mengorkestrasi percepatan serapan anggaran APBD, digitalisasi pelayanan publik, dan menjaga keharmonisan jajaran aparatur sipil negara.
      </p>',
    '/uploads/berita/daerah/infrastruktur-lrt-sumsel.jpg',
    2,
    'Daerah',
    'daerah',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    41500,
    '3 menit baca',
    'Daerah, Media Four Tribuan News, Terkini',
    '2026-11-15T06:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    30,
    'Erdogan Sebut Israel Ingin Hapus Palestina dari Agenda Dunia',
    'erdogan-sebut-israel-ingin-hapus-palestina-dari-agenda-dunia',
    'ANKARA — Presiden Turkiye Recep Tayyip Erdogan melancarkan kritik keras terhadap manuver agresif di kawasan Timur Tengah yang berupaya meminggirkan isu kemerdekaan Palestina dari perhatian masyarakat ...',
    '      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>ANKARA</strong> — Presiden Turkiye Recep Tayyip Erdogan melancarkan kritik keras terhadap manuver agresif di kawasan Timur Tengah yang berupaya meminggirkan isu kemerdekaan Palestina dari perhatian masyarakat internasional.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Erdogan menegaskan bahwa keadilan global tidak akan pernah terwujud tanpa pengakuan berdaulat bagi bangsa Palestina dengan Yerusalem Timur sebagai ibu kota yang sah.
      </p>',
    '/uploads/berita/internasional/konflik-timur-tengah.jpg',
    10,
    'Internasional',
    'internasional',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    38900,
    '3 menit baca',
    'Internasional, Media Four Tribuan News, Terkini',
    '2026-11-15T03:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    31,
    'Profil Dr. Kurdi: Birokrat Inovatif Penggagas Reformasi Tata Kelola Birokrasi Responsif dan Transparan',
    'profil-dr-kurdi-birokrat-inovatif-penggagas-reformasi-tata-kelola-birokrasi-responsif-dan-transparan',
    'MEULABOH — Nama Dr. Kurdi, S.T., M.T. lekat dengan citra birokrat pekerja keras yang mengedepankan pendekatan solutif, cepat, dan berbasis data dalam merespons kebutuhan mendesak masyarakat di wilayah...',
    '
      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>MEULABOH</strong> — Nama Dr. Kurdi, S.T., M.T. lekat dengan citra birokrat pekerja keras yang mengedepankan pendekatan solutif, cepat, dan berbasis data dalam merespons kebutuhan mendesak masyarakat di wilayah pantai barat selatan Aceh.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Sebelum resmi dipercaya memegang amanah sebagai Sekretaris Daerah (Sekda) definitif Kabupaten Aceh Barat, rekam jejaknya dalam memimpin dinas teknis telah melahirkan berbagai percepatan pembangunan sarana konektivitas jalan, jembatan gantung penghubung desa terisolir, hingga penataan ruang publik yang humanis.
      </p>
      <blockquote class="my-6 p-4 border-l-4 border-mftn-red bg-red-50 italic text-gray-800 font-serif text-lg">
        "Birokrasi bukan sekadar duduk di balik meja administrasi, tetapi harus hadir langsung mendengar denyut nadi rakyat dan bergerak sigap menyelesaikan persoalan di lapangan," tutur Dr. Kurdi dalam wawancara eksklusif Media Four Tribuan News.
      </blockquote>
      <h3 class="text-xl font-bold text-black mt-6 mb-3">Komitmen Penguatan Disiplin dan Akuntabilitas</h3>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Di bawah kepemimpinannya, koordinasi antar SKPK diperkuat melalui sistem pelaporan kinerja real-time yang memangkas hambatan birokrasi, menjadikan pelayanan umum lebih cepat dan bebas dari pungutan liar.
      </p>',
    '/uploads/berita/nasional/reformasi-birokrasi-kementerian.jpg',
    15,
    'Tokoh',
    'tokoh',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    2130,
    '3 menit baca',
    'Tokoh, Media Four Tribuan News, Terkini',
    '2026-11-15T00:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    32,
    'Prabowo Guyur Rp18,9 Triliun Untuk 546 Daerah Buat Gaji PPPK',
    'prabowo-guyur-rp189-triliun-untuk-546-daerah-buat-gaji-pppk',
    'JAKARTA — Kepastian kesejahteraan ribuan tenaga pendidik dan tenaga kesehatan honorer yang telah lolos seleksi Pegawai Pemerintah dengan Perjanjian Kerja (PPPK) terjawab tuntas setelah pemerintah meng...',
    '      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>JAKARTA</strong> — Kepastian kesejahteraan ribuan tenaga pendidik dan tenaga kesehatan honorer yang telah lolos seleksi Pegawai Pemerintah dengan Perjanjian Kerja (PPPK) terjawab tuntas setelah pemerintah menggelontorkan alokasi anggaran Rp18,9 triliun ke 546 pemerintah daerah.
      </p>',
    '/uploads/berita/nasional/kebijakan-subsidi-bbm.jpg',
    1,
    'Nasional',
    'nasional',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    37100,
    '3 menit baca',
    'Nasional, Media Four Tribuan News, Terkini',
    '2026-11-14T21:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    33,
    'Sidang Perdana Tipikor Proyek Fasilitas Publik Digelar di Pengadilan Negeri, Jaksa Hadirkan Saksi Kunci',
    'sidang-perdana-tipikor-proyek-fasilitas-publik-digelar-di-pengadilan-negeri-jaksa-hadirkan-saksi-kunci',
    'MEULABOH — Pengadilan Tindak Pidana Korupsi (Tipikor) menggelar sidang perdana pemeriksaan saksi dalam perkara dugaan penyimpangan anggaran pembangunan fasilitas publik tahun anggaran sebelumnya. Jaks...',
    '
      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>MEULABOH</strong> — Pengadilan Tindak Pidana Korupsi (Tipikor) menggelar sidang perdana pemeriksaan saksi dalam perkara dugaan penyimpangan anggaran pembangunan fasilitas publik tahun anggaran sebelumnya.
      </p>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Jaksa Penuntut Umum (JPU) Kejaksaan Negeri menghadirkan empat saksi kunci yang terdiri dari tim pemeriksa teknis, konsultan pengawas, dan perwakilan dinas terkait. Majelis hakim yang memimpin jalannya persidangan menegaskan komitmen peradilan dalam menegakkan transparansi serta asas kepastian hukum tanpa intervensi pihak manapun.
      </p>
      <blockquote class="my-6 p-4 border-l-4 border-mftn-red bg-red-50 italic text-gray-800 font-serif text-lg">
        "Penegakan hukum kasus tindak pidana korupsi adalah amanat konstitusi demi menyelamatkan keuangan negara dan memastikan hak-hak masyarakat atas pembangunan yang layak dapat terpenuhi secara berkeadilan," ujar jaksa dalam pembacaan keterangannya.
      </blockquote>
      <h3 class="text-xl font-bold text-black mt-6 mb-3">Pemeriksaan Dokumen Fisik dan Keterangan Ahli</h3>
      <p class="mb-4 text-gray-700 leading-relaxed">
        Persidangan dijadwalkan berlanjut pekan depan dengan agenda mendengarkan keterangan saksi ahli konstruksi independen guna menguji kesesuaian spesifikasi volume fisik bangunan di lapangan dengan kontrak kerja.
      </p>',
    '/uploads/berita/kriminal/sidang-tipikor-pn.jpg',
    4,
    'Hukum',
    'hukum',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1420,
    '3 menit baca',
    'Hukum, Media Four Tribuan News, Terkini',
    '2026-11-14T18:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    34,
    '[FOTO] Satgas PRR Pusat Bersama Wabup Said Tinjau Kerusakan Desa Jambak',
    'foto-satgas-prr-pusat-bersama-wabup-said-tinjau-kerusakan-desa-jambak',
    'MEULABOH — Galeri foto eksklusif tim redaksi Media Four Tribuan News mendampingi kunjungan kerja Satgas Pemulihan Pascabencana (PRR) pusat bersama Wakil Bupati Aceh Barat Said Fadheil meninjau penanganan darurat...',
    '      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>MEULABOH</strong> — Galeri foto eksklusif tim redaksi Media Four Tribuan News mendampingi kunjungan kerja Satgas Pemulihan Pascabencana (PRR) pusat bersama Wakil Bupati Aceh Barat Said Fadheil meninjau penanganan darurat tebing pantai Desa Jambak.
      </p>',
    '/uploads/berita/daerah/penanganan-banjir-sumatera.jpg',
    13,
    'Foto',
    'foto',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    29400,
    '3 menit baca',
    'Foto, Media Four Tribuan News, Terkini',
    '2026-11-14T15:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    35,
    'Mengembalikan Fungsi Sekolah: Mengapa Pengelolaan Makan Bergizi Gratis Harus Ditangani Ahlinya?',
    'mengembalikan-fungsi-sekolah-mengapa-pengelolaan-makan-bergizi-gratis-harus-ditangani-ahlinya',
    'Program pemberian makan bergizi gratis bagi jutaan pelajar tanah air adalah ikhtiar luhur menyiapkan Generasi Emas 2045. Namun, keberhasilannya sangat ditentukan oleh profesionalitas rantai pasok dan ...',
    '      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        Program pemberian makan bergizi gratis bagi jutaan pelajar tanah air adalah ikhtiar luhur menyiapkan Generasi Emas 2045. Namun, keberhasilannya sangat ditentukan oleh profesionalitas rantai pasok dan tata kelola higienitas pangan tanpa membebani fokus utama para guru dalam mengajar.
      </p>',
    '/uploads/berita/pendidikan/kurikulum-merdeka-smk.jpg',
    11,
    'Opini',
    'opini',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    17200,
    '3 menit baca',
    'Opini, Media Four Tribuan News, Terkini',
    '2026-11-14T12:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    36,
    'Lewat Kreasi Masakan Serba Ikan, Kak Na Ajak Anak Gemar Konsumsi Ikan',
    'lewat-kreasi-masakan-serba-ikan-kak-na-ajak-anak-gemar-konsumsi-ikan',
    'MEULABOH — Ketua Forum Peningkatan Konsumsi Ikan (Forikan) Aceh Barat, Ny. Nurmaziah Tarmizi atau akrab disapa Kak Na, terus menggencarkan inovasi olahan serba ikan seperti nugget, bakso, dan abon ika...',
    '      <p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4">
        <strong>MEULABOH</strong> — Ketua Forum Peningkatan Konsumsi Ikan (Forikan) Aceh Barat, Ny. Nurmaziah Tarmizi atau akrab disapa Kak Na, terus menggencarkan inovasi olahan serba ikan seperti nugget, bakso, dan abon ikan segar guna membiasakan anak-anak menyukai konsumsi ikan demi tumbuh kembang otak yang optimal.
      </p>',
    '/uploads/berita/daerah/festival-budaya-palembang.jpg',
    2,
    'Daerah',
    'daerah',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    15900,
    '3 menit baca',
    'Daerah, Media Four Tribuan News, Terkini',
    '2026-11-14T09:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    37,
    'Mahasiswa Kesma UTU Adakan Lomba Cerdas Cermat Antar Desa',
    'mahasiswa-kesma-utu-adakan-lomba-cerdas-cermat-antar-desa',
    'Ajang cerdas cermat antar gampong ini dirancang guna memotivasi semangat membaca, pemahaman wawasan kebangsaan, dan daya pikir kritis generasi muda di tingkat desa binaan kampus....',
    '<p class=''mb-4''>Ajang cerdas cermat antar gampong ini dirancang guna memotivasi semangat membaca, pemahaman wawasan kebangsaan, dan daya pikir kritis generasi muda di tingkat desa binaan kampus.</p>',
    '/uploads/berita/pendidikan/kurikulum-merdeka-smk.jpg',
    7,
    'Pendidikan',
    'pendidikan',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    14300,
    '3 menit baca',
    'Pendidikan, Media Four Tribuan News, Terkini',
    '2026-11-14T06:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    38,
    'Sekolah Rakyat Aceh Barat Ditargetkan Mulai Dibangun Oktober, Uji Sondir Dilakukan Awal September',
    'sekolah-rakyat-aceh-barat-ditargetkan-mulai-dibangun-oktober-uji-sondir-dilakukan-awal-september',
    'Sekolah Rakyat terintegrasi asrama ini diproyeksikan menjadi pusat pembinaan karakter unggul anak-anak yatim dan berprestasi dari keluarga prasejahtera dengan pembiayaan beasiswa penuh pemda....',
    '<p class=''mb-4''>Sekolah Rakyat terintegrasi asrama ini diproyeksikan menjadi pusat pembinaan karakter unggul anak-anak yatim dan berprestasi dari keluarga prasejahtera dengan pembiayaan beasiswa penuh pemda.</p>',
    '/uploads/berita/daerah/infrastruktur-lrt-sumsel.jpg',
    2,
    'Daerah',
    'daerah',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    16800,
    '3 menit baca',
    'Daerah, Media Four Tribuan News, Terkini',
    '2026-11-14T03:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    39,
    'Cath Lab RSUD CND Kembali Difungsikan, Bupati Aceh Barat Targetkan Layanan Jantung Segera Berjalan',
    'cath-lab-rsud-cnd-kembali-difungsikan-bupati-aceh-barat-targetkan-layanan-jantung-segera-berjalan',
    'Pengaktifan kembali instalasi Cath Lab canggih ini memangkas waktu darurat penanganan serangan jantung bagi warga di delapan kabupaten/kota wilayah barat-selatan Aceh secara signifikan....',
    '<p class=''mb-4''>Pengaktifan kembali instalasi Cath Lab canggih ini memangkas waktu darurat penanganan serangan jantung bagi warga di delapan kabupaten/kota wilayah barat-selatan Aceh secara signifikan.</p>',
    '/uploads/berita/nasional/reformasi-birokrasi-kementerian.jpg',
    2,
    'Daerah',
    'daerah',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    24800,
    '3 menit baca',
    'Daerah, Media Four Tribuan News, Terkini',
    '2026-11-14T00:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    40,
    '[FOTO] Mengintip Kemegahan Pesawat Jumbo Airbus A380 yang Mampir RI',
    'foto-mengintip-kemegahan-pesawat-jumbo-airbus-a380-yang-mampir-ri',
    'Kemegahan burung besi bertingkat ganda terbesar di dunia ini memukau para pecinta kedirgantaraan saat menyentuh landas pacu dan menjalani proses penanganan darat terpadu di Bandara Internasional I Gusti Ngurah Rai, Bali.',
    '<p class=''mb-4''>Kemegahan burung besi bertingkat ganda terbesar di dunia ini memukau para pecinta kedirgantaraan saat menyentuh landas pacu dan menjalani proses penanganan darat terpadu di Bandara Internasional I Gusti Ngurah Rai, Bali.</p><p class=''mb-4''>Pesawat berbadan lebar dengan bentang sayap mencapai 79,75 meter ini mencatatkan sejarah baru bagi operasional penerbangan komersial internasional di tanah air dengan fasilitas garbarata ganda yang telah disiapkan secara komprehensif.</p><p class=''mb-4''>Berikut rangkaian dokumentasi lensa foto eksklusif yang memperlihatkan dari dekat setiap sudut kemegahan pesawat super jumbo jet Airbus A380 saat berada di apron bandara.</p>',
    '/uploads/berita/nasional/pembangunan-ikn-nusantara.jpg',
    13,
    'Foto',
    'foto',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    33800,
    '3 menit baca',
    'Foto, Media Four Tribuan News, Terkini',
    '2026-11-13T21:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    41,
    '[FOTO] Kebakaran Bromo Meluas, Api Dekati Permukiman Warga',
    'foto-kebakaran-bromo-meluas-api-dekati-permukiman-warga',
    'Ratusan personel gabungan bergotong-royong membuat sekat bakar manual di tengah kepulan asap pekat guna melindungi desa-desa pemukiman di sekitar lereng pegunungan....',
    '<p class=''mb-4''>Ratusan personel gabungan bergotong-royong membuat sekat bakar manual di tengah kepulan asap pekat guna melindungi desa-desa pemukiman di sekitar lereng pegunungan.</p>',
    '/uploads/berita/internasional/krisis-energi-eropa.jpg',
    13,
    'Foto',
    'foto',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    25600,
    '3 menit baca',
    'Foto, Media Four Tribuan News, Terkini',
    '2026-11-13T18:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    42,
    'Menteri PU Tegaskan Jembatan Sikundo dan Irigasi Lhok Guci Jadi Prioritas',
    'menteri-pu-tegaskan-jembatan-sikundo-dan-irigasi-lhok-guci-jadi-prioritas',
    'Penyelesaian jaringan saluran sekunder irigasi Lhok Guci diproyeksikan mengairi lebih dari 10.000 hektare areal persawahan produktif sehingga memperkuat swasembada beras di Aceh....',
    '<p class=''mb-4''>Penyelesaian jaringan saluran sekunder irigasi Lhok Guci diproyeksikan mengairi lebih dari 10.000 hektare areal persawahan produktif sehingga memperkuat swasembada beras di Aceh.</p>',
    '/uploads/berita/daerah/revitalisasi-pelabuhan-banyuasin.jpg',
    2,
    'Daerah',
    'daerah',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    21900,
    '3 menit baca',
    'Daerah, Media Four Tribuan News, Terkini',
    '2026-11-13T15:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    43,
    'Gaji 3.300 Pegawai Paruh Waktu Pidie Jaya Tertunggak hingga Tiga Bulan',
    'gaji-3-300-pegawai-paruh-waktu-pidie-jaya-tertunggak-hingga-tiga-bulan',
    'Pemerintah Kabupaten Pidie Jaya menyatakan proses rekonsiliasi data anggaran bersama badan pengelola keuangan daerah sedang dirampungkan agar pencairan hak pegawai honorer tuntas pekan ini....',
    '<p class=''mb-4''>Pemerintah Kabupaten Pidie Jaya menyatakan proses rekonsiliasi data anggaran bersama badan pengelola keuangan daerah sedang dirampungkan agar pencairan hak pegawai honorer tuntas pekan ini.</p>',
    '/uploads/berita/ekonomi/inflasi-bank-indonesia.jpg',
    2,
    'Daerah',
    'daerah',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    28100,
    '3 menit baca',
    'Daerah, Media Four Tribuan News, Terkini',
    '2026-11-13T12:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    44,
    'Donald Trump Ancam FIFA Tak Kudeta Gianni Infantino Jelang Piala Dunia 2026',
    'donald-trump-ancam-fifa-tak-kudeta-gianni-infantino',
    'Dalam wawancara eksklusif, Trump menegaskan kepemimpinan Gianni Infantino telah membawa stabilitas finansial dan kerja sama sukses bagi tuan rumah bersama Amerika Serikat, Kanada, dan Meksiko....',
    '<p class=''mb-4''>Dalam wawancara eksklusif, Trump menegaskan kepemimpinan Gianni Infantino telah membawa stabilitas finansial dan kerja sama sukses bagi tuan rumah bersama Amerika Serikat, Kanada, dan Meksiko.</p>',
    '/uploads/berita/olahraga/kualifikasi-piala-dunia-timnas.jpg',
    9,
    'Olahraga',
    'olahraga',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    34500,
    '3 menit baca',
    'Olahraga, Media Four Tribuan News, Terkini',
    '2026-11-13T09:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    45,
    'Pemakaman Ayah Messi Berlangsung Tertutup, Hanya Dihadiri Keluarga Dekat',
    'pemakaman-ayah-messi-berlangsung-tertutup-hanya-dihadiri-keluarga',
    'Keluarga besar Lionel Messi menyampaikan terima kasih mendalam atas ribuan ucapan belasungkawa dan simpati yang mengalir dari komunitas sepak bola internasional di seluruh penjuru dunia....',
    '<p class=''mb-4''>Keluarga besar Lionel Messi menyampaikan terima kasih mendalam atas ribuan ucapan belasungkawa dan simpati yang mengalir dari komunitas sepak bola internasional di seluruh penjuru dunia.</p>',
    '/uploads/berita/olahraga/final-bulutangkis-dunia.jpg',
    9,
    'Olahraga',
    'olahraga',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    44200,
    '3 menit baca',
    'Olahraga, Media Four Tribuan News, Terkini',
    '2026-11-13T06:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    46,
    'Turki Harap Mesir Gabung ke Pakta Pertahanan Bareng Saudi dan Pakistan',
    'turki-harap-mesir-gabung-ke-pakta-pertahanan-bareng-saudi-pakistan',
    'Inisiatif integrasi kemitraan pertahanan ini dinilai strategis dalam menjaga stabilitas jalur perdagangan energi maritim Laut Merah dan Terusan Suez dari potensi ancaman asimetris....',
    '<p class=''mb-4''>Inisiatif integrasi kemitraan pertahanan ini dinilai strategis dalam menjaga stabilitas jalur perdagangan energi maritim Laut Merah dan Terusan Suez dari potensi ancaman asimetris.</p>',
    '/uploads/berita/internasional/pemilu-amerika-serikat.jpg',
    10,
    'Internasional',
    'internasional',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    27400,
    '3 menit baca',
    'Internasional, Media Four Tribuan News, Terkini',
    '2026-11-13T03:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    47,
    '[VIDEO] Penanganan Cepat Tanggap Banjir Pidie Jaya dan Bantuan Dapur Umum',
    'video-penanganan-cepat-tanggap-banjir-pidie-jaya-dan-bantuan-dapur-umum',
    'MEUREUDU — Video dokumentasi penyaluran bantuan pangan darurat dan evakuasi lansia di posko pengungsian terpadu Pidie Jaya pasca luapan air sungai surut perlahan.',
    '<p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4"><strong>MEUREUDU</strong> — Tim tanggap darurat BPBD bersama relawan kemanusiaan bahu-membahu mendirikan dapur umum lapangan dan mendistribusikan kebutuhan sanitasi bagi ribuan warga terdampak banjir di Pidie Jaya.</p><p class="mb-4 text-gray-700 leading-relaxed">Kondisi terkini menunjukkan genangan air di sejumlah titik telah berangsur surut, namun aparat tetap mengimbau masyarakat untuk mewaspadai potensi curah hujan susulan.</p>',
    '/uploads/berita/daerah/revitalisasi-pelabuhan-banyuasin.jpg',
    14,
    'Video',
    'video',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    3420,
    '2 menit tonton',
    'Video, Banjir, Pidie Jaya, Terkini',
    '2026-11-13T00:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    48,
    '[VIDEO] Semarak Latihan Perdana Skuad PSP Pidie Jaya Menuju Liga 3 Aceh',
    'video-semarak-latihan-perdana-skuad-psp-pidie-jaya-menuju-liga-3-aceh',
    'TRIENGGADENG — Liputan video eksklusif sesi latihan perdana para talenta muda PSP Pidie Jaya di bawah arahan pelatih kepala guna mematangkan taktik dan fisik jelang kick-off kompetisi.',
    '<p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4"><strong>TRIENGGADENG</strong> — Skuad kebanggaan masyarakat Pidie Jaya, PSP Pidie Jaya, resmi menggelar pemusatan latihan intensif guna mempersiapkan formasi tempur menghadapi ketatnya persaingan Liga 3 zona Aceh.</p><p class="mb-4 text-gray-700 leading-relaxed">Ratusan suporter turut hadir di pinggir lapangan memberikan suntikan motivasi moril bagi para pemain muda lokal yang menjadi tumpuan harapan daerah.</p>',
    '/uploads/berita/olahraga/pekan-olahraga-nasional.jpg',
    14,
    'Video',
    'video',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    4150,
    '3 menit tonton',
    'Video, Olahraga, PSP Pidie Jaya, Liga 3',
    '2026-11-12T21:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    49,
    '[FOTO] Pesona Karnaval Adat dan Budaya Gampong Pesisir Aceh',
    'foto-pesona-karnaval-adat-dan-budaya-gampong-pesisir-aceh',
    'MEUREUDU — Deretan foto warna-warni busana tradisional adat Aceh dan parade perahu hias nelayan memukau ribuan penonton dalam pagelaran festival pesisir tahun 2026.',
    '<p class="lead font-medium text-lg text-gray-800 leading-relaxed mb-4"><strong>MEUREUDU</strong> — Ribuan masyarakat antusias menyaksikan karnaval ragam budaya lokal yang menampilkan busana kebesaran adat Aceh dan atraksi kesenian tradisional pesisir.</p><p class="mb-4 text-gray-700 leading-relaxed">Festival tahunan ini diinisiasi untuk menjaga kelestarian warisan budaya indatu sekaligus membangkitkan sektor pariwisata daerah.</p>',
    '/uploads/berita/daerah/festival-budaya-palembang.jpg',
    13,
    'Foto',
    'foto',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    21300,
    '2 menit lihat',
    'Foto, Budaya, Pidie Jaya, Karnaval',
    '2026-11-12T18:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    50,
    'Percepatan Pembangunan IKN Tahap 2: Gedung Kementerian dan Hunian ASN Selesai Tepat Waktu',
    'pembangunan-ikn-tahap-2-gedung-kementerian-selesai',
    'Kementerian Pekerjaan Umum dan Perumahan Rakyat memastikan infrastruktur dasar serta fasilitas hunian bagi aparatur sipil negara di Ibu Kota Nusantara telah mencapai tahap akhir penyelesaian.',
    '<p>Kementerian Pekerjaan Umum dan Perumahan Rakyat (PUPR) memastikan pembangunan tahap kedua di Kawasan Inti Pusat Pemerintahan (KIPP) IKN Nusantara berjalan sesuai target yang telah ditetapkan oleh pemerintah.</p>',
    '/uploads/berita/nasional/pembangunan-ikn-nusantara.jpg',
    1,
    'Nasional',
    'nasional',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1850,
    '3 menit baca',
    'Nasional, IKN, Pembangunan',
    '2026-11-12T15:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    51,
    'Kementerian Sosial Salurkan Bansos Beras dan PKH Serentak ke 38 Provinsi di Seluruh Indonesia',
    'kementerian-sosial-salurkan-bansos-beras-pkh-serentak',
    'Penyaluran bantuan sosial tahap ketiga tahun 2026 menyasar lebih dari 10 juta keluarga penerima manfaat guna menjaga stabilitas daya beli masyarakat pasca penyesuaian harga pangan.',
    '<p>Kementerian Sosial Republik Indonesia secara resmi mulai mendistribusikan bantuan sosial pangan berupa beras 10 kilogram serta bantuan langsung tunai Program Keluarga Harapan (PKH) ke seluruh penjuru Nusantara.</p>',
    '/uploads/berita/nasional/kebijakan-subsidi-bbm.jpg',
    1,
    'Nasional',
    'nasional',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1420,
    '3 menit baca',
    'Nasional, Bansos, Kemensos',
    '2026-11-12T12:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    52,
    'KPU Matangkan Distribusi Logistik dan Kesiapan TPS Menjelang Pemungutan Suara Serentak',
    'kpu-matangkan-distribusi-logistik-dan-kesiapan-tps',
    'Komisi Pemilihan Umum memastikan seluruh surat suara, kotak suara, dan perangkat pemindai digital telah terdistribusi hingga ke wilayah terluar dan pelosok kepulauan.',
    '<p>Komisi Pemilihan Umum (KPU) Republik Indonesia menggelar rapat koordinasi nasional bersama jajaran KPU Provinsi dan Kabupaten/Kota guna mengecek kesiapan logistik pemilu secara komprehensif.</p>',
    '/uploads/berita/politik/revisi-uu-pilkada.jpg',
    3,
    'Politik',
    'politik',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1230,
    '3 menit baca',
    'Politik, KPU, Pemilu',
    '2026-11-12T09:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    53,
    'Rapat Kerja Komisi II DPR Bahas Netralitas Aparatur Sipil Negara dan Efisiensi Anggaran',
    'rapat-kerja-komisi-ii-dpr-bahas-netralitas-asn',
    'DPR RI bersama Kementerian Pendayagunaan Aparatur Negara dan Reformasi Birokrasi menyepakati sanksi tegas bagi pegawai negeri yang terbukti tidak netral dalam kontestasi politik.',
    '<p>Komisi II Dewan Perwakilan Rakyat Republik Indonesia menggelar rapat kerja intensif guna membahas penegakan disiplin dan netralitas ASN di seluruh tingkatan pemerintahan.</p>',
    '/uploads/berita/politik/sidang-paripurna-dpr.jpg',
    3,
    'Politik',
    'politik',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1150,
    '3 menit baca',
    'Politik, DPR RI, ASN',
    '2026-11-12T06:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    54,
    'Kejaksaan Agung Tangkap Buronan Kasus Investasi Bodong Senilai Puluhan Miliar Rupiah',
    'kejaksaan-agung-tangkap-buronan-kasus-investasi-bodong',
    'Tim gabungan Intelijen Kejaksaan Agung berhasil mengamankan terpidana kasus penipuan skema piramida yang sempat melarikan diri ke luar daerah selama lebih dari dua tahun.',
    '<p>Tim Tangkap Buronan (Tabur) Kejaksaan Agung Republik Indonesia berhasil mengeksekusi seorang terpidana kasus penipuan investasi bodong berkedok perdagangan komoditas digital.</p>',
    '/uploads/berita/kriminal/sidang-tipikor-pn.jpg',
    4,
    'Hukum',
    'hukum',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    2100,
    '3 menit baca',
    'Hukum, Kejaksaan, Kriminal',
    '2026-11-12T03:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    55,
    'Pertumbuhan Kredit UMKM Meningkat 8,5 Persen Didukung Akselerasi Digitalisasi Perbankan',
    'pertumbuhan-kredit-umkm-meningkat-didukung-digitalisasi',
    'Otoritas Jasa Keuangan (OJK) melaporkan stabilitas sektor perbankan tetap solid dengan rasio kredit macet yang terjaga rendah di bawah ambang batas tiga persen.',
    '<p>Penyaluran pembiayaan usaha mikro, kecil, dan menengah (UMKM) nasional mencatatkan pertumbuhan positif sepanjang kuartal ketiga tahun 2026 seiring ekspansi ekosistem pembayaran nontunai.</p>',
    '/uploads/berita/ekonomi/pertumbuhan-umkm-digital.jpg',
    5,
    'Ekonomi',
    'ekonomi',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1340,
    '3 menit baca',
    'Ekonomi, UMKM, Perbankan',
    '2026-11-12T00:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    56,
    'Kementerian Keuangan Pastikan Insentif Pajak Sektor Industri Manufaktur Diperpanjang',
    'kemenkeu-pastikan-insentif-pajak-manufaktur-diperpanjang',
    'Langkah strategis ini diambil guna menstimulasi penciptaan lapangan kerja baru serta menjaga daya saing produk ekspor nasional di tengah volatilitas pasar global.',
    '<p>Kementerian Keuangan Republik Indonesia mengumumkan perpanjangan fasilitas pembebasan pajak penghasilan dan tax holiday untuk sektor industri pengolahan strategis dan padat karya.</p>',
    '/uploads/berita/ekonomi/bursa-efek-perdagangan.jpg',
    5,
    'Ekonomi',
    'ekonomi',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1520,
    '3 menit baca',
    'Ekonomi, Kemenkeu, Pajak',
    '2026-11-11T21:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    57,
    'Kemendikbudristek Buka Beasiswa Unggulan 2026 untuk Jenjang Sarjana dan Pascasarjana',
    'kemendikbudristek-buka-beasiswa-unggulan-2026',
    'Program bantuan biaya kuliah penuh dan tunjangan hidup ini ditujukan bagi putra-putri berprestasi nasional serta talenta riset masa depan di perguruan tinggi terakreditasi A.',
    '<p>Kementerian Pendidikan, Kebudayaan, Riset, dan Teknologi secara resmi meluncurkan pendaftaran Beasiswa Unggulan gelombang kedua tahun akademik 2026/2027.</p>',
    '/uploads/berita/pendidikan/kurikulum-merdeka-nasional.jpg',
    7,
    'Pendidikan',
    'pendidikan',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1980,
    '3 menit baca',
    'Pendidikan, Beasiswa, Kampus',
    '2026-11-11T18:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    58,
    'UIN Ar-Raniry Banda Aceh Raih Akreditasi Unggul dari BAN-PT untuk 15 Program Studi',
    'uin-ar-raniry-raih-akreditasi-unggul-ban-pt',
    'Capaian prestisius ini memperkokoh reputasi kampus Islam negeri di Aceh tersebut sebagai salah satu episentrum keilmuan integratif terbaik di kawasan barat Indonesia.',
    '<p>Universitas Islam Negeri (UIN) Ar-Raniry Banda Aceh kembali menorehkan prestasi membanggakan dengan meraih akreditasi institusi berkategori Unggul dari Badan Akreditasi Nasional Perguruan Tinggi (BAN-PT).</p>',
    '/uploads/berita/pendidikan/wisuda-universitas-negeri.jpg',
    7,
    'Pendidikan',
    'pendidikan',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1650,
    '3 menit baca',
    'Pendidikan, Aceh, Kampus',
    '2026-11-11T15:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    59,
    'Kemenkominfo Siapkan Regulasi Etika Pemanfaatan Artificial Intelligence di Indonesia',
    'kemenkominfo-siapkan-regulasi-etika-pemanfaatan-ai',
    'Pedoman tata kelola kecerdasan buatan dirancang guna melindungi hak cipta intelektual, privasi data warga, serta mencegah disinformasi berbasis deepfake di ruang publik.',
    '<p>Kementerian Komunikasi dan Informatika bersama para pakar teknologi informasi merampungkan draf panduan etis adopsi Artificial Intelligence bagi sektor industri dan korporasi teknologi.</p>',
    '/uploads/berita/teknologi/regulasi-ai-indonesia.jpg',
    8,
    'Teknologi',
    'teknologi',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1780,
    '3 menit baca',
    'Teknologi, AI, Kominfo',
    '2026-11-11T12:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    60,
    'Startup Lokal Kembangkan Aplikasi Deteksi Dini Bencana Banjir Berbasis IoT dan Radar Cuaca',
    'startup-lokal-kembangkan-aplikasi-deteksi-banjir-iot',
    'Sistem peringatan dini ini mampu memberikan notifikasi evakuasi hingga dua jam lebih cepat kepada masyarakat pesisir dan bantaran sungai sebelum air meluap.',
    '<p>Inovasi teknologi kebencanaan karya anak bangsa kembali hadir melalui peluncuran sensor permukaan air pintar yang terhubung dengan jaringan satelit pemantau hidrometeorologi.</p>',
    '/uploads/berita/teknologi/pusat-keamanan-siber.jpg',
    8,
    'Teknologi',
    'teknologi',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1410,
    '3 menit baca',
    'Teknologi, Inovasi, Bencana',
    '2026-11-11T09:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    61,
    'Timnas Indonesia Gelar TC Intensif di Bali Menjelang Laga Krusial Kualifikasi Piala Dunia 2026',
    'timnas-indonesia-tc-intensif-bali-kualifikasi-piala-dunia',
    'Pelatih kepala memanggil 26 pemain terbaik termasuk penggawa yang berkompetisi di liga-liga top Eropa guna mematangkan skema transisi cepat dan koordinasi lini pertahanan.',
    '<p>Skuad Garuda resmi memulai pemusatan latihan terpusat di Bali sebagai bagian dari persiapan menghadapi dua laga penentu putaran ketiga Kualifikasi Piala Dunia zona Asia.</p>',
    '/uploads/berita/olahraga/kualifikasi-piala-dunia-timnas.jpg',
    9,
    'Olahraga',
    'olahraga',
    'Admin Redaksi',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    2850,
    '3 menit baca',
    'Olahraga, Timnas, Sepakbola',
    '2026-11-11T06:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    62,
    'KTT Iklim Global Sepakati Dana Bantuan Transisi Energi Hijau untuk Negara Berkembang',
    'ktt-iklim-global-sepakati-dana-bantuan-transisi-energi',
    'Negara-negara maju berkomitmen mengucurkan pendanaan senilai 100 miliar dolar AS guna mempercepat penghentian pembangkit batu bara dan pembangunan PLTS ramah lingkungan.',
    '<p>Konferensi Tingkat Tinggi Perubahan Iklim Perserikatan Bangsa-Bangsa berhasil membuahkan kesepakatan bersejarah terkait skema pembiayaan transisi energi terbarukan di Asia Tenggara dan Afrika.</p>',
    '/uploads/berita/internasional/diplomasi-ktt-global.jpg',
    10,
    'Internasional',
    'internasional',
    'Rama Pratama',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1320,
    '3 menit baca',
    'Internasional, KTT, Iklim',
    '2026-11-11T03:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO articles (id, title, slug, excerpt, content, thumbnail, category_id, category_name, category_slug, author_name, author_role, status, is_headline, is_featured, is_popular, is_breaking, views, read_time, tags, published_at)
VALUES (
    63,
    'PBB Desak Gencatan Senjata Permanen dan Jalur Koridor Medis Dibuka Tanpa Hambatan',
    'pbb-desak-gencatan-senjata-permanen-dan-jalur-evakuasi-medis',
    'Sekretaris Jenderal Perserikatan Bangsa-Bangsa menyerukan kepatuhan total terhadap hukum kemanusiaan internasional demi melindungi jutaan warga sipil tak berdosa di zona konflik.',
    '<p>Dewan Keamanan PBB menggelar sidang darurat menyusul memburuknya krisis kemanusiaan di wilayah konflik Timur Tengah dan mendesak seluruh pihak menyetujui penghentian permusuhan tanpa syarat.</p>',
    '/uploads/berita/internasional/konflik-timur-tengah.jpg',
    10,
    'Internasional',
    'internasional',
    'Siti Rahmawati',
    'Redaksi',
    'published',
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    1670,
    '3 menit baca',
    'Internasional, PBB, Kemanusiaan',
    '2026-11-11T00:03:17.8035265+07:00'
) ON CONFLICT (id) DO NOTHING;

-- Inisialisasi Multimedia Video
INSERT INTO videos (id, title, slug, youtube_id, duration, thumbnail, category_name, views)
VALUES (1, 'Liputan Khusus: Akselerasi Infrastruktur Nasional dan Konektivitas Daerah', NULL, 'ScMzIvxBSi4', NULL, NULL, NULL, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO videos (id, title, slug, youtube_id, duration, thumbnail, category_name, views)
VALUES (2, 'Inovasi Kampus Indonesia: Pengolahan Limbah Organik Jadi Filter Air Bersih', NULL, 'kXYiU_JCYtU', NULL, NULL, NULL, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO videos (id, title, slug, youtube_id, duration, thumbnail, category_name, views)
VALUES (3, 'Semangat Atlet Daerah Matangkan Persiapan Menuju Kejuaraan Nasional', NULL, 'kJQP7kiw5Fk', NULL, NULL, NULL, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO videos (id, title, slug, youtube_id, duration, thumbnail, category_name, views)
VALUES (4, 'Potret Ekonomi Kreatif & Kebangkitan UMKM Nusantara di Era Digital', NULL, 'aqz-KE-bpKQ', NULL, NULL, NULL, 0)
ON CONFLICT (id) DO NOTHING;

-- Inisialisasi Struktur Redaksi
INSERT INTO editorial_team (id, name, role, bio, avatar, sort_order)
VALUES (1, 'Dr. H. Ahmad Fauzan, S.H., M.H.', NULL, NULL, NULL, 1)
ON CONFLICT (id) DO NOTHING;
INSERT INTO editorial_team (id, name, role, bio, avatar, sort_order)
VALUES (2, 'H. Surya Dharmawan', NULL, NULL, NULL, 2)
ON CONFLICT (id) DO NOTHING;
INSERT INTO editorial_team (id, name, role, bio, avatar, sort_order)
VALUES (3, 'Rama Pratama, S.I.Kom.', NULL, NULL, NULL, 3)
ON CONFLICT (id) DO NOTHING;
INSERT INTO editorial_team (id, name, role, bio, avatar, sort_order)
VALUES (4, 'Dian Kusuma, S.Sos.', NULL, NULL, NULL, 4)
ON CONFLICT (id) DO NOTHING;
INSERT INTO editorial_team (id, name, role, bio, avatar, sort_order)
VALUES (5, 'Fajar Nugroho', NULL, NULL, NULL, 5)
ON CONFLICT (id) DO NOTHING;
INSERT INTO editorial_team (id, name, role, bio, avatar, sort_order)
VALUES (6, 'Rina Marlina, S.E.', NULL, NULL, NULL, 6)
ON CONFLICT (id) DO NOTHING;
INSERT INTO editorial_team (id, name, role, bio, avatar, sort_order)
VALUES (7, 'Bagas Saputra', NULL, NULL, NULL, 7)
ON CONFLICT (id) DO NOTHING;

-- Inisialisasi Slot Iklan
INSERT INTO ads (id, title, position, type, image_url, target_url, is_active)
VALUES (1, 'Ruang Iklan & Advertorial Resmi Media Four Tribuan News', 'home_middle', 'banner', NULL, '/tentang#kontak', TRUE)
ON CONFLICT (id) DO NOTHING;
INSERT INTO ads (id, title, position, type, image_url, target_url, is_active)
VALUES (2, 'Kemitraan Liputan & Publikasi Instansi Nasional', 'sidebar', 'banner', NULL, '/tentang#kontak', TRUE)
ON CONFLICT (id) DO NOTHING;

-- Inisialisasi Komentar Awal
INSERT INTO comments (id, article_id, article_slug, name, email, content, is_approved)
VALUES (1, 1, NULL, 'Budi Santoso', 'budi@example.com', NULL, FALSE)
ON CONFLICT (id) DO NOTHING;
INSERT INTO comments (id, article_id, article_slug, name, email, content, is_approved)
VALUES (2, 1, NULL, 'Nadia Putri', 'nadia@example.com', NULL, FALSE)
ON CONFLICT (id) DO NOTHING;
INSERT INTO comments (id, article_id, article_slug, name, email, content, is_approved)
VALUES (3, 1, NULL, 'Hendra Wijaya', 'hendra@example.com', NULL, FALSE)
ON CONFLICT (id) DO NOTHING;

-- Reset sequence IDs agar auto-increment berjalan normal
SELECT setval('categories_id_seq', (SELECT COALESCE(MAX(id), 1) FROM categories));
SELECT setval('articles_id_seq', (SELECT COALESCE(MAX(id), 1) FROM articles));
SELECT setval('videos_id_seq', (SELECT COALESCE(MAX(id), 1) FROM videos));
SELECT setval('comments_id_seq', (SELECT COALESCE(MAX(id), 1) FROM comments));
SELECT setval('editorial_team_id_seq', (SELECT COALESCE(MAX(id), 1) FROM editorial_team));
SELECT setval('ads_id_seq', (SELECT COALESCE(MAX(id), 1) FROM ads));
SELECT setval('admin_users_id_seq', (SELECT COALESCE(MAX(id), 1) FROM admin_users));
