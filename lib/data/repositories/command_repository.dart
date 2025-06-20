import '../models/command.dart';
import '../datasources/command_datasource.dart';
import '../../core/utils/uuid_generator.dart';
import '../../core/utils/validation_utils.dart';

/// 快捷指令仓库
class CommandRepository {
  final CommandDataSource _dataSource = CommandDataSource();

  /// 获取所有指令
  Future<List<Command>> getAllCommands() async {
    try {
      return await _dataSource.getAllCommands();
    } catch (e) {
      throw Exception('获取指令列表失败: $e');
    }
  }

  /// 根据分类获取指令
  Future<List<Command>> getCommandsByCategory(String category) async {
    try {
      if (category.trim().isEmpty) {
        return await getAllCommands();
      }
      return await _dataSource.getCommandsByCategory(category.trim());
    } catch (e) {
      throw Exception('获取分类指令失败: $e');
    }
  }

  /// 根据ID获取指令
  Future<Command?> getCommandById(String id) async {
    try {
      if (!ValidationUtils.isValidId(id)) {
        throw ArgumentError('无效的指令ID');
      }
      return await _dataSource.getCommandById(id);
    } catch (e) {
      throw Exception('获取指令信息失败: $e');
    }
  }

  /// 搜索指令
  Future<List<Command>> searchCommands(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllCommands();
      }
      return await _dataSource.searchCommands(query.trim());
    } catch (e) {
      throw Exception('搜索指令失败: $e');
    }
  }

  /// 添加指令
  Future<Command> addCommand({
    required String name,
    required String command,
    required String description,
    required String category,
    List<String>? tags,
  }) async {
    try {
      // 验证输入
      _validateCommandInput(name, command, description, category);

      // 检查指令名称是否已存在
      if (await _dataSource.isCommandNameExists(name)) {
        throw Exception('指令名称 "$name" 已存在');
      }

      final now = DateTime.now();
      final commandObj = Command(
        id: UuidGenerator.generate(),
        name: name.trim(),
        command: command.trim(),
        description: description.trim(),
        category: category.trim(),
        tags: tags?.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList() ?? [],
        createdAt: now,
        updatedAt: now,
      );

      await _dataSource.insertCommand(commandObj);
      return commandObj;
    } catch (e) {
      throw Exception('添加指令失败: $e');
    }
  }

  /// 更新指令
  Future<Command> updateCommand({
    required String id,
    required String name,
    required String command,
    required String description,
    required String category,
    List<String>? tags,
  }) async {
    try {
      // 验证输入
      if (!ValidationUtils.isValidId(id)) {
        throw ArgumentError('无效的指令ID');
      }
      _validateCommandInput(name, command, description, category);

      // 获取原指令信息
      final existingCommand = await _dataSource.getCommandById(id);
      if (existingCommand == null) {
        throw Exception('指令不存在');
      }

      // 检查指令名称是否已存在（排除当前指令）
      if (await _dataSource.isCommandNameExists(name, excludeId: id)) {
        throw Exception('指令名称 "$name" 已存在');
      }

      final updatedCommand = existingCommand.copyWith(
        name: name.trim(),
        command: command.trim(),
        description: description.trim(),
        category: category.trim(),
        tags: tags?.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList() ?? [],
        updatedAt: DateTime.now(),
      );

      await _dataSource.updateCommand(updatedCommand);
      return updatedCommand;
    } catch (e) {
      throw Exception('更新指令失败: $e');
    }
  }

  /// 删除指令
  Future<void> deleteCommand(String id) async {
    try {
      if (!ValidationUtils.isValidId(id)) {
        throw ArgumentError('无效的指令ID');
      }

      final command = await _dataSource.getCommandById(id);
      if (command == null) {
        throw Exception('指令不存在');
      }

      await _dataSource.deleteCommand(id);
    } catch (e) {
      throw Exception('删除指令失败: $e');
    }
  }

  /// 执行指令（增加使用次数）
  Future<Command?> executeCommand(String id) async {
    try {
      if (!ValidationUtils.isValidId(id)) {
        throw ArgumentError('无效的指令ID');
      }

      final command = await _dataSource.getCommandById(id);
      if (command == null) {
        throw Exception('指令不存在');
      }

      // 增加使用次数
      await _dataSource.incrementUsageCount(id);
      
      // 返回更新后的指令
      return await _dataSource.getCommandById(id);
    } catch (e) {
      throw Exception('执行指令失败: $e');
    }
  }

  /// 获取所有分类
  Future<List<String>> getAllCategories() async {
    try {
      return await _dataSource.getAllCategories();
    } catch (e) {
      throw Exception('获取分类列表失败: $e');
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

  /// 获取最常用的指令
  Future<List<Command>> getMostUsedCommands({int limit = 10}) async {
    try {
      return await _dataSource.getMostUsedCommands(limit: limit);
    } catch (e) {
      throw Exception('获取常用指令失败: $e');
    }
  }

  /// 获取最近添加的指令
  Future<List<Command>> getRecentCommands({int limit = 10}) async {
    try {
      return await _dataSource.getRecentCommands(limit: limit);
    } catch (e) {
      throw Exception('获取最近指令失败: $e');
    }
  }

  /// 获取指令统计信息
  Future<Map<String, dynamic>> getCommandStats() async {
    try {
      return await _dataSource.getCommandStats();
    } catch (e) {
      throw Exception('获取指令统计失败: $e');
    }
  }

  /// 批量导入指令
  Future<List<Command>> importCommands(List<Map<String, dynamic>> commandData) async {
    try {
      final commands = <Command>[];
      final now = DateTime.now();

      for (final data in commandData) {
        // 验证数据
        final name = data['name'] as String?;
        final command = data['command'] as String?;
        final description = data['description'] as String?;
        final category = data['category'] as String?;

        if (name == null || command == null || description == null || category == null) {
          continue; // 跳过无效数据
        }

        try {
          _validateCommandInput(name, command, description, category);
        } catch (e) {
          continue; // 跳过验证失败的数据
        }

        // 检查是否已存在
        if (await _dataSource.isCommandNameExists(name)) {
          continue; // 跳过已存在的指令
        }

        final tags = (data['tags'] as String?)?.split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList() ?? [];

        final commandObj = Command(
          id: UuidGenerator.generate(),
          name: name.trim(),
          command: command.trim(),
          description: description.trim(),
          category: category.trim(),
          tags: tags,
          createdAt: now,
          updatedAt: now,
        );

        commands.add(commandObj);
      }

      if (commands.isNotEmpty) {
        await _dataSource.batchInsertCommands(commands);
      }

      return commands;
    } catch (e) {
      throw Exception('导入指令失败: $e');
    }
  }

  /// 导出指令
  Future<List<Map<String, dynamic>>> exportCommands() async {
    try {
      return await _dataSource.exportCommands();
    } catch (e) {
      throw Exception('导出指令失败: $e');
    }
  }

  /// 重置使用统计
  Future<void> resetUsageStats() async {
    try {
      await _dataSource.resetUsageStats();
    } catch (e) {
      throw Exception('重置使用统计失败: $e');
    }
  }

  /// 验证指令输入
  void _validateCommandInput(String name, String command, String description, String category) {
    if (!ValidationUtils.isValidCommandName(name)) {
      throw ArgumentError('指令名称格式无效');
    }

    if (command.trim().isEmpty) {
      throw ArgumentError('指令内容不能为空');
    }

    if (description.trim().isEmpty) {
      throw ArgumentError('指令描述不能为空');
    }

    if (category.trim().isEmpty) {
      throw ArgumentError('指令分类不能为空');
    }

    // 检查指令长度
    if (command.length > 1000) {
      throw ArgumentError('指令内容过长（最多1000字符）');
    }

    if (description.length > 500) {
      throw ArgumentError('指令描述过长（最多500字符）');
    }
  }
}
