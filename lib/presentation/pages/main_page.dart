import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/ssh_host.dart';
import 'hosts/hosts_page.dart';
import 'ai_assistant/ai_assistant_page.dart';
import 'commands/commands_page.dart';
import 'notes/notes_page.dart';
import 'settings/settings_page.dart';
import 'ssh_terminal_page.dart';

/// 应用主页面 - 左右分栏布局
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  SSHHost? _currentSSHHost; // 当前连接的SSH主机
  bool _showSSHTerminal = false; // 是否显示SSH终端

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
          // SSH终端返回按钮
          if (_showSSHTerminal) _buildSSHTerminalHeader(),
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

  /// 构建SSH终端头部
  Widget _buildSSHTerminalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _closeSSHTerminal,
            icon: const Icon(Icons.arrow_back),
            tooltip: '返回主机列表',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SSH终端',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                if (_currentSSHHost != null)
                  Text(
                    _currentSSHHost!.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
              ],
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
    return Container(
      padding: const EdgeInsets.all(24),
      child: _buildPageContent(),
    );
  }

  /// 构建页面内容
  Widget _buildPageContent() {
    // 如果显示SSH终端，则显示SSH终端页面
    if (_showSSHTerminal && _currentSSHHost != null) {
      return SSHTerminalPage(host: _currentSSHHost!);
    }

    switch (_selectedIndex) {
      case 0:
        return HostsPage(
          onConnectToHost: _connectToHost,
        );
      case 1:
        return const AIAssistantPage();
      case 2:
        return const CommandsPage();
      case 3:
        return const NotesPage();
      case 4:
        return const SettingsPage();
      default:
        return const Center(child: Text('页面未找到'));
    }
  }

  /// 连接到SSH主机
  void _connectToHost(SSHHost host) {
    setState(() {
      _currentSSHHost = host;
      _showSSHTerminal = true;
    });
  }

  /// 关闭SSH终端
  void _closeSSHTerminal() {
    setState(() {
      _currentSSHHost = null;
      _showSSHTerminal = false;
    });
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
