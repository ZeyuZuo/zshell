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
  bool _isSidebarCollapsed = false;

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
    return AnimatedContainer(
      duration: AppConstants.animationDuration,
      width: _isSidebarCollapsed ? AppConstants.sidebarCollapsedWidth : AppConstants.sidebarWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 当宽度过小时（动画过程中），暂时隐藏内容以避免溢出
          if (constraints.maxWidth < 50) {
            return const SizedBox.shrink();
          }

          return Column(
            children: [
              // 应用标题和折叠按钮
              _buildAppHeader(),
              // 导航菜单
              Expanded(
                child: _buildNavigationMenu(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建应用标题
  Widget _buildAppHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 当宽度过小时（动画过程中），暂时隐藏内容以避免溢出
          if (constraints.maxWidth < 50) {
            return const SizedBox.shrink();
          }

          return _isSidebarCollapsed
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.terminal,
                        size: 24,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isSidebarCollapsed = !_isSidebarCollapsed;
                          });
                        },
                        icon: const Icon(
                          Icons.menu_open,
                          size: 18,
                        ),
                        tooltip: '展开侧边栏',
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(6),
                          minimumSize: const Size(28, 28),
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    Icon(
                      Icons.terminal,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isSidebarCollapsed = !_isSidebarCollapsed;
                        });
                      },
                      icon: const Icon(
                        Icons.menu,
                        size: 20,
                      ),
                      tooltip: '折叠侧边栏',
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }



  /// 构建导航菜单
  Widget _buildNavigationMenu() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: _navigationItems.length,
          itemBuilder: (context, index) {
            final item = _navigationItems[index];
            final isSelected = index == _selectedIndex;

            if (_isSidebarCollapsed) {
              // 折叠状态：只显示图标
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Tooltip(
                  message: item.label,
                  child: Center(
                    child: Material(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          child: Icon(
                            item.icon,
                            size: 20,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            // 展开状态：显示图标和文字
            // 当宽度过小时（动画过程中），暂时隐藏以避免溢出
            if (constraints.maxWidth < 100) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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
          // 标签页 - 移除Expanded包装以避免与isScrollable冲突
          Flexible(
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
                      // 使用Flexible包装文本以防止溢出
                      Flexible(
                        child: Text(
                          tab.title,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
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
