import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/features/deleted_transactions/repository/deleted_transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/model/missing_transaction.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';

// Provider to store missing transactions results
final missingTransactionsProvider =
    StateProvider<List<MissingTransaction>>((ref) => []);

// Provider to store backup filename
final backupFilenameProvider = StateProvider<String>((ref) => '');

/// Detects missing transactions by comparing backup file with current database
/// Returns true if successful, false if user cancelled or error occurred
Future<bool> detectMissingTransactions(
  BuildContext context,
  WidgetRef ref,
  Function(int current, int total) onProgress,
  bool Function() shouldCancel,
) async {
  try {
    // Step 1: Pick ZIP file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null) {
      // User cancelled file picker
      return false;
    }

    String? filePath = result.files.single.path;
    if (filePath == null) {
      if (context.mounted) {
        failureUserMessage(context, 'خطأ: لا يمكن الوصول إلى الملف');
      }
      return false;
    }

    // Store backup filename
    final filename = result.files.single.name;
    ref.read(backupFilenameProvider.notifier).state = filename;

    // Step 2: Extract ZIP file
    File zipFile = File(filePath);
    List<int> bytes;

    try {
      bytes = await zipFile.readAsBytes();
    } catch (e) {
      if (context.mounted) {
        failureUserMessage(context, 'خطأ: لا يمكن قراءة ملف النسخة الاحتياطية');
      }
      return false;
    }

    Archive? archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      if (context.mounted) {
        failureUserMessage(
            context, 'خطأ: ملف النسخة الاحتياطية تالف أو غير صحيح');
      }
      return false;
    }

    // Step 3: Find "التعاملات.json" file in archive
    ArchiveFile? transactionsFile;
    for (final file in archive) {
      if (file.name == 'التعاملات.json') {
        transactionsFile = file;
        break;
      }
    }

    if (transactionsFile == null) {
      if (context.mounted) {
        failureUserMessage(
            context, 'خطأ: ملف التعاملات غير موجود في النسخة الاحتياطية');
      }
      return false;
    }

    // Step 4: Parse JSON
    String jsonContent;
    try {
      jsonContent = utf8.decode(transactionsFile.content as List<int>);
    } catch (e) {
      if (context.mounted) {
        failureUserMessage(context, 'خطأ: ملف التعاملات تالف أو بصيغة غير صحيحة');
      }
      return false;
    }

    if (jsonContent.trim().isEmpty) {
      if (context.mounted) {
        failureUserMessage(context, 'خطأ: ملف التعاملات فارغ');
      }
      return false;
    }

    List<dynamic> backupTransactions;
    try {
      backupTransactions = json.decode(jsonContent) as List<dynamic>;
    } catch (e) {
      if (context.mounted) {
        failureUserMessage(context, 'خطأ: ملف التعاملات تالف أو بصيغة غير صحيحة');
      }
      return false;
    }

    if (backupTransactions.isEmpty) {
      if (context.mounted) {
        failureUserMessage(context, 'خطأ: ملف التعاملات فارغ');
      }
      return false;
    }

    // Step 5: Get current and deleted transactions
    final currentTransactions = ref.read(transactionDbCacheProvider);
    final deletedTransactions = ref.read(deletedTransactionDbCacheProvider);

    // Build Sets of dbRefs for O(1) lookup
    final currentDbRefs = <String>{};
    for (final transaction in currentTransactions) {
      final dbRef = transaction['dbRef'];
      if (dbRef != null) {
        currentDbRefs.add(dbRef.toString());
      }
    }

    final deletedDbRefs = <String>{};
    for (final transaction in deletedTransactions) {
      final dbRef = transaction['dbRef'];
      if (dbRef != null) {
        deletedDbRefs.add(dbRef.toString());
      }
    }

    // Step 6: Compare and find missing transactions
    final missingTransactions = <MissingTransaction>[];
    final totalTransactions = backupTransactions.length;
    final dateFormat = DateFormat('dd/MM/yyyy');

    for (int i = 0; i < totalTransactions; i++) {
      // Check if should cancel every 200 transactions
      if (i % 200 == 0) {
        if (shouldCancel()) {
          return false;
        }
        onProgress(i, totalTransactions);
      }

      final backupTransaction = backupTransactions[i] as Map<String, dynamic>;
      final dbRef = backupTransaction['dbRef'];

      if (dbRef == null) continue;

      final dbRefString = dbRef.toString();

      // Check if transaction exists in current OR deleted
      if (!currentDbRefs.contains(dbRefString) &&
          !deletedDbRefs.contains(dbRefString)) {
        // Transaction is missing!
        final customerName = backupTransaction['name']?.toString() ?? '';
        final transactionNumber = backupTransaction['number'] is int
            ? backupTransaction['number'] as int
            : (backupTransaction['number']?.toInt() ?? 0);
        final transactionType =
            backupTransaction['transactionType']?.toString() ?? '';

        // Parse date
        String dateString = '';
        try {
          final dateValue = backupTransaction['date'];
          if (dateValue is String) {
            // Try to parse the date string and reformat
            final parsedDate = DateTime.tryParse(dateValue);
            if (parsedDate != null) {
              dateString = dateFormat.format(parsedDate);
            } else {
              dateString = dateValue;
            }
          } else {
            dateString = dateValue?.toString() ?? '';
          }
        } catch (e) {
          dateString = backupTransaction['date']?.toString() ?? '';
        }

        final totalAmount = backupTransaction['totalAmount'] is double
            ? backupTransaction['totalAmount'] as double
            : (backupTransaction['totalAmount']?.toDouble() ?? 0.0);

        missingTransactions.add(MissingTransaction(
          customerName: customerName,
          transactionNumber: transactionNumber,
          transactionType: transactionType,
          date: dateString,
          totalAmount: totalAmount,
        ));
      }
    }

    // Final progress update
    onProgress(totalTransactions, totalTransactions);

    // Store results
    ref.read(missingTransactionsProvider.notifier).state = missingTransactions;

    return true;
  } catch (e) {
    if (context.mounted) {
      failureUserMessage(context, 'خطأ غير متوقع: $e');
    }
    return false;
  }
}
