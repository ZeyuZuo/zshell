import 'package:flutter/material.dart';
import '../widgets/ssh_terminal.dart';
import '../../data/models/ssh_host.dart';

/// SSH连接页面
class SSHConnectionPage extends StatefulWidget {
  final SSHHost host;

  const SSHConnectionPage({
    super.key,
    required this.host,
  });

  @override
  State<SSHConnectionPage> createState() => _SSHConnectionPageState();
}

class _SSHConnectionPageState extends State<SSHConnectionPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<SSHTerminalTab> _tabs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
    _addNewTab();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SSH连接 - ${widget.host.name}'),
        bottom: _tabs.isNotEmpty
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _tabs.map((tab) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tab.title),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _closeTab(tab.id),
                        child: const Icon(Icons.close, size: 16),
                      ),
                    ],
                  ),
                )).toList(),
              )
            : null,
        actions: [
          IconButton(
            onPressed: _addNewTab,
            icon: const Icon(Icons.add),
            tooltip: '新建终端',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: '关闭连接',
          ),
        ],
      ),
      body: _tabs.isNotEmpty
          ? TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) => SSHTerminal(
                host: widget.host,
                onClose: () => _closeTab(tab.id),
              )).toList(),
            )
          : const Center(
              child: Text('没有活跃的终端'),
            ),
    );
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
  }

  /// 关闭标签页
  void _closeTab(String tabId) {
    final index = _tabs.indexWhere((tab) => tab.id == tabId);
    if (index == -1) return;

    setState(() {
      _tabs.removeAt(index);
    });

    if (_tabs.isEmpty) {
      // 如果没有标签页了，关闭整个连接页面
      Navigator.of(context).pop();
      return;
    }

    // 更新TabController
    final newIndex = index >= _tabs.length ? _tabs.length - 1 : index;
    _tabController.dispose();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: newIndex,
    );
  }
}

/// SSH终端标签页
class SSHTerminalTab {
  final String id;
  final String title;

  SSHTerminalTab({
    required this.id,
    required this.title,
  });
}
