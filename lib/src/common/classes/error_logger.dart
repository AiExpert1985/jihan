import 'dart:io';

import 'package:tablets/src/common/functions/debug_print.dart';

class Logger {
  static Future<File> _getLogFile() async {
    final logFilePath = getFilePath();
    // Create the log file if it doesn't exist
    return File(logFilePath);
  }

  static Future<void> logError(String error) async {
    try {
      final file = await _getLogFile();
      // Append the error message with a timestamp
      final timestamp = DateTime.now().toIso8601String();
      await file.writeAsString('$timestamp: $error\n', mode: FileMode.append);
    } catch (e) {
      // we shouldn't log error, otherwise we will fall in an infite loop
      errorPrint('error during writing to log file', logError: false);
    }
  }

  static String getFilePath() {
    String executablePath = Platform.resolvedExecutable;

    String appFolderPath = Directory(executablePath).parent.path;

    return '$appFolderPath/error_log.txt';
  }
}
