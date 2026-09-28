import { createRouter, createWebHistory } from 'vue-router';

const routes = [
  {
    path: '/',
    component: () => import('../layouts/PortalLayout.vue'),
    children: [{ path: '', name: 'Home', component: () => import('../views/portal/Home.vue') }]
  },
  {
    path: '/admin/login',
    name: 'AdminLogin',
    component: () => import('../views/admin/Login.vue')
  },
  {
    path: '/admin',
    component: () => import('../layouts/AdminLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      { path: '', name: 'NotesManage', component: () => import('../views/admin/NotesManage.vue') }
    ]
  },
  { path: '/:pathMatch(.*)*', redirect: '/' }
];

const router = createRouter({
  history: createWebHistory(),
  routes
});

// 全局前置守卫：校验 Token
router.beforeEach((to) => {
  if (to.meta.requiresAuth) {
    const token = localStorage.getItem('bank_exam_token');
    if (!token) {
      return { path: '/admin/login', query: { redirect: to.fullPath } };
    }
  }
  return true;
});

export default router;
