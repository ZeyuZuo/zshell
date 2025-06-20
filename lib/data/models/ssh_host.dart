import '../../core/utils/logger.dart';

/// SSH主机配置模型
/// 用于存储和管理SSH连接的配置信息
/// 包含主机地址、端口、认证信息等必要参数
class SSHHost {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String? password;
  final String? privateKeyPath;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const SSHHost({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    this.password,
    this.privateKeyPath,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// 从JSON创建实例
  /// 安全地从Map<String, dynamic>创建SSHHost实例
  /// 处理数据库中可能的类型不匹配问题
  factory SSHHost.fromJson(Map<String, dynamic> json) {
    try {
      AppLogger.database('fromJson', 'Creating SSHHost from JSON', data: json);

      // 安全地处理isActive字段的类型转换
      // 数据库中可能存储为int(0/1)或bool
      bool isActiveValue = true; // 默认值
      final isActiveRaw = json['is_active'];
      if (isActiveRaw != null) {
        if (isActiveRaw is bool) {
          isActiveValue = isActiveRaw;
        } else if (isActiveRaw is int) {
          isActiveValue = isActiveRaw == 1;
        } else if (isActiveRaw is String) {
          isActiveValue = isActiveRaw.toLowerCase() == 'true' || isActiveRaw == '1';
        }
      }

      final host = SSHHost(
        id: json['id'] as String,
        name: json['name'] as String,
        host: json['host'] as String,
        port: json['port'] as int,
        username: json['username'] as String,
        password: json['password'] as String?,
        privateKeyPath: json['private_key_path'] as String?,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        isActive: isActiveValue,
      );

      AppLogger.database('fromJson', 'Successfully created SSHHost: ${host.name}');
      return host;

    } catch (e, stackTrace) {
      AppLogger.exception('SSHHost', 'fromJson', e,
          stackTrace: stackTrace, context: {'json': json});
      rethrow;
    }
  }

  /// 转换为JSON
  /// 将布尔值转换为整数以兼容SQLite数据库
  Map<String, dynamic> toJson() {
    try {
      AppLogger.database('toJson', 'Converting SSHHost to JSON: $name');

      final json = {
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'username': username,
        'password': password,
        'private_key_path': privateKeyPath,
        'description': description,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'is_active': isActive ? 1 : 0, // 转换布尔值为整数
      };

      AppLogger.database('toJson', 'Successfully converted SSHHost to JSON', data: json);
      return json;

    } catch (e, stackTrace) {
      AppLogger.exception('SSHHost', 'toJson', e,
          stackTrace: stackTrace, context: {'host': toString()});
      rethrow;
    }
  }

  /// 复制并修改
  SSHHost copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    String? privateKeyPath,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return SSHHost(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      privateKeyPath: privateKeyPath ?? this.privateKeyPath,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'SSHHost(id: $id, name: $name, host: $host:$port, username: $username)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SSHHost && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
