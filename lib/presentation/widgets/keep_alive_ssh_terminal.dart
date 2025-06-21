import 'package:flutter/material.dart';
import '../../data/models/ssh_host.dart';
import 'ssh_terminal.dart';

/// 保持状态的SSH终端组件
/// 使用AutomaticKeepAliveClientMixin确保在TabBarView中切换标签页时不会销毁组件
/// 这样可以保持SSH连接状态和终端内容
class KeepAliveSSHTerminal extends StatefulWidget {
  final SSHHost host;
  final VoidCallback? onClose;

  const KeepAliveSSHTerminal({
    super.key,
    required this.host,
    this.onClose,
  });

  @override
  State<KeepAliveSSHTerminal> createState() => _KeepAliveSSHTerminalState();
}

class _KeepAliveSSHTerminalState extends State<KeepAliveSSHTerminal>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // 必须调用super.build来启用AutomaticKeepAliveClientMixin
    super.build(context);
    
    // 直接返回SSH终端组件，不添加额外的层级
    return SSHTerminal(
      host: widget.host,
      onClose: widget.onClose,
    );
  }
}
