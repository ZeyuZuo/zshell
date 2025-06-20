import 'dart:async';
import '../../data/models/ssh_host.dart';
import '../../data/models/ssh_session.dart';
import 'ssh_connection_service.dart';

/// SSH连接服务
class SSHService {
  static final SSHService _instance = SSHService._internal();
  factory SSHService() => _instance;
  SSHService._internal();

  final Map<String, SSHConnectionService> _connections = {};
  final StreamController<Map<String, SSHSession>> _sessionController = 
      StreamController<Map<String, SSHSession>>.broadcast();

  /// SSH会话流
  Stream<Map<String, SSHSession>> get sessions => _sessionController.stream;

  /// 获取所有活跃连接
  Map<String, SSHConnectionService> get activeConnections => Map.from(_connections);

  /// 创建SSH连接
  Future<SSHConnectionService> connect(SSHHost host) async {
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
      final connectionId = '${host.id}_${DateTime.now().millisecondsSinceEpoch}';
      final connection = SSHConnectionService(connectionId, host);
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
  SSHConnectionService? getConnection(String hostId) {
    return _connections[hostId];
  }

  /// 通知会话变化
  void _notifySessionChange() {
    final sessions = <String, SSHSession>{};
    for (final entry in _connections.entries) {
      // 创建临时会话对象用于兼容性
      final session = SSHSession(
        id: entry.value.connectionId,
        hostId: entry.key,
        sessionName: '${entry.value.host.name} - ${DateTime.now().toString().substring(0, 19)}',
        startTime: DateTime.now(),
        status: entry.value.isConnected ? SSHSessionStatus.connected : SSHSessionStatus.connecting,
      );
      sessions[entry.key] = session;
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
