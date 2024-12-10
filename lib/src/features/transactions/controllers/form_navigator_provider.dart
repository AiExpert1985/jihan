import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';

class FromNavigator {
  final DbCache _dbCacheNotifier;
  final ItemFormData _formDataNotifier;
  int? currentIndex;
  bool? isReadOnly;
  List<Map<String, dynamic>>? transactionsOfSameType;

  FromNavigator(
    this._dbCacheNotifier,
    this._formDataNotifier,
  );

  void initialize(String transactionType, String dbRef) {
    try {
      // first we copy transactions with same type
      List<Map<String, dynamic>> dbCacheData = _dbCacheNotifier.data;
      transactionsOfSameType = dbCacheData.where((formData) {
        return formData[transTypeKey] == transactionType;
      }).toList();
      transactionsOfSameType!.sort((a, b) => a[numberKey].compareTo(b[numberKey]));
      // and add empty form to the end (new form)
      transactionsOfSameType!.add({});
      // then search for dbRef, if found means user is editing new form so we use its inde
      // if not found means user creating new form, means index should point to last empty form
      currentIndex = transactionsOfSameType!.length - 1;
      for (int i = 0; i < transactionsOfSameType!.length; i++) {
        if (transactionsOfSameType![i][dbRefKey] == dbRef) {
          currentIndex = i;
        }
      }
      isReadOnly = false;
    } catch (e) {
      String message = 'Error during initializing FormNavigator';
      errorLog(message);
      errorPrint(message);
    }
  }

  bool isValidRequest() {
    if (currentIndex == null || transactionsOfSameType == null) {
      String message = 'FormNavigator was not initialized';
      errorLog(message);
      errorPrint(message);
      return false;
    }
    return true;
  }

  Map<String, dynamic> next() {
    if (!isValidRequest()) return {};
    if (currentIndex! < transactionsOfSameType!.length - 1) {
      saveNewFormData();
      currentIndex = currentIndex! + 1;
      isReadOnly = true;
    }
    return transactionsOfSameType![currentIndex!];
  }

  Map<String, dynamic> previous() {
    if (!isValidRequest()) return {};
    if (currentIndex! > 0) {
      saveNewFormData();
      currentIndex = currentIndex! - 1;
      isReadOnly = true;
    }
    return transactionsOfSameType![currentIndex!];
  }

  Map<String, dynamic> last() {
    if (!isValidRequest()) return {};
    saveNewFormData();
    currentIndex = transactionsOfSameType!.length - 1;
    isReadOnly = false;
    return transactionsOfSameType![currentIndex!];
  }

  Map<String, dynamic> first() {
    if (!isValidRequest()) return {};
    saveNewFormData();
    currentIndex = 0;
    isReadOnly = true;
    return transactionsOfSameType![currentIndex!];
  }

  void allowEdit() {
    isReadOnly = false;
  }

  void reset() {
    currentIndex = null;
    isReadOnly = null;
    transactionsOfSameType = null;
  }

  void saveNewFormData() {
    if (!isValidRequest()) return;
    if (currentIndex == transactionsOfSameType!.length - 1) {
      transactionsOfSameType![currentIndex!] = _formDataNotifier.data;
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
