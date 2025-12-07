import 'dart:convert';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';

/// List of detail field keys that contain transactions at index 0
/// These are the keys where the first element of each inner list is a Transaction object
const List<String> _detailFieldsWithTransactions = [
  // Customer screen detail fields
  'totalDebtDetails',
  'openInvoicesDetails',
  'dueDebtDetails',
  'avgClosingDaysDetails',
  'invoicesProfitDetails',
  'giftsDetails',
  // Product screen detail fields
  'quantityDetails',
  'profitDetails',
  // Salesman screen detail fields
  'salaryDetails', // commission details
  'numInvoicesDetails',
  'numReceiptsDetails',
  'numReturnsDetails',
  'profitDetails',
  'invoices', // Full transaction lists in salesman data
  'receipts',
  'returns',
];

/// Converts screen data for saving to Firebase cache
/// Replaces Transaction objects in detail fields with their dbRef strings
/// Also stores nested lists as JSON strings for Firebase Web compatibility
Map<String, dynamic> convertForCacheSave(Map<String, dynamic> screenData) {
  final Map<String, dynamic> result = {};

  screenData.forEach((key, value) {
    // Check if this is a List<List> (nested list) - needs JSON encoding for Firebase Web
    if (value is List && value.isNotEmpty && value.first is List) {
      // This is a nested list - convert Transaction/DateTime objects and JSON encode
      if (_detailFieldsWithTransactions.contains(key)) {
        // Contains Transaction objects - needs special conversion
        final converted = _convertDetailListForSave(value);
        result[key] = jsonEncode(converted);
      } else {
        // Doesn't contain Transaction objects, but still needs JSON encoding
        result[key] = jsonEncode(value);
      }
    } else if (_detailFieldsWithTransactions.contains(key) && value is List) {
      // Flat list with transactions - still convert and encode
      final converted = _convertDetailListForSave(value);
      result[key] = jsonEncode(converted);
    } else {
      result[key] = value;
    }
  });

  return result;
}

/// Converts cached data after loading from Firebase
/// Replaces dbRef strings in detail fields with Transaction objects from cache
/// Also parses JSON strings back to lists (stored as JSON for Web compatibility)
Map<String, dynamic> enrichWithTransactions(
  Map<String, dynamic> cachedData,
  List<Map<String, dynamic>> transactionDbCache,
) {
  final Map<String, dynamic> result = {};

  cachedData.forEach((key, value) {
    if (value is String && (value.startsWith('[') || value.startsWith('{'))) {
      // This looks like a JSON string - try to decode it
      try {
        final decoded = jsonDecode(value);
        if (_detailFieldsWithTransactions.contains(key) && decoded is List) {
          // This is a transaction detail list - needs enrichment
          result[key] =
              _enrichDetailListWithTransactions(decoded, transactionDbCache);
        } else if (decoded is List &&
            decoded.isNotEmpty &&
            decoded.first is List) {
          // This is a nested list (without transactions) - explicitly cast to List<List<dynamic>>
          result[key] =
              decoded.map((item) => (item as List).cast<dynamic>()).toList();
        } else {
          // Just a regular JSON-encoded value
          result[key] = decoded;
        }
      } catch (_) {
        // Not valid JSON, keep as-is
        result[key] = value;
      }
    } else if (_detailFieldsWithTransactions.contains(key) && value is List) {
      // Legacy format - already a list with transactions
      result[key] =
          _enrichDetailListWithTransactions(value, transactionDbCache);
    } else {
      result[key] = value;
    }
  });

  return result;
}

/// Helper to convert detail list for saving (Transaction -> dbRef, DateTime -> milliseconds)
List<List<dynamic>> _convertDetailListForSave(List<dynamic> detailList) {
  final List<List<dynamic>> result = [];

  for (var item in detailList) {
    if (item is List && item.isNotEmpty) {
      final List<dynamic> newItem = [];

      // Process each element in the inner list
      for (var element in item) {
        if (element is Transaction) {
          // Convert Transaction to dbRef string
          newItem.add(element.dbRef);
        } else if (element is DateTime) {
          // Convert DateTime to milliseconds since epoch
          newItem.add(element.millisecondsSinceEpoch);
        } else {
          // Keep other types as-is
          newItem.add(element);
        }
      }

      result.add(newItem);
    }
  }

  return result;
}

/// Helper to enrich detail list with transactions (dbRef -> Transaction, milliseconds -> DateTime)
List<List<dynamic>> _enrichDetailListWithTransactions(
  List<dynamic> detailList,
  List<Map<String, dynamic>> transactionDbCache,
) {
  // Timestamps for year 2000 and 2100 in milliseconds (reasonable date range)
  const int minValidTimestamp = 946684800000; // 2000-01-01
  const int maxValidTimestamp = 4102444800000; // 2100-01-01

  final List<List<dynamic>> result = [];

  for (var item in detailList) {
    if (item is List && item.isNotEmpty) {
      final List<dynamic> newItem = [];

      for (var j = 0; j < item.length; j++) {
        final element = item[j];

        if (j == 0 && element is String) {
          // First element is dbRef, convert to Transaction
          final transactionMap =
              _findTransactionByDbRef(element, transactionDbCache);
          if (transactionMap != null) {
            newItem.add(Transaction.fromMap(transactionMap));
          } else {
            // If not found, keep the dbRef as is (transaction might have been deleted)
            newItem.add(element);
          }
        } else if (element is int &&
            element >= minValidTimestamp &&
            element <= maxValidTimestamp) {
          // This looks like a timestamp in milliseconds, convert to DateTime
          newItem.add(DateTime.fromMillisecondsSinceEpoch(element));
        } else {
          // Keep other elements as-is
          newItem.add(element);
        }
      }

      result.add(newItem);
    }
  }

  return result;
}

/// Find transaction in cache by dbRef
Map<String, dynamic>? _findTransactionByDbRef(
  String dbRef,
  List<Map<String, dynamic>> transactionDbCache,
) {
  try {
    return transactionDbCache.firstWhere(
      (t) => t['dbRef'] == dbRef,
    );
  } catch (e) {
    // Transaction not found (might have been deleted)
    debugLog('Transaction with dbRef $dbRef not found in cache');
    return null;
  }
}

/// Enriches a list of screen data items with transactions
List<Map<String, dynamic>> enrichScreenDataList(
  List<Map<String, dynamic>> cachedDataList,
  List<Map<String, dynamic>> transactionDbCache,
) {
  return cachedDataList.map((item) {
    return enrichWithTransactions(item, transactionDbCache);
  }).toList();
}
