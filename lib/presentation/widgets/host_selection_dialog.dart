import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/ssh_host.dart';
import '../providers/ssh_host_provider.dart';

/// 主机选择对话框
/// 用于在创建新终端标签页时选择要连接的主机
class HostSelectionDialog extends StatefulWidget {
  final Function(SSHHost) onHostSelected;

  const HostSelectionDialog({
    super.key,
    required this.onHostSelected,
  });

  @override
  State<HostSelectionDialog> createState() => _HostSelectionDialogState();
}

class _HostSelectionDialogState extends State<HostSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '选择主机',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '选择要连接的SSH主机',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            // 搜索栏
            _buildSearchBar(),
            const SizedBox(height: 16),
            // 主机列表
            Expanded(
              child: _buildHostsList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: '搜索主机名称、地址或用户名...',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value.toLowerCase();
        });
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
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  '加载主机列表失败',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => provider.refreshHosts(),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        final filteredHosts = _getFilteredHosts(provider.hosts);

        if (filteredHosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.computer_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty ? '暂无主机配置' : '未找到匹配的主机',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isEmpty 
                      ? '请先在主机列表页面添加SSH主机配置'
                      : '尝试使用其他关键词搜索',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredHosts.length,
          itemBuilder: (context, index) {
            final host = filteredHosts[index];
            return _buildHostItem(host, provider.getHostConnectionState(host.id));
          },
        );
      },
    );
  }

  /// 构建主机项
  Widget _buildHostItem(SSHHost host, bool isOnline) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isOnline ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          host.name.isNotEmpty ? host.name : host.host,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${host.username}@${host.host}:${host.port}'),
            if (host.description?.isNotEmpty == true)
              Text(
                host.description!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.outline,
        ),
        onTap: () {
          Navigator.of(context).pop();
          widget.onHostSelected(host);
        },
      ),
    );
  }

  /// 获取过滤后的主机列表
  List<SSHHost> _getFilteredHosts(List<SSHHost> hosts) {
    if (_searchQuery.isEmpty) {
      return hosts;
    }

    return hosts.where((host) {
      return host.name.toLowerCase().contains(_searchQuery) ||
             host.host.toLowerCase().contains(_searchQuery) ||
             host.username.toLowerCase().contains(_searchQuery) ||
             (host.description?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }
}
