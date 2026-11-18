import { createRouter, createWebHistory } from 'vue-router'
import { getToken } from '../api/client'

import PublicLayout from '../layouts/PublicLayout.vue'
import AdminLayout from '../layouts/AdminLayout.vue'

import HomeView from '../views/HomeView.vue'
import CategoryView from '../views/CategoryView.vue'
import ArticleDetailView from '../views/ArticleDetailView.vue'
import SearchView from '../views/SearchView.vue'
import AboutView from '../views/AboutView.vue'

import AdminLoginView from '../views/admin/AdminLoginView.vue'
import AdminDashboardView from '../views/admin/AdminDashboardView.vue'
import AdminArticlesView from '../views/admin/AdminArticlesView.vue'
import AdminCategoriesView from '../views/admin/AdminCategoriesView.vue'
import AdminVideosView from '../views/admin/AdminVideosView.vue'
import AdminCommentsView from '../views/admin/AdminCommentsView.vue'
import AdminAdsView from '../views/admin/AdminAdsView.vue'
import AdminEditorialView from '../views/admin/AdminEditorialView.vue'
import AdminUsersView from '../views/admin/AdminUsersView.vue'
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
      { path: 'tentang', name: 'about', component: AboutView },
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
      { path: 'pengguna', name: 'admin-users', component: AdminUsersView },
      { path: 'pengaturan', name: 'admin-settings', component: AdminSettingsView },
    ],
  },
  { path: '/:pathMatch(.*)*', redirect: '/' },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) return savedPosition
    if (to.hash) return { el: to.hash, behavior: 'smooth' }
    return { top: 0 }
  },
})

router.beforeEach((to) => {
  const token = getToken()
  if (to.meta.requiresAuth && !token) {
    return { name: 'admin-login', query: { redirect: to.fullPath } }
  }
  if (to.meta.guestOnly && token) {
    return { name: 'admin-dashboard' }
  }
  return true
})

export default router
