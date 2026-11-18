package main

import (
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"

	"mediafourtribuannews/backend/internal/db"
	"mediafourtribuannews/backend/internal/handlers"
	"mediafourtribuannews/backend/internal/middleware"
)

func main() {
	store, err := db.Connect()
	if err != nil {
		log.Fatalf("Database connection failed: %v", err)
	}
	defer store.Close()

	api := &handlers.API{Store: store}

	r := chi.NewRouter()
	r.Use(chimw.Logger)
	r.Use(chimw.Recoverer)
	r.Use(chimw.Compress(5))
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"http://localhost:5173", "http://127.0.0.1:5173", "http://localhost:8080", "*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type"},
		AllowCredentials: false,
		MaxAge:           300,
	}))

	// Static uploads
	uploadsDir := http.Dir("./uploads")
	r.Handle("/uploads/*", http.StripPrefix("/uploads/", http.FileServer(uploadsDir)))

	// Health check
	r.Get("/api/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"status":"ok","portal":"Media Four Tribuan News"}`))
	})

	// Public API routes
	r.Route("/api", func(r chi.Router) {
		r.Post("/auth/login", api.Login)

		r.Get("/articles", api.ListArticles)
		r.Get("/articles/{slug}", api.GetArticleBySlug)
		r.Get("/categories", api.ListCategories)
		r.Get("/videos", api.ListVideos)
		r.Get("/redaksi", api.ListEditorial)
		r.Get("/ads", api.ListAds)
		r.Get("/settings", api.GetSettings)
		r.Post("/comments", api.CreateComment)

		// Protected Admin API routes
		r.Group(func(r chi.Router) {
			r.Use(middleware.RequireAuth)

			r.Get("/auth/me", api.Me)
			r.Put("/auth/account", api.UpdateAccount)
			r.Get("/admin/dashboard", api.GetDashboard)

			r.Get("/admin/articles", api.ListArticles)
			r.Post("/admin/articles", api.CreateArticle)
			r.Put("/admin/articles/{id}", api.UpdateArticle)
			r.Delete("/admin/articles/{id}", api.DeleteArticle)

			r.Get("/admin/categories", api.ListCategories)
			r.Post("/admin/categories", api.CreateCategory)
			r.Put("/admin/categories/{id}", api.UpdateCategory)
			r.Delete("/admin/categories/{id}", api.DeleteCategory)

			r.Get("/admin/videos", api.ListVideos)
			r.Post("/admin/videos", api.CreateVideo)
			r.Put("/admin/videos/{id}", api.UpdateVideo)
			r.Delete("/admin/videos/{id}", api.DeleteVideo)

			r.Get("/admin/comments", api.ListAdminComments)
			r.Put("/admin/comments/{id}/status", api.UpdateCommentStatus)
			r.Delete("/admin/comments/{id}", api.DeleteComment)

			r.Get("/admin/redaksi", api.ListEditorial)
			r.Post("/admin/redaksi", api.CreateEditorial)
			r.Put("/admin/redaksi/{id}", api.UpdateEditorial)
			r.Delete("/admin/redaksi/{id}", api.DeleteEditorial)

			r.Get("/admin/ads", api.ListAds)
			r.Post("/admin/ads", api.CreateAd)
			r.Put("/admin/ads/{id}", api.UpdateAd)
			r.Delete("/admin/ads/{id}", api.DeleteAd)

			r.Get("/admin/users", api.ListUsers)
			r.Post("/admin/users", api.CreateUser)
			r.Put("/admin/users/{id}", api.UpdateUser)
			r.Delete("/admin/users/{id}", api.DeleteUser)

			r.Put("/admin/settings", api.UpdateSettings)
			r.Post("/admin/upload", api.UploadFile)
			r.Get("/admin/media", api.ListMedia)
		})
	})

	// Optional: serve built Vue SPA from ../frontend/dist when present
	distDir := filepath.Join("..", "frontend", "dist")
	if info, err := os.Stat(distDir); err == nil && info.IsDir() {
		fs := http.FileServer(http.Dir(distDir))
		r.NotFound(func(w http.ResponseWriter, r *http.Request) {
			if strings.HasPrefix(r.URL.Path, "/api/") {
				http.NotFound(w, r)
				return
			}
			fullPath := filepath.Join(distDir, filepath.Clean(r.URL.Path))
			if fi, err := os.Stat(fullPath); err == nil && !fi.IsDir() {
				fs.ServeHTTP(w, r)
				return
			}
			http.ServeFile(w, r, filepath.Join(distDir, "index.html"))
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Printf("Media Four Tribuan News API running on http://localhost:%s (DB: %s)", port, store.Driver)
	if err := http.ListenAndServe(":"+port, r); err != nil {
		log.Fatal(err)
	}
}
