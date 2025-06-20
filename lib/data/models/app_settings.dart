import 'package:flutter/material.dart';

/// 应用设置模型
class AppSettings {
  final String id;
  final ThemeMode themeMode;
  final String language;
  final int connectionTimeout;
  final int maxRetryAttempts;
  final bool autoLock;
  final int autoLockTimeout; // 分钟
  final bool enableLogging;
  final String defaultTerminal;
  final bool enableNotifications;
  final bool enableAutoBackup;
  final String backupPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppSettings({
    required this.id,
    this.themeMode = ThemeMode.system,
    this.language = 'zh_CN',
    this.connectionTimeout = 30,
    this.maxRetryAttempts = 3,
    this.autoLock = false,
    this.autoLockTimeout = 15,
    this.enableLogging = true,
    this.defaultTerminal = 'system',
    this.enableNotifications = true,
    this.enableAutoBackup = false,
    this.backupPath = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从JSON创建实例
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    // 安全地处理布尔值字段的类型转换
    bool autoLockValue = false;
    final autoLockRaw = json['auto_lock'];
    if (autoLockRaw != null) {
      if (autoLockRaw is bool) {
        autoLockValue = autoLockRaw;
      } else if (autoLockRaw is int) {
        autoLockValue = autoLockRaw == 1;
      }
    }

    bool enableLoggingValue = true;
    final enableLoggingRaw = json['enable_logging'];
    if (enableLoggingRaw != null) {
      if (enableLoggingRaw is bool) {
        enableLoggingValue = enableLoggingRaw;
      } else if (enableLoggingRaw is int) {
        enableLoggingValue = enableLoggingRaw == 1;
      }
    }

    bool enableNotificationsValue = true;
    final enableNotificationsRaw = json['enable_notifications'];
    if (enableNotificationsRaw != null) {
      if (enableNotificationsRaw is bool) {
        enableNotificationsValue = enableNotificationsRaw;
      } else if (enableNotificationsRaw is int) {
        enableNotificationsValue = enableNotificationsRaw == 1;
      }
    }

    bool enableAutoBackupValue = false;
    final enableAutoBackupRaw = json['enable_auto_backup'];
    if (enableAutoBackupRaw != null) {
      if (enableAutoBackupRaw is bool) {
        enableAutoBackupValue = enableAutoBackupRaw;
      } else if (enableAutoBackupRaw is int) {
        enableAutoBackupValue = enableAutoBackupRaw == 1;
      }
    }

    return AppSettings(
      id: json['id'] as String,
      themeMode: ThemeMode.values[json['theme_mode'] as int? ?? 0],
      language: json['language'] as String? ?? 'zh_CN',
      connectionTimeout: json['connection_timeout'] as int? ?? 30,
      maxRetryAttempts: json['max_retry_attempts'] as int? ?? 3,
      autoLock: autoLockValue,
      autoLockTimeout: json['auto_lock_timeout'] as int? ?? 15,
      enableLogging: enableLoggingValue,
      defaultTerminal: json['default_terminal'] as String? ?? 'system',
      enableNotifications: enableNotificationsValue,
      enableAutoBackup: enableAutoBackupValue,
      backupPath: json['backup_path'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// 转换为JSON
  /// 将布尔值转换为整数以兼容SQLite数据库
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'theme_mode': themeMode.index,
      'language': language,
      'connection_timeout': connectionTimeout,
      'max_retry_attempts': maxRetryAttempts,
      'auto_lock': autoLock ? 1 : 0, // 转换布尔值为整数
      'auto_lock_timeout': autoLockTimeout,
      'enable_logging': enableLogging ? 1 : 0, // 转换布尔值为整数
      'default_terminal': defaultTerminal,
      'enable_notifications': enableNotifications ? 1 : 0, // 转换布尔值为整数
      'enable_auto_backup': enableAutoBackup ? 1 : 0, // 转换布尔值为整数
      'backup_path': backupPath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改
  AppSettings copyWith({
    String? id,
    ThemeMode? themeMode,
    String? language,
    int? connectionTimeout,
    int? maxRetryAttempts,
    bool? autoLock,
    int? autoLockTimeout,
    bool? enableLogging,
    String? defaultTerminal,
    bool? enableNotifications,
    bool? enableAutoBackup,
    String? backupPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      id: id ?? this.id,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      maxRetryAttempts: maxRetryAttempts ?? this.maxRetryAttempts,
      autoLock: autoLock ?? this.autoLock,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      enableLogging: enableLogging ?? this.enableLogging,
      defaultTerminal: defaultTerminal ?? this.defaultTerminal,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableAutoBackup: enableAutoBackup ?? this.enableAutoBackup,
      backupPath: backupPath ?? this.backupPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 创建默认设置
  factory AppSettings.defaultSettings() {
    final now = DateTime.now();
    return AppSettings(
      id: 'default',
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  String toString() {
    return 'AppSettings(id: $id, themeMode: $themeMode, language: $language)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 支持的语言枚举
enum SupportedLanguage {
  zhCN('zh_CN', '简体中文'),
  enUS('en_US', 'English');

  const SupportedLanguage(this.code, this.displayName);
  final String code;
  final String displayName;

  static SupportedLanguage fromCode(String code) {
    return SupportedLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => SupportedLanguage.zhCN,
    );
  }
}

/// 终端类型枚举
enum TerminalType {
  system('system', '系统默认'),
  cmd('cmd', 'Command Prompt'),
  powershell('powershell', 'PowerShell'),
  wsl('wsl', 'WSL'),
  gitBash('git-bash', 'Git Bash');

  const TerminalType(this.value, this.displayName);
  final String value;
  final String displayName;

  static TerminalType fromValue(String value) {
    return TerminalType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TerminalType.system,
    );
  }
}
