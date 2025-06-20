import '../models/note.dart';
import '../datasources/note_datasource.dart';
import '../../core/utils/uuid_generator.dart';
import '../../core/utils/validation_utils.dart';

/// 笔记仓库
class NoteRepository {
  final NoteDataSource _dataSource = NoteDataSource();

  /// 获取所有笔记
  Future<List<Note>> getAllNotes() async {
    try {
      return await _dataSource.getAllNotes();
    } catch (e) {
      throw Exception('获取笔记列表失败: $e');
    }
  }

  /// 根据标签获取笔记
  Future<List<Note>> getNotesByTag(String tag) async {
    try {
      if (tag.trim().isEmpty) {
        return await getAllNotes();
      }
      return await _dataSource.getNotesByTag(tag.trim());
    } catch (e) {
      throw Exception('获取标签笔记失败: $e');
    }
  }

  /// 根据主机ID获取笔记
  Future<List<Note>> getNotesByHostId(String hostId) async {
    try {
      if (!ValidationUtils.isValidId(hostId)) {
        throw ArgumentError('无效的主机ID');
      }
      return await _dataSource.getNotesByHostId(hostId);
    } catch (e) {
      throw Exception('获取主机笔记失败: $e');
    }
  }

  /// 根据ID获取笔记
  Future<Note?> getNoteById(String id) async {
    try {
      if (!ValidationUtils.isValidId(id)) {
        throw ArgumentError('无效的笔记ID');
      }
      return await _dataSource.getNoteById(id);
    } catch (e) {
      throw Exception('获取笔记信息失败: $e');
    }
  }

  /// 搜索笔记
  Future<List<Note>> searchNotes(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllNotes();
      }
      return await _dataSource.searchNotes(query.trim());
    } catch (e) {
      throw Exception('搜索笔记失败: $e');
    }
  }

  /// 添加笔记
  Future<Note> addNote({
    required String title,
    required String content,
    List<String>? tags,
    String? hostId,
    bool isPinned = false,
  }) async {
    try {
      // 验证输入
      _validateNoteInput(title, content);

      if (hostId != null && !ValidationUtils.isValidId(hostId)) {
        throw ArgumentError('无效的主机ID');
      }

      // 检查笔记标题是否已存在
      if (await _dataSource.isNoteTitleExists(title)) {
        throw Exception('笔记标题 "$title" 已存在');
      }

      final now = DateTime.now();
      final note = Note(
        id: UuidGenerator.generate(),
        title: title.trim(),
        content: content.trim(),
        tags: tags?.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList() ?? [],
        hostId: hostId,
        createdAt: now,
        updatedAt: now,
        isPinned: isPinned,
      );

      await _dataSource.insertNote(note);
      return note;
    } catch (e) {
      throw Exception('添加笔记失败: $e');
    }
  }

  /// 更新笔记
  Future<Note> updateNote({
    required String id,
    required String title,
    required String content,
    List<String>? tags,
    String? hostId,
    bool? isPinned,
  }) async {
    try {
      // 验证输入
      if (!ValidationUtils.isValidId(id)) {
        throw ArgumentError('无效的笔记ID');
      }
      _validateNoteInput(title, content);

      if (hostId != null && !ValidationUtils.isValidId(hostId)) {
        throw ArgumentError('无效的主机ID');
      }

      // 获取原笔记信息
      final existingNote = await _dataSource.getNoteById(id);
      if (existingNote == null) {
        throw Exception('笔记不存在');
      }

      // 检查笔记标题是否已存在（排除当前笔记）
      if (await _dataSource.isNoteTitleExists(title, excludeId: id)) {
        throw Exception('笔记标题 "$title" 已存在');
      }

      final updatedNote = existingNote.copyWith(
        title: title.trim(),
        content: content.trim(),
        tags: tags?.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList(),
        hostId: hostId,
        updatedAt: DateTime.now(),
        isPinned: isPinned,
      );

      await _dataSource.updateNote(updatedNote);
      return updatedNote;
    } catch (e) {
      throw Exception('更新笔记失败: $e');
    }
  }

  /// 删除笔记
  Future<void> deleteNote(String id) async {
    try {
      if (!ValidationUtils.isValidId(id)) {
        throw ArgumentError('无效的笔记ID');
      }

      final note = await _dataSource.getNoteById(id);
      if (note == null) {
        throw Exception('笔记不存在');
      }

      await _dataSource.deleteNote(id);
    } catch (e) {
      throw Exception('删除笔记失败: $e');
    }
  }

  /// 切换笔记置顶状态
  Future<Note?> togglePinNote(String id) async {
    try {
      if (!ValidationUtils.isValidId(id)) {
        throw ArgumentError('无效的笔记ID');
      }

      final note = await _dataSource.getNoteById(id);
      if (note == null) {
        throw Exception('笔记不存在');
      }

      await _dataSource.togglePinNote(id);
      
      // 返回更新后的笔记
      return await _dataSource.getNoteById(id);
    } catch (e) {
      throw Exception('切换置顶状态失败: $e');
    }
  }

  /// 获取置顶笔记
  Future<List<Note>> getPinnedNotes() async {
    try {
      return await _dataSource.getPinnedNotes();
    } catch (e) {
      throw Exception('获取置顶笔记失败: $e');
    }
  }

  /// 获取所有标签
  Future<List<String>> getAllTags() async {
    try {
      return await _dataSource.getAllTags();
    } catch (e) {
      throw Exception('获取标签列表失败: $e');
    }
  }

  /// 获取最近更新的笔记
  Future<List<Note>> getRecentNotes({int limit = 10}) async {
    try {
      return await _dataSource.getRecentNotes(limit: limit);
    } catch (e) {
      throw Exception('获取最近笔记失败: $e');
    }
  }

  /// 获取笔记统计信息
  Future<Map<String, dynamic>> getNoteStats() async {
    try {
      return await _dataSource.getNoteStats();
    } catch (e) {
      throw Exception('获取笔记统计失败: $e');
    }
  }

  /// 批量导入笔记
  Future<List<Note>> importNotes(List<Map<String, dynamic>> noteData) async {
    try {
      final notes = <Note>[];
      final now = DateTime.now();

      for (final data in noteData) {
        // 验证数据
        final title = data['title'] as String?;
        final content = data['content'] as String?;

        if (title == null || content == null) {
          continue; // 跳过无效数据
        }

        try {
          _validateNoteInput(title, content);
        } catch (e) {
          continue; // 跳过验证失败的数据
        }

        // 检查是否已存在
        if (await _dataSource.isNoteTitleExists(title)) {
          continue; // 跳过已存在的笔记
        }

        final tags = (data['tags'] as String?)?.split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList() ?? [];

        final note = Note(
          id: UuidGenerator.generate(),
          title: title.trim(),
          content: content.trim(),
          tags: tags,
          hostId: data['host_id'] as String?,
          createdAt: now,
          updatedAt: now,
          isPinned: data['is_pinned'] as bool? ?? false,
        );

        notes.add(note);
      }

      if (notes.isNotEmpty) {
        await _dataSource.batchInsertNotes(notes);
      }

      return notes;
    } catch (e) {
      throw Exception('导入笔记失败: $e');
    }
  }

  /// 导出笔记
  Future<List<Map<String, dynamic>>> exportNotes() async {
    try {
      return await _dataSource.exportNotes();
    } catch (e) {
      throw Exception('导出笔记失败: $e');
    }
  }

  /// 全文搜索笔记
  Future<List<Note>> fullTextSearch(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllNotes();
      }
      return await _dataSource.fullTextSearch(query.trim());
    } catch (e) {
      throw Exception('全文搜索失败: $e');
    }
  }

  /// 验证笔记输入
  void _validateNoteInput(String title, String content) {
    if (!ValidationUtils.isValidNoteTitle(title)) {
      throw ArgumentError('笔记标题格式无效');
    }

    if (content.trim().isEmpty) {
      throw ArgumentError('笔记内容不能为空');
    }

    // 检查内容长度
    if (content.length > 100000) {
      throw ArgumentError('笔记内容过长（最多100000字符）');
    }
  }
}
