import 'package:sqflite/sqflite.dart';
import '../models/note.dart';
import '../../core/constants/app_constants.dart';
import 'database_helper.dart';

/// 笔记数据源
class NoteDataSource {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// 获取所有笔记
  Future<List<Note>> getAllNotes() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.notes,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'is_pinned DESC, updated_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Note.fromJson(maps[i]);
    });
  }

  /// 根据标签获取笔记
  Future<List<Note>> getNotesByTag(String tag) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.notes,
      where: 'tags LIKE ? AND is_active = ?',
      whereArgs: ['%$tag%', 1],
      orderBy: 'is_pinned DESC, updated_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Note.fromJson(maps[i]);
    });
  }

  /// 根据主机ID获取笔记
  Future<List<Note>> getNotesByHostId(String hostId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.notes,
      where: 'host_id = ? AND is_active = ?',
      whereArgs: [hostId, 1],
      orderBy: 'is_pinned DESC, updated_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Note.fromJson(maps[i]);
    });
  }

  /// 根据ID获取笔记
  Future<Note?> getNoteById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.notes,
      where: 'id = ? AND is_active = ?',
      whereArgs: [id, 1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Note.fromJson(maps.first);
    }
    return null;
  }

  /// 搜索笔记
  Future<List<Note>> searchNotes(String query) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.notes,
      where: '''
        is_active = ? AND (
          title LIKE ? OR 
          content LIKE ? OR 
          tags LIKE ?
        )
      ''',
      whereArgs: [1, '%$query%', '%$query%', '%$query%'],
      orderBy: 'is_pinned DESC, updated_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Note.fromJson(maps[i]);
    });
  }

  /// 添加笔记
  Future<String> insertNote(Note note) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseTables.notes,
      note.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return note.id;
  }

  /// 更新笔记
  Future<int> updateNote(Note note) async {
    final db = await _databaseHelper.database;
    return await db.update(
      DatabaseTables.notes,
      note.toJson(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  /// 删除笔记（软删除）
  Future<int> deleteNote(String id) async {
    final db = await _databaseHelper.database;
    return await db.update(
      DatabaseTables.notes,
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 切换笔记置顶状态
  Future<int> togglePinNote(String id) async {
    final db = await _databaseHelper.database;
    
    // 先获取当前状态
    final note = await getNoteById(id);
    if (note == null) return 0;

    return await db.update(
      DatabaseTables.notes,
      {
        'is_pinned': note.isPinned ? 0 : 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取置顶笔记
  Future<List<Note>> getPinnedNotes() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.notes,
      where: 'is_pinned = ? AND is_active = ?',
      whereArgs: [1, 1],
      orderBy: 'updated_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Note.fromJson(maps[i]);
    });
  }

  /// 获取所有标签
  Future<List<String>> getAllTags() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.notes,
      columns: ['tags'],
      where: 'is_active = ? AND tags IS NOT NULL AND tags != ""',
      whereArgs: [1],
    );

    final Set<String> allTags = {};
    for (final map in maps) {
      final tags = (map['tags'] as String?)?.split(',') ?? [];
      allTags.addAll(tags.where((tag) => tag.trim().isNotEmpty));
    }

    return allTags.toList()..sort();
  }

  /// 获取最近更新的笔记
  Future<List<Note>> getRecentNotes({int limit = 10}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.notes,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'updated_at DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return Note.fromJson(maps[i]);
    });
  }

  /// 检查笔记标题是否存在
  Future<bool> isNoteTitleExists(String title, {String? excludeId}) async {
    final db = await _databaseHelper.database;
    String whereClause = 'title = ? AND is_active = ?';
    List<dynamic> whereArgs = [title, 1];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.notes,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  /// 获取笔记统计信息
  Future<Map<String, dynamic>> getNoteStats() async {
    final db = await _databaseHelper.database;
    
    // 总笔记数
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseTables.notes} WHERE is_active = ?',
      [1],
    );
    final totalNotes = totalResult.first['count'] as int;

    // 置顶笔记数
    final pinnedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseTables.notes} WHERE is_active = ? AND is_pinned = ?',
      [1, 1],
    );
    final pinnedNotes = pinnedResult.first['count'] as int;

    // 标签统计
    final tagStats = await getAllTags();

    // 主机关联统计
    final hostResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM ${DatabaseTables.notes} 
      WHERE is_active = ? AND host_id IS NOT NULL
    ''', [1]);
    final notesWithHost = hostResult.first['count'] as int;

    return {
      'total': totalNotes,
      'pinned': pinnedNotes,
      'tags': tagStats.length,
      'withHost': notesWithHost,
    };
  }

  /// 批量导入笔记
  Future<List<String>> batchInsertNotes(List<Note> notes) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();
    final insertedIds = <String>[];

    for (final note in notes) {
      batch.insert(
        DatabaseTables.notes,
        note.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      insertedIds.add(note.id);
    }

    await batch.commit(noResult: true);
    return insertedIds;
  }

  /// 导出笔记
  Future<List<Map<String, dynamic>>> exportNotes() async {
    final db = await _databaseHelper.database;
    return await db.query(
      DatabaseTables.notes,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at ASC',
    );
  }

  /// 全文搜索笔记内容
  Future<List<Note>> fullTextSearch(String query) async {
    final db = await _databaseHelper.database;
    
    // 使用FTS（全文搜索）如果可用，否则使用LIKE
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM ${DatabaseTables.notes}
      WHERE is_active = ? AND (
        title MATCH ? OR 
        content MATCH ? OR
        title LIKE ? OR 
        content LIKE ?
      )
      ORDER BY is_pinned DESC, updated_at DESC
    ''', [1, query, query, '%$query%', '%$query%']);

    return List.generate(maps.length, (i) {
      return Note.fromJson(maps[i]);
    });
  }
}
