import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';

const _primary = Color(0xFF4A9B8E);
const _accent = Color(0xFFE08A5B);

/// 考点编辑/新增页
class NoteEditScreen extends StatefulWidget {
  final Note? note;
  final String? defaultCategoryId;

  const NoteEditScreen({super.key, this.note, this.defaultCategoryId});

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  String? _categoryId;
  bool _isImportant = false;
  bool _showPreview = false;
  bool _saving = false;

  bool get _isEdit => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.note?.content ?? '');
    _categoryId = widget.note?.categoryId ?? widget.defaultCategoryId;
    _isImportant = widget.note?.isImportant ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty) {
      Fluttertoast.showToast(msg: '请输入标题');
      return;
    }
    if (_categoryId == null || _categoryId!.isEmpty) {
      Fluttertoast.showToast(msg: '请选择所属分类');
      return;
    }
    if (content.isEmpty) {
      Fluttertoast.showToast(msg: '请输入正文内容');
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<AppProvider>().saveNote(
            id: widget.note?.id,
            payload: {
              'title': title,
              'categoryId': _categoryId,
              'content': content,
              'isImportant': _isImportant,
              'tags': widget.note?.tags ?? [],
            },
          );
      Fluttertoast.showToast(msg: _isEdit ? '笔记已更新' : '笔记已保存');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();

    // 拍平分类树用于下拉
    final items = <DropdownMenuItem<String>>[];
    void flatten(Category c, int depth) {
      items.add(DropdownMenuItem(
        value: c.id,
        child: Text('${'　' * depth}${c.name}'),
      ));
      for (final child in c.children) {
        flatten(child, depth + 1);
      }
    }

    for (final c in prov.tree) {
      flatten(c, 0);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(_isEdit ? '编辑考点' : '新增考点'),
        actions: [
          IconButton(
            tooltip: _showPreview ? '继续编辑' : '预览',
            icon: Icon(_showPreview ? Icons.edit_note : Icons.preview_outlined),
            onPressed: () => setState(() => _showPreview = !_showPreview),
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('保存',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: _deco('标题'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: items.any((e) => e.value == _categoryId) ? _categoryId : null,
              isExpanded: true,
              decoration: _deco('所属分类'),
              items: items,
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('设为高频考点', style: TextStyle(fontSize: 15)),
                  Switch(
                    value: _isImportant,
                    activeColor: _accent,
                    onChanged: (v) => setState(() => _isImportant = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // 编辑 / 预览
            _showPreview
                ? Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 300),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: MarkdownBody(
                      data: _contentCtrl.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 15, height: 1.8),
                        strong: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB95F33),
                          backgroundColor: Color(0x33E08A5B),
                        ),
                      ),
                    ),
                  )
                : TextField(
                    controller: _contentCtrl,
                    maxLines: null,
                    minLines: 12,
                    keyboardType: TextInputType.multiline,
                    decoration: _deco('正文（用 **文字** 标记重点）'),
                  ),
          ],
        ),
      ),
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );
}
