import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 快捷指令页面
class CommandsPage extends StatefulWidget {
  const CommandsPage({super.key});

  @override
  State<CommandsPage> createState() => _CommandsPageState();
}

class _CommandsPageState extends State<CommandsPage> {
  String _selectedCategory = '全部';
  final List<String> _categories = ['全部', '系统管理', '文件操作', '网络工具', '开发工具'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 页面标题和操作
        _buildHeader(),
        const SizedBox(height: 24),
        // 分类筛选
        _buildCategoryFilter(),
        const SizedBox(height: 16),
        // 指令列表
        Expanded(
          child: _buildCommandsList(),
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
              '快捷指令',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '管理和执行常用的shell命令',
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
              tooltip: '搜索指令',
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () {
                // TODO: 实现添加指令功能
                _showAddCommandDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text('添加指令'),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建分类筛选器
  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          final isSelected = category == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建指令列表
  Widget _buildCommandsList() {
    final commands = _getFilteredCommands();

    if (commands.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: commands.length,
      itemBuilder: (context, index) {
        return _buildCommandCard(commands[index]);
      },
    );
  }

  /// 获取筛选后的指令
  List<CommandItem> _getFilteredCommands() {
    final allCommands = _getMockCommands();
    
    if (_selectedCategory == '全部') {
      return allCommands;
    }
    
    return allCommands.where((cmd) => cmd.category == _selectedCategory).toList();
  }

  /// 获取模拟指令数据
  List<CommandItem> _getMockCommands() {
    return [
      CommandItem(
        name: '查看系统信息',
        command: 'uname -a',
        description: '显示系统的详细信息',
        category: '系统管理',
      ),
      CommandItem(
        name: '查看磁盘使用情况',
        command: 'df -h',
        description: '以人性化格式显示磁盘使用情况',
        category: '系统管理',
      ),
      CommandItem(
        name: '查看内存使用',
        command: 'free -h',
        description: '显示内存使用情况',
        category: '系统管理',
      ),
      CommandItem(
        name: '列出文件详情',
        command: 'ls -la',
        description: '显示目录中所有文件的详细信息',
        category: '文件操作',
      ),
      CommandItem(
        name: '查找文件',
        command: 'find . -name "*.txt"',
        description: '在当前目录及子目录中查找txt文件',
        category: '文件操作',
      ),
      CommandItem(
        name: '测试网络连接',
        command: 'ping -c 4 google.com',
        description: '向Google发送4个ping包测试网络',
        category: '网络工具',
      ),
      CommandItem(
        name: '查看端口占用',
        command: 'netstat -tulpn',
        description: '显示所有监听端口和进程',
        category: '网络工具',
      ),
      CommandItem(
        name: 'Git状态',
        command: 'git status',
        description: '查看Git仓库当前状态',
        category: '开发工具',
      ),
      CommandItem(
        name: 'Docker容器列表',
        command: 'docker ps -a',
        description: '显示所有Docker容器',
        category: '开发工具',
      ),
    ];
  }

  /// 构建指令卡片
  Widget _buildCommandCard(CommandItem command) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        command.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        command.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    command.category,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      command.command,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copyCommand(command.command),
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: '复制命令',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editCommand(command),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('编辑'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _executeCommand(command),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('执行'),
                ),
              ],
            ),
          ],
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
            Icons.terminal,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedCategory == '全部' ? '还没有保存任何指令' : '该分类下没有指令',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加常用的shell命令以便快速访问',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _showAddCommandDialog,
            icon: const Icon(Icons.add),
            label: const Text('添加指令'),
          ),
        ],
      ),
    );
  }

  /// 复制命令
  void _copyCommand(String command) {
    Clipboard.setData(ClipboardData(text: command));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('命令已复制到剪贴板')),
    );
  }

  /// 执行命令
  void _executeCommand(CommandItem command) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('执行命令'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('即将执行命令：'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                command.command,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            Text('执行命令功能正在开发中...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('正在执行: ${command.command}')),
              );
            },
            child: const Text('执行'),
          ),
        ],
      ),
    );
  }

  /// 编辑命令
  void _editCommand(CommandItem command) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑 ${command.name}'),
        content: const Text('编辑指令功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示添加指令对话框
  void _showAddCommandDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加指令'),
        content: const Text('添加指令功能正在开发中...'),
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

/// 指令项模型
class CommandItem {
  final String name;
  final String command;
  final String description;
  final String category;

  CommandItem({
    required this.name,
    required this.command,
    required this.description,
    required this.category,
  });
}
