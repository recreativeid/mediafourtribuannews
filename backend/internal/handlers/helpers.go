package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"unicode"

	"mediafourtribuannews/backend/internal/db"
)

type API struct {
	Store *db.Store
}

func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, map[string]string{"error": msg})
}

func queryInt(r *http.Request, key string, def int) int {
	raw := strings.TrimSpace(r.URL.Query().Get(key))
	if raw == "" {
		return def
	}
	v, err := strconv.Atoi(raw)
	if err != nil || v < 0 {
		return def
	}
	return v
}

var nonAlnumRe = regexp.MustCompile(`[^a-z0-9]+`)
var htmlTagRe = regexp.MustCompile(`<[^>]*>`)

func slugify(s string) string {
	s = strings.ToLower(strings.TrimSpace(s))
	var b strings.Builder
	for _, r := range s {
		if unicode.IsLetter(r) || unicode.IsDigit(r) {
			b.WriteRune(r)
		} else {
			b.WriteRune('-')
		}
	}
	out := nonAlnumRe.ReplaceAllString(b.String(), "-")
	out = strings.Trim(out, "-")
	if out == "" {
		return "item"
	}
	return out
}

func stripHTML(s string) string {
	txt := htmlTagRe.ReplaceAllString(s, " ")
	fields := strings.Fields(txt)
	return strings.Join(fields, " ")
}

func estimateReadTime(html string) string {
	words := len(strings.Fields(stripHTML(html)))
	mins := words / 200
	if mins < 1 {
		mins = 1
	}
	return fmt.Sprintf("%d menit baca", mins)
}

func extractYoutubeID(urlStr string) string {
	urlStr = strings.TrimSpace(urlStr)
	if len(urlStr) == 11 && !strings.Contains(urlStr, "/") {
		return urlStr
	}
	re := regexp.MustCompile(`(?:youtube\.com/(?:watch\?v=|embed/|shorts/)|youtu\.be/)([A-Za-z0-9_-]{11})`)
	if m := re.FindStringSubmatch(urlStr); len(m) > 1 {
		return m[1]
	}
	return urlStr
}
