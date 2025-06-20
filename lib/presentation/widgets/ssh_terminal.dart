import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/ssh_host.dart';
import '../../core/services/ssh_service.dart';

/// SSH终端组件
class SSHTerminal extends StatefulWidget {
  final SSHHost host;
  final VoidCallback? onClose;

  const SSHTerminal({
    super.key,
    required this.host,
    this.onClose,
  });

  @override
  State<SSHTerminal> createState() => _SSHTerminalState();
}

class _SSHTerminalState extends State<SSHTerminal> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commandFocusNode = FocusNode();
  
  SSHConnection? _connection;
  final List<String> _output = [];
  final List<String> _commandHistory = [];
  int _historyIndex = -1;
  bool _isConnecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connectToHost();
  }

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    _commandFocusNode.dispose();
    _connection?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 终端头部
        _buildTerminalHeader(),
        // 终端内容
        Expanded(
          child: _buildTerminalContent(),
        ),
        // 命令输入区域
        _buildCommandInput(),
      ],
    );
  }

  /// 构建终端头部
  Widget _buildTerminalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // 连接状态指示器
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          // 主机信息
          Expanded(
            child: Text(
              '${widget.host.username}@${widget.host.host}:${widget.host.port}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // 操作按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _clearTerminal,
                icon: const Icon(Icons.clear_all, size: 18),
                tooltip: '清空终端',
              ),
              IconButton(
                onPressed: _isConnecting ? null : _reconnect,
                icon: _isConnecting 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                tooltip: '重新连接',
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close, size: 18),
                tooltip: '关闭',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建终端内容
  Widget _buildTerminalContent() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // 输出区域
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _output.length,
              itemBuilder: (context, index) {
                return SelectableText(
                  _output[index],
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                );
              },
            ),
          ),
          // 错误信息
          if (_error != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建命令输入区域
  Widget _buildCommandInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // 提示符
          Text(
            '${widget.host.username}@${widget.host.host}:\$ ',
            style: const TextStyle(
              color: Colors.green,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          // 命令输入框
          Expanded(
            child: TextField(
              controller: _commandController,
              focusNode: _commandFocusNode,
              style: const TextStyle(
                fontFamily: 'monospace',
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '输入命令...',
                isDense: true,
              ),
              enabled: _connection?.isConnected == true,
              onSubmitted: _executeCommand,
              onChanged: (value) {
                _historyIndex = -1; // 重置历史索引
              },
            ),
          ),
          // 发送按钮
          IconButton(
            onPressed: _connection?.isConnected == true 
                ? () => _executeCommand(_commandController.text)
                : null,
            icon: const Icon(Icons.send),
            tooltip: '执行命令',
          ),
        ],
      ),
    );
  }

  /// 连接到主机
  Future<void> _connectToHost() async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      _addOutput('正在连接到 ${widget.host.name}...');
      
      _connection = await SSHService().connect(widget.host);
      
      // 监听输出
      _connection!.output.listen((output) {
        _addOutput(output);
      });
      
      // 监听错误
      _connection!.error.listen((error) {
        _addOutput('错误: $error');
      });
      
      _addOutput('连接成功！');
      _commandFocusNode.requestFocus();
      
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      _addOutput('连接失败: $e');
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  /// 执行命令
  Future<void> _executeCommand(String command) async {
    if (command.trim().isEmpty || _connection?.isConnected != true) {
      return;
    }

    try {
      // 添加到历史记录
      if (!_commandHistory.contains(command)) {
        _commandHistory.add(command);
      }
      
      // 显示命令
      _addOutput('${widget.host.username}@${widget.host.host}:\$ $command');
      
      // 执行命令
      await _connection!.executeCommand(command);
      
      // 清空输入框
      _commandController.clear();
      _historyIndex = -1;
      
    } catch (e) {
      _addOutput('命令执行失败: $e');
    }
  }

  /// 添加输出
  void _addOutput(String text) {
    setState(() {
      _output.add(text);
    });
    
    // 自动滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 清空终端
  void _clearTerminal() {
    setState(() {
      _output.clear();
      _error = null;
    });
  }

  /// 重新连接
  Future<void> _reconnect() async {
    await _connection?.disconnect();
    _connection = null;
    _clearTerminal();
    await _connectToHost();
  }

  /// 获取状态颜色
  Color _getStatusColor() {
    if (_isConnecting) {
      return Colors.orange;
    } else if (_connection?.isConnected == true) {
      return Colors.green;
    } else if (_error != null) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
}
