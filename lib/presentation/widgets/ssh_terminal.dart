import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../data/models/ssh_host.dart';
import '../../core/services/ssh_connection_service.dart';
import '../../core/utils/logger.dart';
import '../../core/terminal/terminal_buffer.dart';
import 'terminal_renderer.dart';

/// SSH终端组件 - 使用dartssh2重新实现
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
  SSHConnectionService? _connection;
  bool _isConnecting = false;
  String? _error;
  
  // 终端缓冲区
  late TerminalBuffer _terminalBuffer;

  // 终端状态
  String _lastOutput = ''; // 用于检测重复输出
  int _lastOutputTime = 0; // 最后输出时间，用于重复检测

  // 调试模式标志
  static const bool _debugMode = false;
  static const bool _debugArrowKeys = false;

  // 按键防抖 - 防止快速按键导致的竞争条件
  Timer? _keyDebounceTimer;
  String? _pendingKeyInput;
  int _lastArrowKeyTime = 0;

  // 按键长按重复功能
  Timer? _keyRepeatTimer;
  LogicalKeyboardKey? _currentPressedKey;
  String? _currentKeySequence;
  bool _isKeyPressed = false;

  // 控制器
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // 文本选择状态（为将来的文本选择功能预留）
  String _selectedText = '';

  // 流订阅
  StreamSubscription<String>? _outputSubscription;
  StreamSubscription<String>? _errorSubscription;

  @override
  void initState() {
    super.initState();

    // 初始化终端缓冲区 (120列 x 30行)
    _terminalBuffer = TerminalBuffer(width: 120, height: 30);

    _connectToHost();

    // 请求焦点并滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _outputSubscription?.cancel();
    _errorSubscription?.cancel();
    _keyDebounceTimer?.cancel();
    _keyRepeatTimer?.cancel();
    _connection?.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 连接到主机
  Future<void> _connectToHost() async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      final connectionId = '${widget.host.id}_${DateTime.now().millisecondsSinceEpoch}';
      _connection = SSHConnectionService(connectionId, widget.host);
      
      // 监听输出流
      _outputSubscription = _connection!.outputStream.listen((output) {
        if (mounted) {
          _processOutput(output);
        }
      });
      
      // 监听错误流
      _errorSubscription = _connection!.errorStream.listen((error) {
        if (mounted) {
          setState(() {
            _terminalBuffer.write('\r\n错误: $error\r\n');
          });
          _scrollToBottom();
        }
      });
      
      // 建立连接
      await _connection!.connect();
      
      setState(() {
        _isConnecting = false;
      });
      
      AppLogger.info('SSH终端连接成功: ${widget.host.name}', tag: 'SSHTerminal');
      
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isConnecting = false;
      });
      AppLogger.exception('SSHTerminal', 'connect', e);
    }
  }

  /// 处理输出 - 直接处理，使用新的顺序解析
  void _processOutput(String output) {
    if (output.isEmpty) return;

    // 改进的重复检测 - 更加智能
    final now = DateTime.now().millisecondsSinceEpoch;

    // 只过滤非常短的重复空白输出
    if (output == _lastOutput &&
        output.length <= 3 &&
        output.trim().isEmpty &&
        (now - _lastOutputTime) < 50) {
      AppLogger.debug('过滤重复空输出: ${output.replaceAll('\n', '\\n').replaceAll('\r', '\\r')}', tag: 'SSHTerminal');
      return;
    }

    _lastOutput = output;
    _lastOutputTime = now;

    // 详细日志记录用于调试
    if (_debugMode) {
      final debugOutput = output
          .replaceAll('\r', '\\r')
          .replaceAll('\n', '\\n')
          .replaceAll('\x1b', '\\x1b');
      print('SSH_OUTPUT: $debugOutput');
    }

    setState(() {
      // 直接处理输出，使用新的顺序解析
      _terminalBuffer.write(output);
    });

    // 强制滚动到底部，确保新内容可见
    _scrollToBottomForced();
  }

  /// 强制滚动到底部（用于新内容输出）
  void _scrollToBottomForced() {
    // 立即尝试滚动
    _performScrollToBottom();

    // 使用多个回调确保滚动生效
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performScrollToBottom();
    });

    // 额外的延迟回调，确保内容已经渲染完成
    Future.delayed(const Duration(milliseconds: 20), () {
      if (mounted) {
        _performScrollToBottom();
      }
    });

    // 最后的保险回调
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _performScrollToBottom();
      }
    });
  }



  /// 处理键盘事件
  bool _handleKeyEvent(KeyEvent event) {
    // 确保终端保持焦点
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }

    if (event is KeyDownEvent) {
      return _handleKeyDown(event);
    } else if (event is KeyUpEvent) {
      return _handleKeyUp(event);
    }

    return false;
  }

  /// 处理按键按下事件
  bool _handleKeyDown(KeyDownEvent event) {
    final key = event.logicalKey;

    // Ctrl组合键处理
    if (HardwareKeyboard.instance.isControlPressed) {
      return _handleControlKey(key);
    }

    // Alt组合键处理
    if (HardwareKeyboard.instance.isAltPressed) {
      return _handleAltKey(key);
    }

    // 功能键处理 - 必须在字符处理之前
    if (_isFunctionKey(key)) {
      final handled = _handleFunctionKey(key);
      if (handled) {
        _startKeyRepeat(key);
      }
      return handled;
    }

    // 可打印字符处理
    if (event.character != null &&
        event.character!.isNotEmpty &&
        _isPrintableCharacter(event.character!)) {
      _handleCharacterInput(event.character!);
      return true;
    }

    return false;
  }

  /// 处理按键释放事件
  bool _handleKeyUp(KeyUpEvent event) {
    final key = event.logicalKey;

    // 停止按键重复
    if (_currentPressedKey == key) {
      _stopKeyRepeat();
    }

    return false;
  }

  /// 判断是否为功能键
  bool _isFunctionKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.enter ||
           key == LogicalKeyboardKey.backspace ||
           key == LogicalKeyboardKey.delete ||
           key == LogicalKeyboardKey.tab ||
           key == LogicalKeyboardKey.escape ||
           key == LogicalKeyboardKey.arrowUp ||
           key == LogicalKeyboardKey.arrowDown ||
           key == LogicalKeyboardKey.arrowLeft ||
           key == LogicalKeyboardKey.arrowRight ||
           key == LogicalKeyboardKey.home ||
           key == LogicalKeyboardKey.end ||
           key == LogicalKeyboardKey.pageUp ||
           key == LogicalKeyboardKey.pageDown ||
           key == LogicalKeyboardKey.insert ||
           key.keyId >= LogicalKeyboardKey.f1.keyId &&
           key.keyId <= LogicalKeyboardKey.f12.keyId;
  }

  /// 判断是否为可打印字符
  bool _isPrintableCharacter(String character) {
    if (character.length != 1) return false;
    final code = character.codeUnitAt(0);

    // 排除控制字符
    if (code < 32) return false;

    // 排除DEL字符
    if (code == 127) return false;

    // 可打印ASCII字符范围：32-126
    // 扩展ASCII和Unicode字符：128以上
    return (code >= 32 && code <= 126) || code >= 128;
  }

  /// 处理功能键
  bool _handleFunctionKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.enter) {
      AppLogger.debug('回车键按下', tag: 'SSHTerminal');
      _sendToSSH('\r');
      // 回车键通常意味着命令执行，预先滚动到底部
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _scrollToBottomForced();
        }
      });
      return true;
    } else if (key == LogicalKeyboardKey.backspace) {
      AppLogger.debug('退格键按下', tag: 'SSHTerminal');
      _sendToSSH('\x7f'); // 标准退格序列
      return true;
    } else if (key == LogicalKeyboardKey.delete) {
      AppLogger.debug('删除键按下', tag: 'SSHTerminal');
      _sendToSSH('\x1b[3~'); // 标准删除键序列
      return true;
    } else if (key == LogicalKeyboardKey.tab) {
      AppLogger.debug('Tab键按下', tag: 'SSHTerminal');
      _sendToSSH('\t');
      return true;
    } else if (key == LogicalKeyboardKey.escape) {
      AppLogger.debug('Esc键按下', tag: 'SSHTerminal');
      _sendToSSH('\x1b');
      return true;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      AppLogger.debug('上方向键按下', tag: 'SSHTerminal');
      _sendDebouncedArrowKey('\x1b[A');
      return true;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      AppLogger.debug('下方向键按下', tag: 'SSHTerminal');
      _sendDebouncedArrowKey('\x1b[B');
      return true;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      AppLogger.debug('右方向键按下', tag: 'SSHTerminal');
      if (_debugArrowKeys) {
        print('ARROW_RIGHT: Sending \\x1b[C');
      }
      _sendDebouncedArrowKey('\x1b[C');
      return true;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      AppLogger.debug('左方向键按下', tag: 'SSHTerminal');
      if (_debugArrowKeys) {
        print('ARROW_LEFT: Sending \\x1b[D');
      }
      _sendDebouncedArrowKey('\x1b[D');
      return true;
    } else if (key == LogicalKeyboardKey.home) {
      _sendToSSH('\x1b[H');
      return true;
    } else if (key == LogicalKeyboardKey.end) {
      _sendToSSH('\x1b[F');
      return true;
    } else if (key == LogicalKeyboardKey.pageUp) {
      _sendToSSH('\x1b[5~');
      return true;
    } else if (key == LogicalKeyboardKey.pageDown) {
      _sendToSSH('\x1b[6~');
      return true;
    } else if (key == LogicalKeyboardKey.insert) {
      _sendToSSH('\x1b[2~');
      return true;
    } else if (key.keyId >= LogicalKeyboardKey.f1.keyId &&
               key.keyId <= LogicalKeyboardKey.f12.keyId) {
      // F1-F12功能键
      int fNum = key.keyId - LogicalKeyboardKey.f1.keyId + 1;
      if (fNum <= 4) {
        _sendToSSH('\x1b[${10 + fNum}~'); // F1-F4
      } else if (fNum <= 6) {
        _sendToSSH('\x1b[${11 + fNum}~'); // F5-F6
      } else if (fNum <= 12) {
        _sendToSSH('\x1b[${12 + fNum}~'); // F7-F12
      }
      return true;
    }
    return false;
  }

  /// 处理Alt组合键
  bool _handleAltKey(LogicalKeyboardKey key) {
    // Alt+字符组合键处理
    AppLogger.debug('Alt组合键: $key', tag: 'SSHTerminal');
    // 大多数Alt组合键发送ESC前缀
    if (key.keyLabel.length == 1) {
      _sendToSSH('\x1b${key.keyLabel.toLowerCase()}');
      return true;
    }
    return false;
  }

  /// 处理Ctrl组合键
  bool _handleControlKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.keyC) {
      // 检查是否有选中文本，如果有则复制，否则发送Ctrl+C
      if (_selectedText.isNotEmpty) {
        _copySelectedText();
        return true;
      } else {
        _sendToSSH('\x03');
        return true;
      }
    } else if (key == LogicalKeyboardKey.keyV) {
      // Ctrl+V (粘贴)
      _pasteFromClipboard();
      return true;
    } else if (key == LogicalKeyboardKey.keyA) {
      // Ctrl+A (全选)
      _selectAllText();
      return true;
    } else if (key == LogicalKeyboardKey.keyD) {
      // Ctrl+D
      _sendToSSH('\x04');
      return true;
    } else if (key == LogicalKeyboardKey.keyL) {
      // Ctrl+L (清屏)
      setState(() {
        _terminalBuffer.clear();
      });
      _sendToSSH('\x0c');
      return true;
    } else if (key == LogicalKeyboardKey.keyZ) {
      // Ctrl+Z
      _sendToSSH('\x1a');
      return true;
    }
    return false;
  }

  /// 处理字符输入
  void _handleCharacterInput(String character) {
    // 只过滤真正的控制字符，保留可打印字符
    final code = character.codeUnitAt(0);
    if (code < 32 && character != '\t') {
      AppLogger.debug('过滤控制字符: $code', tag: 'SSHTerminal');
      return;
    }

    AppLogger.debug('字符输入: $character (code: $code)', tag: 'SSHTerminal');

    // 直接发送字符到SSH，不在本地跟踪
    _sendToSSH(character);
  }

  /// 发送数据到SSH
  void _sendToSSH(String data) {
    try {
      _connection?.sendInput(data);
      AppLogger.debug('发送到SSH: ${data.replaceAll('\n', '\\n').replaceAll('\r', '\\r')}', tag: 'SSHTerminal');
    } catch (e) {
      AppLogger.exception('SSHTerminal', 'sendToSSH', e);
      setState(() {
        _terminalBuffer.write('\r\n发送失败: $e\r\n');
      });
      _scrollToBottom();
    }
  }

  /// 发送防抖的方向键输入
  void _sendDebouncedArrowKey(String keySequence) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 如果距离上次方向键按下时间很短，使用防抖机制
    if (now - _lastArrowKeyTime < 50) {
      _keyDebounceTimer?.cancel();
      _pendingKeyInput = keySequence;

      _keyDebounceTimer = Timer(const Duration(milliseconds: 20), () {
        if (_pendingKeyInput != null) {
          _sendToSSH(_pendingKeyInput!);
          _pendingKeyInput = null;
        }
      });
    } else {
      // 直接发送
      _sendToSSH(keySequence);
    }

    _lastArrowKeyTime = now;
  }

  /// 开始按键重复
  void _startKeyRepeat(LogicalKeyboardKey key) {
    // 只对特定按键启用重复功能
    if (!_shouldRepeatKey(key)) {
      return;
    }

    _stopKeyRepeat(); // 停止之前的重复

    _currentPressedKey = key;
    _currentKeySequence = _getKeySequence(key);
    _isKeyPressed = true;

    // 延迟500ms后开始重复，然后每50ms重复一次
    _keyRepeatTimer = Timer(const Duration(milliseconds: 500), () {
      if (_isKeyPressed && _currentKeySequence != null) {
        _keyRepeatTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
          if (_isKeyPressed && _currentKeySequence != null) {
            _sendToSSH(_currentKeySequence!);
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  /// 停止按键重复
  void _stopKeyRepeat() {
    _keyRepeatTimer?.cancel();
    _keyRepeatTimer = null;
    _currentPressedKey = null;
    _currentKeySequence = null;
    _isKeyPressed = false;
  }

  /// 判断按键是否应该支持重复
  bool _shouldRepeatKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.backspace ||
           key == LogicalKeyboardKey.delete ||
           key == LogicalKeyboardKey.arrowUp ||
           key == LogicalKeyboardKey.arrowDown ||
           key == LogicalKeyboardKey.arrowLeft ||
           key == LogicalKeyboardKey.arrowRight;
  }

  /// 获取按键对应的序列
  String? _getKeySequence(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.backspace) {
      return '\x7f';
    } else if (key == LogicalKeyboardKey.delete) {
      return '\x1b[3~';
    } else if (key == LogicalKeyboardKey.arrowUp) {
      return '\x1b[A';
    } else if (key == LogicalKeyboardKey.arrowDown) {
      return '\x1b[B';
    } else if (key == LogicalKeyboardKey.arrowRight) {
      return '\x1b[C';
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      return '\x1b[D';
    }
    return null;
  }

  /// 滚动到底部
  void _scrollToBottom() {
    // 使用多重回调确保滚动生效
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performScrollToBottom();
    });

    // 额外的延迟回调，确保内容已经渲染完成
    Future.delayed(const Duration(milliseconds: 10), () {
      if (mounted) {
        _performScrollToBottom();
      }
    });
  }

  /// 执行滚动到底部的操作
  void _performScrollToBottom() {
    if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
      try {
        // 使用jumpTo而不是animateTo，确保立即滚动
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } catch (e) {
        // 如果jumpTo失败，尝试使用animateTo
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 50),
          curve: Curves.easeOut,
        );
      }
    }
  }

  /// 复制选中的文本
  void _copySelectedText() {
    if (_selectedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _selectedText));
      AppLogger.debug('复制文本: $_selectedText', tag: 'SSHTerminal');
      // 清除选择
      setState(() {
        _selectedText = '';
      });
    }
  }

  /// 从剪贴板粘贴
  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        final text = clipboardData.text!;
        AppLogger.debug('粘贴文本: $text', tag: 'SSHTerminal');
        _sendToSSH(text);
      }
    } catch (e) {
      AppLogger.exception('SSHTerminal', 'pasteFromClipboard', e);
    }
  }

  /// 全选文本
  void _selectAllText() {
    // 获取终端缓冲区的所有文本
    final allText = _terminalBuffer.getAllText();
    setState(() {
      _selectedText = allText;
    });
    // 直接复制到剪贴板
    Clipboard.setData(ClipboardData(text: allText));
    AppLogger.debug('全选并复制文本: ${allText.length} 字符', tag: 'SSHTerminal');
  }

  /// 处理拖拽开始（文本选择开始）
  void _handlePanStart(DragStartDetails details) {
    // 暂时禁用文本选择，专注于键盘输入修复
    AppLogger.debug('文本选择功能暂未实现', tag: 'SSHTerminal');
  }

  /// 处理拖拽更新（文本选择更新）
  void _handlePanUpdate(DragUpdateDetails details) {
    // 暂时禁用文本选择，专注于键盘输入修复
  }

  /// 处理拖拽结束（文本选择结束）
  void _handlePanEnd(DragEndDetails details) {
    // 暂时禁用文本选择，专注于键盘输入修复
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnecting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在连接SSH...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('连接失败: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _connectToHost,
              child: const Text('重新连接'),
            ),
          ],
        ),
      );
    }

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      canRequestFocus: true,
      skipTraversal: false,
      onKeyEvent: (node, event) {
        // 处理键盘事件并阻止事件冒泡
        final handled = _handleKeyEvent(event);
        return handled ? KeyEventResult.handled : KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          _focusNode.requestFocus();
        },
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: Container(
          color: const Color(0xFF0C0C0C), // 深黑色背景
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _buildTerminalContent(),
          ),
        ),
      ),
    );
  }

  /// 构建终端内容
  Widget _buildTerminalContent() {
    return TerminalScrollView(
      buffer: _terminalBuffer,
      scrollController: _scrollController, // 传递滚动控制器
      showCursor: true,
      fontSize: 14,
      fontFamily: 'JetBrainsMono',
      onTap: () => _focusNode.requestFocus(),
    );
  }


}
