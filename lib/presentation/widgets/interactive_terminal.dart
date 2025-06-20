import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/ssh_terminal_service.dart';
import '../../core/utils/logger.dart';

/// 交互式终端组件 - 真正的终端体验
class InteractiveTerminal extends StatefulWidget {
  final SSHTerminalConnection connection;
  final List<String> initialOutput;

  const InteractiveTerminal({
    super.key,
    required this.connection,
    this.initialOutput = const [],
  });

  @override
  State<InteractiveTerminal> createState() => _InteractiveTerminalState();
}

class _InteractiveTerminalState extends State<InteractiveTerminal>
    with TickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _cursorController;
  late Animation<double> _cursorAnimation;

  List<String> _output = [];
  String _currentLine = '';
  bool _isConnected = false;

  // Stream订阅，用于在dispose时取消
  StreamSubscription<String>? _outputSubscription;
  StreamSubscription<String>? _errorSubscription;

  @override
  void initState() {
    super.initState();
    
    // 初始化输出
    _output = List.from(widget.initialOutput);
    
    // 初始化光标动画
    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _cursorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cursorController, curve: Curves.easeInOut),
    );
    _cursorController.repeat(reverse: true);
    
    // 监听连接状态
    _isConnected = widget.connection.isConnected;
    
    // 监听SSH输出
    _outputSubscription = widget.connection.output.listen((output) {
      if (mounted) {  // 检查组件是否还在树中
        setState(() {
          _processOutput(output);
        });
        _scrollToBottom();
      }
    });

    // 监听SSH错误
    _errorSubscription = widget.connection.error.listen((error) {
      if (mounted) {  // 检查组件是否还在树中
        setState(() {
          _output.add('错误: $error');
        });
        _scrollToBottom();
      }
    });
    
    // 自动获得焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    
    AppLogger.info('交互式终端初始化完成', tag: 'InteractiveTerminal');
  }

  @override
  void dispose() {
    // 取消Stream订阅，防止内存泄漏
    _outputSubscription?.cancel();
    _errorSubscription?.cancel();

    _focusNode.dispose();
    _scrollController.dispose();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Container(
        color: const Color(0xFF0D1117),
        child: KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: _handleKeyEvent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 终端输出区域
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 历史输出
                        ..._buildOutputLines(),
                        // 当前输入行
                        _buildCurrentLine(),
                      ],
                    ),
                  ),
                ),
                // 状态栏
                _buildStatusBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建输出行
  List<Widget> _buildOutputLines() {
    return _output.map((line) => Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: _buildStyledText(line),
    )).toList();
  }

  /// 构建带样式的文本
  Widget _buildStyledText(String text) {
    // 移除ANSI转义序列并应用颜色
    final cleanText = _removeAnsiCodes(text);
    final color = _getTextColor(text);

    return SelectableText.rich(
      TextSpan(
        text: cleanText,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 14,
          color: color,
          height: 1.4,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// 移除ANSI转义序列
  String _removeAnsiCodes(String text) {
    // 移除ANSI颜色代码
    return text.replaceAll(RegExp(r'\x1B\[[0-9;]*[mK]'), '');
  }

  /// 根据内容获取文本颜色
  Color _getTextColor(String text) {
    final lowerText = text.toLowerCase();

    // 检测命令提示符（更精确的匹配）
    if (RegExp(r'.*[@#]\s*\$\s*$').hasMatch(text) ||
        RegExp(r'^\s*[\w-]+@[\w-]+:.*\$\s*$').hasMatch(text)) {
      return const Color(0xFF58A6FF); // 蓝色
    }

    // 检测错误信息
    if (lowerText.contains('error') ||
        lowerText.contains('failed') ||
        lowerText.contains('denied') ||
        lowerText.contains('permission denied') ||
        lowerText.contains('not found')) {
      return const Color(0xFFFF6B6B); // 红色
    }

    // 检测警告信息
    if (lowerText.contains('warning') ||
        lowerText.contains('warn')) {
      return const Color(0xFFFFD93D); // 黄色
    }

    // 检测成功信息
    if (lowerText.contains('success') ||
        lowerText.contains('complete') ||
        lowerText.contains('done') ||
        lowerText.contains('connected')) {
      return const Color(0xFF6BCF7F); // 绿色
    }

    // 检测目录和文件
    if (text.startsWith('/') || text.contains('~/') ||
        RegExp(r'\s+[drwx-]{10}\s+').hasMatch(text)) {
      return const Color(0xFF79C0FF); // 浅蓝色
    }

    // 检测IP地址和主机信息
    if (RegExp(r'\d+\.\d+\.\d+\.\d+').hasMatch(text)) {
      return const Color(0xFFFFA657); // 橙色
    }

    // 默认颜色
    return const Color(0xFFE6EDF3);
  }

  /// 构建当前输入行
  Widget _buildCurrentLine() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 当前行内容
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _currentLine,
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 14,
                      color: Color(0xFFE6EDF3),
                      height: 1.4,
                      letterSpacing: 0.5,
                    ),
                  ),
                  // 光标
                  WidgetSpan(
                    child: AnimatedBuilder(
                      animation: _cursorAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 8,
                          height: 20,
                          color: _focusNode.hasFocus && _isConnected
                              ? Color(0xFFE6EDF3).withValues(alpha: _cursorAnimation.value)
                              : Colors.transparent,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建状态栏
  Widget _buildStatusBar() {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          // 连接状态
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _isConnected ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isConnected ? '已连接' : '未连接',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF7D8590),
              fontFamily: 'JetBrainsMono',
            ),
          ),
          const Spacer(),
          // 提示信息
          Text(
            _focusNode.hasFocus ? '终端已激活 - 直接输入命令' : '点击终端区域开始输入',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF7D8590),
              fontFamily: 'JetBrainsMono',
            ),
          ),
        ],
      ),
    );
  }

  /// 处理键盘事件
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || !_isConnected) return;

    final key = event.logicalKey;
    
    if (key == LogicalKeyboardKey.enter) {
      _handleEnter();
    } else if (key == LogicalKeyboardKey.backspace) {
      _handleBackspace();
    } else if (key == LogicalKeyboardKey.delete) {
      _handleDelete();
    } else if (HardwareKeyboard.instance.isControlPressed) {
      // Ctrl键组合
      if (key == LogicalKeyboardKey.keyC) {
        _handleCtrlC();
      } else if (key == LogicalKeyboardKey.keyD) {
        _handleCtrlD();
      }
    } else if (event.character != null && event.character!.isNotEmpty) {
      _handleCharacterInput(event.character!);
    }
  }

  /// 处理回车键
  void _handleEnter() {
    if (mounted) {
      setState(() {
        _output.add(_currentLine);
        _currentLine = '';
      });
    }

    // 发送回车到SSH
    _sendToSSH('\n');
    _scrollToBottom();
  }

  /// 处理退格键
  void _handleBackspace() {
    if (_currentLine.isNotEmpty && mounted) {
      setState(() {
        _currentLine = _currentLine.substring(0, _currentLine.length - 1);
      });
      _sendToSSH('\b');
    }
  }

  /// 处理删除键
  void _handleDelete() {
    _sendToSSH('\x7f');
  }

  /// 处理Ctrl+C
  void _handleCtrlC() {
    if (mounted) {
      setState(() {
        _output.add('$_currentLine^C');
        _currentLine = '';
      });
    }
    _sendToSSH('\x03');
    _scrollToBottom();
  }

  /// 处理Ctrl+D
  void _handleCtrlD() {
    _sendToSSH('\x04');
  }

  /// 处理字符输入
  void _handleCharacterInput(String character) {
    // 过滤控制字符
    if (character.codeUnitAt(0) < 32 && character != '\t') {
      return;
    }

    if (mounted) {
      setState(() {
        _currentLine += character;
      });
    }

    _sendToSSH(character);
  }

  /// 发送数据到SSH
  void _sendToSSH(String data) {
    try {
      widget.connection.sendInput(data);
      AppLogger.debug('发送到SSH: ${data.replaceAll('\n', '\\n').replaceAll('\t', '\\t')}', tag: 'InteractiveTerminal');
    } catch (e) {
      AppLogger.exception('InteractiveTerminal', 'sendToSSH', e);
    }
  }

  /// 处理SSH输出 - 改进的输出处理逻辑
  void _processOutput(String output) {
    if (output.isEmpty) return;

    // 移除ANSI转义序列中的控制字符，但保留颜色
    String cleanOutput = output
        .replaceAll(RegExp(r'\x1b\[[0-9;]*[JKH]'), '') // 清除屏幕相关的转义序列
        .replaceAll(RegExp(r'\x1b\[2J'), '') // 清除整个屏幕
        .replaceAll(RegExp(r'\x1b\[H'), '') // 光标移动到左上角
        .replaceAll('\r\n', '\n') // 统一换行符
        .replaceAll('\r', ''); // 移除单独的回车符

    // 如果输出以换行符结尾，分割后处理
    if (cleanOutput.endsWith('\n')) {
      final lines = cleanOutput.substring(0, cleanOutput.length - 1).split('\n');
      for (final line in lines) {
        if (line.isNotEmpty || _output.isEmpty) {
          _output.add(line);
        }
      }
    } else {
      // 如果不以换行符结尾，可能是部分输出
      final lines = cleanOutput.split('\n');
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (i == 0 && _output.isNotEmpty) {
          // 第一行追加到最后一行
          _output[_output.length - 1] += line;
        } else {
          // 新增行
          _output.add(line);
        }
      }
    }

    // 限制输出行数，避免内存过度使用
    if (_output.length > 1000) {
      _output.removeRange(0, _output.length - 1000);
    }
  }

  /// 滚动到底部
  void _scrollToBottom() {
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
}
