/// 分类节点（三级树）
class Category {
  final String id;
  final String name;
  final int level;
  final int noteCount;
  final List<Category> children;

  Category({
    required this.id,
    required this.name,
    this.level = 1,
    this.noteCount = 0,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['_id'] ?? '',
        name: j['name'] ?? '',
        level: j['level'] ?? 1,
        noteCount: j['noteCount'] ?? 0,
        children:
            (j['children'] as List?)?.map((e) => Category.fromJson(e)).toList() ?? [],
      );
}

/// 笔记
class Note {
  final String id;
  final String title;
  final String categoryId;
  final String content;
  final bool isImportant;
  final List<String> tags;

  Note({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.content,
    this.isImportant = false,
    this.tags = const [],
  });

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['_id'] ?? '',
        title: j['title'] ?? '',
        categoryId: j['categoryId'] ?? '',
        content: j['content'] ?? '',
        isImportant: j['isImportant'] ?? false,
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
}

/// 文档小节（长文档渲染用）：一个分类节点 + 它直属的笔记
class DocSection {
  final Category category;
  final int headingLevel; // 2=H2, 3=H3
  final List<Note> notes;

  DocSection(this.category, this.headingLevel, this.notes);

  bool get isImportant => notes.any((n) => n.isImportant);
}
