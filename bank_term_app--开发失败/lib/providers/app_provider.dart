import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

/// 全局数据：分类树 + 笔记 + 长文档小节
class AppProvider extends ChangeNotifier {
  List<Category> _tree = [];
  List<Note> _notes = [];
  Category? _selected; // null = 全部
  String _keyword = '';
  bool _importantOnly = false;
  bool _loading = false;

  List<Category> get tree => _tree;
  List<Note> get notes => _notes;
  Category? get selected => _selected;
  String get keyword => _keyword;
  bool get importantOnly => _importantOnly;
  bool get loading => _loading;

  Future<void> loadTree() async {
    final data = await ApiService().getCategoryTree();
    _tree = (data as List).map((e) => Category.fromJson(e)).toList();
    notifyListeners();
  }

  Future<void> loadNotes() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await ApiService().getNotes(
        categoryId: _selected?.id,
        keyword: _keyword,
        important: _importantOnly ? true : null,
      );
      _notes = (data['list'] as List).map((e) => Note.fromJson(e)).toList();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void selectCategory(Category? c) {
    _selected = c;
    loadNotes();
  }

  void setKeyword(String k) {
    _keyword = k;
    loadNotes();
  }

  void setImportantOnly(bool v) {
    _importantOnly = v;
    loadNotes();
  }

  /* ---------- 笔记 CRUD ---------- */
  Future<void> toggleImportant(Note note, bool v) async {
    await ApiService().updateNote(note.id, {'isImportant': v});
    await loadNotes();
  }

  Future<void> saveNote({String? id, required Map<String, dynamic> payload}) async {
    if (id == null) {
      await ApiService().createNote(payload);
    } else {
      await ApiService().updateNote(id, payload);
    }
    await loadTree();
    await loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await ApiService().deleteNote(id);
    await loadTree();
    await loadNotes();
  }

  /* ---------- 分类 CRUD ---------- */
  Future<void> addCategory(String name, String? parentId) async {
    await ApiService().createCategory(name, parentId);
    await loadTree();
  }

  Future<void> renameCategory(String id, String name) async {
    await ApiService().renameCategory(id, name);
    await loadTree();
  }

  Future<void> deleteCategory(String id) async {
    await ApiService().deleteCategory(id);
    if (_selected?.id == id) _selected = null;
    await loadTree();
    await loadNotes();
  }

  /* ---------- 长文档构建：级联聚合 ---------- */
  /// 从选中节点（或全部）出发，DFS 生成连贯的 DocSection 列表
  List<DocSection> buildSections() {
    final noteMap = <String, List<Note>>{};
    for (final n in _notes) {
      noteMap.putIfAbsent(n.categoryId, () => []).add(n);
    }
    final sections = <DocSection>[];

    void walk(Category node, int headingLevel) {
      final own = noteMap[node.id] ?? [];
      if (own.isNotEmpty || node.children.isNotEmpty) {
        if (own.isNotEmpty || node.children.isNotEmpty) {
          sections.add(DocSection(node, headingLevel.clamp(2, 3), own));
        }
        for (final child in node.children) {
          walk(child, headingLevel + 1);
        }
      }
    }

    if (_selected != null) {
      walk(_selected!, 2);
    } else {
      for (final top in _tree) {
        walk(top, 2);
      }
    }
    return sections;
  }

  /// 面包屑
  String crumb() {
    if (_selected == null) return '全部知识点';
    final path = <String>[];
    bool find(List<Category> nodes, String id, List<String> trail) {
      for (final n in nodes) {
        final next = [...trail, n.name];
        if (n.id == id) {
          path.addAll(next);
          return true;
        }
        if (find(n.children, id, next)) return true;
      }
      return false;
    }

    find(_tree, _selected!.id, []);
    return path.join(' / ');
  }
}
