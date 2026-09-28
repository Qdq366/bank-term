<template>
  <div ref="rootRef" class="notes-manage">
    <!-- 顶部工具条：节点信息 + 秒搜框 + 新增按钮 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <h2 class="current-name">{{ currentCategoryName }}</h2>
        <span class="note-total">共 {{ total }} 条笔记</span>
      </div>
      <div class="toolbar-right">
        <el-input
          v-model="keyword"
          size="large"
          clearable
          :prefix-icon="Search"
          placeholder="秒搜：输入知识点标题 / 内容关键词…"
          class="search-input"
        />
        <el-button class="add-btn" size="large" @click="openCreate">+ 新增笔记</el-button>
      </div>
    </div>

    <!-- 数据表格区：后端分页 -->
    <el-table v-loading="loading" :data="notes" stripe class="note-table">
      <el-table-column label="知识点标题" width="240">
        <template #default="{ row }">
          <div class="kp-name">{{ catNameOf(row) }}</div>
          <el-tag size="small" effect="plain" class="kp-path">{{ catPathOf(row) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="内容预览" min-width="300" show-overflow-tooltip>
        <template #default="{ row }">
          <span class="preview-text">{{ stripMd(row.content) }}</span>
        </template>
      </el-table-column>
      <el-table-column label="高频考点" width="110" align="center">
        <template #default="{ row }">
          <el-switch
            :model-value="row.isImportant"
            style="--el-switch-on-color: #e08a5b"
            @change="toggleImportant(row, $event)"
          />
        </template>
      </el-table-column>
      <el-table-column label="操作" width="130" align="center" fixed="right">
        <template #default="{ row }">
          <el-button text type="primary" size="small" @click="openEdit(row)">编辑</el-button>
          <el-button text type="danger" size="small" @click="handleDelete(row)">删除</el-button>
        </template>
      </el-table-column>
      <template #empty>
        <el-empty :description="keyword ? '没有匹配的知识点' : '该节点下暂无笔记'" />
      </template>
    </el-table>

    <!-- 分页栏 -->
    <div class="pagination-wrap">
      <el-pagination
        v-model:current-page="page"
        v-model:page-size="pageSize"
        :total="total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        background
        @current-change="handlePageChange"
        @size-change="handleSizeChange"
      />
    </div>

    <!-- 新增/编辑抽屉 -->
    <NoteDrawer
      v-model:visible="drawerVisible"
      :note="editingNote"
      :categories="categories"
      :default-category-id="categoryId"
      @saved="onSaved"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, inject } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { Search } from '@element-plus/icons-vue';
import NoteDrawer from '../../components/admin/NoteDrawer.vue';
import { getNotes, updateNote, deleteNote } from '../../api/note';
import { getCategoryTree } from '../../api/category';

const props = defineProps({
  categoryId: { type: String, default: '' }
});

const refreshTree = inject('refreshTree', () => {});

const rootRef = ref(null);
const notes = ref([]);
const categories = ref([]);
const total = ref(0);
const page = ref(1);
const pageSize = ref(10);
const keyword = ref('');
const loading = ref(false);
const drawerVisible = ref(false);
const editingNote = ref(null);

/* 分类映射：id -> { name, path }，path 为祖先路径（如：微观经济学 / 供求理论） */
const categoryMap = computed(() => {
  const map = new Map();
  const walk = (nodes, trail) => {
    for (const node of nodes) {
      map.set(String(node._id), {
        name: node.name.replace(/[—-]高频$/, ''),
        path: trail.join(' / ')
      });
      if (node.children?.length) walk(node.children, [...trail, node.name.replace(/[—-]高频$/, '')]);
    }
  };
  walk(categories.value, []);
  return map;
});

// 当前选中节点名
const currentCategoryName = computed(() => {
  if (!props.categoryId) return '全部笔记';
  return categoryMap.value.get(props.categoryId)?.name || '全部笔记';
});

// 知识点标题：笔记所属小节/章节名（加粗显示）
function catNameOf(row) {
  return categoryMap.value.get(String(row.categoryId))?.name || '未分类';
}

// 层级路径标签：所属小节/章节的祖先路径
function catPathOf(row) {
  const path = categoryMap.value.get(String(row.categoryId))?.path;
  return path || '顶层科目';
}

function stripMd(text) {
  return (text || '').replace(/\*\*/g, '');
}

async function loadCategories() {
  const res = await getCategoryTree();
  categories.value = res.data || [];
}

// 后端分页查询：级联当前节点及所有子孙节点
async function loadNotes() {
  loading.value = true;
  try {
    const params = { page: page.value, pageSize: pageSize.value };
    if (props.categoryId) params.categoryId = props.categoryId;
    if (keyword.value.trim()) params.keyword = keyword.value.trim();
    const res = await getNotes(params);
    notes.value = res.data.list;
    total.value = res.data.total;
  } finally {
    loading.value = false;
  }
}

// 切换页码/每页条数时平滑回到表格顶部
function scrollToTop() {
  const scrollEl = rootRef.value?.closest('.admin-main');
  scrollEl?.scrollTo({ top: 0, behavior: 'smooth' });
}

function handlePageChange() {
  loadNotes();
  scrollToTop();
}

function handleSizeChange() {
  page.value = 1;
  loadNotes();
  scrollToTop();
}

function openCreate() {
  editingNote.value = null;
  drawerVisible.value = true;
}

function openEdit(row) {
  editingNote.value = { ...row };
  drawerVisible.value = true;
}

async function toggleImportant(row, val) {
  await updateNote(row._id, { isImportant: val });
  row.isImportant = val;
  ElMessage.success(val ? '已设为高频考点' : '已取消高频标记');
}

async function handleDelete(row) {
  await ElMessageBox.confirm(`确定删除笔记「${row.title}」吗？`, '删除笔记', {
    confirmButtonText: '确定删除',
    cancelButtonText: '取消',
    type: 'warning'
  });
  await deleteNote(row._id);
  ElMessage.success('笔记已删除');
  // 删除后若当前页空了，回退一页
  if (notes.value.length === 1 && page.value > 1) page.value -= 1;
  await loadNotes();
  refreshTree();
}

async function onSaved() {
  await loadNotes();
  refreshTree();
}

// 切换目录节点：重置到第 1 页
watch(
  () => props.categoryId,
  () => {
    page.value = 1;
    loadNotes();
  }
);

// 秒搜：输入即重置第 1 页并即时过滤（防抖）
let debounceTimer = null;
watch(keyword, () => {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    page.value = 1;
    loadNotes();
  }, 300);
});

onMounted(async () => {
  await loadCategories();
  await loadNotes();
});
</script>

<style scoped>
.notes-manage {
  background: #fff;
  border-radius: 12px;
  padding: 20px 24px;
  box-shadow: 0 2px 12px rgba(51, 49, 46, 0.06);
  min-height: calc(100vh - 120px);
  display: flex;
  flex-direction: column;
}

.toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 18px;
}

.toolbar-left {
  display: flex;
  align-items: baseline;
  gap: 12px;
}

.current-name {
  font-size: 18px;
  font-weight: 600;
}

.note-total {
  font-size: 13px;
  color: var(--color-text-secondary);
}

.toolbar-right {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
  justify-content: flex-end;
}

.search-input {
  width: min(420px, 46vw);
}

.search-input :deep(.el-input__wrapper) {
  border-radius: 10px;
}

.add-btn {
  background: var(--color-accent);
  border-color: var(--color-accent);
  color: #fff;
  font-weight: 600;
  border-radius: 10px;
  flex-shrink: 0;
}

.add-btn:hover,
.add-btn:focus {
  background: #c97543;
  border-color: #c97543;
  color: #fff;
}

.note-table {
  width: 100%;
}

/* 知识点标题：加粗醒目 */
.kp-name {
  font-weight: 700;
  font-size: 14px;
  color: var(--color-text);
  line-height: 1.4;
  margin-bottom: 4px;
}

/* 层级路径标签 */
.kp-path {
  border-color: var(--color-border);
  color: var(--color-text-secondary);
  font-size: 11px;
  max-width: 100%;
}

.kp-path :deep(.el-tag__content) {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  display: inline-block;
  max-width: 100%;
}

.preview-text {
  color: var(--color-text-secondary);
  font-size: 13px;
}

.pagination-wrap {
  display: flex;
  justify-content: flex-end;
  margin-top: 18px;
}
</style>
