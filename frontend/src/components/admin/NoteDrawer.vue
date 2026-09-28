<template>
  <!-- 新增/编辑笔记抽屉表单（右侧滑出，含实时预览） -->
  <el-drawer
    :model-value="visible"
    :title="isEdit ? '编辑笔记' : '新增笔记'"
    size="560px"
    :close-on-click-modal="false"
    destroy-on-close
    @update:model-value="$emit('update:visible', $event)"
    @closed="resetForm"
  >
    <div class="drawer-body">
      <el-form label-position="top">
        <el-form-item label="笔记标题" required>
          <el-input v-model="form.title" placeholder="请输入标题" maxlength="100" show-word-limit />
        </el-form-item>

        <el-form-item label="挂载分类" required>
          <el-tree-select
            v-model="form.categoryId"
            :data="categories"
            :props="{ label: 'name', children: 'children', value: '_id' }"
            node-key="_id"
            check-strictly
            :render-after-expand="false"
            placeholder="请选择所属分类"
            style="width: 100%"
          />
        </el-form-item>

        <el-form-item label="设为高频考点">
          <el-switch
            v-model="form.isImportant"
            style="--el-switch-on-color: #e08a5b"
          />
        </el-form-item>

        <el-form-item label="标签">
          <el-select
            v-model="form.tags"
            multiple
            filterable
            allow-create
            default-first-option
            placeholder="输入后回车创建标签"
            style="width: 100%"
          >
            <el-option label="计算题" value="计算题" />
            <el-option label="曲线规律" value="曲线规律" />
          </el-select>
        </el-form-item>

        <el-form-item label="正文内容（用 **文字** 标记重点）" required>
          <el-input
            v-model="form.content"
            type="textarea"
            :rows="8"
            placeholder="支持 **加粗** 标记，实时预览见下方"
          />
        </el-form-item>

        <div class="preview-box">
          <div class="preview-title">实时预览效果</div>
          <MarkdownViewer v-if="form.content" :content="form.content" />
          <p v-else class="preview-empty">输入内容后这里会即时渲染排版效果</p>
        </div>
      </el-form>
    </div>

    <template #footer>
      <div class="drawer-footer">
        <el-button @click="$emit('update:visible', false)">取消</el-button>
        <el-button type="primary" :loading="saving" @click="handleSave">保存入库</el-button>
      </div>
    </template>
  </el-drawer>
</template>

<script setup>
import { ref, reactive, computed, watch } from 'vue';
import { ElMessage } from 'element-plus';
import MarkdownViewer from '../portal/MarkdownViewer.vue';
import { createNote, updateNote } from '../../api/note';

const props = defineProps({
  visible: { type: Boolean, default: false },
  note: { type: Object, default: null },
  categories: { type: Array, default: () => [] },
  defaultCategoryId: { type: String, default: '' }
});

const emit = defineEmits(['update:visible', 'saved']);

const saving = ref(false);
const isEdit = computed(() => !!props.note);

const form = reactive({
  title: '',
  categoryId: '',
  content: '',
  tags: [],
  isImportant: false
});

watch(
  () => props.visible,
  (val) => {
    if (!val) return;
    if (props.note) {
      form.title = props.note.title;
      form.categoryId = props.note.categoryId;
      form.content = props.note.content;
      form.tags = [...(props.note.tags || [])];
      form.isImportant = !!props.note.isImportant;
    } else {
      form.title = '';
      form.categoryId = props.defaultCategoryId || '';
      form.content = '';
      form.tags = [];
      form.isImportant = false;
    }
  }
);

function resetForm() {
  form.title = '';
  form.categoryId = '';
  form.content = '';
  form.tags = [];
  form.isImportant = false;
}

async function handleSave() {
  if (!form.title.trim()) return ElMessage.warning('请输入笔记标题');
  if (!form.categoryId) return ElMessage.warning('请选择挂载分类');
  if (!form.content.trim()) return ElMessage.warning('请输入正文内容');

  saving.value = true;
  try {
    const payload = {
      title: form.title.trim(),
      categoryId: form.categoryId,
      content: form.content.trim(),
      tags: form.tags,
      isImportant: form.isImportant
    };
    if (isEdit.value) {
      await updateNote(props.note._id, payload);
      ElMessage.success('笔记已更新');
    } else {
      await createNote(payload);
      ElMessage.success('笔记已保存入库');
    }
    emit('update:visible', false);
    emit('saved');
  } catch {
    // 错误已由拦截器提示
  } finally {
    saving.value = false;
  }
}
</script>

<style scoped>
.drawer-body {
  padding: 0 4px;
}

.preview-box {
  margin-top: 4px;
  border: 1px dashed var(--color-border);
  border-radius: 10px;
  padding: 14px 16px;
  background: var(--color-bg);
}

.preview-title {
  font-size: 12px;
  font-weight: 600;
  color: var(--color-text-secondary);
  margin-bottom: 8px;
  letter-spacing: 1px;
}

.preview-empty {
  font-size: 13px;
  color: var(--color-text-secondary);
}

.drawer-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}
</style>
