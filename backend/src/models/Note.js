const mongoose = require('mongoose');

// 知识点笔记表模型
const noteSchema = new mongoose.Schema(
  {
    categoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Category', required: true },
    title: { type: String, required: true, trim: true },
    content: { type: String, required: true }, // 保留 ** 加粗标记的原文
    tags: { type: [String], default: [] },
    isImportant: { type: Boolean, default: false } // 高频考点标记
  },
  { timestamps: true }
);

noteSchema.index({ categoryId: 1 });

module.exports = mongoose.model('Note', noteSchema);
