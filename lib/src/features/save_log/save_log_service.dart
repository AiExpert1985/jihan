import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tablets/src/common/functions/debug_print.dart';

/// A lightweight save log entry — only essential fields, not the full transaction
class SaveLogEntry {
  final DateTime saveTime;
  final String dbRef;
  final int number;
  final String transactionType;
  final String date; // transaction date as ISO string
  final String name;
  final num totalAmount;

  SaveLogEntry({
    required this.saveTime,
    required this.dbRef,
    required this.number,
    required this.transactionType,
    required this.date,
    required this.name,
    required this.totalAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'saveTime': saveTime.toIso8601String(),
      'dbRef': dbRef,
      'number': number,
      'transactionType': transactionType,
      'date': date,
      'name': name,
      'totalAmount': totalAmount,
    };
  }

  factory SaveLogEntry.fromJson(Map<String, dynamic> json) {
    return SaveLogEntry(
      saveTime: DateTime.parse(json['saveTime']),
      dbRef: json['dbRef'] ?? '',
      number: json['number'] ?? 0,
      transactionType: json['transactionType'] ?? '',
      date: json['date'] ?? '',
      name: json['name'] ?? '',
      totalAmount: json['totalAmount'] ?? 0,
    );
  }

  /// Convert transaction data to a SaveLogEntry
  static SaveLogEntry fromTransactionData(Map<String, dynamic> data) {
    // Handle date conversion
    String dateStr = '';
    final dateValue = data['date'];
    if (dateValue is DateTime) {
      dateStr = dateValue.toIso8601String();
    } else if (dateValue is Timestamp) {
      dateStr = dateValue.toDate().toIso8601String();
    } else if (dateValue is String) {
      dateStr = dateValue;
    }

    return SaveLogEntry(
      saveTime: DateTime.now(),
      dbRef: (data['dbRef'] ?? '').toString(),
      number: data['number'] ?? 0,
      transactionType: data['transactionType'] ?? '',
      date: dateStr,
      name: data['name'] ?? '',
      totalAmount: data['totalAmount'] ?? 0,
    );
  }
}

class SaveLogService {
  /// Get the save_log directory path (next to the executable)
  String _getLogDirPath() {
    final executablePath = Platform.resolvedExecutable;
    final appFolderPath = Directory(executablePath).parent.path;
    return '$appFolderPath/save_log';
  }

  /// Get the JSONL file path for a given month
  String _getLogFilePath(DateTime date) {
    final dir = _getLogDirPath();
    final month = date.month.toString().padLeft(2, '0');
    return '$dir/save_log_${date.year}_$month.jsonl';
  }

  /// Log a successful save
  void logSave(Map<String, dynamic> transactionData) {
    try {
      // Skip transactions with empty names
      final name = transactionData['name'];
      if (name == null || name.toString().isEmpty) return;

      final dir = Directory(_getLogDirPath());
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final entry = SaveLogEntry.fromTransactionData(transactionData);
      final file = File(_getLogFilePath(entry.saveTime));
      file.writeAsStringSync('${jsonEncode(entry.toJson())}\n',
          mode: FileMode.append);
    } catch (e) {
      errorPrint('Error writing save log: $e');
    }
  }

  /// Load all save log entries from all files
  List<SaveLogEntry> loadAllEntries() {
    try {
      final dir = Directory(_getLogDirPath());
      if (!dir.existsSync()) return [];
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jsonl'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      final entries = <SaveLogEntry>[];
      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            entries.add(SaveLogEntry.fromJson(json));
          } catch (e) {
            // skip corrupted lines
          }
        }
      }
      return entries;
    } catch (e) {
      errorPrint('Error loading save log: $e');
      return [];
    }
  }

  /// Sync local save log to Firebase (per-device collection)
  /// Only uploads entries newer than the last sync timestamp
  Future<void> syncToFirebase() async {
    try {
      final deviceName = Platform.localHostname;
      final collectionName = 'save-log-$deviceName';
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
          : allEntries.where((e) => e.saveTime.isAfter(lastSync!)).toList();

      if (newEntries.isEmpty) return;

      // Upload in batches of 500
      const batchSize = 500;
      for (var i = 0; i < newEntries.length; i += batchSize) {
        final chunk = newEntries.skip(i).take(batchSize).toList();
        final batch = firestore.batch();
        for (final entry in chunk) {
          final docId = entry.saveTime.millisecondsSinceEpoch.toString();
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
      debugLog(
          'Save log synced ${newEntries.length} entries to $collectionName');
    } catch (e) {
      errorPrint('Error syncing save log to Firebase: $e');
    }
  }

  /// Get all dbRefs from the save log (for missing transaction detection)
  Set<String> getAllLoggedDbRefs() {
    final entries = loadAllEntries();
    final dbRefs = <String>{};
    for (final entry in entries) {
      if (entry.dbRef.isNotEmpty) {
        dbRefs.add(entry.dbRef);
      }
    }
    return dbRefs;
  }
}

final saveLogServiceProvider =
    Provider<SaveLogService>((ref) => SaveLogService());

/// Helper to format save log entry date for display
String formatSaveLogDate(DateTime date) {
  return DateFormat('yyyy-MM-dd HH:mm').format(date);
}
