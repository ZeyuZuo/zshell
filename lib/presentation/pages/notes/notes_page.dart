import 'package:flutter/material.dart';

/// 笔记页面
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  String _selectedTag = '全部';
  final List<String> _tags = ['全部', '运维', '开发', '故障排查', '配置'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 页面标题和操作
        _buildHeader(),
        const SizedBox(height: 24),
        // 标签筛选
        _buildTagFilter(),
        const SizedBox(height: 16),
        // 笔记列表
        Expanded(
          child: _buildNotesList(),
        ),
      ],
    );
  }

  /// 构建页面头部
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '笔记',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '记录和管理运维相关笔记',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                // TODO: 实现搜索功能
              },
              icon: const Icon(Icons.search),
              tooltip: '搜索笔记',
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () {
                // TODO: 实现添加笔记功能
                _showAddNoteDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text('新建笔记'),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建标签筛选器
  Widget _buildTagFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tags.map((tag) {
          final isSelected = tag == _selectedTag;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedTag = tag;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建笔记列表
  Widget _buildNotesList() {
    final notes = _getFilteredNotes();

    if (notes.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        return _buildNoteCard(notes[index]);
      },
    );
  }

  /// 获取筛选后的笔记
  List<NoteItem> _getFilteredNotes() {
    final allNotes = _getMockNotes();
    
    if (_selectedTag == '全部') {
      return allNotes;
    }
    
    return allNotes.where((note) => note.tags.contains(_selectedTag)).toList();
  }

  /// 获取模拟笔记数据
  List<NoteItem> _getMockNotes() {
    return [
      NoteItem(
        title: 'Nginx配置优化',
        content: '记录Nginx性能优化的相关配置...\n\n'
            '1. worker_processes auto;\n'
            '2. worker_connections 1024;\n'
            '3. gzip压缩配置\n'
            '4. 缓存设置',
        tags: ['运维', '配置'],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      NoteItem(
        title: 'Docker常用命令',
        content: '整理常用的Docker命令和技巧...\n\n'
            '• docker ps -a\n'
            '• docker logs container_name\n'
            '• docker exec -it container_name bash\n'
            '• docker-compose up -d',
        tags: ['开发', '运维'],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      NoteItem(
        title: '服务器故障排查流程',
        content: '系统性的故障排查步骤...\n\n'
            '1. 检查系统负载 (top, htop)\n'
            '2. 查看磁盘空间 (df -h)\n'
            '3. 检查内存使用 (free -h)\n'
            '4. 查看系统日志 (/var/log/)\n'
            '5. 网络连接检查 (netstat)',
        tags: ['故障排查', '运维'],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      NoteItem(
        title: 'Git工作流最佳实践',
        content: '团队Git协作的最佳实践...\n\n'
            '• 使用feature分支开发\n'
            '• 提交信息规范\n'
            '• Code Review流程\n'
            '• 合并策略选择',
        tags: ['开发'],
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  /// 构建笔记卡片
  Widget _buildNoteCard(NoteItem note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openNote(note),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('编辑'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16),
                            SizedBox(width: 8),
                            Text('删除'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editNote(note);
                      } else if (value == 'delete') {
                        _deleteNote(note);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      children: note.tags.map((tag) => Chip(
                        label: Text(
                          tag,
                          style: const TextStyle(fontSize: 12),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                  ),
                  Text(
                    _formatDate(note.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedTag == '全部' ? '还没有创建任何笔记' : '该标签下没有笔记',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '记录运维经验和技术要点',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _showAddNoteDialog,
            icon: const Icon(Icons.add),
            label: const Text('新建笔记'),
          ),
        ],
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 打开笔记
  void _openNote(NoteItem note) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    note.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 4,
                    children: note.tags.map((tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 12)),
                    )).toList(),
                  ),
                  Text(
                    '更新于 ${_formatDate(note.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 编辑笔记
  void _editNote(NoteItem note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑 ${note.title}'),
        content: const Text('编辑笔记功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 删除笔记
  void _deleteNote(NoteItem note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除笔记 "${note.title}" 吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已删除笔记 ${note.title}')),
              );
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 显示添加笔记对话框
  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建笔记'),
        content: const Text('新建笔记功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 笔记项模型
class NoteItem {
  final String title;
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteItem({
    required this.title,
    required this.content,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });
}
