import 'dart:async';
import 'dart:io';
import 'dart:convert';
import '../../data/models/ssh_host.dart';
import '../utils/logger.dart';

/// SSH终端服务 - 支持真正的实时交互
class SSHTerminalService {
  static final SSHTerminalService _instance = SSHTerminalService._internal();
  factory SSHTerminalService() => _instance;
  SSHTerminalService._internal();

  final Map<String, SSHTerminalConnection> _connections = {};

  /// 创建SSH终端连接
  Future<SSHTerminalConnection> connect(SSHHost host) async {
    try {
      final connectionId = '${host.id}_${DateTime.now().millisecondsSinceEpoch}';
      
      // 创建新连接
      final connection = SSHTerminalConnection(connectionId, host);
      await connection.connect();
      
      _connections[connectionId] = connection;
      AppLogger.info('SSH终端连接创建成功: ${host.name}', tag: 'SSHTerminal');
      
      return connection;
    } catch (e) {
      AppLogger.exception('SSHTerminal', 'connect', e);
      throw Exception('SSH终端连接失败: $e');
    }
  }

  /// 断开连接
  Future<void> disconnect(String connectionId) async {
    final connection = _connections[connectionId];
    if (connection != null) {
      await connection.disconnect();
      _connections.remove(connectionId);
      AppLogger.info('SSH终端连接已断开: $connectionId', tag: 'SSHTerminal');
    }
  }

  /// 断开所有连接
  Future<void> disconnectAll() async {
    for (final connection in _connections.values) {
      await connection.disconnect();
    }
    _connections.clear();
    AppLogger.info('所有SSH终端连接已断开', tag: 'SSHTerminal');
  }

  /// 获取连接
  SSHTerminalConnection? getConnection(String connectionId) {
    return _connections[connectionId];
  }

  /// 释放资源
  void dispose() {
    disconnectAll();
  }
}

/// SSH终端连接类
class SSHTerminalConnection {
  final String id;
  final SSHHost host;
  Process? _process;
  StreamSubscription<List<int>>? _outputSubscription;
  StreamSubscription<List<int>>? _errorSubscription;
  
  final StreamController<String> _outputController = 
      StreamController<String>.broadcast();
  final StreamController<String> _errorController = 
      StreamController<String>.broadcast();
  
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _passwordSent = false;

  SSHTerminalConnection(this.id, this.host);

  /// 输出流
  Stream<String> get output => _outputController.stream;
  
  /// 错误流
  Stream<String> get error => _errorController.stream;
  
  /// 是否已连接
  bool get isConnected => _isConnected;
  
  /// 是否正在连接
  bool get isConnecting => _isConnecting;

  /// 建立SSH连接
  Future<void> connect() async {
    if (_isConnected || _isConnecting) {
      return;
    }

    try {
      _isConnecting = true;
      _passwordSent = false; // 重置密码发送标志
      AppLogger.info('开始建立SSH终端连接: ${host.name}', tag: 'SSHTerminal');

      // 构建SSH命令
      List<String> sshCommand;
      String executable;

      // 在Windows下使用特殊处理来避免密码弹窗
      if (Platform.isWindows && host.password?.isNotEmpty == true) {
        // 尝试使用plink（PuTTY的命令行工具）
        executable = 'plink';
        sshCommand = [
          '-ssh',
          '-batch', // 非交互模式
          '-pw', host.password!, // 直接提供密码
          '-P', host.port.toString(),
          '${host.username}@${host.host}',
        ];
        AppLogger.debug('使用plink连接: $executable ${sshCommand.join(' ')}', tag: 'SSHTerminal');
      } else {
        // 使用普通SSH连接
        executable = 'ssh';
        sshCommand = _buildSSHCommand();
        AppLogger.debug('SSH命令: $executable ${sshCommand.join(' ')}', tag: 'SSHTerminal');
      }

      // 设置环境变量以获得更好的终端体验
      final environment = <String, String>{
        'TERM': 'xterm-256color',
        'LANG': 'en_US.UTF-8',
        'LC_ALL': 'en_US.UTF-8',
        'COLUMNS': '120',
        'LINES': '30',
      };

      // 启动SSH进程
      try {
        _process = await Process.start(
          executable,
          sshCommand,
          mode: ProcessStartMode.normal,
          runInShell: Platform.isWindows,
          environment: environment,
        );
        AppLogger.info('SSH进程启动成功: $executable', tag: 'SSHTerminal');
      } catch (e) {
        // 如果plink失败，回退到普通SSH
        if (executable == 'plink') {
          AppLogger.warning('plink不可用，回退到SSH: $e', tag: 'SSHTerminal');
          executable = 'ssh';
          sshCommand = _buildSSHCommand();
          _process = await Process.start(
            executable,
            sshCommand,
            mode: ProcessStartMode.normal,
            runInShell: Platform.isWindows,
            environment: environment,
          );
        } else {
          rethrow;
        }
      }

      // 如果使用普通SSH且有密码，立即发送密码
      if (executable == 'ssh' && host.password?.isNotEmpty == true) {
        // 延迟一点时间让SSH进程启动
        Timer(const Duration(milliseconds: 800), () {
          _autoInputPassword();
          _passwordSent = true;
        });
      }

      // 监听输出
      _outputSubscription = _process!.stdout.listen(
        (data) {
          try {
            // 使用UTF-8解码，确保中文正确显示
            final output = utf8.decode(data, allowMalformed: true);

            // 处理输出并添加到控制器
            _processOutput(output);

            AppLogger.debug('SSH输出: ${output.replaceAll('\n', '\\n').replaceAll('\r', '\\r')}', tag: 'SSHTerminal');
          } catch (e) {
            AppLogger.warning('解码SSH输出失败: $e', tag: 'SSHTerminal');
          }
        },
        onError: (error) {
          AppLogger.error('SSH输出流错误: $error', tag: 'SSHTerminal');
          _errorController.add('输出错误: $error');
        },
        onDone: () {
          AppLogger.info('SSH输出流已关闭', tag: 'SSHTerminal');
          _handleDisconnection();
        },
      );

      // 监听错误
      _errorSubscription = _process!.stderr.listen(
        (data) {
          try {
            final error = utf8.decode(data, allowMalformed: true);
            _errorController.add(error);
            AppLogger.warning('SSH错误: $error', tag: 'SSHTerminal');
          } catch (e) {
            AppLogger.warning('解码SSH错误失败: $e', tag: 'SSHTerminal');
          }
        },
        onError: (error) {
          AppLogger.error('SSH错误流错误: $error', tag: 'SSHTerminal');
        },
      );

      // 监听进程退出
      _process!.exitCode.then((exitCode) {
        AppLogger.info('SSH进程退出，退出码: $exitCode', tag: 'SSHTerminal');
        _handleDisconnection();
      });

      // 等待连接建立
      await Future.delayed(const Duration(milliseconds: 1000));

      _isConnected = true;
      _isConnecting = false;

      AppLogger.info('SSH终端连接建立成功: ${host.name}', tag: 'SSHTerminal');
      
    } catch (e) {
      _isConnecting = false;
      AppLogger.exception('SSHTerminal', 'connect', e);
      throw Exception('SSH终端连接失败: $e');
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      AppLogger.info('断开SSH终端连接: ${host.name}', tag: 'SSHTerminal');
      
      _isConnected = false;
      _isConnecting = false;
      
      // 发送退出命令
      if (_process != null) {
        try {
          _process!.stdin.writeln('exit');
          await _process!.stdin.flush();
          await _process!.stdin.close();
        } catch (e) {
          AppLogger.warning('发送退出命令失败: $e', tag: 'SSHTerminal');
        }
      }
      
      // 等待进程自然退出
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 强制终止进程
      if (_process != null) {
        _process!.kill(ProcessSignal.sigterm);
      }
      
      // 取消订阅
      await _outputSubscription?.cancel();
      await _errorSubscription?.cancel();
      
      // 关闭流控制器
      if (!_outputController.isClosed) {
        await _outputController.close();
      }
      if (!_errorController.isClosed) {
        await _errorController.close();
      }
      
      AppLogger.info('SSH终端连接已断开: ${host.name}', tag: 'SSHTerminal');
      
    } catch (e) {
      AppLogger.exception('SSHTerminal', 'disconnect', e);
    }
  }

  /// 发送输入到终端
  Future<void> sendInput(String input) async {
    if (!_isConnected || _process == null) {
      throw Exception('SSH终端连接未建立或已关闭');
    }

    try {
      _process!.stdin.write(input);
      await _process!.stdin.flush();
      AppLogger.debug('发送输入: $input', tag: 'SSHTerminal');
    } catch (e) {
      AppLogger.exception('SSHTerminal', 'sendInput', e);
      throw Exception('发送输入失败: $e');
    }
  }

  /// 发送命令（带换行符）
  Future<void> sendCommand(String command) async {
    await sendInput('$command\n');
  }

  /// 发送特殊按键
  Future<void> sendKey(String key) async {
    String keyCode;
    switch (key.toLowerCase()) {
      case 'enter':
        keyCode = '\n';
        break;
      case 'tab':
        keyCode = '\t';
        break;
      case 'backspace':
        keyCode = '\b';
        break;
      case 'delete':
        keyCode = '\x7f';
        break;
      case 'escape':
        keyCode = '\x1b';
        break;
      case 'ctrl+c':
        keyCode = '\x03';
        break;
      case 'ctrl+d':
        keyCode = '\x04';
        break;
      case 'ctrl+z':
        keyCode = '\x1a';
        break;
      default:
        keyCode = key;
    }
    
    await sendInput(keyCode);
  }

  /// 处理连接断开
  void _handleDisconnection() {
    if (_isConnected) {
      _isConnected = false;
      _isConnecting = false;
      AppLogger.info('SSH终端连接意外断开: ${host.name}', tag: 'SSHTerminal');
      _errorController.add('连接已断开');
    }
  }

  /// 构建SSH命令参数
  List<String> _buildSSHCommand() {
    final args = <String>[];

    // 基本参数 - 添加更多终端相关选项
    args.addAll([
      '-o', 'StrictHostKeyChecking=no',
      '-o', 'UserKnownHostsFile=/dev/null',
      '-o', 'ConnectTimeout=30',
      '-o', 'ServerAliveInterval=60',
      '-o', 'ServerAliveCountMax=3',
      '-o', 'RequestTTY=yes',  // 强制请求TTY
      '-o', 'SendEnv=TERM',    // 发送终端类型
      '-t',                    // 强制分配伪终端
    ]);

    // 端口
    if (host.port != 22) {
      args.addAll(['-p', host.port.toString()]);
    }

    // 私钥文件
    if (host.privateKeyPath?.isNotEmpty == true) {
      args.addAll(['-i', host.privateKeyPath!]);
    }

    // 用户和主机
    args.add('${host.username}@${host.host}');

    return args;
  }

  /// 自动输入密码
  void _autoInputPassword() {
    if (host.password?.isNotEmpty == true && _process != null) {
      try {
        // 立即发送密码，不需要延迟
        _process!.stdin.add(utf8.encode('${host.password!}\n'));
        AppLogger.info('已自动输入密码', tag: 'SSHTerminal');
      } catch (e) {
        AppLogger.warning('自动输入密码失败: $e', tag: 'SSHTerminal');
      }
    }
  }

  /// 处理SSH输出 - 改进的输出处理逻辑
  void _processOutput(String rawOutput) {
    if (rawOutput.isEmpty) return;

    // 移除ANSI转义序列中的一些控制字符，但保留颜色
    String cleanOutput = rawOutput
        .replaceAll(RegExp(r'\x1b\[[0-9;]*[JKH]'), '') // 清除屏幕相关的转义序列
        .replaceAll(RegExp(r'\x1b\[2J'), '') // 清除整个屏幕
        .replaceAll(RegExp(r'\x1b\[H'), '') // 光标移动到左上角
        .replaceAll('\r\n', '\n') // 统一换行符
        .replaceAll('\r', '\n'); // 将单独的\r也转换为\n

    // 按行分割并处理
    final lines = cleanOutput.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // 跳过空行（除非是最后一行）
      if (line.trim().isEmpty && i < lines.length - 1) {
        continue;
      }

      // 添加处理过的行到输出
      _outputController.add(i == lines.length - 1 ? line : '$line\n');
    }
  }
}
