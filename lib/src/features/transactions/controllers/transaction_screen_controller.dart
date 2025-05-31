import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/interfaces/screen_controller.dart';
import 'package:tablets/src/common/providers/screen_data_notifier.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_data_notifier.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:flutter/material.dart';

const String transactionTypeKey = 'transactionType';
const String transactionDateKey = 'date';
const String transactionNameKey = 'name';
const String transactionSalesmanKey = 'salesman';
const String transactionNumberKey = 'number';
const String transactionTotalAmountKey = 'totalAmount';
const String transactionNotesKey = 'notes';

final transactionScreenControllerProvider = Provider<TransactionScreenController>((ref) {
  final screenDataNotifier = ref.read(transactionScreenDataNotifier.notifier);
  final transactionsDbCache = ref.read(transactionDbCacheProvider.notifier);
  return TransactionScreenController(screenDataNotifier, transactionsDbCache);
});

class TransactionScreenController implements ScreenDataController {
  TransactionScreenController(
    this._screenDataNotifier,
    this._transactionsDbCache,
  );
  final ScreenDataNotifier _screenDataNotifier;
  final DbCache _transactionsDbCache;

  /// This is the optimized version of the function.
  /// It avoids a slow deep copy and uses efficient Dart collection methods.
  @override
  void setFeatureScreenData(BuildContext context) {
    final originalCacheData = _transactionsDbCache.data;

    // Step 1: Efficiently transform the list.
    // .map() creates a new list by applying a function to each element.
    // We create a new map for each transaction using the spread operator (...)
    // and then update the 'transactionTypeKey'. This is much faster than deep copying.
    final screenData = originalCacheData.map((transaction) {
      final newTransaction = {...transaction}; // Create a shallow copy of the map
      newTransaction[transactionTypeKey] =
          translateDbTextToScreenText(context, newTransaction[transactionTypeKey]);
      return newTransaction;
    }).toList();

    // Step 2: Sort the new list.
    // The comment specifies sorting from "recent to oldest", so we use a descending sort.
    // Dart's built-in sort is highly optimized.
    screenData.sort((a, b) {
      final dateA = a[transactionDateKey];
      final dateB = b[transactionDateKey];

      // Safety checks for robust sorting
      if (dateB == null) return -1;
      if (dateA == null) return 1;

      // For descending order, compare B to A.
      return dateB.compareTo(dateA);
    });

    // Step 3: Update the screen data notifier.
    _screenDataNotifier.initialize({});
    _screenDataNotifier.set(screenData);
  }

  /// create a list of lists, where each resulting list contains transaction info
  /// [type, number, date, totalQuantity, totalProfit, totalSalesmanCommission, ]
  @override
  Map<String, dynamic> getItemScreenData(
      BuildContext context, Map<String, dynamic> transactionData) {
    final dbRef = transactionData['dbRefKey'];
    return _transactionsDbCache.getItemByDbRef(dbRef);
  }
}
