import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/ssh_host.dart';
import '../../providers/ssh_host_provider.dart';
import '../../widgets/host_card.dart';
import '../../widgets/add_host_dialog.dart';

/// 主机列表页面
/// 应用的核心页面之一，负责显示和管理SSH主机列表
///
/// 主要功能：
/// - 显示所有SSH主机的卡片列表
/// - 提供搜索和筛选功能
/// - 支持添加、编辑、删除主机配置
/// - 显示主机连接状态
/// - 支持测试连接和建立SSH连接
/// - 下拉刷新和加载状态管理
class HostsPage extends StatefulWidget {
  final Function(SSHHost)? onConnectToHost;

  const HostsPage({
    super.key,
    this.onConnectToHost,
  });

  @override
  State<HostsPage> createState() => _HostsPageState();
}

class _HostsPageState extends State<HostsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 初始化加载主机列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SSHHostProvider>().loadHosts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 页面标题和操作按钮
        _buildHeader(),
        const SizedBox(height: 24),
        // 搜索栏
        _buildSearchBar(),
        const SizedBox(height: 16),
        // 主机列表内容
        Expanded(
          child: _buildHostsList(),
        ),
      ],
    );
  }

  /// 构建页面头部
  Widget _buildHeader() {
    return Consumer<SSHHostProvider>(
      builder: (context, provider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '主机列表',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.hasHosts
                      ? '管理您的${provider.totalHosts}个SSH连接配置'
                      : '管理您的SSH连接配置',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                // 刷新按钮
                IconButton(
                  onPressed: provider.isLoading ? null : () {
                    provider.refreshHosts();
                  },
                  icon: provider.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  tooltip: '刷新',
                ),
                const SizedBox(width: 8),
                // 添加主机按钮
                FilledButton.icon(
                  onPressed: () => _showAddHostDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('添加主机'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Consumer<SSHHostProvider>(
      builder: (context, provider, child) {
        return TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '搜索主机名称、地址或用户名...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: provider.searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      provider.clearSearch();
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            provider.searchHosts(value);
          },
        );
      },
    );
  }

  /// 构建主机列表
  Widget _buildHostsList() {
    return Consumer<SSHHostProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  '加载失败',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => provider.refreshHosts(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          );
        }

        if (provider.hosts.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => provider.refreshHosts(),
          child: ListView.builder(
            itemCount: provider.hosts.length,
            itemBuilder: (context, index) {
              final host = provider.hosts[index];
              return HostCard(
                host: host,
                isOnline: provider.getHostConnectionState(host.id),
                onConnect: () => _connectToHost(host),
                onEdit: () => _editHost(host),
              );
            },
          ),
        );
      },
    );
  }



  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.computer_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有配置任何主机',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击"添加主机"按钮开始配置您的第一个SSH连接',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _showAddHostDialog,
            icon: const Icon(Icons.add),
            label: const Text('添加主机'),
          ),
        ],
      ),
    );
  }

  /// 显示添加主机对话框
  void _showAddHostDialog([SSHHost? host]) {
    showDialog(
      context: context,
      builder: (context) => AddHostDialog(
        host: host,
        onSave: (hostData) async {
          final provider = context.read<SSHHostProvider>();
          bool success;

          if (host == null) {
            // 添加新主机
            success = await provider.addHost(
              name: hostData['name'],
              host: hostData['host'],
              port: hostData['port'],
              username: hostData['username'],
              password: hostData['password'],
              privateKeyPath: hostData['privateKeyPath'],
              description: hostData['description'],
            );
          } else {
            // 更新现有主机
            success = await provider.updateHost(
              id: host.id,
              name: hostData['name'],
              host: hostData['host'],
              port: hostData['port'],
              username: hostData['username'],
              password: hostData['password'],
              privateKeyPath: hostData['privateKeyPath'],
              description: hostData['description'],
            );
          }

          if (success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(host == null ? '主机添加成功' : '主机更新成功'),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.error ?? '操作失败'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  /// 连接到主机
  void _connectToHost(SSHHost host) {
    if (widget.onConnectToHost != null) {
      // 使用回调函数在主页面中显示SSH终端
      widget.onConnectToHost!(host);
    } else {
      // 显示提示信息，因为没有提供连接回调
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('无法连接到 ${host.name}：缺少连接处理器'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }



  /// 编辑主机
  void _editHost(SSHHost host) {
    _showAddHostDialog(host);
  }


}
