import 'package:flutter/material.dart';
import '../../core/utils/logger.dart';

/// 调试页面
/// 用于测试日志系统和调试应用功能
/// 仅在开发模式下可用
class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  int _testCounter = 0;

  @override
  void initState() {
    super.initState();
    AppLogger.info('Debug page initialized', tag: 'Debug');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('调试页面'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '日志测试',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text('测试计数器: $_testCounter'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _testDebugLog,
                          child: const Text('测试Debug日志'),
                        ),
                        ElevatedButton(
                          onPressed: _testInfoLog,
                          child: const Text('测试Info日志'),
                        ),
                        ElevatedButton(
                          onPressed: _testWarningLog,
                          child: const Text('测试Warning日志'),
                        ),
                        ElevatedButton(
                          onPressed: _testErrorLog,
                          child: const Text('测试Error日志'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '性能测试',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _testPerformanceMonitor,
                      child: const Text('测试性能监控'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '数据库测试',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _testDatabaseLog,
                      child: const Text('测试数据库日志'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 测试Debug日志
  void _testDebugLog() {
    setState(() {
      _testCounter++;
    });
    
    AppLogger.debug(
      'This is a debug message #$_testCounter',
      tag: 'DebugTest',
    );
    
    _showSnackBar('Debug日志已记录');
  }

  /// 测试Info日志
  void _testInfoLog() {
    setState(() {
      _testCounter++;
    });
    
    AppLogger.info(
      'This is an info message #$_testCounter',
      tag: 'InfoTest',
    );
    
    _showSnackBar('Info日志已记录');
  }

  /// 测试Warning日志
  void _testWarningLog() {
    setState(() {
      _testCounter++;
    });
    
    AppLogger.warning(
      'This is a warning message #$_testCounter',
      tag: 'WarningTest',
    );
    
    _showSnackBar('Warning日志已记录');
  }

  /// 测试Error日志
  void _testErrorLog() {
    setState(() {
      _testCounter++;
    });
    
    try {
      throw Exception('Test exception #$_testCounter');
    } catch (e, stackTrace) {
      AppLogger.error(
        'This is an error message #$_testCounter',
        tag: 'ErrorTest',
        error: e,
        stackTrace: stackTrace,
      );
    }
    
    _showSnackBar('Error日志已记录');
  }

  /// 测试性能监控
  void _testPerformanceMonitor() async {
    setState(() {
      _testCounter++;
    });
    
    final monitor = PerformanceMonitor(
      'test_operation_$_testCounter',
      context: {'test_id': _testCounter},
    );
    
    // 模拟一些工作
    await Future.delayed(Duration(milliseconds: 100 + (_testCounter * 50)));
    
    monitor.end(additionalMetrics: {
      'items_processed': _testCounter * 10,
      'cache_hits': _testCounter * 3,
    });
    
    _showSnackBar('性能监控测试完成');
  }

  /// 测试数据库日志
  void _testDatabaseLog() {
    setState(() {
      _testCounter++;
    });
    
    AppLogger.database(
      'SELECT',
      'Testing database operation #$_testCounter',
      data: {
        'table': 'test_table',
        'operation': 'select',
        'count': _testCounter,
      },
    );
    
    _showSnackBar('数据库日志已记录');
  }

  /// 显示提示消息
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
