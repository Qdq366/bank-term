<template>
  <div class="portal-layout">
    <router-view />
  </div>
</template>

<script setup>
// 查阅端布局：沉浸式框架由 Home.vue 内部实现（头部 + 侧栏 + 内容区）
</script>

<style scoped>
.portal-layout {
  min-height: 100vh;
  background-color: var(--color-bg);
}
</style>
