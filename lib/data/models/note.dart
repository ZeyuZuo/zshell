/// 笔记模型
class Note {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final String? hostId; // 关联的主机ID
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isPinned;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    this.hostId,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.isPinned = false,
  });

  /// 从JSON创建实例
  factory Note.fromJson(Map<String, dynamic> json) {
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

    bool isPinnedValue = false;
    final isPinnedRaw = json['is_pinned'];
    if (isPinnedRaw != null) {
      if (isPinnedRaw is bool) {
        isPinnedValue = isPinnedRaw;
      } else if (isPinnedRaw is int) {
        isPinnedValue = isPinnedRaw == 1;
      }
    }

    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      tags: (json['tags'] as String?)?.split(',') ?? [],
      hostId: json['host_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isActive: isActiveValue,
      isPinned: isPinnedValue,
    );
  }

  /// 转换为JSON
  /// 将布尔值转换为整数以兼容SQLite数据库
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'tags': tags.join(','),
      'host_id': hostId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0, // 转换布尔值为整数
      'is_pinned': isPinned ? 1 : 0, // 转换布尔值为整数
    };
  }

  /// 复制并修改
  Note copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    String? hostId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isPinned,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      hostId: hostId ?? this.hostId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  /// 切换置顶状态
  Note togglePin() {
    return copyWith(
      isPinned: !isPinned,
      updatedAt: DateTime.now(),
    );
  }

  /// 添加标签
  Note addTag(String tag) {
    if (tags.contains(tag)) return this;
    return copyWith(
      tags: [...tags, tag],
      updatedAt: DateTime.now(),
    );
  }

  /// 移除标签
  Note removeTag(String tag) {
    return copyWith(
      tags: tags.where((t) => t != tag).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// 获取内容预览
  String get contentPreview {
    const maxLength = 100;
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }

  /// 获取字数统计
  int get wordCount {
    return content.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 笔记标签枚举
enum NoteTag {
  operation('运维'),
  development('开发'),
  troubleshooting('故障排查'),
  configuration('配置'),
  security('安全'),
  performance('性能'),
  backup('备份'),
  monitoring('监控'),
  deployment('部署'),
  other('其他');

  const NoteTag(this.displayName);
  final String displayName;

  static NoteTag fromString(String value) {
    return NoteTag.values.firstWhere(
      (tag) => tag.name == value || tag.displayName == value,
      orElse: () => NoteTag.other,
    );
  }
}
