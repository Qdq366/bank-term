<template>
  <header class="portal-header">
    <div class="header-inner">
      <div class="brand">
        <div class="logo">银</div>
        <span class="brand-name">银行备考知识库</span>
      </div>

      <div class="header-tools">
        <div class="search-box">
          <el-icon class="search-icon"><Search /></el-icon>
          <input
            :value="keyword"
            type="text"
            placeholder="搜索知识点…"
            class="search-input"
            @input="$emit('update:keyword', $event.target.value)"
          />
        </div>

        <div class="hot-switch">
          <span class="switch-label">仅看高频重点</span>
          <el-switch
            :model-value="importantOnly"
            @change="$emit('update:importantOnly', $event)"
          />
        </div>

        <button class="admin-entry" @click="$router.push('/admin/login')">管理端</button>
      </div>
    </div>
  </header>
</template>

<script setup>
import { Search } from '@element-plus/icons-vue';

defineProps({
  keyword: { type: String, default: '' },
  importantOnly: { type: Boolean, default: false }
});

defineEmits(['update:keyword', 'update:importantOnly']);
</script>

<style scoped>
.portal-header {
  position: sticky;
  top: 0;
  z-index: 100;
  background-color: rgba(245, 240, 232, 0.92);
  backdrop-filter: blur(8px);
  border-bottom: 1px solid var(--color-border);
}

.header-inner {
  max-width: 1280px;
  margin: 0 auto;
  padding: 0 24px;
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
}

.brand {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-shrink: 0;
}

.logo {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  background: var(--color-primary);
  color: #fff;
  font-weight: 700;
  font-size: 17px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.brand-name {
  font-size: 17px;
  font-weight: 600;
  letter-spacing: 1px;
}

.header-tools {
  display: flex;
  align-items: center;
  gap: 20px;
  flex: 1;
  justify-content: flex-end;
}

.search-box {
  position: relative;
  width: min(320px, 40vw);
}

.search-icon {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: var(--color-text-secondary);
  font-size: 15px;
}

.search-input {
  width: 100%;
  height: 38px;
  padding: 0 14px 0 36px;
  border-radius: 20px;
  border: 1px solid var(--color-border);
  background-color: #fff;
  font-size: 14px;
  outline: none;
  transition: border-color 0.25s ease, box-shadow 0.25s ease;
}

.search-input:focus {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px rgba(74, 155, 142, 0.15);
}

.hot-switch {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}

.switch-label {
  font-size: 13px;
  color: var(--color-text-secondary);
  white-space: nowrap;
}

.admin-entry {
  height: 36px;
  padding: 0 18px;
  border-radius: 18px;
  border: 1px solid var(--color-primary);
  background: transparent;
  color: var(--color-primary);
  font-size: 14px;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.25s ease;
}

.admin-entry:hover {
  background: var(--color-primary);
  color: #fff;
}

@media (max-width: 860px) {
  .header-inner {
    flex-wrap: wrap;
    height: auto;
    padding: 12px 16px;
    row-gap: 10px;
  }
  .header-tools {
    width: 100%;
    justify-content: flex-start;
    flex-wrap: wrap;
  }
  .search-box {
    width: 100%;
  }
}
</style>
