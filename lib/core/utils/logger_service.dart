import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class LoggerService {
  LoggerService._internal() {
    _logger = Logger(
      printer: PrettyPrinter(methodCount: 0),
      level: kReleaseMode ? Level.warning : Level.debug,
    );
  }

  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;

  late final Logger _logger;

  void debug(String message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.d(message, error, stackTrace);
  void info(String message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.i(message, error, stackTrace);
  void warning(String message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.w(message, error, stackTrace);
  void error(String message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(message, error, stackTrace);
}

final logger = LoggerService();
