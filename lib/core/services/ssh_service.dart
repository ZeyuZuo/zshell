import 'dart:async';
import 'dart:io';
import 'dart:convert';
import '../../data/models/ssh_host.dart';
import '../../data/models/ssh_session.dart';

/// SSH连接服务
class SSHService {
  static final SSHService _instance = SSHService._internal();
  factory SSHService() => _instance;
  SSHService._internal();

  final Map<String, SSHConnection> _connections = {};
  final StreamController<Map<String, SSHSession>> _sessionController = 
      StreamController<Map<String, SSHSession>>.broadcast();

  /// SSH会话流
  Stream<Map<String, SSHSession>> get sessions => _sessionController.stream;

  /// 获取所有活跃连接
  Map<String, SSHConnection> get activeConnections => Map.from(_connections);

  /// 创建SSH连接
  Future<SSHConnection> connect(SSHHost host) async {
    try {
      // 检查是否已有连接
      if (_connections.containsKey(host.id)) {
        final existingConnection = _connections[host.id]!;
        if (existingConnection.isConnected) {
          return existingConnection;
        } else {
          // 清理旧连接
          await disconnect(host.id);
        }
      }

      // 创建新连接
      final connection = SSHConnection(host);
      await connection.connect();
      
      _connections[host.id] = connection;
      _notifySessionChange();
      
      return connection;
    } catch (e) {
      throw Exception('SSH连接失败: $e');
    }
  }

  /// 断开SSH连接
  Future<void> disconnect(String hostId) async {
    final connection = _connections[hostId];
    if (connection != null) {
      await connection.disconnect();
      _connections.remove(hostId);
      _notifySessionChange();
    }
  }

  /// 断开所有连接
  Future<void> disconnectAll() async {
    for (final connection in _connections.values) {
      await connection.disconnect();
    }
    _connections.clear();
    _notifySessionChange();
  }

  /// 获取连接
  SSHConnection? getConnection(String hostId) {
    return _connections[hostId];
  }

  /// 通知会话变化
  void _notifySessionChange() {
    final sessions = <String, SSHSession>{};
    for (final entry in _connections.entries) {
      sessions[entry.key] = entry.value.session;
    }
    
    if (!_sessionController.isClosed) {
      _sessionController.add(sessions);
    }
  }

  /// 释放资源
  void dispose() {
    disconnectAll();
    _sessionController.close();
  }
}

/// SSH连接类
class SSHConnection {
  final SSHHost host;
  Process? _process;
  StreamSubscription<List<int>>? _outputSubscription;
  StreamSubscription<List<int>>? _errorSubscription;
  
  final StreamController<String> _outputController = 
      StreamController<String>.broadcast();
  final StreamController<String> _errorController = 
      StreamController<String>.broadcast();
  
  late SSHSession _session;
  bool _isConnected = false;

  SSHConnection(this.host) {
    _session = SSHSession(
      id: '${host.id}_${DateTime.now().millisecondsSinceEpoch}',
      hostId: host.id,
      sessionName: '${host.name} - ${DateTime.now().toString().substring(0, 19)}',
      startTime: DateTime.now(),
      status: SSHSessionStatus.connecting,
    );
  }

  /// 输出流
  Stream<String> get output => _outputController.stream;
  
  /// 错误流
  Stream<String> get error => _errorController.stream;
  
  /// 会话信息
  SSHSession get session => _session;
  
  /// 是否已连接
  bool get isConnected => _isConnected;

  /// 建立SSH连接
  Future<void> connect() async {
    try {
      _session = _session.copyWith(status: SSHSessionStatus.connecting);
      
      // 构建SSH命令
      final sshCommand = _buildSSHCommand();
      
      // 启动SSH进程
      _process = await Process.start(
        'ssh',
        sshCommand,
        mode: ProcessStartMode.normal,
      );

      // 监听输出
      _outputSubscription = _process!.stdout.listen(
        (data) {
          final output = utf8.decode(data);
          _outputController.add(output);
        },
        onError: (error) {
          _errorController.add('输出错误: $error');
        },
      );

      // 监听错误
      _errorSubscription = _process!.stderr.listen(
        (data) {
          final error = utf8.decode(data);
          _errorController.add(error);
        },
      );

      // 等待连接建立
      await Future.delayed(const Duration(seconds: 2));
      
      _isConnected = true;
      _session = _session.copyWith(
        status: SSHSessionStatus.connected,
        lastActivity: DateTime.now(),
      );
      
    } catch (e) {
      _session = _session.copyWith(
        status: SSHSessionStatus.failed,
        errorMessage: e.toString(),
      );
      throw Exception('SSH连接失败: $e');
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      _isConnected = false;
      
      // 关闭进程
      _process?.kill();
      
      // 取消订阅
      await _outputSubscription?.cancel();
      await _errorSubscription?.cancel();
      
      // 关闭流控制器
      await _outputController.close();
      await _errorController.close();
      
      _session = _session.copyWith(
        status: SSHSessionStatus.closed,
        endTime: DateTime.now(),
      );
      
    } catch (e) {
      _session = _session.copyWith(
        status: SSHSessionStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  /// 执行命令
  Future<void> executeCommand(String command) async {
    if (!_isConnected || _process == null) {
      throw Exception('SSH连接未建立');
    }

    try {
      _process!.stdin.writeln(command);
      await _process!.stdin.flush();
      
      _session = _session.updateActivity(command);
    } catch (e) {
      throw Exception('命令执行失败: $e');
    }
  }

  /// 构建SSH命令参数
  List<String> _buildSSHCommand() {
    final args = <String>[];
    
    // 基本参数
    args.addAll([
      '-o', 'StrictHostKeyChecking=no',
      '-o', 'UserKnownHostsFile=/dev/null',
      '-o', 'ConnectTimeout=30',
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
}

/// SSH连接状态
enum SSHConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// SSH命令结果
class SSHCommandResult {
  final String command;
  final String output;
  final String error;
  final int exitCode;
  final Duration executionTime;

  const SSHCommandResult({
    required this.command,
    required this.output,
    required this.error,
    required this.exitCode,
    required this.executionTime,
  });

  bool get isSuccess => exitCode == 0;
}
