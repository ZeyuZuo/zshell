/// 快捷指令模型
class Command {
  final String id;
  final String name;
  final String command;
  final String description;
  final String category;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int usageCount;

  const Command({
    required this.id,
    required this.name,
    required this.command,
    required this.description,
    required this.category,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.usageCount = 0,
  });

  /// 从JSON创建实例
  factory Command.fromJson(Map<String, dynamic> json) {
    // 安全地处理布尔值字段的类型转换
    bool isActiveValue = true;
    final isActiveRaw = json['is_active'];
    if (isActiveRaw != null) {
      if (isActiveRaw is bool) {
        isActiveValue = isActiveRaw;
      } else if (isActiveRaw is int) {
        isActiveValue = isActiveRaw == 1;
      }
    }

    return Command(
      id: json['id'] as String,
      name: json['name'] as String,
      command: json['command'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      tags: (json['tags'] as String?)?.split(',') ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isActive: isActiveValue,
      usageCount: json['usage_count'] as int? ?? 0,
    );
  }

  /// 转换为JSON
  /// 将布尔值转换为整数以兼容SQLite数据库
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'command': command,
      'description': description,
      'category': category,
      'tags': tags.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0, // 转换布尔值为整数
      'usage_count': usageCount,
    };
  }

  /// 复制并修改
  Command copyWith({
    String? id,
    String? name,
    String? command,
    String? description,
    String? category,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? usageCount,
  }) {
    return Command(
      id: id ?? this.id,
      name: name ?? this.name,
      command: command ?? this.command,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  /// 增加使用次数
  Command incrementUsage() {
    return copyWith(
      usageCount: usageCount + 1,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Command(id: $id, name: $name, command: $command, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Command && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 指令分类枚举
enum CommandCategory {
  system('系统管理'),
  file('文件操作'),
  network('网络工具'),
  development('开发工具'),
  database('数据库'),
  docker('Docker'),
  git('Git'),
  other('其他');

  const CommandCategory(this.displayName);
  final String displayName;

  static CommandCategory fromString(String value) {
    return CommandCategory.values.firstWhere(
      (category) => category.name == value || category.displayName == value,
      orElse: () => CommandCategory.other,
    );
  }
}
