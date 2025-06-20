import 'package:flutter/material.dart';

/// SSH连接会话模型
class SSHSession {
  final String id;
  final String hostId;
  final String sessionName;
  final DateTime startTime;
  final DateTime? endTime;
  final SSHSessionStatus status;
  final String? lastCommand;
  final DateTime? lastActivity;
  final int commandCount;
  final String? errorMessage;

  const SSHSession({
    required this.id,
    required this.hostId,
    required this.sessionName,
    required this.startTime,
    this.endTime,
    required this.status,
    this.lastCommand,
    this.lastActivity,
    this.commandCount = 0,
    this.errorMessage,
  });

  /// 从JSON创建实例
  factory SSHSession.fromJson(Map<String, dynamic> json) {
    return SSHSession(
      id: json['id'] as String,
      hostId: json['host_id'] as String,
      sessionName: json['session_name'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time'] as String) 
          : null,
      status: SSHSessionStatus.fromString(json['status'] as String),
      lastCommand: json['last_command'] as String?,
      lastActivity: json['last_activity'] != null 
          ? DateTime.parse(json['last_activity'] as String) 
          : null,
      commandCount: json['command_count'] as int? ?? 0,
      errorMessage: json['error_message'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'host_id': hostId,
      'session_name': sessionName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status.name,
      'last_command': lastCommand,
      'last_activity': lastActivity?.toIso8601String(),
      'command_count': commandCount,
      'error_message': errorMessage,
    };
  }

  /// 复制并修改
  SSHSession copyWith({
    String? id,
    String? hostId,
    String? sessionName,
    DateTime? startTime,
    DateTime? endTime,
    SSHSessionStatus? status,
    String? lastCommand,
    DateTime? lastActivity,
    int? commandCount,
    String? errorMessage,
  }) {
    return SSHSession(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      sessionName: sessionName ?? this.sessionName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      lastCommand: lastCommand ?? this.lastCommand,
      lastActivity: lastActivity ?? this.lastActivity,
      commandCount: commandCount ?? this.commandCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// 更新最后活动
  SSHSession updateActivity(String command) {
    return copyWith(
      lastCommand: command,
      lastActivity: DateTime.now(),
      commandCount: commandCount + 1,
    );
  }

  /// 结束会话
  SSHSession endSession({String? error}) {
    return copyWith(
      endTime: DateTime.now(),
      status: error != null ? SSHSessionStatus.failed : SSHSessionStatus.closed,
      errorMessage: error,
    );
  }

  /// 获取会话持续时间
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// 获取会话持续时间的格式化字符串
  String get durationString {
    final d = duration;
    if (d.inHours > 0) {
      return '${d.inHours}小时${d.inMinutes.remainder(60)}分钟';
    } else if (d.inMinutes > 0) {
      return '${d.inMinutes}分钟${d.inSeconds.remainder(60)}秒';
    } else {
      return '${d.inSeconds}秒';
    }
  }

  /// 检查会话是否活跃
  bool get isActive {
    return status == SSHSessionStatus.connected && endTime == null;
  }

  /// 检查会话是否空闲
  bool get isIdle {
    if (!isActive || lastActivity == null) return false;
    final idleTime = DateTime.now().difference(lastActivity!);
    return idleTime.inMinutes > 5; // 5分钟无活动视为空闲
  }

  @override
  String toString() {
    return 'SSHSession(id: $id, hostId: $hostId, status: $status, duration: $durationString)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SSHSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// SSH会话状态枚举
enum SSHSessionStatus {
  connecting('connecting', '连接中'),
  connected('connected', '已连接'),
  disconnected('disconnected', '已断开'),
  closed('closed', '已关闭'),
  failed('failed', '连接失败'),
  timeout('timeout', '连接超时');

  const SSHSessionStatus(this.name, this.displayName);
  final String name;
  final String displayName;

  static SSHSessionStatus fromString(String value) {
    return SSHSessionStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SSHSessionStatus.disconnected,
    );
  }

  /// 获取状态颜色
  Color get color {
    switch (this) {
      case SSHSessionStatus.connecting:
        return const Color(0xFFFF9800); // 橙色
      case SSHSessionStatus.connected:
        return const Color(0xFF4CAF50); // 绿色
      case SSHSessionStatus.disconnected:
      case SSHSessionStatus.closed:
        return const Color(0xFF9E9E9E); // 灰色
      case SSHSessionStatus.failed:
      case SSHSessionStatus.timeout:
        return const Color(0xFFF44336); // 红色
    }
  }
}

/// 命令历史记录模型
class CommandHistory {
  final String id;
  final String sessionId;
  final String command;
  final String? output;
  final int exitCode;
  final DateTime executedAt;
  final Duration executionTime;

  const CommandHistory({
    required this.id,
    required this.sessionId,
    required this.command,
    this.output,
    required this.exitCode,
    required this.executedAt,
    required this.executionTime,
  });

  /// 从JSON创建实例
  factory CommandHistory.fromJson(Map<String, dynamic> json) {
    return CommandHistory(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      command: json['command'] as String,
      output: json['output'] as String?,
      exitCode: json['exit_code'] as int,
      executedAt: DateTime.parse(json['executed_at'] as String),
      executionTime: Duration(milliseconds: json['execution_time_ms'] as int),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'command': command,
      'output': output,
      'exit_code': exitCode,
      'executed_at': executedAt.toIso8601String(),
      'execution_time_ms': executionTime.inMilliseconds,
    };
  }

  /// 检查命令是否成功执行
  bool get isSuccess => exitCode == 0;

  @override
  String toString() {
    return 'CommandHistory(id: $id, command: $command, exitCode: $exitCode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommandHistory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
