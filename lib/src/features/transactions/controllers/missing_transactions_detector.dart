import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firebase;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/features/deleted_transactions/repository/deleted_transaction_db_cache_provider.dart';
import 'package:tablets/src/features/print_log/print_log_service.dart';
import 'package:tablets/src/features/transactions/model/missing_transaction.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/repository/transaction_repository_provider.dart';

// Provider to store missing transactions results
final missingTransactionsProvider =
    StateProvider<List<MissingTransaction>>((ref) => []);

// Provider to store file processing stats
final fileProcessingStatsProvider =
    StateProvider<List<FileProcessingResult>>((ref) => []);

/// Extracts date from backup filename (returns YYYYMMDD format)
/// Input: "tablets_backup_20260110.zip"
/// Output: "20260110"
String extractAndFormatBackupDate(String filename) {
  // Remove "tablets_backup_" prefix and ".zip" suffix
  String dateStr =
      filename.replaceAll('tablets_backup_', '').replaceAll('.zip', '');

  // Return the date string as-is (YYYYMMDD format)
  return dateStr;
}

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

    // Get backup filename
    final filename = result.files.single.name;

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
        failureUserMessage(
            context, 'خطأ: ملف التعاملات تالف أو بصيغة غير صحيحة');
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
        failureUserMessage(
            context, 'خطأ: ملف التعاملات تالف أو بصيغة غير صحيحة');
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
          backupDate: extractAndFormatBackupDate(filename),
          fullTransactionData: backupTransaction,
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

/// Detects missing transactions by comparing multiple backup files with current database
/// Processes files sequentially from oldest to newest
/// Returns true if successful (even if no missing transactions found)
Future<bool> detectMissingTransactionsMultiple(
  BuildContext context,
  WidgetRef ref,
  List<String> filePaths,
  Function(int currentFile, int totalFiles, String currentFilename) onProgress,
  bool Function() shouldCancel,
) async {
  try {
    // Sort files alphabetically (works for chronological order with YYYYMMDD format)
    final sortedFilePaths = List<String>.from(filePaths)..sort();

    // Get current and deleted transactions
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

    // Track found missing transactions using Map for efficient updates
    final missingTransactionsMap = <String, MissingTransaction>{};
    final fileStats = <FileProcessingResult>[];
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Process each file
    for (int fileIndex = 0; fileIndex < sortedFilePaths.length; fileIndex++) {
      // Check if should cancel
      if (shouldCancel()) {
        break;
      }

      final filePath = sortedFilePaths[fileIndex];
      final filename = path.basename(filePath); // Extract filename from path

      // Update progress
      onProgress(fileIndex + 1, sortedFilePaths.length, filename);

      int fileMissingCount = 0;

      try {
        // Extract ZIP file
        File zipFile = File(filePath);
        List<int> bytes;

        try {
          bytes = await zipFile.readAsBytes();
        } catch (e) {
          fileStats.add(FileProcessingResult(
            filename: filename,
            missingCount: 0,
            isCorrupted: true,
          ));
          continue; // Skip to next file
        }

        Archive? archive;
        try {
          archive = ZipDecoder().decodeBytes(bytes);
        } catch (e) {
          fileStats.add(FileProcessingResult(
            filename: filename,
            missingCount: 0,
            isCorrupted: true,
          ));
          continue; // Skip to next file
        }

        // Find "التعاملات.json" file in archive
        ArchiveFile? transactionsFile;
        for (final file in archive) {
          if (file.name == 'التعاملات.json') {
            transactionsFile = file;
            break;
          }
        }

        if (transactionsFile == null) {
          fileStats.add(FileProcessingResult(
            filename: filename,
            missingCount: 0,
            isCorrupted: true,
          ));
          continue; // Skip to next file
        }

        // Parse JSON
        String jsonContent;
        try {
          jsonContent = utf8.decode(transactionsFile.content as List<int>);
        } catch (e) {
          fileStats.add(FileProcessingResult(
            filename: filename,
            missingCount: 0,
            isCorrupted: true,
          ));
          continue; // Skip to next file
        }

        if (jsonContent.trim().isEmpty) {
          fileStats.add(FileProcessingResult(
            filename: filename,
            missingCount: 0,
            isCorrupted: true,
          ));
          continue; // Skip to next file
        }

        List<dynamic> backupTransactions;
        try {
          backupTransactions = json.decode(jsonContent) as List<dynamic>;
        } catch (e) {
          fileStats.add(FileProcessingResult(
            filename: filename,
            missingCount: 0,
            isCorrupted: true,
          ));
          continue; // Skip to next file
        }

        if (backupTransactions.isEmpty) {
          fileStats.add(FileProcessingResult(
            filename: filename,
            missingCount: 0,
            isCorrupted: true,
          ));
          continue; // Skip to next file
        }

        // Compare and find missing transactions
        for (final backupTransaction in backupTransactions) {
          if (backupTransaction is! Map<String, dynamic>) continue;

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

            // Filter out transactions with empty customer name or zero amount
            if (customerName.trim().isEmpty || totalAmount == 0) {
              continue;
            }

            final transaction = MissingTransaction(
              customerName: customerName,
              transactionNumber: transactionNumber,
              transactionType: transactionType,
              date: dateString,
              totalAmount: totalAmount,
              backupDate: extractAndFormatBackupDate(filename),
              fullTransactionData: backupTransaction,
            );

            // Check if already found in previous files
            if (!missingTransactionsMap.containsKey(dbRefString)) {
              // First occurrence - add to map and count for this file
              missingTransactionsMap[dbRefString] = transaction;
              fileMissingCount++;
            } else {
              // Already found - update with newer backup date (don't count)
              missingTransactionsMap[dbRefString] = transaction;
            }
          }
        }

        // Add file stats
        fileStats.add(FileProcessingResult(
          filename: filename,
          missingCount: fileMissingCount,
          isCorrupted: false,
        ));
      } catch (e) {
        // Error processing this file, mark as corrupted
        fileStats.add(FileProcessingResult(
          filename: filename,
          missingCount: 0,
          isCorrupted: true,
        ));
      }

      // Yield to UI thread to allow progress updates and prevent freezing
      await Future.delayed(Duration.zero);
    }

    // Convert map to list for display
    final missingTransactions = missingTransactionsMap.values.toList();

    // Store results
    ref.read(missingTransactionsProvider.notifier).state = missingTransactions;
    ref.read(fileProcessingStatsProvider.notifier).state = fileStats;

    return true;
  } catch (e) {
    if (context.mounted) {
      failureUserMessage(context, 'خطأ غير متوقع: $e');
    }
    return false;
  }
}

/// Restores a missing transaction to Firestore and local cache
/// Returns true if successful, false if failed or cancelled
Future<bool> restoreMissingTransaction(
  BuildContext context,
  WidgetRef ref,
  MissingTransaction missingTransaction,
) async {
  // Show confirmation dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('استرجاع القائمة'),
      content: const Text('هل ترغب بأسترجاع القائمة ؟'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('لا'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('نعم'),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;

  try {
    // Prepare transaction data
    final transactionData = Map<String, dynamic>.from(missingTransaction.fullTransactionData);

    // Convert date from String to DateTime (handles ISO and DD-MM-YYYY)
    if (transactionData['date'] is String) {
      final dateStr = transactionData['date'] as String;
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        transactionData['date'] = parsed;
      } else {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          transactionData['date'] = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
    }

    // Provide default for imageUrls if missing (older print-log entries)
    transactionData['imageUrls'] ??= <String>[];

    // Create Transaction object
    final transaction = Transaction.fromMap(transactionData);

    // Add to Firestore
    final repository = ref.read(transactionRepositoryProvider);
    final success = await repository.addItem(transaction);

    if (!success) {
      if (context.mounted) {
        failureUserMessage(context, 'حدث خطأ, لم يتم استراجاع القائمة');
      }
      return false;
    }

    // Add to local cache with Timestamp (to match Firestore format)
    final dbCache = ref.read(transactionDbCacheProvider.notifier);
    final cacheData = transaction.toMap();
    cacheData['date'] = firebase.Timestamp.fromDate(transaction.date);
    dbCache.update(cacheData, DbCacheOperationTypes.add);

    // Remove from missing transactions list
    final currentMissingTransactions = ref.read(missingTransactionsProvider);
    final updatedMissingTransactions = currentMissingTransactions
        .where((t) => t != missingTransaction)
        .toList();
    ref.read(missingTransactionsProvider.notifier).state = updatedMissingTransactions;

    if (context.mounted) {
      successUserMessage(context, 'تم استرجاع القائمة بنجاح');
    }

    return true;
  } catch (e) {
    if (context.mounted) {
      failureUserMessage(context, 'حدث خطأ, لم يتم استراجاع القائمة');
    }
    return false;
  }
}

/// Detects missing transactions from print log
/// Compares print log dbRefs against current transactions and deleted transactions
/// Returns list of MissingTransaction with source='print-log'
List<MissingTransaction> detectMissingFromPrintLog(WidgetRef ref) {
  final printLogService = ref.read(printLogServiceProvider);
  final loggedEntries = printLogService.getLoggedEntriesByDbRef();

  if (loggedEntries.isEmpty) return [];

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

  final missingTransactions = <MissingTransaction>[];
  final dateFormat = DateFormat('dd/MM/yyyy');

  for (final entry in loggedEntries.entries) {
    final dbRefString = entry.key;
    final logEntry = entry.value;

    if (!currentDbRefs.contains(dbRefString) &&
        !deletedDbRefs.contains(dbRefString)) {
      // Transaction is missing!
      final transactionData = logEntry.transaction;
      final customerName = transactionData['name']?.toString() ?? '';
      final transactionNumber = transactionData['number'] is int
          ? transactionData['number'] as int
          : (transactionData['number']?.toInt() ?? 0);
      final transactionType =
          transactionData['transactionType']?.toString() ?? '';

      // Skip empty transactions
      if (customerName.trim().isEmpty) continue;

      // Parse date
      String dateString = '';
      try {
        final dateValue = transactionData['date'];
        if (dateValue is String) {
          final parsedDate = DateTime.tryParse(dateValue);
          if (parsedDate != null) {
            dateString = dateFormat.format(parsedDate);
          } else {
            dateString = dateValue;
          }
        } else if (dateValue is DateTime) {
          dateString = dateFormat.format(dateValue);
        } else {
          dateString = dateValue?.toString() ?? '';
        }
      } catch (e) {
        dateString = transactionData['date']?.toString() ?? '';
      }

      final totalAmount = transactionData['totalAmount'] is double
          ? transactionData['totalAmount'] as double
          : (transactionData['totalAmount']?.toDouble() ?? 0.0);

      missingTransactions.add(MissingTransaction(
        customerName: customerName,
        transactionNumber: transactionNumber,
        transactionType: transactionType,
        date: dateString,
        totalAmount: totalAmount,
        backupDate: DateFormat('dd/MM/yyyy').format(logEntry.printTime),
        fullTransactionData: transactionData,
        source: 'print-log',
      ));
    }
  }

  return missingTransactions;
}
