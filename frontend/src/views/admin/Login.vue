<template>
  <div class="login-page">
    <div class="login-card">
      <h1 class="login-title">管理后台</h1>
      <p class="login-subtitle">银行备考知识库 · 系统管理</p>

      <el-form :model="form" :rules="rules" ref="formRef" @keyup.enter="handleLogin">
        <el-form-item prop="username">
          <el-input
            v-model="form.username"
            placeholder="用户名"
            :prefix-icon="User"
            size="large"
            clearable
          />
        </el-form-item>

        <el-form-item prop="password">
          <el-input
            v-model="form.password"
            type="password"
            placeholder="密码"
            :prefix-icon="Lock"
            size="large"
            show-password
            clearable
          />
        </el-form-item>

        <el-form-item>
          <el-button
            class="login-btn"
            type="primary"
            size="large"
            :loading="loading"
            @click="handleLogin"
          >立即登录</el-button>
        </el-form-item>
      </el-form>

      <div class="login-back">
        <router-link to="/">← 返回网页端</router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { User, Lock } from '@element-plus/icons-vue';
import { ElMessage } from 'element-plus';
import { useUserStore } from '../../store/user';

const router = useRouter();
const route = useRoute();
const userStore = useUserStore();
const formRef = ref(null);
const loading = ref(false);

const form = reactive({ username: '', password: '' });

const rules = {
  username: [{ required: true, message: '请输入用户名', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }]
};

async function handleLogin() {
  const valid = await formRef.value.validate().catch(() => false);
  if (!valid) return;
  loading.value = true;
  try {
    await userStore.login(form.username, form.password);
    ElMessage.success('登录成功');
    const redirect = route.query.redirect || '/admin';
    router.push(redirect);
  } catch {
    // 错误在拦截器里提示了
  } finally {
    loading.value = false;
  }
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  background-color: var(--color-bg);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}

.login-card {
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 12px 40px rgba(51, 49, 46, 0.08);
  padding: 48px 40px 36px;
  width: 420px;
  max-width: 100%;
}

.login-title {
  font-size: 26px;
  font-weight: 700;
  text-align: center;
  color: var(--color-text);
  letter-spacing: 2px;
}

.login-subtitle {
  font-size: 14px;
  text-align: center;
  color: var(--color-text-secondary);
  margin: 8px 0 28px;
}

.login-btn {
  width: 100%;
  border-radius: 10px;
  font-weight: 600;
  letter-spacing: 2px;
  margin-top: 6px;
}

.login-back {
  text-align: center;
  margin-top: 20px;
}

.login-back a {
  font-size: 13px;
  color: var(--color-primary);
  text-decoration: none;
}

.login-back a:hover {
  text-decoration: underline;
}
</style>
