<template>
  <div class="home">
    <PortalHeader v-model:keyword="keyword" v-model:importantOnly="importantOnly" />

    <div class="home-body">
      <!-- 左侧目录导航 -->
      <aside class="sidebar">
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
            <span class="tree-node">
              <span class="tree-node-name">{{ data.name }}</span>
              <span v-if="data.noteCount" class="tree-node-count">{{ data.noteCount }}</span>
            </span>
          </template>
        </el-tree>
      </aside>

      <!-- 右侧主内容区：技术文档阅读器 -->
      <main class="content">
        <div class="content-bar">
          <div class="crumb">{{ crumbText }}</div>
          <div class="total">共 {{ total }} 条笔记</div>
        </div>

        <div v-if="loading" class="loading-wrap">
          <el-icon class="is-loading" :size="28" color="#4a9b8e"><Loading /></el-icon>
        </div>

        <EmptyState v-else-if="!article || article.totalNotes === 0" />

        <!-- 整页白底文档容器：自下而上淡入 -->
        <article v-else :key="articleKey" class="article-container fade-in-up">
          <!-- 递归渲染：当前节点 + 所有子孙节点，按层级生成 h2/h3 -->
          <DocSection v-for="sec in article.sections" :key="sec.id" :section="sec" />
        </article>
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, h } from 'vue';
import { Star, Loading } from '@element-plus/icons-vue';
import PortalHeader from '../../components/portal/PortalHeader.vue';
import MarkdownViewer from '../../components/portal/MarkdownViewer.vue';
import EmptyState from '../../components/common/EmptyState.vue';
import { getCategoryTree } from '../../api/category';
import { getNotes } from '../../api/note';

const treeData = ref([]);
const treeRef = ref(null);
const selectedCategory = ref(null);
const keyword = ref('');
const importantOnly = ref(false);
const notes = ref([]);
const total = ref(0);
const loading = ref(false);
const expandedKeys = ref([]);
// 触发淡入动画的 key（节点/筛选变化时整篇重渲染）
const articleKey = ref(0);

/* ---------- 工具：在树中查找节点 ---------- */
function findNode(nodes, id) {
  for (const node of nodes) {
    if (node._id === id) return node;
    if (node.children?.length) {
      const found = findNode(node.children, id);
      if (found) return found;
    }
  }
  return null;
}

// 面包屑路径
const crumbText = computed(() => {
  if (!selectedCategory.value) return '全部知识点';
  const path = [];
  const findPath = (nodes, targetId, trail) => {
    for (const node of nodes) {
      const next = [...trail, node.name];
      if (node._id === targetId) {
        path.push(...next);
        return true;
      }
      if (node.children?.length && findPath(node.children, targetId, next)) return true;
    }
    return false;
  };
  findPath(treeData.value, selectedCategory.value, []);
  return path.join(' / ') || '全部知识点';
});

/* ---------- 核心：构建层级化文章 sections ----------
 * 从被点击节点出发，深度优先遍历其整棵子树；
 * 每个节点产出 { id, level(2|3), name, content, isImportant }
 * level=2 渲染大标题，level=3 渲染小标题，直属正文用 Markdown 渲染。
 * 未选中节点时，把所有一级节点当作根（各自作为 h2）递归铺开。
 */
const article = computed(() => {
  const noteMap = new Map();
  for (const n of notes.value) {
    const key = String(n.categoryId);
    if (!noteMap.has(key)) noteMap.set(key, []);
    noteMap.get(key).push(n);
  }

  const sections = [];
  let totalNotes = 0;

  const walk = (node, headingLevel) => {
    const own = noteMap.get(String(node._id)) || [];
    const isImportant = own.some((n) => n.isImportant);
    totalNotes += own.length;

    // 有正文或有子节点才渲染该节
    if (own.length || (node.children && node.children.length)) {
      sections.push({
        id: node._id,
        level: Math.min(headingLevel, 3),
        name: node.name,
        notes: own,
        isImportant
      });
      for (const child of node.children || []) {
        walk(child, headingLevel + 1);
      }
    }
  };

  if (selectedCategory.value) {
    const node = findNode(treeData.value, selectedCategory.value);
    if (node) walk(node, 2); // 被点节点本身作为 h2 起
  } else {
    for (const top of treeData.value) walk(top, 2);
  }

  return { sections, totalNotes };
});

async function loadTree() {
  const res = await getCategoryTree();
  treeData.value = res.data || [];
  expandedKeys.value = treeData.value.map((n) => n._id);
}

async function loadNotes() {
  loading.value = true;
  try {
    const params = { page: 0 };
    if (selectedCategory.value) params.categoryId = selectedCategory.value;
    if (keyword.value.trim()) params.keyword = keyword.value.trim();
    if (importantOnly.value) params.important = 'true';
    const res = await getNotes(params);
    notes.value = res.data.list;
    total.value = res.data.total;
    articleKey.value += 1; // 触发淡入动画
  } finally {
    loading.value = false;
  }
}

function handleNodeClick(data) {
  selectedCategory.value = data._id;
}

let debounceTimer = null;
watch([selectedCategory, importantOnly], () => loadNotes());
watch(keyword, () => {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(loadNotes, 350);
});

onMounted(async () => {
  await loadTree();
  await loadNotes();
});

/* ---------- 递归小节组件：h2/h3 + 正文 + 子节 ---------- */
const DocSection = (props) => {
  const { section } = props;
  const HeadingTag = section.level === 2 ? 'h2' : 'h3';
  const headingClass = section.level === 2 ? 'doc-h2' : 'doc-h3';

  const children = [
    h(
      HeadingTag,
      { class: headingClass },
      [
        section.name,
        section.isImportant
          ? h('span', { class: 'hot-badge' }, [h(Star, { size: 13 }), '高频考点'])
          : null
      ]
    )
  ];
  // 正文段落：每条笔记作为一个段落块，高频徽章 + 标签 + 正文
  for (const note of section.notes || []) {
    const meta = [];
    if (note.isImportant) {
      meta.push(h('span', { class: 'hot-badge hot-badge--inline' }, [h(Star, { size: 12 }), '高频考点']));
    }
    for (const tag of note.tags || []) {
      meta.push(h('span', { class: 'note-tag' }, tag));
    }
    children.push(
      h('div', { class: 'doc-note' }, [
        meta.length ? h('div', { class: 'doc-note-meta' }, meta) : null,
        h(MarkdownViewer, { content: note.content })
      ])
    );
  }
  return h('section', { class: 'doc-section' }, children);
};
DocSection.props = { section: { type: Object, required: true } };
</script>

<style>
/* 注意：DocSection 是函数式组件，其内部类名需在非 scoped 或 :deep 下生效 */
.doc-section {
  margin-bottom: 8px;
}

.doc-h2 {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 26px;
  font-weight: 700;
  letter-spacing: 0.5px;
  color: var(--color-text);
  margin: 30px 0 16px;
  padding-bottom: 12px;
  border-bottom: 1px solid var(--color-border);
}
.doc-section:first-child > .doc-h2 {
  margin-top: 0;
}

.doc-h3 {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 19px;
  font-weight: 600;
  color: var(--color-text);
  margin: 24px 0 12px;
}
.doc-h3::before {
  content: '';
  width: 4px;
  height: 18px;
  background: var(--color-primary);
  border-radius: 2px;
}

/* 段落块：段间距 16px，保证呼吸感 */
.doc-note {
  margin-bottom: 16px;
}

/* 段落级高频徽章：落日橘，行内小尺寸 */
.hot-badge--inline {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  font-size: 11px;
  font-weight: 600;
  color: #fff;
  background: var(--color-accent);
  border-radius: 10px;
  padding: 2px 8px;
}

/* 笔记标签 + 徽章所在行 */
.doc-note-meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
  margin-bottom: 6px;
}

/* 笔记标签：青绿描边小胶囊，与高频徽章同尺寸 */
.note-tag {
  display: inline-flex;
  align-items: center;
  font-size: 11px;
  font-weight: 600;
  color: var(--color-primary-dark);
  background: #fff;
  border: 1px solid var(--color-primary);
  border-radius: 10px;
  padding: 2px 16px;
  line-height: 2;
}
</style>

<style scoped>
.home-body {
  max-width: 1280px;
  margin: 0 auto;
  padding: 24px;
  display: flex;
  gap: 24px;
  align-items: flex-start;
}

/* 左侧目录 */
.sidebar {
  width: 300px;
  flex-shrink: 0;
  background: #fff;
  border-radius: 12px;
  padding: 12px 8px;
  box-shadow: 0 2px 12px rgba(51, 49, 46, 0.06);
  max-height: calc(100vh - 112px);
  overflow-y: auto;
  position: sticky;
  top: 88px;
}

.sidebar :deep(.el-tree) {
  background: transparent;
  --el-tree-node-hover-bg-color: rgba(74, 155, 142, 0.08);
}

.sidebar :deep(.el-tree-node__content) {
  height: 38px;
  border-radius: 8px;
  border-left: 3px solid transparent;
  transition: all 0.2s ease;
}

.sidebar :deep(.el-tree-node.is-current > .el-tree-node__content) {
  background-color: rgba(74, 155, 142, 0.14);
  border-left-color: var(--color-primary);
  color: var(--color-primary-dark);
  font-weight: 600;
}

.tree-node {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex: 1;
  padding-right: 8px;
  overflow: hidden;
}

.tree-node-name {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.tree-node-count {
  font-size: 12px;
  color: var(--color-text-secondary);
  background: var(--color-bg);
  border-radius: 10px;
  padding: 0 8px;
  flex-shrink: 0;
}

/* 右侧内容 */
.content {
  flex: 1;
  min-width: 0;
}

.content-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
  padding: 0 4px;
}

.crumb {
  font-size: 14px;
  color: var(--color-text-secondary);
}
.crumb::before {
  content: '';
  display: inline-block;
  width: 4px;
  height: 14px;
  background: var(--color-primary);
  border-radius: 2px;
  margin-right: 8px;
  vertical-align: -2px;
}

.total {
  font-size: 13px;
  color: var(--color-text-secondary);
}

.loading-wrap {
  display: flex;
  justify-content: center;
  padding: 80px 0;
}

/* 整页白底文档容器：模拟纸张阅读体验 */
.article-container {
  background: #fff;
  border-radius: 14px;
  box-shadow: 0 4px 24px rgba(51, 49, 46, 0.08);
  padding: 48px 56px 64px;
  max-width: 880px;
  margin: 0 auto;
}

/* 高频考点落日橘徽章（用于 DocSection 函数式组件内部） */
:deep(.hot-badge) {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  font-size: 12px;
  font-weight: 600;
  color: #fff;
  background: var(--color-accent);
  border-radius: 12px;
  padding: 4px 12px;
  white-space: nowrap;
}

@media (max-width: 900px) {
  .home-body {
    flex-direction: column;
  }
  .sidebar {
    width: 100%;
    position: static;
    max-height: 320px;
  }
  .article-container {
    padding: 28px 22px 40px;
  }
}
</style>
