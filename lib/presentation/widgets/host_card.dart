import 'package:flutter/material.dart';
import '../../data/models/ssh_host.dart';

/// 主机卡片组件
/// 用于在主机列表中显示单个SSH主机的信息
/// 包含主机基本信息、连接状态指示器和操作按钮
///
/// 功能特性：
/// - 显示主机名、地址、端口、用户名等基本信息
/// - 实时显示连接状态（在线/离线）
/// - 提供连接、编辑、删除、测试连接等操作
/// - 响应式设计，适配不同屏幕尺寸
class HostCard extends StatelessWidget {
  final SSHHost host;
  final VoidCallback? onConnect;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTestConnection;
  final bool isOnline;

  const HostCard({
    super.key,
    required this.host,
    this.onConnect,
    this.onEdit,
    this.onDelete,
    this.onTestConnection,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 状态指示器
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            // 主机信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    host.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${host.username}@${host.host}:${host.port}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (host.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      host.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  // 主机详细信息
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildInfoChip(
                        context,
                        Icons.computer,
                        host.host,
                      ),
                      _buildInfoChip(
                        context,
                        Icons.person,
                        host.username,
                      ),
                      if (host.privateKeyPath != null)
                        _buildInfoChip(
                          context,
                          Icons.key,
                          '私钥',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // 操作按钮
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: isOnline ? onConnect : null,
                  icon: const Icon(Icons.play_arrow),
                  tooltip: '连接',
                  style: IconButton.styleFrom(
                    backgroundColor: isOnline
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onTestConnection,
                      icon: const Icon(Icons.wifi_find, size: 20),
                      tooltip: '测试连接',
                    ),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: '编辑',
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 20),
                      tooltip: '删除',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建信息芯片
  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Chip(
      avatar: Icon(
        icon,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      label: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
