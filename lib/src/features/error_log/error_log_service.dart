import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tablets/src/common/functions/debug_print.dart';

/// A single error log entry stored in the JSONL file
class ErrorLogEntry {
  final Map<String, dynamic> transaction;
  final DateTime errorTime;
  final String errorType; // 'save_failed', 'delete_failed', 'cache_update_failed'
  final String operationType; // 'add', 'edit', 'delete'
  final String errorMessage;

  ErrorLogEntry({
    required this.transaction,
    required this.errorTime,
    required this.errorType,
    required this.operationType,
    required this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    final transactionCopy = _deepConvert(transaction);
    return {
      'transaction': transactionCopy,
      'errorTime': errorTime.toIso8601String(),
      'errorType': errorType,
      'operationType': operationType,
      'errorMessage': errorMessage,
    };
  }

  /// Recursively convert all Timestamp/DateTime values to ISO strings
  /// so that jsonEncode can handle them
  static dynamic _deepConvert(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      return value.map((k, v) => MapEntry(k, _deepConvert(v)));
    }
    if (value is List) {
      return value.map(_deepConvert).toList();
    }
    return value;
  }

  factory ErrorLogEntry.fromJson(Map<String, dynamic> json) {
    return ErrorLogEntry(
      transaction: Map<String, dynamic>.from(json['transaction']),
      errorTime: DateTime.parse(json['errorTime']),
      errorType: json['errorType'] ?? '',
      operationType: json['operationType'] ?? '',
      errorMessage: json['errorMessage'] ?? '',
    );
  }
}

class ErrorLogService {
  /// Get the error_log directory path (next to the executable)
  String _getLogDirPath() {
    final executablePath = Platform.resolvedExecutable;
    final appFolderPath = Directory(executablePath).parent.path;
    return '$appFolderPath/error_log';
  }

  /// Get the JSONL file path for a given month
  String _getLogFilePath(DateTime date) {
    final dir = _getLogDirPath();
    final month = date.month.toString().padLeft(2, '0');
    return '$dir/error_log_${date.year}_$month.jsonl';
  }

  /// Log a transaction error
  void logError(Map<String, dynamic> transactionData, String errorType,
      String operationType, String errorMessage) {
    try {
      final dir = Directory(_getLogDirPath());
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final now = DateTime.now();
      final entry = ErrorLogEntry(
        transaction: transactionData,
        errorTime: now,
        errorType: errorType,
        operationType: operationType,
        errorMessage: errorMessage,
      );
      final file = File(_getLogFilePath(now));
      file.writeAsStringSync('${jsonEncode(entry.toJson())}\n',
          mode: FileMode.append);
    } catch (e) {
      errorPrint('Error writing error log: $e');
    }
  }

  /// Load all error log entries from all files
  List<ErrorLogEntry> loadAllEntries() {
    try {
      final dir = Directory(_getLogDirPath());
      if (!dir.existsSync()) return [];
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jsonl'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      final entries = <ErrorLogEntry>[];
      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            entries.add(ErrorLogEntry.fromJson(json));
          } catch (e) {
            // skip corrupted lines
          }
        }
      }
      return entries;
    } catch (e) {
      errorPrint('Error loading error log: $e');
      return [];
    }
  }

  /// Sync local error log to Firebase (per-device collection)
  /// Only uploads entries newer than the last sync timestamp
  Future<void> syncToFirebase() async {
    try {
      final deviceName = Platform.localHostname;
      final collectionName = 'error-log-$deviceName';
      final firestore = FirebaseFirestore.instance;

      // Read last sync timestamp
      final metaFile = File('${_getLogDirPath()}/sync_meta.json');
      DateTime? lastSync;
      if (metaFile.existsSync()) {
        try {
          final meta = jsonDecode(metaFile.readAsStringSync());
          lastSync = DateTime.parse(meta['lastSync']);
        } catch (_) {}
      }

      // Load all entries and filter to only new ones
      final allEntries = loadAllEntries();
      final newEntries = lastSync == null
          ? allEntries
          : allEntries.where((e) => e.errorTime.isAfter(lastSync!)).toList();

      if (newEntries.isEmpty) return;

      // Upload in batches of 500
      const batchSize = 500;
      for (var i = 0; i < newEntries.length; i += batchSize) {
        final chunk = newEntries.skip(i).take(batchSize).toList();
        final batch = firestore.batch();
        for (final entry in chunk) {
          final docId = entry.errorTime.millisecondsSinceEpoch.toString();
          final docRef = firestore.collection(collectionName).doc(docId);
          batch.set(docRef, entry.toJson());
        }
        await batch.commit();
      }

      // Update last sync timestamp
      final dir = Directory(_getLogDirPath());
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      metaFile.writeAsStringSync(
          jsonEncode({'lastSync': DateTime.now().toIso8601String()}));
      debugLog('Error log synced ${newEntries.length} entries to $collectionName');
    } catch (e) {
      errorPrint('Error syncing error log to Firebase: $e');
    }
  }
}

final errorLogServiceProvider = Provider<ErrorLogService>((ref) => ErrorLogService());

/// Helper to format error log entry date for display
String formatErrorLogDate(DateTime date) {
  return DateFormat('yyyy-MM-dd HH:mm').format(date);
}
