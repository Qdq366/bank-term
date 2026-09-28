const mongoose = require('mongoose');
const Category = require('../models/Category');
const Note = require('../models/Note');
const { success, fail } = require('../utils/response');

// GET /api/categories/tree 获取三级分类树（每个节点带笔记数量）
async function getTree(req, res, next) {
  try {
    const [categories, noteCounts] = await Promise.all([
      Category.find().sort({ level: 1, order: 1 }).lean(),
      Note.aggregate([{ $group: { _id: '$categoryId', count: { $sum: 1 } } }])
    ]);
    const countMap = new Map(noteCounts.map((c) => [String(c._id), c.count]));

    const nodes = categories.map((c) => ({
      ...c,
      parentId: c.parentId ? String(c.parentId) : null,
      noteCount: countMap.get(String(c._id)) || 0,
      children: []
    }));
    const map = new Map(nodes.map((n) => [String(n._id), n]));
    const tree = [];
    for (const node of nodes) {
      if (node.parentId && map.has(node.parentId)) {
        map.get(node.parentId).children.push(node);
      } else {
        tree.push(node);
      }
    }

    // 递归汇总：父级 noteCount 累加所有子孙节点的笔记数
    function sumChildren(node) {
      let sum = node.noteCount;
      for (const child of node.children) {
        sum += sumChildren(child);
      }
      node.noteCount = sum;
      return sum;
    }
    for (const root of tree) sumChildren(root);

    return success(res, tree);
  } catch (err) {
    next(err);
  }
}

// POST /api/categories 新增分类（需鉴权）
async function createCategory(req, res, next) {
  try {
    const { name, parentId = null } = req.body || {};
    if (!name || !name.trim()) return fail(res, '分类名称不能为空', 400, 400);

    let level = 1;
    if (parentId) {
      if (!mongoose.isValidObjectId(parentId)) return fail(res, '父级分类无效', 400, 400);
      const parent = await Category.findById(parentId);
      if (!parent) return fail(res, '父级分类不存在', 404, 404);
      if (parent.level >= 3) return fail(res, '最多支持三级分类', 400, 400);
      level = parent.level + 1;
    }

    const maxOrder = await Category.findOne({ parentId: parentId || null })
      .sort({ order: -1 })
      .lean();
    const category = await Category.create({
      name: name.trim(),
      level,
      parentId: parentId || null,
      order: maxOrder ? maxOrder.order + 1 : 1
    });
    return success(res, category, '分类创建成功');
  } catch (err) {
    next(err);
  }
}

// PUT /api/categories/:id 重命名分类（需鉴权）
async function renameCategory(req, res, next) {
  try {
    const { name } = req.body || {};
    if (!name || !name.trim()) return fail(res, '分类名称不能为空', 400, 400);
    const category = await Category.findByIdAndUpdate(
      req.params.id,
      { name: name.trim() },
      { new: true }
    );
    if (!category) return fail(res, '分类不存在', 404, 404);
    return success(res, category, '分类已重命名');
  } catch (err) {
    next(err);
  }
}

// DELETE /api/categories/:id 删除分类（需鉴权，子分类与笔记一并删除）
async function deleteCategory(req, res, next) {
  try {
    const id = req.params.id;
    if (!mongoose.isValidObjectId(id)) return fail(res, '分类无效', 400, 400);

    // 收集该分类及所有后代分类 id
    const all = await Category.find().lean();
    const childMap = new Map();
    for (const c of all) {
      const p = c.parentId ? String(c.parentId) : null;
      if (!childMap.has(p)) childMap.set(p, []);
      childMap.get(p).push(String(c._id));
    }
    const ids = [String(id)];
    const queue = [String(id)];
    while (queue.length) {
      const cur = queue.shift();
      for (const child of childMap.get(cur) || []) {
        ids.push(child);
        queue.push(child);
      }
    }

    const noteResult = await Note.deleteMany({ categoryId: { $in: ids } });
    const catResult = await Category.deleteMany({ _id: { $in: ids } });
    return success(res, {
      deletedCategories: catResult.deletedCount,
      deletedNotes: noteResult.deletedCount
    }, '分类已删除');
  } catch (err) {
    next(err);
  }
}

module.exports = { getTree, createCategory, renameCategory, deleteCategory };
