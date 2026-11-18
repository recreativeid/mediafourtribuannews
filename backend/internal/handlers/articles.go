package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"

	"mediafourtribuannews/backend/internal/middleware"
	"mediafourtribuannews/backend/internal/models"
)

func (a *API) enrichArticleLocked(art models.Article) models.Article {
	for _, c := range a.Store.Data.Categories {
		if c.ID == art.CategoryID {
			art.CategoryName = c.Name
			art.CategorySlug = c.Slug
			break
		}
	}
	for _, u := range a.Store.Data.Users {
		if u.ID == art.AuthorID {
			art.AuthorName = u.Name
			art.AuthorAvatar = u.Avatar
		}
		if art.EditorID != nil && u.ID == *art.EditorID {
			art.EditorName = u.Name
		}
	}
	return art
}

func (a *API) ListArticles(w http.ResponseWriter, r *http.Request) {
	q := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("q")))
	cat := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("category")))
	sortBy := strings.TrimSpace(r.URL.Query().Get("sort"))
	status := strings.TrimSpace(r.URL.Query().Get("status"))
	featured := strings.TrimSpace(r.URL.Query().Get("featured"))

	limit := queryInt(r, "limit", 20)
	if limit == 0 || limit > 100 {
		limit = 20
	}
	page := queryInt(r, "page", 1)
	if page < 1 {
		page = 1
	}

	isAdminRoute := strings.HasPrefix(r.URL.Path, "/api/admin")

	a.Store.Mu.RLock()
	filtered := make([]models.Article, 0, len(a.Store.Data.Articles))
	for _, raw := range a.Store.Data.Articles {
		art := a.enrichArticleLocked(raw)
		if !isAdminRoute && art.Status != "published" {
			continue
		}
		if isAdminRoute && status != "" && status != "all" && art.Status != status {
			continue
		}
		if cat != "" && cat != "all" && cat != "terbaru" {
			if strings.ToLower(art.CategorySlug) != cat && strconv.FormatInt(art.CategoryID, 10) != cat {
				continue
			}
		}
		if (featured == "1" || featured == "true") && !art.IsFeatured {
			continue
		}
		if q != "" {
			hay := strings.ToLower(art.Title + " " + art.Excerpt + " " + art.Tags + " " + art.CategoryName)
			if !strings.Contains(hay, q) {
				continue
			}
		}
		filtered = append(filtered, art)
	}
	a.Store.Mu.RUnlock()

	sort.Slice(filtered, func(i, j int) bool {
		if sortBy == "popular" {
			if filtered[i].Views != filtered[j].Views {
				return filtered[i].Views > filtered[j].Views
			}
		} else if sortBy == "oldest" {
			return filtered[i].PublishedAt.Before(filtered[j].PublishedAt)
		}
		return filtered[i].PublishedAt.After(filtered[j].PublishedAt)
	})

	total := int64(len(filtered))
	start := (page - 1) * limit
	if start > len(filtered) {
		start = len(filtered)
	}
	end := start + limit
	if end > len(filtered) {
		end = len(filtered)
	}
	slice := filtered[start:end]

	writeJSON(w, http.StatusOK, map[string]any{
		"data":       slice,
		"total":      total,
		"page":       page,
		"limit":      limit,
		"totalPages": (total + int64(limit) - 1) / int64(limit),
	})
}

func (a *API) GetArticleBySlug(w http.ResponseWriter, r *http.Request) {
	slug := chi.URLParam(r, "slug")

	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()

	idx := -1
	for i := range a.Store.Data.Articles {
		if a.Store.Data.Articles[i].Slug == slug {
			idx = i
			break
		}
	}
	if idx < 0 {
		writeError(w, http.StatusNotFound, "Berita tidak ditemukan")
		return
	}

	a.Store.Data.Articles[idx].Views++
	art := a.enrichArticleLocked(a.Store.Data.Articles[idx])
	_ = a.Store.SaveLocked()

	related := make([]models.Article, 0, 4)
	for _, other := range a.Store.Data.Articles {
		if other.Status == "published" && other.CategoryID == art.CategoryID && other.ID != art.ID {
			related = append(related, a.enrichArticleLocked(other))
			if len(related) >= 4 {
				break
			}
		}
	}

	comments := make([]models.Comment, 0)
	for _, cm := range a.Store.Data.Comments {
		if cm.ArticleID == art.ID && cm.Status == "approved" {
			comments = append(comments, cm)
		}
	}
	sort.Slice(comments, func(i, j int) bool {
		return comments[i].CreatedAt.After(comments[j].CreatedAt)
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"article":  art,
		"related":  related,
		"comments": comments,
	})
}

type articleInput struct {
	CategoryID int64  `json:"category_id"`
	Title      string `json:"title"`
	Slug       string `json:"slug"`
	Excerpt    string `json:"excerpt"`
	Content    string `json:"content"`
	Thumbnail  string `json:"thumbnail"`
	Caption    string `json:"caption"`
	Tags       string `json:"tags"`
	Status     string `json:"status"`
	IsFeatured bool   `json:"is_featured"`
}

func (a *API) CreateArticle(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetAuthUser(r)
	var in articleInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		writeError(w, http.StatusBadRequest, "Payload tidak valid")
		return
	}
	in.Title = strings.TrimSpace(in.Title)
	if in.Title == "" || strings.TrimSpace(in.Content) == "" {
		writeError(w, http.StatusBadRequest, "Judul dan isi berita wajib diisi")
		return
	}
	if in.CategoryID == 0 {
		in.CategoryID = 1
	}
	if in.Slug == "" {
		in.Slug = slugify(in.Title)
	} else {
		in.Slug = slugify(in.Slug)
	}
	if in.Excerpt == "" {
		plain := stripHTML(in.Content)
		if len(plain) > 190 {
			in.Excerpt = plain[:190] + "..."
		} else {
			in.Excerpt = plain
		}
	}
	if in.Status == "" {
		in.Status = "published"
	}
	if in.Thumbnail == "" {
		in.Thumbnail = "/uploads/berita/nasional/pembangunan-ikn-nusantara.jpg"
	}

	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()

	for _, existing := range a.Store.Data.Articles {
		if existing.Slug == in.Slug {
			in.Slug = fmt.Sprintf("%s-%d", in.Slug, time.Now().Unix()%10000)
			break
		}
	}

	authorID := int64(1)
	if claims != nil {
		authorID = claims.UserID
	}
	editorID := authorID
	now := time.Now()
	art := models.Article{
		ID:          a.Store.NextID("articles"),
		CategoryID:  in.CategoryID,
		AuthorID:    authorID,
		EditorID:    &editorID,
		Title:       in.Title,
		Slug:        in.Slug,
		Excerpt:     in.Excerpt,
		Content:     in.Content,
		Thumbnail:   in.Thumbnail,
		Caption:     in.Caption,
		Tags:        in.Tags,
		Status:      in.Status,
		Views:       0,
		IsFeatured:  in.IsFeatured,
		ReadTime:    estimateReadTime(in.Content),
		PublishedAt: now,
		UpdatedAt:   now,
	}
	art = a.enrichArticleLocked(art)
	a.Store.Data.Articles = append([]models.Article{art}, a.Store.Data.Articles...)
	_ = a.Store.SaveLocked()

	writeJSON(w, http.StatusCreated, map[string]any{"data": art})
}

func (a *API) UpdateArticle(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		writeError(w, http.StatusBadRequest, "ID tidak valid")
		return
	}
	claims := middleware.GetAuthUser(r)
	var in articleInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		writeError(w, http.StatusBadRequest, "Payload tidak valid")
		return
	}
	in.Title = strings.TrimSpace(in.Title)
	if in.Title == "" || strings.TrimSpace(in.Content) == "" {
		writeError(w, http.StatusBadRequest, "Judul dan isi berita wajib diisi")
		return
	}

	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()

	for i := range a.Store.Data.Articles {
		if a.Store.Data.Articles[i].ID == id {
			art := &a.Store.Data.Articles[i]
			art.CategoryID = in.CategoryID
			art.Title = in.Title
			if in.Slug != "" {
				art.Slug = slugify(in.Slug)
			}
			if in.Excerpt != "" {
				art.Excerpt = in.Excerpt
			}
			art.Content = in.Content
			art.Thumbnail = in.Thumbnail
			art.Caption = in.Caption
			art.Tags = in.Tags
			if in.Status != "" {
				art.Status = in.Status
			}
			art.IsFeatured = in.IsFeatured
			art.ReadTime = estimateReadTime(in.Content)
			art.UpdatedAt = time.Now()
			if claims != nil {
				eid := claims.UserID
				art.EditorID = &eid
			}
			enriched := a.enrichArticleLocked(*art)
			*art = enriched
			_ = a.Store.SaveLocked()
			writeJSON(w, http.StatusOK, map[string]any{"data": enriched})
			return
		}
	}
	writeError(w, http.StatusNotFound, "Berita tidak ditemukan")
}

func (a *API) DeleteArticle(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		writeError(w, http.StatusBadRequest, "ID tidak valid")
		return
	}
	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()

	kept := make([]models.Article, 0, len(a.Store.Data.Articles))
	for _, art := range a.Store.Data.Articles {
		if art.ID != id {
			kept = append(kept, art)
		}
	}
	a.Store.Data.Articles = kept

	keptComments := make([]models.Comment, 0, len(a.Store.Data.Comments))
	for _, cm := range a.Store.Data.Comments {
		if cm.ArticleID != id {
			keptComments = append(keptComments, cm)
		}
	}
	a.Store.Data.Comments = keptComments
	_ = a.Store.SaveLocked()

	writeJSON(w, http.StatusOK, map[string]string{"message": "Berita berhasil dihapus"})
}
