import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tablets/src/common/functions/debug_print.dart';

/// Arabic labels for primary transaction fields shown in the change summary
const Map<String, String> fieldArabicLabels = {
  'name': 'اسم الزبون',
  'number': 'رقم التعامل',
  'date': 'التاريخ',
  'salesman': 'المندوب',
  'totalAmount': 'المبلغ الكلي',
  'discount': 'الخصم',
  'currency': 'العملة',
  'notes': 'الملاحظات',
  'paymentType': 'نوع الدفع',
  'transactionType': 'نوع التعامل',
  'sellingPriceType': 'نوع سعر البيع',
  'totalAsText': 'المبلغ كتابة',
  'items': 'المواد',
  'isPrinted': 'الطباعة',
  'imageUrls': 'الصور',
};

class EditLogEntry {
  final Map<String, dynamic> oldTransaction;
  final Map<String, dynamic> newTransaction;
  final DateTime editTime;
  final List<String> changedFields;

  EditLogEntry({
    required this.oldTransaction,
    required this.newTransaction,
    required this.editTime,
    required this.changedFields,
  });

  Map<String, dynamic> toJson() {
    return {
      'oldTransaction': _deepConvert(oldTransaction),
      'newTransaction': _deepConvert(newTransaction),
      'editTime': editTime.toIso8601String(),
      'changedFields': changedFields,
    };
  }

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

  factory EditLogEntry.fromJson(Map<String, dynamic> json) {
    return EditLogEntry(
      oldTransaction: Map<String, dynamic>.from(json['oldTransaction']),
      newTransaction: Map<String, dynamic>.from(json['newTransaction']),
      editTime: DateTime.parse(json['editTime']),
      changedFields: List<String>.from(json['changedFields']),
    );
  }
}

class EditLogService {
  String _getLogDirPath() {
    final executablePath = Platform.resolvedExecutable;
    final appFolderPath = Directory(executablePath).parent.path;
    return '$appFolderPath/edit_log';
  }

  String _getLogFilePath(DateTime date) {
    final dir = _getLogDirPath();
    final month = date.month.toString().padLeft(2, '0');
    return '$dir/edit_log_${date.year}_$month.jsonl';
  }

  /// Compare two transaction maps and return list of Arabic labels for changed primary fields.
  /// Returns empty list if transactions are identical.
  List<String> getChangedFields(
      Map<String, dynamic> oldTx, Map<String, dynamic> newTx) {
    final changedLabels = <String>[];
    // Check all keys from both maps
    final allKeys = {...oldTx.keys, ...newTx.keys};
    for (final key in allKeys) {
      final oldVal = _deepConvert(oldTx[key]);
      final newVal = _deepConvert(newTx[key]);
      if (!_deepEquals(oldVal, newVal)) {
        // Only add to summary if it's a primary field
        final label = fieldArabicLabels[key];
        if (label != null) {
          changedLabels.add(label);
        }
      }
    }
    return changedLabels;
  }

  /// Check if two transactions are different (compares ALL fields)
  bool hasChanges(Map<String, dynamic> oldTx, Map<String, dynamic> newTx) {
    final allKeys = {...oldTx.keys, ...newTx.keys};
    for (final key in allKeys) {
      final oldVal = _deepConvert(oldTx[key]);
      final newVal = _deepConvert(newTx[key]);
      if (!_deepEquals(oldVal, newVal)) {
        return true;
      }
    }
    return false;
  }

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

  bool _deepEquals(dynamic a, dynamic b) {
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  /// Log an edit event
  void logEdit(Map<String, dynamic> oldTransaction,
      Map<String, dynamic> newTransaction, List<String> changedFields) {
    try {
      final dir = Directory(_getLogDirPath());
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final now = DateTime.now();
      final entry = EditLogEntry(
        oldTransaction: oldTransaction,
        newTransaction: newTransaction,
        editTime: now,
        changedFields: changedFields,
      );
      final file = File(_getLogFilePath(now));
      file.writeAsStringSync('${jsonEncode(entry.toJson())}\n',
          mode: FileMode.append);
    } catch (e) {
      errorPrint('Error writing edit log: $e');
    }
  }

  /// Load all edit log entries from all files
  List<EditLogEntry> loadAllEntries() {
    try {
      final dir = Directory(_getLogDirPath());
      if (!dir.existsSync()) return [];
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jsonl'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      final entries = <EditLogEntry>[];
      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            entries.add(EditLogEntry.fromJson(json));
          } catch (e) {
            // skip corrupted lines
          }
        }
      }
      return entries;
    } catch (e) {
      errorPrint('Error loading edit log: $e');
      return [];
    }
  }

  /// Sync local edit log to Firebase (per-device collection)
  Future<void> syncToFirebase() async {
    try {
      final deviceName = Platform.localHostname;
      final collectionName = 'edit-log-$deviceName';
      final firestore = FirebaseFirestore.instance;

      final metaFile = File('${_getLogDirPath()}/sync_meta.json');
      DateTime? lastSync;
      if (metaFile.existsSync()) {
        try {
          final meta = jsonDecode(metaFile.readAsStringSync());
          lastSync = DateTime.parse(meta['lastSync']);
        } catch (_) {}
      }

      final allEntries = loadAllEntries();
      final newEntries = lastSync == null
          ? allEntries
          : allEntries.where((e) => e.editTime.isAfter(lastSync!)).toList();

      if (newEntries.isEmpty) return;

      const batchSize = 500;
      for (var i = 0; i < newEntries.length; i += batchSize) {
        final chunk = newEntries.skip(i).take(batchSize).toList();
        final batch = firestore.batch();
        for (final entry in chunk) {
          final docId = entry.editTime.millisecondsSinceEpoch.toString();
          final docRef = firestore.collection(collectionName).doc(docId);
          batch.set(docRef, entry.toJson());
        }
        await batch.commit();
      }

      final dir = Directory(_getLogDirPath());
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      metaFile.writeAsStringSync(
          jsonEncode({'lastSync': DateTime.now().toIso8601String()}));
      debugLog('Edit log synced ${newEntries.length} entries to $collectionName');
    } catch (e) {
      errorPrint('Error syncing edit log to Firebase: $e');
    }
  }

  /// Deep copy a transaction map to prevent mutation
  Map<String, dynamic> deepCopyMap(Map<String, dynamic> source) {
    return Map<String, dynamic>.from(
        jsonDecode(jsonEncode(_deepConvert(source))));
  }
}

final editLogServiceProvider =
    Provider<EditLogService>((ref) => EditLogService());

/// Provider to hold the "before edit" snapshot
final editLogSnapshotProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

String formatEditLogDate(DateTime date) {
  return DateFormat('yyyy-MM-dd HH:mm').format(date);
}
