import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/ssh_host.dart';

/// 连接状态检测服务
class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  final Map<String, bool> _connectionStates = {};
  final Map<String, Timer?> _timers = {};
  final StreamController<Map<String, bool>> _stateController = 
      StreamController<Map<String, bool>>.broadcast();

  /// 连接状态流
  Stream<Map<String, bool>> get connectionStates => _stateController.stream;

  /// 获取主机连接状态
  bool getConnectionState(String hostId) {
    return _connectionStates[hostId] ?? false;
  }

  /// 开始监控主机连接状态
  void startMonitoring(List<SSHHost> hosts) {
    for (final host in hosts) {
      _startHostMonitoring(host);
    }
  }

  /// 停止监控主机连接状态
  void stopMonitoring(String hostId) {
    _timers[hostId]?.cancel();
    _timers.remove(hostId);
    _connectionStates.remove(hostId);
    _notifyStateChange();
  }

  /// 停止所有监控
  void stopAllMonitoring() {
    for (final timer in _timers.values) {
      timer?.cancel();
    }
    _timers.clear();
    _connectionStates.clear();
    _notifyStateChange();
  }

  /// 手动检测主机连接状态
  Future<bool> checkConnection(SSHHost host) async {
    try {
      final result = await _pingHost(host.host, host.port);
      _connectionStates[host.id] = result;
      _notifyStateChange();
      return result;
    } catch (e) {
      _connectionStates[host.id] = false;
      _notifyStateChange();
      return false;
    }
  }

  /// 开始监控单个主机
  void _startHostMonitoring(SSHHost host) {
    // 取消现有的定时器
    _timers[host.id]?.cancel();

    // 立即检测一次
    checkConnection(host);

    // 设置定期检测（每30秒检测一次）
    _timers[host.id] = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        await checkConnection(host);
      },
    );
  }

  /// Ping主机检测连接状态
  Future<bool> _pingHost(String host, int port) async {
    try {
      // 使用Socket连接测试端口是否可达
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 通知状态变化
  void _notifyStateChange() {
    if (!_stateController.isClosed) {
      _stateController.add(Map.from(_connectionStates));
    }
  }

  /// 释放资源
  void dispose() {
    stopAllMonitoring();
    _stateController.close();
  }
}

/// 连接状态枚举
enum ConnectionStatus {
  unknown('未知', 0),
  connecting('连接中', 1),
  connected('已连接', 2),
  disconnected('已断开', 3),
  error('连接错误', 4);

  const ConnectionStatus(this.displayName, this.value);
  final String displayName;
  final int value;

  /// 获取状态颜色
  Color get color {
    switch (this) {
      case ConnectionStatus.unknown:
        return const Color(0xFF9E9E9E); // 灰色
      case ConnectionStatus.connecting:
        return const Color(0xFFFF9800); // 橙色
      case ConnectionStatus.connected:
        return const Color(0xFF4CAF50); // 绿色
      case ConnectionStatus.disconnected:
        return const Color(0xFFF44336); // 红色
      case ConnectionStatus.error:
        return const Color(0xFF9C27B0); // 紫色
    }
  }

  /// 获取状态图标
  IconData get icon {
    switch (this) {
      case ConnectionStatus.unknown:
        return Icons.help_outline;
      case ConnectionStatus.connecting:
        return Icons.sync;
      case ConnectionStatus.connected:
        return Icons.check_circle;
      case ConnectionStatus.disconnected:
        return Icons.cancel;
      case ConnectionStatus.error:
        return Icons.error;
    }
  }
}
