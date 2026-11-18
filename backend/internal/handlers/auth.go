package handlers

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"

	"mediafourtribuannews/backend/internal/middleware"
)

type loginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (a *API) Login(w http.ResponseWriter, r *http.Request) {
	var req loginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}
	ident := strings.TrimSpace(strings.ToLower(req.Email))
	if ident == "" || req.Password == "" {
		writeError(w, http.StatusBadRequest, "Email dan kata sandi wajib diisi")
		return
	}

	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()

	foundIdx := -1
	for i, u := range a.Store.Data.Users {
		if strings.ToLower(u.Email) == ident || strings.ToLower(u.Name) == ident {
			foundIdx = i
			break
		}
	}
	if foundIdx < 0 {
		writeError(w, http.StatusUnauthorized, "Email atau kata sandi salah")
		return
	}
	u := &a.Store.Data.Users[foundIdx]
	if u.Status != "active" {
		writeError(w, http.StatusForbidden, "Akun sedang dinonaktifkan")
		return
	}
	if err := bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(req.Password)); err != nil {
		writeError(w, http.StatusUnauthorized, "Email atau kata sandi salah")
		return
	}

	now := time.Now()
	u.LastLogin = &now
	_ = a.Store.SaveLocked()

	token, err := middleware.GenerateToken(u.ID, u.Name, u.Email, u.Role)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Gagal membuat token sesi")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"token": token,
		"user":  u.User,
	})
}

func (a *API) Me(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetAuthUser(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "Tidak terautentikasi")
		return
	}
	a.Store.Mu.RLock()
	defer a.Store.Mu.RUnlock()
	for _, u := range a.Store.Data.Users {
		if u.ID == claims.UserID {
			writeJSON(w, http.StatusOK, map[string]any{"user": u.User})
			return
		}
	}
	writeError(w, http.StatusNotFound, "Pengguna tidak ditemukan")
}
