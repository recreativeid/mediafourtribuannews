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
		"token":      token,
		"expires_in": 1200, // 20 menit dalam detik
		"user":       u.User,
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

type updateAccountRequest struct {
	Name            string `json:"name"`
	Email           string `json:"email"`
	CurrentPassword string `json:"current_password"`
	NewPassword     string `json:"new_password"`
}

func (a *API) UpdateAccount(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetAuthUser(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "Tidak terautentikasi")
		return
	}

	var req updateAccountRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	newEmail := strings.TrimSpace(strings.ToLower(req.Email))
	newName := strings.TrimSpace(req.Name)
	if newEmail == "" || !strings.Contains(newEmail, "@") {
		writeError(w, http.StatusBadRequest, "Format email tidak valid")
		return
	}
	if req.CurrentPassword == "" {
		writeError(w, http.StatusBadRequest, "Kata sandi saat ini wajib diisi untuk verifikasi")
		return
	}
	if req.NewPassword != "" && len(req.NewPassword) < 6 {
		writeError(w, http.StatusBadRequest, "Kata sandi baru minimal 6 karakter")
		return
	}

	a.Store.Mu.Lock()
	defer a.Store.Mu.Unlock()

	foundIdx := -1
	for i, u := range a.Store.Data.Users {
		if u.ID == claims.UserID {
			foundIdx = i
		} else if strings.ToLower(u.Email) == newEmail {
			writeError(w, http.StatusBadRequest, "Email tersebut sudah digunakan oleh akun lain")
			return
		}
	}
	if foundIdx < 0 {
		writeError(w, http.StatusNotFound, "Akun tidak ditemukan")
		return
	}

	u := &a.Store.Data.Users[foundIdx]
	if err := bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(req.CurrentPassword)); err != nil {
		writeError(w, http.StatusUnauthorized, "Kata sandi saat ini tidak sesuai")
		return
	}

	if newName != "" {
		u.Name = newName
	}
	u.Email = newEmail
	if req.NewPassword != "" {
		hash, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "Gagal memproses kata sandi baru")
			return
		}
		u.PasswordHash = string(hash)
	}
	u.UpdatedAt = time.Now()
	if err := a.Store.SaveLocked(); err != nil {
		writeError(w, http.StatusInternalServerError, "Gagal menyimpan perubahan akun")
		return
	}

	token, err := middleware.GenerateToken(u.ID, u.Name, u.Email, u.Role)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Gagal memperbarui token sesi")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message":    "Email dan/atau kata sandi berhasil diperbarui",
		"token":      token,
		"expires_in": 1200,
		"user":       u.User,
	})
}
