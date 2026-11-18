package db

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	"golang.org/x/crypto/bcrypt"

	"mediafourtribuannews/backend/internal/models"
)

// PersistedUser wraps models.User and persists the bcrypt password hash safely on disk.
type PersistedUser struct {
	models.User
	PasswordHash string `json:"password_hash"`
}

type DatabaseData struct {
	NextIDs       map[string]int64         `json:"next_ids"`
	Users         []PersistedUser          `json:"users"`
	Categories    []models.Category        `json:"categories"`
	Articles      []models.Article         `json:"articles"`
	Videos        []models.Video           `json:"videos"`
	Comments      []models.Comment         `json:"comments"`
	EditorialTeam []models.EditorialMember `json:"editorial_team"`
	Ads           []models.Ad              `json:"ads"`
	Settings      map[string]string        `json:"settings"`
}

type Store struct {
	Mu       sync.RWMutex
	Driver   string
	FilePath string
	Data     DatabaseData
}

func Connect() (*Store, error) {
	filePath := os.Getenv("DB_FILE")
	if filePath == "" {
		filePath = "./data/mftn-db.json"
	}
	if err := os.MkdirAll(filepath.Dir(filePath), 0o755); err != nil {
		return nil, fmt.Errorf("mkdir data dir: %w", err)
	}

	s := &Store{
		Driver:   "embedded-json",
		FilePath: filePath,
		Data: DatabaseData{
			NextIDs:  map[string]int64{},
			Settings: map[string]string{},
		},
	}

	if raw, err := os.ReadFile(filePath); err == nil && len(raw) > 0 {
		if err := json.Unmarshal(raw, &s.Data); err != nil {
			return nil, fmt.Errorf("parse db file: %w", err)
		}
		if s.Data.NextIDs == nil {
			s.Data.NextIDs = map[string]int64{}
		}
		if s.Data.Settings == nil {
			s.Data.Settings = map[string]string{}
		}
	}

	if err := s.seedIfEmpty(); err != nil {
		return nil, err
	}
	return s, nil
}

func (s *Store) Close() error {
	return nil
}

// NextID returns a monotonically increasing ID for a collection (caller must hold write lock).
func (s *Store) NextID(table string) int64 {
	s.Data.NextIDs[table]++
	return s.Data.NextIDs[table]
}

// SaveLocked writes the current database state atomically (caller must hold write lock).
func (s *Store) SaveLocked() error {
	raw, err := json.MarshalIndent(s.Data, "", "  ")
	if err != nil {
		return err
	}
	tmp := s.FilePath + ".tmp"
	if err := os.WriteFile(tmp, raw, 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, s.FilePath)
}

type seedArticle struct {
	Title        string   `json:"title"`
	Slug         string   `json:"slug"`
	Excerpt      string   `json:"excerpt"`
	Content      string   `json:"content"`
	Image        string   `json:"image"`
	Caption      string   `json:"caption"`
	Category     string   `json:"category"`
	CategorySlug string   `json:"categorySlug"`
	Author       string   `json:"author"`
	Views        string   `json:"views"`
	ReadTime     string   `json:"readTime"`
	IsHero       bool     `json:"isHero"`
	Tags         []string `json:"tags"`
}

func parseViews(v string) int64 {
	clean := strings.ReplaceAll(strings.TrimSpace(v), ".", "")
	clean = strings.ReplaceAll(clean, ",", "")
	n, _ := strconv.ParseInt(clean, 10, 64)
	if n == 0 {
		return 150
	}
	return n
}

func (s *Store) seedIfEmpty() error {
	s.Mu.Lock()
	defer s.Mu.Unlock()

	dirty := false
	now := time.Now()

	if len(s.Data.Users) == 0 {
		adminPass, _ := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
		editorPass, _ := bcrypt.GenerateFromPassword([]byte("editor123"), bcrypt.DefaultCost)
		s.Data.Users = []PersistedUser{
			{
				User: models.User{
					ID: 1, Name: "Admin Redaksi", Email: "admin@mediafourtribuannews.id",
					Role: "Administrator", Status: "active", Avatar: "/uploads/logo/logo-mftn.jpg",
					Bio: "Administrator & Penanggung Jawab Portal Media Four Tribuan News Nasional.",
					CreatedAt: now, UpdatedAt: now,
				},
				PasswordHash: string(adminPass),
			},
			{
				User: models.User{
					ID: 2, Name: "Rama Pratama", Email: "redaksi@mediafourtribuannews.id",
					Role: "Editor", Status: "active", Avatar: "/uploads/logo/logo-mftn.jpg",
					Bio: "Redaktur Pelaksana Nasional Media Four Tribuan News.",
					CreatedAt: now, UpdatedAt: now,
				},
				PasswordHash: string(editorPass),
			},
			{
				User: models.User{
					ID: 3, Name: "Siti Rahmawati", Email: "reporter@mediafourtribuannews.id",
					Role: "Reporter", Status: "active", Avatar: "/uploads/logo/logo-mftn.jpg",
					Bio: "Koresponden Lapangan Nasional & Daerah.",
					CreatedAt: now, UpdatedAt: now,
				},
				PasswordHash: string(editorPass),
			},
		}
		s.Data.NextIDs["users"] = 3
		dirty = true
		log.Println("Seeded default users (admin@mediafourtribuannews.id / admin123)")
	}

	if len(s.Data.Categories) == 0 {
		cats := [][3]string{
			{"Nasional", "nasional", "Berita peristiwa nasional, pemerintahan, kebijakan publik, dan kenegaraan"},
			{"Daerah", "daerah", "Kabar kedaerahan, otonomi daerah, dan laporan biro wilayah nusantara"},
			{"Politik", "politik", "Dinamika parlemen, demokrasi, pemilu, dan kebijakan strategis"},
			{"Hukum", "hukum", "Liputan penegakan hukum, kepolisian, peradilan, dan keamanan masyarakat"},
			{"Ekonomi", "ekonomi", "Makroekonomi, fiskal, inflasi, komoditas, dan perbankan"},
			{"Bisnis", "bisnis", "Pergerakan pasar, korporasi, UMKM, dan investasi"},
			{"Pendidikan", "pendidikan", "Dunia kampus, sekolah, beasiswa, dan inovasi kurikulum"},
			{"Teknologi", "teknologi", "Transformasi digital, sains terapan, AI, dan telekomunikasi"},
			{"Olahraga", "olahraga", "Kompetisi olahraga nasional, sepak bola, dan prestasi atlet"},
			{"Internasional", "internasional", "Diplomasi dunia, geopolitik global, dan kabar mancanegara"},
			{"Opini", "opini", "Kolom gagasan, analisis kritis akademisi, dan ruang pandang publik"},
			{"Editorial", "editorial", "Tajuk rencana dan sikap resmi dewan redaksi Media Four Tribuan News"},
			{"Foto", "foto", "Galeri visual jurnalistik lensa peristiwa terkini"},
			{"Video", "video", "Kanal tayangan liputan multimedia Media Four Tribuan News"},
			{"Tokoh", "tokoh", "Profil figur inspiratif, pemimpin publik, dan cendekiawan"},
		}
		for i, c := range cats {
			s.Data.Categories = append(s.Data.Categories, models.Category{
				ID: int64(i + 1), Name: c[0], Slug: c[1], Description: c[2], CreatedAt: now,
			})
		}
		s.Data.NextIDs["categories"] = int64(len(cats))
		dirty = true
	}

	if len(s.Data.Articles) == 0 {
		catBySlug := map[string]models.Category{}
		for _, c := range s.Data.Categories {
			catBySlug[c.Slug] = c
		}
		defCat := s.Data.Categories[0]

		if seedBytes, err := os.ReadFile("./seed/articles.json"); err == nil {
			var items []seedArticle
			if err := json.Unmarshal(seedBytes, &items); err == nil {
				seenSlugs := map[string]bool{}
				for idx, item := range items {
					if seenSlugs[item.Slug] {
						continue
					}
					seenSlugs[item.Slug] = true
					c, ok := catBySlug[strings.ToLower(item.CategorySlug)]
					if !ok {
						c = defCat
					}
					pubAt := now.Add(-time.Duration(idx*3) * time.Hour)
					author := s.Data.Users[idx%len(s.Data.Users)]
					editorID := int64(1)
					rt := item.ReadTime
					if rt == "" {
						rt = "3 menit baca"
					}
					id := s.NextID("articles")
					s.Data.Articles = append(s.Data.Articles, models.Article{
						ID:           id,
						CategoryID:   c.ID,
						CategoryName: c.Name,
						CategorySlug: c.Slug,
						AuthorID:     author.ID,
						AuthorName:   author.Name,
						AuthorAvatar: author.Avatar,
						EditorID:     &editorID,
						EditorName:   "Admin Redaksi",
						Title:        item.Title,
						Slug:         item.Slug,
						Excerpt:      item.Excerpt,
						Content:      item.Content,
						Thumbnail:    item.Image,
						Caption:      item.Caption,
						Tags:         strings.Join(item.Tags, ", "),
						Status:       "published",
						Views:        parseViews(item.Views),
						IsFeatured:   item.IsHero || idx < 5,
						ReadTime:     rt,
						PublishedAt:  pubAt,
						UpdatedAt:    pubAt,
					})
				}
				dirty = true
				log.Printf("Seeded %d articles", len(s.Data.Articles))
			}
		}
	}

	if len(s.Data.Videos) == 0 {
		s.Data.Videos = []models.Video{
			{ID: 1, Title: "Liputan Khusus: Akselerasi Infrastruktur Nasional dan Konektivitas Daerah", YoutubeURL: "https://www.youtube.com/watch?v=ScMzIvxBSi4", YoutubeID: "ScMzIvxBSi4", Caption: "Laporan mendalam tim multimedia Media Four Tribuan News mengenai perkembangan proyek konektivitas strategis di berbagai provinsi.", IsActive: true, CreatedAt: now},
			{ID: 2, Title: "Inovasi Kampus Indonesia: Pengolahan Limbah Organik Jadi Filter Air Bersih", YoutubeURL: "https://www.youtube.com/watch?v=kXYiU_JCYtU", YoutubeID: "kXYiU_JCYtU", Caption: "Dokumentasi riset terapan mahasiswa dalam menghadirkan solusi air bersih berbiaya rendah untuk masyarakat pedesaan.", IsActive: true, CreatedAt: now},
			{ID: 3, Title: "Semangat Atlet Daerah Matangkan Persiapan Menuju Kejuaraan Nasional", YoutubeURL: "https://www.youtube.com/watch?v=kJQP7kiw5Fk", YoutubeID: "kJQP7kiw5Fk", Caption: "Liputan eksklusif pemusatan latihan cabang olahraga unggulan berbasis sport science.", IsActive: true, CreatedAt: now},
			{ID: 4, Title: "Potret Ekonomi Kreatif & Kebangkitan UMKM Nusantara di Era Digital", YoutubeURL: "https://www.youtube.com/watch?v=aqz-KE-bpKQ", YoutubeID: "aqz-KE-bpKQ", Caption: "Kisah pelaku usaha kecil dan menengah yang sukses menembus pasar ekspor lewat digitalisasi.", IsActive: true, CreatedAt: now},
		}
		s.Data.NextIDs["videos"] = 4
		dirty = true
	}

	if len(s.Data.Comments) == 0 && len(s.Data.Articles) > 0 {
		first := s.Data.Articles[0]
		s.Data.Comments = []models.Comment{
			{ID: 1, ArticleID: first.ID, Name: "Budi Santoso", Email: "budi@example.com", Comment: "Liputan yang sangat informatif dan berimbang. Semoga Media Four Tribuan News terus konsisten menyajikan berita aktual dan independen.", Status: "approved", CreatedAt: now.Add(-2 * time.Hour)},
			{ID: 2, ArticleID: first.ID, Name: "Nadia Putri", Email: "nadia@example.com", Comment: "Tampilan mobile-nya ringan sekali dibaca di HP! Ditunggu laporan investigasi berikutnya.", Status: "approved", CreatedAt: now.Add(-1 * time.Hour)},
			{ID: 3, ArticleID: first.ID, Name: "Hendra Wijaya", Email: "hendra@example.com", Comment: "Mohon sertakan juga data perbandingan anggaran tahun sebelumnya agar lebih komprehensif.", Status: "pending", CreatedAt: now.Add(-20 * time.Minute)},
		}
		s.Data.NextIDs["comments"] = 3
		dirty = true
	}

	if len(s.Data.EditorialTeam) == 0 {
		s.Data.EditorialTeam = []models.EditorialMember{
			{ID: 1, Name: "Dr. H. Ahmad Fauzan, S.H., M.H.", Position: "Penasihat Hukum & Dewan Etik", Division: "Penasihat & Pembina", Description: "Konsultan Hukum Pers & Kode Etik Jurnalistik", Email: "hukum@mediafourtribuannews.id", Phone: "0812-0000-4401", SortOrder: 1, Status: "active", CreatedAt: now},
			{ID: 2, Name: "H. Surya Dharmawan", Position: "Pemimpin Umum / Direktur Utama", Division: "Pimpinan Perusahaan", Description: "PT Media Four Tribuan Nusantara", Email: "pimpinan@mediafourtribuannews.id", Phone: "0812-0000-4402", SortOrder: 2, Status: "active", CreatedAt: now},
			{ID: 3, Name: "Rama Pratama, S.I.Kom.", Position: "Pemimpin Redaksi / Penanggung Jawab", Division: "Pimpinan Redaksi", Description: "Pemegang Sertifikat UKW Utama Dewan Pers", Email: "pemred@mediafourtribuannews.id", Phone: "0812-0000-4403", SortOrder: 3, Status: "active", CreatedAt: now},
			{ID: 4, Name: "Dian Kusuma, S.Sos.", Position: "Redaktur Pelaksana", Division: "Redaktur", Description: "Koordinator Meja Redaksi Nasional", Email: "redpel@mediafourtribuannews.id", Phone: "0812-0000-4404", SortOrder: 4, Status: "active", CreatedAt: now},
			{ID: 5, Name: "Fajar Nugroho", Position: "Redaktur Politik & Hukum", Division: "Redaktur", Description: "Koordinator Liputan Parlemen & Hukum", Email: "politik@mediafourtribuannews.id", Phone: "0812-0000-4405", SortOrder: 5, Status: "active", CreatedAt: now},
			{ID: 6, Name: "Rina Marlina, S.E.", Position: "Redaktur Ekonomi & Bisnis", Division: "Redaktur", Description: "Analis Ekonomi Makro & UMKM Nusantara", Email: "ekonomi@mediafourtribuannews.id", Phone: "0812-0000-4406", SortOrder: 6, Status: "active", CreatedAt: now},
			{ID: 7, Name: "Bagas Saputra", Position: "Kepala IT & Multimedia Digital", Division: "Teknologi & Multimedia", Description: "Pengembangan Platform, Video & Keamanan Siber", Email: "tech@mediafourtribuannews.id", Phone: "0812-0000-4407", SortOrder: 7, Status: "active", CreatedAt: now},
		}
		s.Data.NextIDs["editorial_team"] = 7
		dirty = true
	}

	if len(s.Data.Ads) == 0 {
		s.Data.Ads = []models.Ad{
			{ID: 1, Title: "Ruang Iklan & Advertorial Resmi Media Four Tribuan News", Type: "banner", Position: "home_middle", TargetDevice: "all", TargetPage: "home", Image: "/uploads/berita/ekonomi/panen-kopi-gayo-organik.jpg", TargetURL: "/tentang#kontak", Description: "Promosikan brand, instansi, atau produk UMKM Anda menjangkau pembaca nasional.", IsActive: true, SortOrder: 1, CreatedAt: now},
			{ID: 2, Title: "Kemitraan Liputan & Publikasi Instansi Nasional", Type: "banner", Position: "sidebar", TargetDevice: "all", TargetPage: "article", Image: "/uploads/berita/nasional/kantor-pusat-bsi-landmark-aceh.jpg", TargetURL: "/tentang#kontak", Description: "Hubungi tim iklan & kerja sama redaksi Media Four Tribuan News.", IsActive: true, SortOrder: 2, CreatedAt: now},
		}
		s.Data.NextIDs["ads"] = 2
		dirty = true
	}

	if len(s.Data.Settings) == 0 {
		s.Data.Settings = map[string]string{
			"site_title":       "Media Four Tribuan News",
			"site_subtitle":    "NASIONAL",
			"site_tagline":     "Aktual • Terpercaya • Independen",
			"site_description": "Portal Berita Nasional Media Four Tribuan News menyajikan kabar aktual, terpercaya, dan independen seputar nasional, daerah, politik, hukum, ekonomi, olahraga, dan teknologi.",
			"company_name":     "PT Media Four Tribuan Nusantara",
			"hotline_phone":    "0812-3456-7890",
			"whatsapp_number":  "6281234567890",
			"redaksi_email":    "redaksi@mediafourtribuannews.id",
			"office_address":   "Gedung Graha Tribuan Pers Lt. 3, Jl. Merdeka Nasional No. 44, Jakarta Pusat, Indonesia",
			"facebook_url":     "https://facebook.com",
			"instagram_url":    "https://instagram.com",
			"twitter_url":      "https://x.com",
			"youtube_url":      "https://youtube.com",
		}
		dirty = true
	}

	if dirty {
		return s.SaveLocked()
	}
	return nil
}
