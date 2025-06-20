import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import '../../data/models/ssh_host.dart';
import '../utils/logger.dart';

/// SSH连接服务 - 使用dartssh2重新实现
class SSHConnectionService {
  final String connectionId;
  final SSHHost host;

  SSHClient? _client;
  SSHSession? _shell;
  bool _isConnected = false;
  bool _isConnecting = false;

  // 输出流控制器
  final StreamController<String> _outputController = StreamController<String>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  // 输入流控制器
  StreamSink<Uint8List>? _inputSink;

  SSHConnectionService(this.connectionId, this.host);

  /// 是否已连接
  bool get isConnected => _isConnected;

  /// 是否正在连接
  bool get isConnecting => _isConnecting;

  /// 输出流
  Stream<String> get outputStream => _outputController.stream;

  /// 错误流
  Stream<String> get errorStream => _errorController.stream;
  
  /// 建立SSH连接
  Future<void> connect() async {
    if (_isConnected || _isConnecting) {
      throw Exception('SSH连接已存在或正在连接中');
    }

    _isConnecting = true;

    try {
      AppLogger.info('开始建立SSH连接: ${host.name} (${host.host}:${host.port})', tag: 'SSHConnection');

      // 创建SSH socket连接
      final socket = await SSHSocket.connect(host.host, host.port);

      // 创建SSH客户端
      _client = SSHClient(
        socket,
        username: host.username,
        onPasswordRequest: () => host.password,
      );

      // 等待认证完成
      await _client!.authenticated;
      AppLogger.info('SSH认证成功', tag: 'SSHConnection');

      // 创建shell会话，配置正确的PTY参数
      _shell = await _client!.shell(
        pty: SSHPtyConfig(
          width: 120,
          height: 30,
          type: 'xterm-256color',
        ),
      );

      // 设置输入流
      _inputSink = _shell!.stdin;

      // 监听输出流 - 使用更安全的UTF-8解码
      _shell!.stdout
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(
            (data) {
              if (data.isNotEmpty) {
                _outputController.add(data);
              }
            },
            onError: (error) {
              AppLogger.exception('SSHConnection', 'stdout', error);
              _errorController.add('输出流错误: $error');
            },
          );

      // 监听错误流 - 使用更安全的UTF-8解码
      _shell!.stderr
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(
            (data) {
              if (data.isNotEmpty) {
                _outputController.add(data); // 将stderr也输出到主流
              }
            },
            onError: (error) {
              AppLogger.exception('SSHConnection', 'stderr', error);
              _errorController.add('错误流错误: $error');
            },
          );

      // 监听会话结束
      _shell!.done.then((_) {
        AppLogger.info('SSH会话结束', tag: 'SSHConnection');
        _isConnected = false;
        _cleanup();
      }).catchError((error) {
        AppLogger.exception('SSHConnection', 'session', error);
        _errorController.add('会话错误: $error');
        _isConnected = false;
        _cleanup();
      });

      _isConnected = true;
      _isConnecting = false;

      AppLogger.info('SSH连接建立成功: ${host.name}', tag: 'SSHConnection');

    } catch (e) {
      _isConnecting = false;
      _isConnected = false;
      AppLogger.exception('SSHConnection', 'connect', e);
      await _cleanup();
      rethrow;
    }
  }

  /// 发送输入到SSH会话
  void sendInput(String input) {
    if (!_isConnected || _inputSink == null) {
      throw Exception('SSH连接未建立');
    }

    try {
      final data = utf8.encode(input);
      _inputSink!.add(Uint8List.fromList(data));
      AppLogger.debug('发送输入: ${input.replaceAll('\n', '\\n').replaceAll('\r', '\\r')}', tag: 'SSHConnection');
    } catch (e) {
      AppLogger.exception('SSHConnection', 'sendInput', e);
      _errorController.add('发送输入失败: $e');
    }
  }

  /// 发送命令到SSH会话
  void sendCommand(String command) {
    sendInput('$command\n');
  }

  /// 断开SSH连接
  Future<void> disconnect() async {
    AppLogger.info('断开SSH连接: ${host.name}', tag: 'SSHConnection');
    await _cleanup();
  }

  /// 清理资源
  Future<void> _cleanup() async {
    try {
      await _inputSink?.close();
      _inputSink = null;

      _shell?.close();
      _shell = null;

      _client?.close();
      _client = null;

      _isConnected = false;
      _isConnecting = false;

    } catch (e) {
      AppLogger.exception('SSHConnection', 'cleanup', e);
    }
  }

  /// 释放资源
  void dispose() {
    disconnect();
    _outputController.close();
    _errorController.close();
  }
}
