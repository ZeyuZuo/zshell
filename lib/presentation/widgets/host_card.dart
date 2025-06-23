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
  final bool isOnline;

  const HostCard({
    super.key,
    required this.host,
    this.onConnect,
    this.onEdit,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isOnline ? onConnect : null,
        onDoubleTap: isOnline ? onConnect : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // 状态指示器
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  boxShadow: isOnline ? [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ] : null,
                ),
              ),
              const SizedBox(width: 20),
              // 主机信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 主机名称
                    Text(
                      host.name.isNotEmpty ? host.name : host.host,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 用户名@主机地址
                    Text(
                      '${host.username}@${host.host}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontFamily: 'JetBrainsMono',
                        fontSize: 13,
                      ),
                    ),
                    // 注释信息
                    if (host.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        host.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // 编辑按钮
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: '编辑主机',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
