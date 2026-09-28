<template>
  <!-- 文档块级渲染器：段落 / 有序列表 / 无序列表 / 标题 / 公式，支持 **加粗高亮** -->
  <div class="md-doc">
    <template v-for="(block, i) in blocks" :key="i">
      <!-- 标题 -->
      <h2 v-if="block.type === 'h' && block.level === 1" class="md-h" v-html="inline(block.text)"></h2>
      <h3 v-else-if="block.type === 'h' && block.level === 2" class="md-h md-h3" v-html="inline(block.text)"></h3>
      <h4 v-else-if="block.type === 'h'" class="md-h md-h4" v-html="inline(block.text)"></h4>

      <!-- 公式块 -->
      <div v-else-if="block.type === 'formula'" class="md-formula" v-html="inline(block.text)"></div>

      <!-- 有序列表 -->
      <ol v-else-if="block.type === 'ol'" class="md-ol">
        <li v-for="(item, j) in block.items" :key="j" v-html="inline(item)"></li>
      </ol>

      <!-- 无序列表 -->
      <ul v-else-if="block.type === 'ul'" class="md-ul">
        <li v-for="(item, j) in block.items" :key="j" v-html="inline(item)"></li>
      </ul>

      <!-- 普通段落 -->
      <p v-else class="md-p" v-html="inline(block.text)"></p>
    </template>
  </div>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
  content: { type: String, default: '' }
});

function escapeHtml(text) {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

// 行内渲染：**加粗** -> 粗体 + 浅落日橘高亮底色
function inline(text) {
  return escapeHtml(text).replace(/\*\*(.+?)\*\*/g, '<strong class="hl">$1</strong>');
}

// 公式判定：短句且包含数学符号（= ÷ × → ->）
function isFormula(line) {
  const plain = line.replace(/\*\*/g, '');
  if (plain.length > 42) return false;
  if (/[。，；：]/.test(plain)) return false;
  return /[=÷×]/.test(plain) || /->|→/.test(plain);
}

// 将原始文本解析为块级结构
function parseBlocks(content) {
  const blocks = [];
  let list = null;

  for (const raw of content.split('\n')) {
    const line = raw.trim();
    if (!line) {
      list = null;
      continue;
    }

    const headMatch = line.match(/^(#{1,4})\s+(.*)$/);
    const olMatch = line.match(/^\d+[\.、\)]\s*(.+)$/);
    const ulMatch = line.match(/^[•\-]\s+(.+)$/);

    if (headMatch) {
      list = null;
      blocks.push({ type: 'h', level: headMatch[1].length, text: headMatch[2] });
    } else if (olMatch) {
      if (!list || list.type !== 'ol') {
        list = { type: 'ol', items: [] };
        blocks.push(list);
      }
      list.items.push(olMatch[1]);
    } else if (ulMatch) {
      if (!list || list.type !== 'ul') {
        list = { type: 'ul', items: [] };
        blocks.push(list);
      }
      list.items.push(ulMatch[1]);
    } else {
      list = null;
      blocks.push({ type: isFormula(line) ? 'formula' : 'p', text: line });
    }
  }
  return blocks;
}

const blocks = computed(() => parseBlocks(props.content));
</script>

<style scoped>
.md-doc {
  font-size: 15px;
  color: var(--color-text);
  line-height: 1.8;
  word-break: break-word;
}

/* 段落：舒适行高与段间距 */
.md-p {
  margin: 0 0 14px;
}

.md-h {
  margin: 22px 0 12px;
  font-size: 20px;
  font-weight: 700;
}

.md-h3 {
  font-size: 17px;
}

.md-h4 {
  font-size: 15px;
}

/* 公式块：等宽感 + 米白底 + 青绿左边条 */
.md-formula {
  margin: 6px 0 16px;
  padding: 10px 16px;
  background: var(--color-bg);
  border-left: 3px solid var(--color-primary);
  border-radius: 0 8px 8px 0;
  font-family: 'Consolas', 'Courier New', monospace;
  font-size: 14px;
  color: var(--color-primary-dark);
  overflow-x: auto;
}

.md-ol,
.md-ul {
  margin: 0 0 14px;
  padding-left: 26px;
}

.md-ol li,
.md-ul li {
  margin-bottom: 8px;
  line-height: 1.8;
}

.md-ol li::marker {
  color: var(--color-primary);
  font-weight: 700;
}

.md-ul li::marker {
  color: var(--color-accent);
}

/* 加粗词句：粗体 + 浅落日橘高亮底色 */
.md-doc :deep(.hl) {
  font-weight: 700;
  background-color: var(--color-accent-light);
  color: #b95f33;
  padding: 0 4px;
  border-radius: 4px;
}
</style>
