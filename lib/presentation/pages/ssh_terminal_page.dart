import 'package:flutter/material.dart';
import '../../data/models/ssh_host.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/ssh_debug_helper.dart';
import '../widgets/ssh_terminal.dart';

/// SSH终端页面 - 在右侧内容区域显示
class SSHTerminalPage extends StatefulWidget {
  final SSHHost host;

  const SSHTerminalPage({
    super.key,
    required this.host,
  });

  @override
  State<SSHTerminalPage> createState() => _SSHTerminalPageState();
}

class _SSHTerminalPageState extends State<SSHTerminalPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<SSHTerminalTab> _tabs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
    _addNewTab();
    AppLogger.info('SSH终端页面初始化', tag: 'SSHTerminal');
  }

  @override
  void dispose() {
    _tabController.dispose();
    // 清理所有标签页
    for (final tab in _tabs) {
      tab.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部工具栏
        _buildToolbar(),
        // 标签页栏
        if (_tabs.isNotEmpty) _buildTabBar(),
        // 终端内容区域
        Expanded(
          child: _tabs.isNotEmpty
              ? TabBarView(
                  controller: _tabController,
                  children: _tabs.map((tab) => _buildTerminalView(tab)).toList(),
                )
              : _buildEmptyState(),
        ),
      ],
    );
  }

  /// 构建工具栏
  Widget _buildToolbar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 主机信息
          Icon(
            Icons.computer,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            widget.host.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.host.host}:${widget.host.port}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ),
          const Spacer(),
          // 操作按钮
          IconButton(
            onPressed: _addNewTab,
            icon: const Icon(Icons.add),
            tooltip: '新建终端',
          ),
          IconButton(
            onPressed: _runSSHDiagnostic,
            icon: const Icon(Icons.bug_report),
            tooltip: 'SSH连接诊断',
          ),
          IconButton(
            onPressed: _closeAllTabs,
            icon: const Icon(Icons.close_fullscreen),
            tooltip: '关闭所有终端',
          ),
        ],
      ),
    );
  }

  /// 构建标签页栏
  Widget _buildTabBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        tabs: _tabs.map((tab) => Tab(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 连接状态指示器
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _getTabStatusColor(tab),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  tab.title,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _closeTab(tab.id),
                  child: const Icon(Icons.close, size: 14),
                ),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  /// 构建终端视图
  Widget _buildTerminalView(SSHTerminalTab tab) {
    // 使用新的SSH终端组件
    return SSHTerminal(
      host: widget.host,
      onClose: () => _closeTab(tab.id),
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
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '没有活跃的终端',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击 + 按钮创建新的终端连接',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取标签页状态颜色
  Color _getTabStatusColor(SSHTerminalTab tab) {
    if (tab.isConnecting) {
      return Colors.orange;
    } else {
      return Colors.green; // 简化状态显示
    }
  }

  /// 添加新标签页
  void _addNewTab() {
    final newTab = SSHTerminalTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '终端 ${_tabs.length + 1}',
    );

    setState(() {
      _tabs.add(newTab);
    });

    // 更新TabController
    _tabController.dispose();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: _tabs.length - 1,
    );

    // 连接到主机
    _connectTab(newTab);
  }

  /// 关闭标签页
  void _closeTab(String tabId) {
    final tabIndex = _tabs.indexWhere((tab) => tab.id == tabId);
    if (tabIndex == -1) return;

    final tab = _tabs[tabIndex];
    tab.dispose();

    setState(() {
      _tabs.removeAt(tabIndex);
    });

    if (_tabs.isEmpty) {
      _tabController.dispose();
      _tabController = TabController(length: 0, vsync: this);
    } else {
      final newIndex = tabIndex >= _tabs.length ? _tabs.length - 1 : tabIndex;
      _tabController.dispose();
      _tabController = TabController(
        length: _tabs.length,
        vsync: this,
        initialIndex: newIndex,
      );
    }
  }

  /// 关闭所有标签页
  void _closeAllTabs() {
    for (final tab in _tabs) {
      tab.dispose();
    }

    setState(() {
      _tabs.clear();
    });

    _tabController.dispose();
    _tabController = TabController(length: 0, vsync: this);
  }

  /// 运行SSH诊断
  Future<void> _runSSHDiagnostic() async {
    try {
      final debugHelper = SSHDebugHelper();
      final report = await debugHelper.generateDiagnosticReport(widget.host);

      // 显示诊断报告对话框
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('SSH连接诊断报告'),
            content: SingleChildScrollView(
              child: Text(
                report,
                style: const TextStyle(fontFamily: 'JetBrainsMono'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      AppLogger.exception('SSHTerminal', 'runSSHDiagnostic', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('诊断失败: $e')),
        );
      }
    }
  }

  /// 连接标签页
  Future<void> _connectTab(SSHTerminalTab tab) async {
    // 新的SSHTerminal组件会自己处理连接，这里只需要设置状态
    tab.isConnecting = false;
    AppLogger.info('创建新的SSH终端标签页: ${tab.title}', tag: 'SSHTerminal');
  }


}

/// SSH终端标签页数据模型
class SSHTerminalTab {
  final String id;
  final String title;
  bool isConnecting;

  SSHTerminalTab({
    required this.id,
    required this.title,
  }) : isConnecting = false;

  void dispose() {
    // 连接现在由SSHTerminal组件管理
  }
}
