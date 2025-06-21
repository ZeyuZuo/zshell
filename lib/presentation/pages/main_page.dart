import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/ssh_host.dart';
import 'hosts/hosts_page.dart';
import 'ai_assistant/ai_assistant_page.dart';
import 'commands/commands_page.dart';
import 'notes/notes_page.dart';
import 'settings/settings_page.dart';
import '../widgets/host_selection_dialog.dart';
import '../widgets/keep_alive_ssh_terminal.dart';

/// 应用主页面 - 左右分栏布局
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  // 标签页管理
  final List<MainPageTab> _terminalTabs = [];
  TabController? _tabController;

  // 侧边栏菜单项
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.computer,
      label: '主机列表',
      route: Routes.hosts,
    ),
    NavigationItem(
      icon: Icons.smart_toy,
      label: 'AI助手',
      route: Routes.aiAssistant,
    ),
    NavigationItem(
      icon: Icons.terminal,
      label: '快捷指令',
      route: Routes.commands,
    ),
    NavigationItem(
      icon: Icons.note,
      label: '笔记',
      route: Routes.notes,
    ),
    NavigationItem(
      icon: Icons.settings,
      label: '设置',
      route: Routes.settings,
    ),
  ];

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧边栏
          _buildSidebar(),
          // 右侧内容区域
          Expanded(
            child: _buildContentArea(),
          ),
        ],
      ),
    );
  }

  /// 构建侧边栏
  Widget _buildSidebar() {
    return Container(
      width: AppConstants.sidebarWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 应用标题
          _buildAppHeader(),
          // 导航菜单
          Expanded(
            child: _buildNavigationMenu(),
          ),
        ],
      ),
    );
  }

  /// 构建应用标题
  Widget _buildAppHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(
            Icons.terminal,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }



  /// 构建导航菜单
  Widget _buildNavigationMenu() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _navigationItems.length,
      itemBuilder: (context, index) {
        final item = _navigationItems[index];
        final isSelected = index == _selectedIndex;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: ListTile(
            leading: Icon(
              item.icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(
              item.label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        );
      },
    );
  }

  /// 构建内容区域
  Widget _buildContentArea() {
    // 使用IndexedStack保持所有页面的状态，避免页面切换时销毁终端连接
    return IndexedStack(
      index: _selectedIndex,
      children: [
        // 主机列表页面 - 可能包含终端标签页
        _buildHostsPageContent(),
        // 其他页面
        Container(
          padding: const EdgeInsets.all(24),
          child: const AIAssistantPage(),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          child: const CommandsPage(),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          child: const NotesPage(),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          child: const SettingsPage(),
        ),
      ],
    );
  }

  /// 构建主机页面内容（包含终端标签页逻辑）
  Widget _buildHostsPageContent() {
    // 如果有终端标签页，显示终端标签页界面
    if (_terminalTabs.isNotEmpty) {
      return Column(
        children: [
          // 标签栏
          _buildTabBar(),
          // 标签页内容
          Expanded(
            child: TabBarView(
              controller: _tabController!,
              children: _terminalTabs.map((tab) =>
                KeepAliveSSHTerminal(
                  host: tab.host,
                  onClose: () => _closeTab(tab.id),
                )
              ).toList(),
            ),
          ),
        ],
      );
    }

    // 没有终端标签页时，显示普通的主机列表页面
    return Container(
      padding: const EdgeInsets.all(24),
      child: HostsPage(
        onConnectToHost: _connectToHost,
      ),
    );
  }

  /// 构建标签栏
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
      child: Row(
        children: [
          // 标签页
          Expanded(
            child: TabBar(
              controller: _tabController!,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: _terminalTabs.map((tab) => Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 连接状态指示器
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.green, // 简化状态显示
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
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),
          // 添加标签页按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: IconButton(
              onPressed: _showHostSelectionDialog,
              icon: const Icon(Icons.add),
              tooltip: '新建终端',
              iconSize: 18,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
      ),
    );
  }



  /// 连接到SSH主机
  void _connectToHost(SSHHost host) {
    _addTab(host);
  }

  /// 添加新的终端标签页
  void _addTab(SSHHost host) {
    final tabId = '${host.id}_${DateTime.now().millisecondsSinceEpoch}';
    final newTab = MainPageTab(
      id: tabId,
      host: host,
    );

    setState(() {
      _terminalTabs.add(newTab);
    });

    _updateTabController(_terminalTabs.length - 1);
  }

  /// 关闭标签页
  void _closeTab(String tabId) {
    final tabIndex = _terminalTabs.indexWhere((tab) => tab.id == tabId);
    if (tabIndex == -1) return;

    setState(() {
      _terminalTabs.removeAt(tabIndex);
    });

    if (_terminalTabs.isEmpty) {
      _tabController?.dispose();
      _tabController = null;
    } else {
      final newIndex = tabIndex >= _terminalTabs.length ? _terminalTabs.length - 1 : tabIndex;
      _updateTabController(newIndex);
    }
  }

  /// 更新TabController
  void _updateTabController(int initialIndex) {
    _tabController?.dispose();
    _tabController = TabController(
      length: _terminalTabs.length,
      vsync: this,
      initialIndex: initialIndex.clamp(0, _terminalTabs.length - 1),
    );
  }

  /// 显示主机选择对话框
  void _showHostSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => HostSelectionDialog(
        onHostSelected: _addTab,
      ),
    );
  }
}

/// 导航项数据模型
class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  const NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

/// 主页标签页数据模型
class MainPageTab {
  final String id;
  final SSHHost host;
  final String title;

  MainPageTab({
    required this.id,
    required this.host,
  }) : title = host.name.trim().isNotEmpty ? host.name : host.host;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MainPageTab && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
