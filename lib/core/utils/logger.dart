import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 应用日志工具类
/// 提供统一的日志记录功能，支持不同级别的日志输出
class AppLogger {
  static const String _tag = 'ZShell';
  
  /// 是否启用详细日志（仅在调试模式下）
  static bool get _isVerbose => kDebugMode;
  
  /// 调试日志 - 用于开发调试
  /// [message] 日志消息
  /// [tag] 可选的标签，默认使用类名
  /// [error] 可选的错误对象
  /// [stackTrace] 可选的堆栈跟踪
  static void debug(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_isVerbose) {
      _log('DEBUG', message, tag: tag, error: error, stackTrace: stackTrace);
    }
  }
  
  /// 信息日志 - 用于记录重要信息
  static void info(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('INFO', message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// 警告日志 - 用于记录警告信息
  static void warning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('WARNING', message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// 错误日志 - 用于记录错误信息
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('ERROR', message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// 数据库操作日志 - 专门用于数据库相关操作
  static void database(
    String operation,
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final fullMessage = '[$operation] $message';
    if (data != null) {
      debug('$fullMessage - Data: $data', tag: 'Database', error: error, stackTrace: stackTrace);
    } else {
      debug(fullMessage, tag: 'Database', error: error, stackTrace: stackTrace);
    }
  }
  
  /// SSH连接日志 - 专门用于SSH连接相关操作
  static void ssh(
    String operation,
    String message, {
    String? hostInfo,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final fullMessage = hostInfo != null 
        ? '[$operation] $message - Host: $hostInfo'
        : '[$operation] $message';
    info(fullMessage, tag: 'SSH', error: error, stackTrace: stackTrace);
  }
  
  /// UI操作日志 - 用于记录用户界面相关操作
  static void ui(
    String action,
    String message, {
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final fullMessage = '[$action] $message';
    if (context != null) {
      debug('$fullMessage - Context: $context', tag: 'UI', error: error, stackTrace: stackTrace);
    } else {
      debug(fullMessage, tag: 'UI', error: error, stackTrace: stackTrace);
    }
  }
  
  /// 网络请求日志 - 用于记录网络相关操作
  static void network(
    String method,
    String url,
    String message, {
    int? statusCode,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final fullMessage = statusCode != null
        ? '[$method] $url - $message (Status: $statusCode)'
        : '[$method] $url - $message';
    info(fullMessage, tag: 'Network', error: error, stackTrace: stackTrace);
  }
  
  /// 性能日志 - 用于记录性能相关信息
  static void performance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? metrics,
    String? tag,
  }) {
    final message = '$operation completed in ${duration.inMilliseconds}ms';
    if (metrics != null) {
      debug('$message - Metrics: $metrics', tag: tag ?? 'Performance');
    } else {
      debug(message, tag: tag ?? 'Performance');
    }
  }
  
  /// 内部日志记录方法
  static void _log(
    String level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final logTag = tag ?? _tag;
    final logMessage = '[$timestamp] [$level] [$logTag] $message';
    
    // 在调试模式下使用developer.log，在生产模式下使用print
    if (kDebugMode) {
      developer.log(
        message,
        time: DateTime.now(),
        level: _getLevelValue(level),
        name: logTag,
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      // 生产模式下只记录警告和错误
      if (level == 'WARNING' || level == 'ERROR') {
        print(logMessage);
        if (error != null) {
          print('Error: $error');
        }
        if (stackTrace != null) {
          print('StackTrace: $stackTrace');
        }
      }
    }
  }
  
  /// 获取日志级别对应的数值
  static int _getLevelValue(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARNING':
        return 900;
      case 'ERROR':
        return 1000;
      default:
        return 800;
    }
  }
  
  /// 记录方法调用开始
  static void methodStart(String className, String methodName, {Map<String, dynamic>? params}) {
    if (_isVerbose) {
      final message = params != null 
          ? '$className.$methodName() started with params: $params'
          : '$className.$methodName() started';
      debug(message, tag: 'Method');
    }
  }
  
  /// 记录方法调用结束
  static void methodEnd(String className, String methodName, {dynamic result}) {
    if (_isVerbose) {
      final message = result != null 
          ? '$className.$methodName() completed with result: $result'
          : '$className.$methodName() completed';
      debug(message, tag: 'Method');
    }
  }
  
  /// 记录异常信息
  static void exception(
    String className,
    String methodName,
    Object exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final message = 'Exception in $className.$methodName(): $exception';
    error(
      message,
      tag: 'Exception',
      error: exception,
      stackTrace: stackTrace ?? StackTrace.current,
    );
    
    if (context != null) {
      debug('Exception context: $context', tag: 'Exception');
    }
  }
}

/// 日志级别枚举
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// 性能监控工具
class PerformanceMonitor {
  final String _operation;
  final Stopwatch _stopwatch;
  final Map<String, dynamic>? _context;
  
  PerformanceMonitor(this._operation, {Map<String, dynamic>? context})
      : _stopwatch = Stopwatch(),
        _context = context {
    _stopwatch.start();
    AppLogger.debug('Performance monitoring started for: $_operation', tag: 'Performance');
  }
  
  /// 结束性能监控并记录结果
  void end({Map<String, dynamic>? additionalMetrics}) {
    _stopwatch.stop();
    final metrics = <String, dynamic>{
      'duration_ms': _stopwatch.elapsedMilliseconds,
      'duration_us': _stopwatch.elapsedMicroseconds,
    };
    
    if (_context != null) {
      metrics.addAll(_context!);
    }
    
    if (additionalMetrics != null) {
      metrics.addAll(additionalMetrics);
    }
    
    AppLogger.performance(_operation, _stopwatch.elapsed, metrics: metrics);
  }
}
