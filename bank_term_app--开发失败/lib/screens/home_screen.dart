import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/category_drawer.dart';
import 'note_edit_screen.dart';

const _primary = Color(0xFF4A9B8E);
const _bg = Color(0xFFF5F0E8);
const _accent = Color(0xFFE08A5B);

/// 主界面：沉浸式长文档阅读 + 即时管理
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<AppProvider>();
      await prov.loadTree();
      await prov.loadNotes();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toastErr(Object e) =>
      Fluttertoast.showToast(msg: e.toString().replaceFirst('Exception: ', ''));

  Future<void> _confirmDelete(Note note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除考点'),
        content: Text('确定删除「${note.title}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context.read<AppProvider>().deleteNote(note.id);
      Fluttertoast.showToast(msg: '已删除');
    } catch (e) {
      _toastErr(e);
    }
  }

  Future<void> _openEditor({Note? note}) async {
    final prov = context.read<AppProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditScreen(
          note: note,
          defaultCategoryId: prov.selected?.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final sections = prov.buildSections();

    return Scaffold(
      backgroundColor: _bg,
      drawer: const CategoryDrawer(),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _searchCtrl,
            onChanged: prov.setKeyword,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: '秒搜知识点…',
              hintStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 20),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        actions: [
          // 仅看高频
          Row(
            children: [
              const Icon(Icons.star, size: 18, color: Colors.white),
              Switch(
                value: prov.importantOnly,
                activeColor: _accent,
                onChanged: prov.setImportantOnly,
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 面包屑 + 总数
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(prov.crumb(),
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      overflow: TextOverflow.ellipsis),
                ),
                Text('共 ${prov.notes.length} 条',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          // 长文档
          Expanded(
            child: prov.loading
                ? const Center(child: CircularProgressIndicator(color: _primary))
                : sections.isEmpty
                    ? const Center(
                        child: Text('未找到相关知识点',
                            style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        color: _primary,
                        onRefresh: () async {
                          await prov.loadTree();
                          await prov.loadNotes();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: sections.length,
                          itemBuilder: (context, i) =>
                              _SectionView(
                                section: sections[i],
                                onEdit: (n) => _openEditor(note: n),
                                onDelete: _confirmDelete,
                              ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accent,
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

/// 一个小节：H2/H3 标题 + 高频徽章 + 笔记段落
class _SectionView extends StatelessWidget {
  final DocSection section;
  final void Function(Note) onEdit;
  final void Function(Note) onDelete;

  const _SectionView({
    required this.section,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isH2 = section.headingLevel == 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Padding(
          padding: EdgeInsets.only(top: isH2 ? 20 : 14, bottom: 8),
          child: Row(
            children: [
              if (!isH2)
                Container(
                  width: 4,
                  height: 18,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Flexible(
                child: Text(
                  section.category.name,
                  style: TextStyle(
                    fontSize: isH2 ? 22 : 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF33312E),
                  ),
                ),
              ),
              if (section.isImportant) ...[
                const SizedBox(width: 8),
                _hotBadge(),
              ],
            ],
          ),
        ),
        if (isH2) const Divider(height: 1),
        // 笔记段落
        for (final note in section.notes)
          _NoteBlock(note: note, onEdit: onEdit, onDelete: onDelete),
      ],
    );
  }

  Widget _hotBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _accent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 12, color: Colors.white),
            SizedBox(width: 3),
            Text('高频考点',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

/// 单条笔记：标题 + 高频开关 + 编辑/删除 + Markdown 正文
class _NoteBlock extends StatelessWidget {
  final Note note;
  final void Function(Note) onEdit;
  final void Function(Note) onDelete;

  const _NoteBlock({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.read<AppProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 管理操作行
          Row(
            children: [
              Expanded(
                child: Text(
                  note.title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 高频开关
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: note.isImportant,
                  activeColor: _accent,
                  onChanged: (v) async {
                    try {
                      await prov.toggleImportant(note, v);
                    } catch (e) {
                      Fluttertoast.showToast(
                          msg: e.toString().replaceFirst('Exception: ', ''));
                    }
                  },
                ),
              ),
              InkWell(
                onTap: () => onEdit(note),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.edit_outlined, size: 20, color: _primary),
                ),
              ),
              InkWell(
                onTap: () => onDelete(note),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.delete_outline, size: 20, color: Colors.red),
                ),
              ),
            ],
          ),
          // Markdown 正文（**加粗** 渲染为粗体 + 柔和橘色底）
          MarkdownBody(
            data: note.content,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 15, height: 1.8, color: Color(0xFF33312E)),
              strong: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFB95F33),
                backgroundColor: Color(0x33E08A5B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
