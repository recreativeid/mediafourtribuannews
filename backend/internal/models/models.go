package models

import "time"

type User struct {
	ID        int64      `json:"id"`
	Name      string     `json:"name"`
	Email     string     `json:"email"`
	Password  string     `json:"-"`
	Role      string     `json:"role"` // Administrator, Editor, Reporter
	Status    string     `json:"status"`
	Avatar    string     `json:"avatar"`
	Bio       string     `json:"bio"`
	LastLogin *time.Time `json:"last_login,omitempty"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
}

type Category struct {
	ID           int64     `json:"id"`
	Name         string    `json:"name"`
	Slug         string    `json:"slug"`
	Description  string    `json:"description"`
	ArticleCount int64     `json:"article_count,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
}

type Article struct {
	ID           int64     `json:"id"`
	CategoryID   int64     `json:"category_id"`
	CategoryName string    `json:"category_name"`
	CategorySlug string    `json:"category_slug"`
	AuthorID     int64     `json:"author_id"`
	AuthorName   string    `json:"author_name"`
	AuthorAvatar string    `json:"author_avatar"`
	EditorID     *int64    `json:"editor_id,omitempty"`
	EditorName   string    `json:"editor_name,omitempty"`
	Title        string    `json:"title"`
	Slug         string    `json:"slug"`
	Excerpt      string    `json:"excerpt"`
	Content      string    `json:"content"`
	Thumbnail    string    `json:"thumbnail"`
	Caption      string    `json:"caption"`
	Tags         string    `json:"tags"`
	Status       string    `json:"status"` // published, draft, review, scheduled
	Views        int64     `json:"views"`
	IsFeatured   bool      `json:"is_featured"`
	ReadTime     string    `json:"read_time"`
	PublishedAt  time.Time `json:"published_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

type Video struct {
	ID         int64     `json:"id"`
	Title      string    `json:"title"`
	YoutubeURL string    `json:"youtube_url"`
	YoutubeID  string    `json:"youtube_id"`
	Caption    string    `json:"caption"`
	IsActive   bool      `json:"is_active"`
	CreatedAt  time.Time `json:"created_at"`
}

type Comment struct {
	ID           int64     `json:"id"`
	ArticleID    int64     `json:"article_id"`
	ArticleTitle string    `json:"article_title,omitempty"`
	ArticleSlug  string    `json:"article_slug,omitempty"`
	Name         string    `json:"name"`
	Email        string    `json:"email"`
	Comment      string    `json:"comment"`
	Status       string    `json:"status"` // pending, approved, rejected, spam
	IPAddress    string    `json:"ip_address,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
}

type EditorialMember struct {
	ID          int64     `json:"id"`
	Name        string    `json:"name"`
	Position    string    `json:"position"`
	Division    string    `json:"division"`
	Description string    `json:"description"`
	Email       string    `json:"email"`
	Phone       string    `json:"phone"`
	Photo       string    `json:"photo"`
	SortOrder   int       `json:"sort_order"`
	Status      string    `json:"status"`
	CreatedAt   time.Time `json:"created_at"`
}

type Ad struct {
	ID           int64     `json:"id"`
	Title        string    `json:"title"`
	Type         string    `json:"type"`          // banner, html
	Position     string    `json:"position"`      // sidebar, home_middle, article_middle, footer
	TargetDevice string    `json:"target_device"` // all, desktop, mobile
	TargetPage   string    `json:"target_page"`   // all, home, article
	HTMLCode     string    `json:"html_code"`
	Image        string    `json:"image"`
	TargetURL    string    `json:"target_url"`
	Description  string    `json:"description"`
	IsActive     bool      `json:"is_active"`
	SortOrder    int       `json:"sort_order"`
	CreatedAt    time.Time `json:"created_at"`
}

type DashboardStats struct {
	TotalArticles     int64              `json:"total_articles"`
	PublishedArticles int64              `json:"published_articles"`
	DraftArticles     int64              `json:"draft_articles"`
	TotalViews        int64              `json:"total_views"`
	TotalCategories   int64              `json:"total_categories"`
	TotalUsers        int64              `json:"total_users"`
	TotalVideos       int64              `json:"total_videos"`
	TotalAds          int64              `json:"total_ads"`
	PendingComments   int64              `json:"pending_comments"`
	TotalComments     int64              `json:"total_comments"`
	CategoryStats     []CategoryStat     `json:"category_stats"`
	LatestArticles    []Article          `json:"latest_articles"`
	TopArticles       []Article          `json:"top_articles"`
	RecentComments    []Comment          `json:"recent_comments"`
}

type CategoryStat struct {
	Name  string `json:"name"`
	Slug  string `json:"slug"`
	Count int64  `json:"count"`
	Views int64  `json:"views"`
}
