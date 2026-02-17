import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tablets/src/common/functions/debug_print.dart';

/// A single print log entry stored in the JSONL file
class PrintLogEntry {
  final Map<String, dynamic> transaction;
  final DateTime printTime;
  final String printType; // 'local' or 'warehouse'

  PrintLogEntry({
    required this.transaction,
    required this.printTime,
    required this.printType,
  });

  Map<String, dynamic> toJson() {
    final transactionCopy = _deepConvert(transaction);
    return {
      'transaction': transactionCopy,
      'printTime': printTime.toIso8601String(),
      'printType': printType,
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

  factory PrintLogEntry.fromJson(Map<String, dynamic> json) {
    return PrintLogEntry(
      transaction: Map<String, dynamic>.from(json['transaction']),
      printTime: DateTime.parse(json['printTime']),
      printType: json['printType'],
    );
  }
}

class PrintLogService {
  /// Get the print_log directory path (next to the executable)
  String _getLogDirPath() {
    final executablePath = Platform.resolvedExecutable;
    final appFolderPath = Directory(executablePath).parent.path;
    return '$appFolderPath/print_log';
  }

  /// Get the JSONL file path for a given month
  String _getLogFilePath(DateTime date) {
    final dir = _getLogDirPath();
    final month = date.month.toString().padLeft(2, '0');
    return '$dir/print_log_${date.year}_$month.jsonl';
  }

  /// Log a print event. Call this BEFORE actual printing.
  void logPrint(Map<String, dynamic> transactionData, String printType) {
    try {
      final dir = Directory(_getLogDirPath());
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final now = DateTime.now();
      final entry = PrintLogEntry(
        transaction: transactionData,
        printTime: now,
        printType: printType,
      );
      final file = File(_getLogFilePath(now));
      file.writeAsStringSync('${jsonEncode(entry.toJson())}\n',
          mode: FileMode.append);
    } catch (e) {
      errorPrint('Error writing print log: $e');
    }
  }

  /// Load all print log entries from all files
  List<PrintLogEntry> loadAllEntries() {
    try {
      final dir = Directory(_getLogDirPath());
      if (!dir.existsSync()) return [];
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jsonl'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      final entries = <PrintLogEntry>[];
      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            entries.add(PrintLogEntry.fromJson(json));
          } catch (e) {
            // skip corrupted lines
          }
        }
      }
      return entries;
    } catch (e) {
      errorPrint('Error loading print log: $e');
      return [];
    }
  }

  /// Sync local print log to Firebase (per-device collection)
  /// Only uploads entries newer than the last sync timestamp
  Future<void> syncToFirebase() async {
    try {
      final deviceName = Platform.localHostname;
      final collectionName = 'print-log-$deviceName';
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
          : allEntries.where((e) => e.printTime.isAfter(lastSync!)).toList();

      if (newEntries.isEmpty) return;

      // Upload in batches of 500
      const batchSize = 500;
      for (var i = 0; i < newEntries.length; i += batchSize) {
        final chunk = newEntries.skip(i).take(batchSize).toList();
        final batch = firestore.batch();
        for (final entry in chunk) {
          // Use printTime as document ID to avoid duplicates
          final docId = entry.printTime.millisecondsSinceEpoch.toString();
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
      debugLog('Print log synced ${newEntries.length} entries to $collectionName');
    } catch (e) {
      errorPrint('Error syncing print log to Firebase: $e');
    }
  }

  /// Get all dbRefs from the print log (for missing transaction detection)
  Set<String> getAllLoggedDbRefs() {
    final entries = loadAllEntries();
    final dbRefs = <String>{};
    for (final entry in entries) {
      final dbRef = entry.transaction['dbRef'];
      if (dbRef != null) {
        dbRefs.add(dbRef.toString());
      }
    }
    return dbRefs;
  }

  /// Get print log entries as maps for missing detection
  /// Returns map of dbRef -> PrintLogEntry (latest entry per dbRef)
  Map<String, PrintLogEntry> getLoggedEntriesByDbRef() {
    final entries = loadAllEntries();
    final map = <String, PrintLogEntry>{};
    for (final entry in entries) {
      final dbRef = entry.transaction['dbRef'];
      if (dbRef != null) {
        map[dbRef.toString()] = entry; // latest entry wins
      }
    }
    return map;
  }
}

final printLogServiceProvider = Provider<PrintLogService>((ref) => PrintLogService());

/// Helper to format print log entry date for display
String formatPrintLogDate(DateTime date) {
  return DateFormat('yyyy-MM-dd HH:mm').format(date);
}
