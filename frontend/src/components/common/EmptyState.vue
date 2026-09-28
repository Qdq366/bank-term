<template>
  <!-- 搜索无结果时的缺省插画 -->
  <div class="empty-state">
    <svg width="120" height="120" viewBox="0 0 120 120" fill="none" xmlns="http://www.w3.org/2000/svg">
      <circle cx="52" cy="52" r="30" stroke="#c9c2b4" stroke-width="3" />
      <line x1="74" y1="74" x2="96" y2="96" stroke="#c9c2b4" stroke-width="5" stroke-linecap="round" />
      <path d="M40 52 Q52 40 64 52" stroke="#e08a5b" stroke-width="3" stroke-linecap="round" fill="none" />
    </svg>
    <p class="empty-text">{{ text }}</p>
  </div>
</template>

<script setup>
defineProps({
  text: { type: String, default: '未找到相关知识点' }
});
</script>

<style scoped>
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80px 0;
  opacity: 0.85;
}

.empty-text {
  margin-top: 16px;
  font-size: 15px;
  color: var(--color-text-secondary);
  letter-spacing: 1px;
}
</style>
