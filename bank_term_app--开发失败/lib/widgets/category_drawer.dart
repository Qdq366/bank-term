import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';

/// 左侧抽屉：三级折叠目录树（含分类新增/重命名/删除）
class CategoryDrawer extends StatelessWidget {
  const CategoryDrawer({super.key});

  static const _primary = Color(0xFF4A9B8E);

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // 头部
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: _primary,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.account_balance, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text('银行备考知识库',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // 全部知识点 + 新增一级
            ListTile(
              leading: const Icon(Icons.library_books, color: _primary),
              title: const Text('全部知识点',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle_outline, color: _primary),
                tooltip: '新增一级科目',
                onPressed: () => _editCategory(context, null, null),
              ),
              onTap: () {
                prov.selectCategory(null);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            // 树
            Expanded(
              child: prov.tree.isEmpty
                  ? const Center(child: Text('暂无分类'))
                  : ListView(
                      children: prov.tree
                          .map((c) => _CategoryTile(category: c, depth: 0))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 新增 / 重命名分类弹窗；parent 为 null 表示新建一级
  static Future<void> _editCategory(
      BuildContext context, Category? parent, Category? editing) async {
    final ctrl = TextEditingController(text: editing?.name ?? '');
    final isRename = editing != null;
    final title = isRename
        ? '重命名分类'
        : (parent == null ? '新增一级科目' : '在「${parent.name}」下新增子分类');
    final prov = context.read<AppProvider>();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '请输入分类名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    try {
      if (isRename) {
        await prov.renameCategory(editing.id, result);
      } else {
        await prov.addCategory(result, parent?.id);
      }
      Fluttertoast.showToast(msg: isRename ? '已重命名' : '分类已创建');
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<void> _deleteCategory(BuildContext context, Category c) async {
    final prov = context.read<AppProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除分类'),
        content: Text('确定删除「${c.name}」及其全部子分类和笔记吗？'),
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
      await prov.deleteCategory(c.id);
      Fluttertoast.showToast(msg: '分类已删除');
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final int depth;

  const _CategoryTile({required this.category, required this.depth});

  static const _primary = Color(0xFF4A9B8E);

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final selected = prov.selected?.id == category.id;

    final title = Row(
      children: [
        Expanded(
          child: Text(
            category.name,
            style: TextStyle(
              fontSize: depth == 0 ? 15 : 14,
              fontWeight: depth == 0 ? FontWeight.bold : FontWeight.normal,
              color: selected ? _primary : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (category.noteCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0E8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${category.noteCount}',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
        // 长按管理
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
          onSelected: (v) {
            if (v == 'add') CategoryDrawer._editCategory(context, category, null);
            if (v == 'rename') CategoryDrawer._editCategory(context, null, category);
            if (v == 'delete') CategoryDrawer._deleteCategory(context, category);
          },
          itemBuilder: (_) => [
            if (category.level < 3)
              const PopupMenuItem(value: 'add', child: Text('添加子级')),
            const PopupMenuItem(value: 'rename', child: Text('重命名')),
            const PopupMenuItem(
                value: 'delete',
                child: Text('删除', style: TextStyle(color: Colors.red))),
          ],
        ),
      ],
    );

    void onTap() {
      prov.selectCategory(category);
      Navigator.pop(context);
    }

    if (category.children.isEmpty) {
      return ListTile(
        dense: true,
        contentPadding: EdgeInsets.only(left: 16.0 + depth * 12, right: 4),
        title: title,
        selected: selected,
        onTap: onTap,
      );
    }

    return ExpansionTile(
      tilePadding: EdgeInsets.only(left: 16.0 + depth * 12, right: 4),
      childrenPadding: EdgeInsets.zero,
      // 标题区点击：选中分类并关闭抽屉；右侧箭头仍可展开/收起
      title: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: title,
      ),
      initiallyExpanded: depth == 0,
      iconColor: _primary,
      collapsedIconColor: Colors.grey,
      children: category.children
          .map((c) => _CategoryTile(category: c, depth: depth + 1))
          .toList(),
    );
  }
}
