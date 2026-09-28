<template>
  <div class="admin-layout">
    <!-- 顶栏 -->
    <header class="admin-header">
      <div class="admin-header-left">
        <span class="admin-brand">系统管理后台</span>
      </div>
      <div class="admin-header-right">
        <el-button type="primary" plain size="small" class="back-btn" @click="goPortal">
          返回网页端
        </el-button>
        <div class="admin-user">
          <el-icon :size="18"><User /></el-icon>
          <span class="admin-username">{{ userName }}</span>
        </div>
        <el-button text type="primary" size="small" @click="openPwdDialog">修改密码</el-button>
        <el-button text type="danger" size="small" @click="handleLogout">退出登录</el-button>
      </div>
    </header>

    <div class="admin-body">
      <!-- 左侧：完整三级科目树（一级科目 -> 二级章节 -> 三级小节） -->
      <aside class="admin-sidebar">
        <div class="sidebar-head">
          <el-button type="primary" :icon="Plus" @click="showCreateCategory(null)">新增一级科目</el-button>
        </div>
        <el-tree
          ref="treeRef"
          :data="treeData"
          :props="{ label: 'name', children: 'children' }"
          node-key="_id"
          highlight-current
          :expand-on-click-node="true"
          :default-expanded-keys="expandedKeys"
          @node-click="handleNodeClick"
        >
          <template #default="{ data }">
            <span class="admin-tree-node" @mouseenter="hoverNode = data._id" @mouseleave="hoverNode = ''">
              <span class="node-name">{{ data.name }}</span>
              <span v-show="hoverNode === data._id" class="node-actions">
                <el-icon title="添加子级" @click.stop="showCreateCategory(data)"><Plus /></el-icon>
                <el-icon title="重命名" @click.stop="showRename(data)"><Edit /></el-icon>
                <el-icon title="删除" @click.stop="handleDeleteCategory(data)"><Delete /></el-icon>
              </span>
            </span>
          </template>
        </el-tree>
      </aside>

      <!-- 右侧工作台 -->
      <main class="admin-main">
        <router-view :category-id="activeCategory" />
      </main>
    </div>

    <!-- 修改密码对话框 -->
    <el-dialog
      v-model="pwdDialogVisible"
      title="修改密码"
      width="420px"
      :close-on-click-modal="false"
    >
      <el-form label-position="top">
        <el-form-item label="旧密码" required>
          <el-input
            v-model="pwdForm.oldPassword"
            type="password"
            show-password
            placeholder="请输入当前使用的密码"
          />
        </el-form-item>
        <el-form-item label="新密码" required>
          <el-input
            v-model="pwdForm.newPassword"
            type="password"
            show-password
            placeholder="请输入新密码（至少 6 位）"
          />
        </el-form-item>
        <el-form-item label="确认新密码" required>
          <el-input
            v-model="pwdForm.confirmPassword"
            type="password"
            show-password
            placeholder="请再次输入新密码"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="pwdDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="pwdSaving" @click="handleChangePassword">确认修改</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick, provide, reactive } from 'vue';
import { useRouter } from 'vue-router';
import { User, Plus, Edit, Delete } from '@element-plus/icons-vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { useUserStore } from '../store/user';
import { getCategoryTree, createCategory, renameCategory, deleteCategory } from '../api/category';
import { changePassword } from '../api/auth';

const router = useRouter();
const userStore = useUserStore();
const treeData = ref([]);
const treeRef = ref(null);
const activeCategory = ref('');
const hoverNode = ref('');
const userName = ref('管理员');
const expandedKeys = ref([]);

// 修改密码对话框
const pwdDialogVisible = ref(false);
const pwdSaving = ref(false);
const pwdForm = reactive({
  oldPassword: '',
  newPassword: '',
  confirmPassword: ''
});

const refreshTree = async () => {
  const res = await getCategoryTree();
  treeData.value = res.data || [];
  // 默认展开一级分类
  expandedKeys.value = treeData.value.map((n) => n._id);
  // 首次加载选中第一个一级科目
  if (!activeCategory.value && treeData.value.length) {
    activeCategory.value = treeData.value[0]._id;
  }
  await nextTick();
  if (activeCategory.value) {
    treeRef.value?.setCurrentKey(activeCategory.value);
  }
};

provide('refreshTree', refreshTree);

function goPortal() {
  router.push('/');
}

function handleLogout() {
  userStore.logout();
  router.push('/admin/login');
}

function handleNodeClick(data) {
  activeCategory.value = data._id;
}

async function showCreateCategory(parent) {
  if (parent && parent.level >= 3) {
    return ElMessage.warning('最多支持三级分类');
  }
  const { value } = await ElMessageBox.prompt(
    parent ? `在「${parent.name}」下新建子分类` : '请输入一级科目名称',
    '新增分类',
    { confirmButtonText: '创建', cancelButtonText: '取消', inputValidator: (v) => !!v?.trim() || '名称不能为空' }
  ).catch(() => ({ value: '' }));
  if (!value?.trim()) return;
  await createCategory({ name: value.trim(), parentId: parent?._id });
  ElMessage.success('分类已创建');
  await refreshTree();
}

async function showRename(data) {
  const { value } = await ElMessageBox.prompt(
    '请输入新的分类名称',
    '重命名分类',
    { confirmButtonText: '保存', cancelButtonText: '取消', inputValue: data.name, inputValidator: (v) => !!v?.trim() || '名称不能为空' }
  ).catch(() => ({ value: '' }));
  if (!value?.trim()) return;
  await renameCategory(data._id, { name: value.trim() });
  ElMessage.success('已重命名');
  await refreshTree();
}

async function handleDeleteCategory(data) {
  await ElMessageBox.confirm(`确定删除「${data.name}」及其子分类和全部笔记吗？`, '删除分类', {
    confirmButtonText: '确定删除',
    cancelButtonText: '取消',
    type: 'warning'
  });
  await deleteCategory(data._id);
  ElMessage.success('分类已删除');
  await refreshTree();
}

function openPwdDialog() {
  pwdForm.oldPassword = '';
  pwdForm.newPassword = '';
  pwdForm.confirmPassword = '';
  pwdDialogVisible.value = true;
}

async function handleChangePassword() {
  if (!pwdForm.oldPassword.trim()) return ElMessage.warning('请输入旧密码');
  if (!pwdForm.newPassword.trim()) return ElMessage.warning('请输入新密码');
  if (pwdForm.newPassword.length < 6) return ElMessage.warning('新密码长度不能少于 6 位');
  if (pwdForm.newPassword !== pwdForm.confirmPassword) return ElMessage.warning('两次输入的新密码不一致');

  pwdSaving.value = true;
  try {
    await changePassword({
      oldPassword: pwdForm.oldPassword,
      newPassword: pwdForm.newPassword
    });
    ElMessage.success('密码修改成功，请重新登录');
    pwdDialogVisible.value = false;
    userStore.logout();
    router.push('/admin/login');
  } catch {
    // 错误已由拦截器提示
  } finally {
    pwdSaving.value = false;
  }
}

onMounted(async () => {
  if (userStore.userInfo?.nickname) userName.value = userStore.userInfo.nickname;
  await refreshTree();
});
</script>

<style scoped>
.admin-layout {
  /* 视口固定：整页不滚动，左右两栏各自独立滚动 */
  height: 100vh;
  overflow: hidden;
  background-color: var(--color-bg);
  display: flex;
  flex-direction: column;
}

.admin-header {
  height: 56px;
  background: #fff;
  border-bottom: 1px solid var(--color-border);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  flex-shrink: 0;
}

.admin-brand {
  font-size: 16px;
  font-weight: 600;
  letter-spacing: 1px;
  color: var(--color-text);
}

.admin-header-right {
  display: flex;
  align-items: center;
  gap: 16px;
}

.back-btn {
  border-color: var(--color-primary);
  color: var(--color-primary);
}

.admin-user {
  display: flex;
  align-items: center;
  gap: 6px;
  color: var(--color-text-secondary);
  font-size: 14px;
}

.admin-username {
  max-width: 120px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.admin-body {
  display: flex;
  flex: 1;
  min-height: 0; /* 关键：允许 flex 子项收缩，内部滚动才能生效 */
  overflow: hidden;
}

.admin-sidebar {
  width: 280px;
  flex-shrink: 0;
  background: #fff;
  border-right: 1px solid var(--color-border);
  padding: 16px 10px;
  overflow-y: auto;
}

.sidebar-head {
  padding: 0 8px 12px;
  border-bottom: 1px solid var(--color-border);
  margin-bottom: 8px;
}

.sidebar-head .el-button {
  width: 100%;
  border-radius: 8px;
}

.admin-sidebar :deep(.el-tree) {
  background: transparent;
  --el-tree-node-hover-bg-color: rgba(74, 155, 142, 0.08);
}

.admin-sidebar :deep(.el-tree-node__content) {
  height: 40px;
  border-radius: 6px;
  transition: all 0.2s ease;
}

.admin-sidebar :deep(.el-tree-node.is-current > .el-tree-node__content) {
  background-color: rgba(74, 155, 142, 0.14);
  color: var(--color-primary-dark);
  font-weight: 600;
}

.admin-tree-node {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex: 1;
  padding-right: 6px;
  overflow: hidden;
}

.node-name {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.node-actions {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-shrink: 0;
}

.node-actions .el-icon {
  font-size: 14px;
  color: var(--color-text-secondary);
  cursor: pointer;
  padding: 3px;
  border-radius: 4px;
  transition: all 0.2s;
}

.node-actions .el-icon:hover {
  background: var(--color-bg);
  color: var(--color-primary);
}

.admin-main {
  flex: 1;
  min-width: 0;
  overflow-y: auto;
  padding: 20px 24px;
}

@media (max-width: 860px) {
  .admin-body {
    flex-direction: column;
  }
  .admin-sidebar {
    width: 100%;
    max-height: 280px;
    border-right: none;
    border-bottom: 1px solid var(--color-border);
  }
}
</style>
