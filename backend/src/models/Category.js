const mongoose = require('mongoose');

// 目录分类树表模型（最多三级）
const categorySchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    level: { type: Number, required: true, min: 1, max: 3 },
    parentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Category', default: null },
    order: { type: Number, default: 0 }
  },
  { timestamps: true }
);

categorySchema.index({ parentId: 1 });
categorySchema.index({ level: 1 });

module.exports = mongoose.model('Category', categorySchema);
