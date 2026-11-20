import { createRouter, createWebHistory } from 'vue-router'
import { isSessionExpired } from '../api/client'
import { logoutAdmin } from '../composables/usePortal'

import PublicLayout from '../layouts/PublicLayout.vue'
import AdminLayout from '../layouts/AdminLayout.vue'

import HomeView from '../views/HomeView.vue'
import CategoryView from '../views/CategoryView.vue'
import ArticleDetailView from '../views/ArticleDetailView.vue'
import SearchView from '../views/SearchView.vue'
import AboutView from '../views/AboutView.vue'
import InstitutionalView from '../views/InstitutionalView.vue'
import IndexNewsView from '../views/IndexNewsView.vue'

import AdminLoginView from '../views/admin/AdminLoginView.vue'
import AdminDashboardView from '../views/admin/AdminDashboardView.vue'
import AdminArticlesView from '../views/admin/AdminArticlesView.vue'
import AdminCategoriesView from '../views/admin/AdminCategoriesView.vue'
import AdminVideosView from '../views/admin/AdminVideosView.vue'
import AdminCommentsView from '../views/admin/AdminCommentsView.vue'
import AdminAdsView from '../views/admin/AdminAdsView.vue'
import AdminEditorialView from '../views/admin/AdminEditorialView.vue'
import AdminPagesView from '../views/admin/AdminPagesView.vue'
import AdminUsersView from '../views/admin/AdminUsersView.vue'
import AdminAccountView from '../views/admin/AdminAccountView.vue'
import AdminSettingsView from '../views/admin/AdminSettingsView.vue'

const routes = [
  {
    path: '/',
    component: PublicLayout,
    children: [
      { path: '', name: 'home', component: HomeView },
      { path: 'kategori/:slug', name: 'category', component: CategoryView },
      { path: 'berita/:slug', name: 'article', component: ArticleDetailView },
      { path: 'cari', name: 'search', component: SearchView },
      { path: 'indeks', name: 'indeks', component: IndexNewsView },
      { path: 'redaksi', name: 'redaksi', component: InstitutionalView, props: { defaultTab: 'redaksi' } },
      { path: 'kode-etik', name: 'kode-etik', component: InstitutionalView, props: { defaultTab: 'kode-etik' } },
      { path: 'pedoman-media-siber', name: 'pedoman-media-siber', component: InstitutionalView, props: { defaultTab: 'pedoman' } },
      { path: 'privacy-policy', name: 'privacy-policy', component: InstitutionalView, props: { defaultTab: 'privacy' } },
      { path: 'kebijakan-privasi', name: 'kebijakan-privasi', component: InstitutionalView, props: { defaultTab: 'privacy' } },
      { path: 'disclaimer', name: 'disclaimer', component: InstitutionalView, props: { defaultTab: 'disclaimer' } },
      { path: 'dewan-pers', name: 'dewan-pers', component: InstitutionalView, props: { defaultTab: 'dewan-pers' } },
      { path: 'tentang', name: 'about', component: InstitutionalView, props: { defaultTab: 'profil' } },
    ],
  },
  {
    path: '/admin/login',
    name: 'admin-login',
    component: AdminLoginView,
    meta: { guestOnly: true },
  },
  {
    path: '/admin',
    component: AdminLayout,
    meta: { requiresAuth: true },
    children: [
      { path: '', name: 'admin-dashboard', component: AdminDashboardView },
      { path: 'berita', name: 'admin-articles', component: AdminArticlesView },
      { path: 'kategori', name: 'admin-categories', component: AdminCategoriesView },
      { path: 'video', name: 'admin-videos', component: AdminVideosView },
      { path: 'komentar', name: 'admin-comments', component: AdminCommentsView },
      { path: 'iklan', name: 'admin-ads', component: AdminAdsView },
      { path: 'redaksi', name: 'admin-editorial', component: AdminEditorialView },
      { path: 'halaman', name: 'admin-pages', component: AdminPagesView },
      { path: 'pengguna', name: 'admin-users', component: AdminUsersView },
      { path: 'akun', name: 'admin-account', component: AdminAccountView },
      { path: 'pengaturan', name: 'admin-settings', component: AdminSettingsView },
    ],
  },
  { path: '/:pathMatch(.*)*', redirect: '/' },
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) return savedPosition
    if (to.hash) return { el: to.hash, behavior: 'smooth' }
    return { top: 0 }
  },
})

router.beforeEach((to) => {
  const expired = isSessionExpired()
  if (to.meta.requiresAuth && expired) {
    logoutAdmin()
    return {
      name: 'admin-login',
      query: { redirect: to.fullPath, expired: '1' },
    }
  }
  if (to.meta.guestOnly && !expired) {
    return { name: 'admin-dashboard' }
  }
  return true
})

export default router
