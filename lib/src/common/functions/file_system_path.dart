import 'dart:io';

import 'package:tablets/src/common/functions/debug_print.dart';

String? getBackupFilePath() {
  try {
    String executablePath = Platform.resolvedExecutable;
    String appFolderPath = Directory(executablePath).parent.path;
    Directory backupDir = Directory('$appFolderPath/database_backup');
    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }
    final currentDate = DateTime.now();
    final day = currentDate.day.toString().padLeft(2, '0');
    final month = currentDate.month.toString().padLeft(2, '0');
    final year = currentDate.year;
    final zipFileName = 'tablets_backup_$year$month$day.zip';
    return '${backupDir.path}/$zipFileName';
  } catch (e) {
    errorPrint('Error during getting backup file path -- $e');
    return null;
  }
}

String? gePdfpath(String filemane) {
  try {
    String executablePath = Platform.resolvedExecutable;
    String appFolderPath = Directory(executablePath).parent.path;
    Directory backupDir = Directory('$appFolderPath/pdf_files');
    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }
    return '${backupDir.path}/$filemane.pdf';
  } catch (e) {
    errorPrint('Error during getting backup file path -- $e');
    return null;
  }
}
