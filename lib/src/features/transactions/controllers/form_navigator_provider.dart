import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';

class FromNavigator {
  final DbCache _dbCacheNotifier;
  final ItemFormData _formDataNotifier;
  int currentIndex = 0;
  bool isReadOnly = false;
  // navigatorTransactions represents all transactions of same type as the currently displayed one
  List<Map<String, dynamic>> navigatorTransactions = [];

  FromNavigator(
    this._dbCacheNotifier,
    this._formDataNotifier,
  );

  void filterPrinted() {
    navigatorTransactions = navigatorTransactions.where((formData) {
      return formData[isPrintedKey] == false;
    }).toList();
  }

  /// during intitalization, we load all transactions of same type as the currently displayed on
  /// and set the index to the displayed transaction
  /// and make it read only (unless it is a new transaction)
  void initialize(String transactionType, String dbRef) {
    try {
      // first we copy transactions with same type
      List<Map<String, dynamic>> dbCacheData = _dbCacheNotifier.data;
      navigatorTransactions = dbCacheData.where((formData) {
        return formData[transTypeKey] == transactionType;
      }).toList();
      navigatorTransactions.sort((a, b) => a[numberKey].compareTo(b[numberKey]));
      // // and add empty form to the end (new form)
      // navigatorTransactions!.add({});
      // then search for dbRef, if found means user is editing new form so we use its inde
      // if not found means user creating new form, means index should point to last empty form
      currentIndex = navigatorTransactions.length - 1;
      for (int i = 0; i < navigatorTransactions.length; i++) {
        if (navigatorTransactions[i][dbRefKey] == dbRef) {
          currentIndex = i;
        }
      }
    } catch (e) {
      String message = 'Error during initializing FormNavigator';
      debugLog(message);
      errorPrint(message);
    }
  }

  bool isValidRequest() {
    if (navigatorTransactions.isEmpty) {
      String message = 'FormNavigator was not initialized';
      debugLog(message);
      errorPrint(message);
      return false;
    }
    return true;
  }

  Map<String, dynamic> next() {
    if (!isValidRequest()) return {};
    if (currentIndex < navigatorTransactions.length - 1) {
      saveNewFormData();
      currentIndex = currentIndex + 1;
      isReadOnly = true;
    }
    return navigatorTransactions[currentIndex];
  }

  Map<String, dynamic> previous() {
    if (!isValidRequest()) return {};
    if (currentIndex > 0) {
      saveNewFormData();
      currentIndex = currentIndex - 1;
      isReadOnly = true;
    }
    return navigatorTransactions[currentIndex];
  }

  Map<String, dynamic> last() {
    if (!isValidRequest()) return {};
    saveNewFormData();
    currentIndex = navigatorTransactions.length - 1;
    isReadOnly = false;
    return navigatorTransactions[currentIndex];
  }

  Map<String, dynamic> first() {
    if (!isValidRequest()) return {};
    saveNewFormData();
    currentIndex = 0;
    isReadOnly = true;
    return navigatorTransactions[currentIndex];
  }

  void allowEdit() {
    isReadOnly = false;
  }

  void reset() {
    currentIndex = 0;
    isReadOnly = false;
    navigatorTransactions = [];
  }

  void saveNewFormData() {
    if (!isValidRequest()) return;
    if (currentIndex == navigatorTransactions.length - 1) {
      navigatorTransactions[currentIndex] = _formDataNotifier.data;
    }
  }

  void goTo(BuildContext context, int? transactionNumber) {
    bool found = false;
    if (transactionNumber == null) return;
    for (int i = 0; i < navigatorTransactions.length; i++) {
      if (navigatorTransactions[i][numberKey] == transactionNumber) {
        currentIndex = i;
        found = true;
      }
    }
    if (!found) {
      failureUserMessage(context, S.of(context).transaction_not_found);
    }
  }
}

/// the idea here is to create a copy of transactionDbCache for only similar type transaction
/// and navigate through them and display their info in the form, all transactions except
/// the newly created one are read only and become editable when user press edit button
/// this provider only provide organized data, it doesn't edit any data
final formNavigatorProvider = Provider<FromNavigator>((ref) {
  final dbCacheNotifier = ref.read(transactionDbCacheProvider.notifier);
  final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
  return FromNavigator(dbCacheNotifier, formDataNotifier);
});
