package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"golang.org/x/crypto/bcrypt"

	"mediafourtribuannews/backend/internal/db"
	"mediafourtribuannews/backend/internal/models"
)

// ==================== CATEGORIES ====================

func (a *API) ListCategories(w http.ResponseWriter, r *http.Request) {
	a.Store.Mu.RLock()
	defer a.Store.Mu.RUnlock()

	counts := map[int64]int64{}
	for _, art := range a.Store.Data.Articles {
		if art.Status == "published" {
			counts[art.CategoryID]++
		}
	}
	list := make([]models.Category, 0, len(a.Store.Data.Categories))
	for _, c := range a.Store.Data.Categories {
		c.ArticleCount = counts[c.ID]
		list = append(list, c)
	}
	writeJSON(w, http.StatusOK, map[string]any{"data": list})
}

func (a *API) CreateCategory(w http.ResponseWriter, r *http.Request) {
	var in struct {
		Name        string `json:"name"`
		Slug        string `json:"slug"`
		Description string `json:"description"`
	}
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil || strings.TrimSpace(in.Name) == "" {
		writeError(w, http.StatusBadRequest, "Nama kategori wajib diisi")
		return
	}
	if in.Slug == "" {
		in.Slug = slugify(in.Name)
	} else {
		in.Slug = slugify(in.Slug)
	}

	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()
	for _, c := range a.Store.Data.Categories {
		if c.Slug == in.Slug {
			writeError(w, http.StatusBadRequest, "Slug kategori sudah digunakan")
			return
		}
	}
	c := models.Category{
		ID:          a.Store.NextID("categories"),
		Name:        strings.TrimSpace(in.Name),
		Slug:        in.Slug,
		Description: in.Description,
		CreatedAt:   time.Now(),
	}
	a.Store.Data.Categories = append(a.Store.Data.Categories, c)
	_ = a.Store.SaveLocked()
	writeJSON(w, http.StatusCreated, c)
}

func (a *API) UpdateCategory(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	var in struct {
		Name        string `json:"name"`
		Slug        string `json:"slug"`
		Description string `json:"description"`
	}
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil || strings.TrimSpace(in.Name) == "" {
		writeError(w, http.StatusBadRequest, "Nama kategori wajib diisi")
		return
	}
	if in.Slug == "" {
		in.Slug = slugify(in.Name)
	} else {
		in.Slug = slugify(in.Slug)
	}
	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()
	for i := range a.Store.Data.Categories {
		if a.Store.Data.Categories[i].ID == id {
			a.Store.Data.Categories[i].Name = strings.TrimSpace(in.Name)
			a.Store.Data.Categories[i].Slug = in.Slug
			a.Store.Data.Categories[i].Description = in.Description
			_ = a.Store.SaveLocked()
			writeJSON(w, http.StatusOK, map[string]string{"message": "Kategori diperbarui"})
			return
		}
	}
	writeError(w, http.StatusNotFound, "Kategori tidak ditemukan")
}

func (a *API) DeleteCategory(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()
	kept := make([]models.Category, 0, len(a.Store.Data.Categories))
	for _, c := range a.Store.Data.Categories {
		if c.ID != id {
			kept = append(kept, c)
		}
	}
	a.Store.Data.Categories = kept
	_ = a.Store.SaveLocked()
	writeJSON(w, http.StatusOK, map[string]string{"message": "Kategori dihapus"})
}

// ==================== VIDEOS ====================

func (a *API) ListVideos(w http.ResponseWriter, r *http.Request) {
	onlyActive := !strings.HasPrefix(r.URL.Path, "/api/admin")
	a.Store.Mu.RLock()
	defer a.Store.Mu.RUnlock()
	list := make([]models.Video, 0)
	for _, v := range a.Store.Data.Videos {
		if onlyActive && !v.IsActive {
			continue
		}
		list = append(list, v)
	}
	sort.Slice(list, func(i, j int) bool { return list[i].ID > list[j].ID })
	writeJSON(w, http.StatusOK, map[string]any{"data": list})
}

func (a *API) CreateVideo(w http.ResponseWriter, r *http.Request) {
	var in struct {
		Title      string `json:"title"`
		YoutubeURL string `json:"youtube_url"`
		Caption    string `json:"caption"`
		IsActive   *bool  `json:"is_active"`
	}
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil || strings.TrimSpace(in.Title) == "" || strings.TrimSpace(in.YoutubeURL) == "" {
		writeError(w, http.StatusBadRequest, "Judul dan URL YouTube wajib diisi")
		return
	}
	active := true
	if in.IsActive != nil {
		active = *in.IsActive
	}
	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()
	v := models.Video{
		ID:         a.Store.NextID("videos"),
		Title:      in.Title,
		YoutubeURL: in.YoutubeURL,
		YoutubeID:  extractYoutubeID(in.YoutubeURL),
		Caption:    in.Caption,
		IsActive:   active,
		CreatedAt:  time.Now(),
	}
	a.Store.Data.Videos = append(a.Store.Data.Videos, v)
	_ = a.Store.SaveLocked()
	writeJSON(w, http.StatusCreated, v)
}

func (a *API) UpdateVideo(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	var in struct {
		Title      string `json:"title"`
		YoutubeURL string `json:"youtube_url"`
		Caption    string `json:"caption"`
		IsActive   bool   `json:"is_active"`
	}
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		writeError(w, http.StatusBadRequest, "Payload tidak valid")
		return
	}
	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()
	for i := range a.Store.Data.Videos {
		if a.Store.Data.Videos[i].ID == id {
			a.Store.Data.Videos[i].Title = in.Title
			a.Store.Data.Videos[i].YoutubeURL = in.YoutubeURL
			a.Store.Data.Videos[i].YoutubeID = extractYoutubeID(in.YoutubeURL)
			a.Store.Data.Videos[i].Caption = in.Caption
			a.Store.Data.Videos[i].IsActive = in.IsActive
			_ = a.Store.SaveLocked()
			writeJSON(w, http.StatusOK, map[string]string{"message": "Video diperbarui"})
			return
		}
	}
	writeError(w, http.StatusNotFound, "Video tidak ditemukan")
}

func (a *API) DeleteVideo(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()
	kept := make([]models.Video, 0, len(a.Store.Data.Videos))
	for _, v := range a.Store.Data.Videos {
		if v.ID != id {
			kept = append(kept, v)
		}
	}
	a.Store.Data.Videos = kept
	_ = a.Store.SaveLocked()
	writeJSON(w, http.StatusOK, map[string]string{"message": "Video dihapus"})
}

// ==================== COMMENTS ====================

func (a *API) CreateComment(w http.ResponseWriter, r *http.Request) {
	var in struct {
		ArticleID int64  `json:"article_id"`
		Name      string `json:"name"`
		Email     string `json:"email"`
		Comment   string `json:"comment"`
	}
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		writeError(w, http.StatusBadRequest, "Format tidak valid")
		return
	}
	if in.ArticleID == 0 || strings.TrimSpace(in.Name) == "" || strings.TrimSpace(in.Comment) == "" {
		writeError(w, http.StatusBadRequest, "Nama dan komentar wajib diisi")
		return
	}
	if strings.TrimSpace(in.Email) == "" {
		in.Email = "pembaca@mediafourtribuannews.id"
	}
	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()
	cm := models.Comment{
		ID:        a.Store.NextID("comments"),
		ArticleID: in.ArticleID,
		Name:      strings.TrimSpace(in.Name),
		Email:     strings.TrimSpace(in.Email),
		Comment:   strings.TrimSpace(in.Comment),
		Status:    "approved",
		IPAddress: r.RemoteAddr,
		CreatedAt: time.Now(),
	}
	a.Store.Data.Comments = append(a.Store.Data.Comments, cm)
	_ = a.Store.SaveLocked()
	writeJSON(w, http.StatusCreated, map[string]any{"data": cm})
}

func (a *API) ListAdminComments(w http.ResponseWriter, r *http.Request) {
	status := strings.TrimSpace(r.URL.Query().Get("status"))
	a.Store.Mu.RLock()
	defer a.Store.Mu.RUnlock()

	artMap := map[int64]models.Article{}
	for _, ar := range a.Store.Data.Articles {
		artMap[ar.ID] = ar
	}

	list := make([]models.Comment, 0)
	for _, c := range a.Store.Data.Comments {
		if status != "" && status != "all" && c.Status != status {
			continue
		}
		if ar, ok := artMap[c.ArticleID]; ok {
			c.ArticleTitle = ar.Title
			c.ArticleSlug = ar.Slug
		}
		list = append(list, c)
	}
	sort.Slice(list, func(i, j int) bool { return list[i].CreatedAt.After(list[j].CreatedAt) })
	writeJSON(w, http.StatusOK, map[string]any{"data": list})
}

func (a *API) UpdateCommentStatus(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	var in struct {
		Status string `json:"status"`
	}
	_ = json.NewDecoder(r.Body).Decode(&in)
	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()
	for i := range a.Store.Data.Comments {
		if a.Store.Data.Comments[i].ID == id {
			a.Store.Data.Comments[i].Status = in.Status
			_ = a.Store.SaveLocked()
			break
		}
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "Status komentar diperbarui"})
}

func (a *API) DeleteComment(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()
	kept := make([]models.Comment, 0, len(a.Store.Data.Comments))
	for _, c := range a.Store.Data.Comments {
		if c.ID != id {
			kept = append(kept, c)
		}
	}
	a.Store.Data.Comments = kept
	_ = a.Store.SaveLocked()
	writeJSON(w, http.StatusOK, map[string]string{"message": "Komentar dihapus"})
}

// ==================== EDITORIAL TEAM ====================

func (a *API) ListEditorial(w http.ResponseWriter, r *http.Request) {
	a.Store.Mu.RLock()
	list := append([]models.EditorialMember{}, a.Store.Data.EditorialTeam...)
	a.Store.Mu.RUnlock()
	sort.Slice(list, func(i, j int) bool {
		if list[i].SortOrder != list[j].SortOrder {
			return list[i].SortOrder < list[j].SortOrder
		}
		return list[i].ID < list[j].ID
	})
	writeJSON(w, http.StatusOK, map[string]any{"data": list})
}

func (a *API) CreateEditorial(w http.ResponseWriter, r *http.Request) {
	var in models.EditorialMember
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil || strings.TrimSpace(in.Name) == "" {
		writeError(w, http.StatusBadRequest, "Nama dan jabatan wajib diisi")
		return
	}
	if in.Division == "" {
		in.Division = "Redaksi"
	}
	if in.Status == "" {
		in.Status = "active"
	}
	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()
	in.ID = a.Store.NextID("editorial_team")
	in.CreatedAt = time.Now()
	a.Store.Data.EditorialTeam = append(a.Store.Data.EditorialTeam, in)
	_ = a.Store.SaveLocked()
	writeJSON(w, http.StatusCreated, in)
}

func (a *API) UpdateEditorial(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	var in models.EditorialMember
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		writeError(w, http.StatusBadRequest, "Payload tidak valid")
		return
	}
	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()
	for i := range a.Store.Data.EditorialTeam {
		if a.Store.Data.EditorialTeam[i].ID == id {
			in.ID = id
			in.CreatedAt = a.Store.Data.EditorialTeam[i].CreatedAt
			a.Store.Data.EditorialTeam[i] = in
			_ = a.Store.SaveLocked()
			writeJSON(w, http.StatusOK, map[string]string{"message": "Data redaksi diperbarui"})
			return
		}
	}
	writeError(w, http.StatusNotFound, "Tidak ditemukan")
}

func (a *API) DeleteEditorial(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()
	kept := make([]models.EditorialMember, 0, len(a.Store.Data.EditorialTeam))
	for _, m := range a.Store.Data.EditorialTeam {
		if m.ID != id {
			kept = append(kept, m)
		}
	}
	a.Store.Data.EditorialTeam = kept
	_ = a.Store.SaveLocked()
	writeJSON(w, http.StatusOK, map[string]string{"message": "Anggota redaksi dihapus"})
}

// ==================== ADS ====================

func (a *API) ListAds(w http.ResponseWriter, r *http.Request) {
	onlyActive := !strings.HasPrefix(r.URL.Path, "/api/admin")
	a.Store.Mu.RLock()
	defer a.Store.Mu.RUnlock()
	list := make([]models.Ad, 0)
	for _, ad := range a.Store.Data.Ads {
		if onlyActive && !ad.IsActive {
			continue
		}
		list = append(list, ad)
	}
	sort.Slice(list, func(i, j int) bool { return list[i].SortOrder < list[j].SortOrder })
	writeJSON(w, http.StatusOK, map[string]any{"data": list})
}

func (a *API) CreateAd(w http.ResponseWriter, r *http.Request) {
	var in models.Ad
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil || strings.TrimSpace(in.Title) == "" {
		writeError(w, http.StatusBadRequest, "Judul iklan wajib diisi")
		return
	}
	if in.Type == "" {
		in.Type = "banner"
	}
	if in.Position == "" {
		in.Position = "home_middle"
	}
	if in.TargetDevice == "" {
		in.TargetDevice = "all"
	}
	if in.TargetPage == "" {
		in.TargetPage = "all"
	}
	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()
	in.ID = a.Store.NextID("ads")
	in.CreatedAt = time.Now()
	a.Store.Data.Ads = append(a.Store.Data.Ads, in)
	_ = a.Store.SaveLocked()
	writeJSON(w, http.StatusCreated, in)
}

func (a *API) UpdateAd(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	var in models.Ad
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		writeError(w, http.StatusBadRequest, "Payload tidak valid")
		return
	}
	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()
	for i := range a.Store.Data.Ads {
		if a.Store.Data.Ads[i].ID == id {
			in.ID = id
			in.CreatedAt = a.Store.Data.Ads[i].CreatedAt
			a.Store.Data.Ads[i] = in
			_ = a.Store.SaveLocked()
			writeJSON(w, http.StatusOK, map[string]string{"message": "Iklan diperbarui"})
			return
		}
	}
	writeError(w, http.StatusNotFound, "Iklan tidak ditemukan")
}

func (a *API) DeleteAd(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()
	kept := make([]models.Ad, 0, len(a.Store.Data.Ads))
	for _, ad := range a.Store.Data.Ads {
		if ad.ID != id {
			kept = append(kept, ad)
		}
	}
	a.Store.Data.Ads = kept
	_ = a.Store.SaveLocked()
	writeJSON(w, http.StatusOK, map[string]string{"message": "Iklan dihapus"})
}

// ==================== USERS ====================

func (a *API) ListUsers(w http.ResponseWriter, r *http.Request) {
	a.Store.Mu.RLock()
	defer a.Store.Mu.RUnlock()
	list := make([]models.User, 0, len(a.Store.Data.Users))
	for _, u := range a.Store.Data.Users {
		list = append(list, u.User)
	}
	writeJSON(w, http.StatusOK, map[string]any{"data": list})
}

func (a *API) CreateUser(w http.ResponseWriter, r *http.Request) {
	var in struct {
		Name     string `json:"name"`
		Email    string `json:"email"`
		Password string `json:"password"`
		Role     string `json:"role"`
		Status   string `json:"status"`
		Bio      string `json:"bio"`
	}
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil || strings.TrimSpace(in.Name) == "" || strings.TrimSpace(in.Email) == "" || len(in.Password) < 6 {
		writeError(w, http.StatusBadRequest, "Nama, email, dan password minimal 6 karakter wajib diisi")
		return
	}
	email := strings.ToLower(strings.TrimSpace(in.Email))
	if in.Role == "" {
		in.Role = "Reporter"
	}
	if in.Status == "" {
		in.Status = "active"
	}
	hash, _ := bcrypt.GenerateFromPassword([]byte(in.Password), bcrypt.DefaultCost)

	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()
	for _, u := range a.Store.Data.Users {
		if strings.ToLower(u.Email) == email {
			writeError(w, http.StatusBadRequest, "Email sudah terdaftar")
			return
		}
	}
	now := time.Now()
	pu := db.PersistedUser{
		User: models.User{
			ID: a.Store.NextID("users"), Name: strings.TrimSpace(in.Name), Email: email,
			Role: in.Role, Status: in.Status, Avatar: "/uploads/logo/logo-mftn.jpg", Bio: in.Bio,
			CreatedAt: now, UpdatedAt: now,
		},
		PasswordHash: string(hash),
	}
	a.Store.Data.Users = append(a.Store.Data.Users, pu)
	_ = a.Store.SaveLocked()
	writeJSON(w, http.StatusCreated, pu.User)
}

func (a *API) UpdateUser(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	var in struct {
		Name     string `json:"name"`
		Email    string `json:"email"`
		Password string `json:"password"`
		Role     string `json:"role"`
		Status   string `json:"status"`
		Bio      string `json:"bio"`
	}
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		writeError(w, http.StatusBadRequest, "Payload tidak valid")
		return
	}
	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()
	for i := range a.Store.Data.Users {
		if a.Store.Data.Users[i].ID == id {
			a.Store.Data.Users[i].Name = in.Name
			a.Store.Data.Users[i].Email = strings.ToLower(strings.TrimSpace(in.Email))
			a.Store.Data.Users[i].Role = in.Role
			a.Store.Data.Users[i].Status = in.Status
			a.Store.Data.Users[i].Bio = in.Bio
			a.Store.Data.Users[i].UpdatedAt = time.Now()
			if strings.TrimSpace(in.Password) != "" {
				hash, _ := bcrypt.GenerateFromPassword([]byte(in.Password), bcrypt.DefaultCost)
				a.Store.Data.Users[i].PasswordHash = string(hash)
			}
			_ = a.Store.SaveLocked()
			writeJSON(w, http.StatusOK, map[string]string{"message": "Pengguna diperbarui"})
			return
		}
	}
	writeError(w, http.StatusNotFound, "Pengguna tidak ditemukan")
}

func (a *API) DeleteUser(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if id == 1 {
		writeError(w, http.StatusBadRequest, "Administrator utama tidak dapat dihapus")
		return
	}
	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()
	kept := make([]db.PersistedUser, 0, len(a.Store.Data.Users))
	for _, u := range a.Store.Data.Users {
		if u.ID != id {
			kept = append(kept, u)
		}
	}
	a.Store.Data.Users = kept
	_ = a.Store.SaveLocked()
	writeJSON(w, http.StatusOK, map[string]string{"message": "Pengguna dihapus"})
}

// ==================== SETTINGS ====================

func (a *API) GetSettings(w http.ResponseWriter, r *http.Request) {
	a.Store.Mu.RLock()
	out := map[string]string{}
	for k, v := range a.Store.Data.Settings {
		out[k] = v
	}
	a.Store.Mu.RUnlock()
	writeJSON(w, http.StatusOK, map[string]any{"data": out})
}

func (a *API) UpdateSettings(w http.ResponseWriter, r *http.Request) {
	var in map[string]string
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		writeError(w, http.StatusBadRequest, "Payload tidak valid")
		return
	}
	a.Store.Mu.Lock()
	for k, v := range in {
		a.Store.Data.Settings[k] = v
	}
	_ = a.Store.SaveLocked()
	a.Store.Mu.Unlock()
	writeJSON(w, http.StatusOK, map[string]string{"message": "Pengaturan disimpan"})
}

// ==================== DASHBOARD ====================

func (a *API) GetDashboard(w http.ResponseWriter, r *http.Request) {
	a.Store.Mu.RLock()
	defer a.Store.Mu.RUnlock()

	var stats models.DashboardStats
	stats.TotalArticles = int64(len(a.Store.Data.Articles))
	stats.TotalCategories = int64(len(a.Store.Data.Categories))
	stats.TotalUsers = int64(len(a.Store.Data.Users))
	stats.TotalVideos = int64(len(a.Store.Data.Videos))
	stats.TotalAds = int64(len(a.Store.Data.Ads))
	stats.TotalComments = int64(len(a.Store.Data.Comments))

	catCounts := map[int64]*models.CategoryStat{}
	for _, c := range a.Store.Data.Categories {
		catCounts[c.ID] = &models.CategoryStat{Name: c.Name, Slug: c.Slug}
	}

	enriched := make([]models.Article, 0, len(a.Store.Data.Articles))
	for _, raw := range a.Store.Data.Articles {
		art := a.enrichArticleLocked(raw)
		enriched = append(enriched, art)
		stats.TotalViews += art.Views
		if art.Status == "published" {
			stats.PublishedArticles++
		} else {
			stats.DraftArticles++
		}
		if cs, ok := catCounts[art.CategoryID]; ok {
			cs.Count++
			cs.Views += art.Views
		}
	}

	for _, cm := range a.Store.Data.Comments {
		if cm.Status == "pending" {
			stats.PendingComments++
		}
	}

	stats.CategoryStats = make([]models.CategoryStat, 0, len(catCounts))
	for _, cs := range catCounts {
		stats.CategoryStats = append(stats.CategoryStats, *cs)
	}
	sort.Slice(stats.CategoryStats, func(i, j int) bool { return stats.CategoryStats[i].Count > stats.CategoryStats[j].Count })
	if len(stats.CategoryStats) > 10 {
		stats.CategoryStats = stats.CategoryStats[:10]
	}

	latest := append([]models.Article{}, enriched...)
	sort.Slice(latest, func(i, j int) bool { return latest[i].PublishedAt.After(latest[j].PublishedAt) })
	if len(latest) > 6 {
		latest = latest[:6]
	}
	stats.LatestArticles = latest

	top := append([]models.Article{}, enriched...)
	sort.Slice(top, func(i, j int) bool { return top[i].Views > top[j].Views })
	if len(top) > 5 {
		top = top[:5]
	}
	stats.TopArticles = top

	recentCm := append([]models.Comment{}, a.Store.Data.Comments...)
	sort.Slice(recentCm, func(i, j int) bool { return recentCm[i].CreatedAt.After(recentCm[j].CreatedAt) })
	if len(recentCm) > 5 {
		recentCm = recentCm[:5]
	}
	stats.RecentComments = recentCm

	writeJSON(w, http.StatusOK, stats)
}

// ==================== UPLOAD & MEDIA ====================

func (a *API) UploadFile(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseMultipartForm(10 << 20); err != nil {
		writeError(w, http.StatusBadRequest, "Ukuran file maksimal 10MB")
		return
	}
	file, header, err := r.FormFile("file")
	if err != nil {
		writeError(w, http.StatusBadRequest, "File tidak ditemukan pada field 'file'")
		return
	}
	defer file.Close()

	ext := strings.ToLower(filepath.Ext(header.Filename))
	switch ext {
	case ".jpg", ".jpeg", ".png", ".webp", ".gif":
	default:
		writeError(w, http.StatusBadRequest, "Format gambar harus JPG, PNG, WEBP, atau GIF")
		return
	}

	dir := filepath.Join("uploads", "berita", "uploads")
	_ = os.MkdirAll(dir, 0o755)
	filename := fmt.Sprintf("mftn_%d%s", time.Now().UnixNano(), ext)
	dstPath := filepath.Join(dir, filename)

	dst, err := os.Create(dstPath)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Gagal menyimpan file")
		return
	}
	defer dst.Close()
	if _, err := io.Copy(dst, file); err != nil {
		writeError(w, http.StatusInternalServerError, "Gagal menulis file")
		return
	}

	publicURL := "/uploads/berita/uploads/" + filename
	writeJSON(w, http.StatusCreated, map[string]string{
		"url":      publicURL,
		"filename": filename,
	})
}

func (a *API) ListMedia(w http.ResponseWriter, r *http.Request) {
	type mediaItem struct {
		Name string `json:"name"`
		URL  string `json:"url"`
		Size int64  `json:"size"`
	}
	items := make([]mediaItem, 0)
	_ = filepath.Walk("uploads", func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() {
			return nil
		}
		ext := strings.ToLower(filepath.Ext(path))
		if ext == ".jpg" || ext == ".jpeg" || ext == ".png" || ext == ".webp" {
			webPath := "/" + filepath.ToSlash(path)
			items = append(items, mediaItem{
				Name: info.Name(),
				URL:  webPath,
				Size: info.Size(),
			})
		}
		return nil
	})
	writeJSON(w, http.StatusOK, map[string]any{"data": items})
}
