const mongoose = require('mongoose');
const Category = require('../models/Category');
const Note = require('../models/Note');
const { success, fail } = require('../utils/response');

// GET /api/notes 笔记列表
// 查询参数：categoryId（含其所有后代分类）、keyword、important、page、pageSize（page=0 表示不分页）
async function listNotes(req, res, next) {
  try {
    const { categoryId, keyword, important, page = '1', pageSize = '10' } = req.query;
    const filter = {};

    if (categoryId && mongoose.isValidObjectId(categoryId)) {
      // 收集该分类及所有后代分类 id
      const all = await Category.find().lean();
      const childMap = new Map();
      for (const c of all) {
        const p = c.parentId ? String(c.parentId) : null;
        if (!childMap.has(p)) childMap.set(p, []);
        childMap.get(p).push(String(c._id));
      }
      const ids = [categoryId];
      const queue = [categoryId];
      while (queue.length) {
        const cur = queue.shift();
        for (const child of childMap.get(cur) || []) {
          ids.push(child);
          queue.push(child);
        }
      }
      filter.categoryId = { $in: ids.map((i) => new mongoose.Types.ObjectId(i)) };
    }

    if (important === 'true' || important === '1') {
      filter.isImportant = true;
    }

    if (keyword && keyword.trim()) {
      const reg = new RegExp(keyword.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
      filter.$or = [{ title: reg }, { content: reg }];
    }

    const pageNum = parseInt(page, 10);
    // page=0 表示返回全部（查阅端按章节浏览时使用）
    if (pageNum === 0) {
      const list = await Note.find(filter).sort({ createdAt: 1 }).lean();
      return success(res, { list, total: list.length });
    }

    const sizeNum = Math.min(Math.max(parseInt(pageSize, 10) || 10, 1), 500);
    const skip = (Math.max(pageNum, 1) - 1) * sizeNum;
    const [list, total] = await Promise.all([
      // 按创建时间正序：保持文档原始顺序，高频开关切换后行不跳动
      Note.find(filter).sort({ createdAt: 1 }).skip(skip).limit(sizeNum).lean(),
      Note.countDocuments(filter)
    ]);
    return success(res, { list, total, page: pageNum, pageSize: sizeNum });
  } catch (err) {
    next(err);
  }
}

// POST /api/notes 新增笔记（需鉴权）
async function createNote(req, res, next) {
  try {
    const { categoryId, title, content, tags = [], isImportant = false } = req.body || {};
    if (!categoryId || !mongoose.isValidObjectId(categoryId)) return fail(res, '请选择所属分类', 400, 400);
    if (!title || !title.trim()) return fail(res, '标题不能为空', 400, 400);
    if (!content || !content.trim()) return fail(res, '正文内容不能为空', 400, 400);
    const cat = await Category.findById(categoryId);
    if (!cat) return fail(res, '所属分类不存在', 404, 404);

    const note = await Note.create({
      categoryId,
      title: title.trim(),
      content: content.trim(),
      tags: Array.isArray(tags) ? tags : [],
      isImportant: !!isImportant
    });
    return success(res, note, '笔记已保存入库');
  } catch (err) {
    next(err);
  }
}

// PUT /api/notes/:id 更新笔记（需鉴权）
async function updateNote(req, res, next) {
  try {
    const { categoryId, title, content, tags, isImportant } = req.body || {};
    const update = {};
    if (categoryId !== undefined) {
      if (!mongoose.isValidObjectId(categoryId)) return fail(res, '所属分类无效', 400, 400);
      update.categoryId = categoryId;
    }
    if (title !== undefined) {
      if (!title.trim()) return fail(res, '标题不能为空', 400, 400);
      update.title = title.trim();
    }
    if (content !== undefined) {
      if (!content.trim()) return fail(res, '正文内容不能为空', 400, 400);
      update.content = content.trim();
    }
    if (tags !== undefined) update.tags = Array.isArray(tags) ? tags : [];
    if (isImportant !== undefined) update.isImportant = !!isImportant;

    const note = await Note.findByIdAndUpdate(req.params.id, update, { new: true });
    if (!note) return fail(res, '笔记不存在', 404, 404);
    return success(res, note, '笔记已更新');
  } catch (err) {
    next(err);
  }
}

// DELETE /api/notes/:id 删除笔记（需鉴权）
async function deleteNote(req, res, next) {
  try {
    const note = await Note.findByIdAndDelete(req.params.id);
    if (!note) return fail(res, '笔记不存在', 404, 404);
    return success(res, null, '笔记已删除');
  } catch (err) {
    next(err);
  }
}

module.exports = { listNotes, createNote, updateNote, deleteNote };
