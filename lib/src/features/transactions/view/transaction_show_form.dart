import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/classes/item_form_controller.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/providers/text_editing_controllers_provider.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/widgets/dialog_delete_confirmation.dart';
import 'package:tablets/src/features/settings/view/settings_keys.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_controller.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_controller.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/view/transaction_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firebase;

class TransactionShowForm {
  static void showForm(
      BuildContext context,
      WidgetRef ref,
      ImageSliderNotifier imagePickerNotifier,
      ItemFormData formDataNotifier,
      ItemFormData settingsDataNotifier,
      TextControllerNotifier textEditingNotifier,
      {String? formType,
      Transaction? transaction,
      DbCache? transactionDbCache}) {
    if (formType == null && transaction?.transactionType == null) {
      errorPrint(
          'both formType and transaction can not be null, one of them is needed for transactionType');
      return;
    }
    String transactionType = formType ?? transaction?.transactionType as String;
    imagePickerNotifier.initialize();
    initializeFormData(
      context,
      formDataNotifier,
      settingsDataNotifier,
      transactionType,
      transaction: transaction,
      transactionDbCache: transactionDbCache,
    );
    initializeTextFieldControllers(textEditingNotifier, formDataNotifier);
    bool isEditMode = transaction != null;

    if (!isEditMode) {
      // if the transaction is new, we save it directly with empty data
      saveTransaction(context, ref, formDataNotifier.data, false);
    }

    // // initalize form navigator
    // final formNavigator = ref.read(formNavigatorProvider);
    // formNavigator.initialize(transactionType, formDataNotifier.data['dbRef']);

    showDialog(
      context: context,
      // barrierDismissible: false,
      builder: (BuildContext ctx) => TransactionForm(isEditMode, transactionType),
    ).whenComplete(() {
      imagePickerNotifier.close();
      final formController = ref.read(transactionFormControllerProvider);
      final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
      final screenController = ref.read(transactionScreenControllerProvider);
      final dbCache = ref.read(transactionDbCacheProvider.notifier);
      if (context.mounted) {
        // if no transaction name, automatically delete the transaction
        if (formDataNotifier.data[nameKey] == '') {
          deleteTransaction(context, formDataNotifier, imagePickerNotifier, formController, dbCache,
              screenController,
              showConfiramtion: false, keepDialog: true);
        } else {
          // we update item on close, unless the dialog were closed due to delete button
          // we need to check, if transaction is in dbCache it means dialog was not close
          // due to delete button, i.e. item was updated
          final transDbRef = formDataNotifier.data[dbRefKey];
          if (dbCache.getItemByDbRef(transDbRef).isNotEmpty) {
            saveTransaction(context, ref, formDataNotifier.data, true);
          }
        }
      }
    });
  }

  static Future<void> deleteTransaction(
      BuildContext context,
      ItemFormData formDataNotifier,
      ImageSliderNotifier formImagesNotifier,
      ItemFormController formController,
      DbCache transactionDbCache,
      TransactionScreenController screenController,
      {bool showConfiramtion = true,
      bool keepDialog = false}) async {
    if (showConfiramtion) {
      final confirmation = await showDeleteConfirmationDialog(
          context: context, message: formDataNotifier.data['name']);
      if (confirmation == null) return;
    }
    final formData = formDataNotifier.data;

    final imageUrls = formImagesNotifier.saveChanges();
    final itemData = {...formData, 'imageUrls': imageUrls};
    final transaction = Transaction.fromMap(itemData);
    if (context.mounted) {
      formController.deleteItemFromDb(context, transaction, keepDialogOpen: true);
    }
    // update the bdCache (database mirror) so that we don't need to fetch data from db
    const operationType = DbCacheOperationTypes.delete;
    transactionDbCache.update(itemData, operationType);
    // redo screenData calculations
    if (context.mounted) {
      screenController.setFeatureScreenData(context);
    }

    if (context.mounted && !keepDialog) {
      Navigator.of(context).pop();
    }
  }

  static void saveTransaction(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> formData,
    bool isEditing,
  ) {
    final formController = ref.read(transactionFormControllerProvider);
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final formImagesNotifier = ref.read(imagePickerProvider.notifier);
    final screenController = ref.read(transactionScreenControllerProvider);
    final dbCache = ref.read(transactionDbCacheProvider.notifier);
    // if (isEditing) {
    //   if (!formController.validateData()) return;
    //   formController.submitData();
    // }
    Map<String, dynamic> formData = {...formDataNotifier.data};
    // we need to remove empty rows (rows without item name, which is usally last one)
    formData = removeEmptyRows(formData);
    final imageUrls = formImagesNotifier.saveChanges();
    final itemData = {...formData, 'imageUrls': imageUrls};
    final transaction = Transaction.fromMap({...formData, 'imageUrls': imageUrls});
    formController.saveItemToDb(context, transaction, isEditing, keepDialogOpen: true);
    // update the bdCache (database mirror) so that we don't need to fetch data from db
    if (itemData[transactionDateKey] is DateTime) {
      // in our form the data type usually is DateTime, but the date type in dbCache should be
      // Timestamp, as to mirror the datatype of firebase
      itemData[transactionDateKey] = firebase.Timestamp.fromDate(formData[transactionDateKey]);
    }
    final operationType = isEditing ? DbCacheOperationTypes.edit : DbCacheOperationTypes.add;
    dbCache.update(itemData, operationType);
    // redo screenData calculations
    if (context.mounted) {
      screenController.setFeatureScreenData(context);
    }
  }

  /// delete rows where there is not item name
  static Map<String, dynamic> removeEmptyRows(Map<String, dynamic> formData) {
    List<Map<String, dynamic>> items = [];
    for (var i = 0; i < formData[itemsKey].length; i++) {
      final item = formData[itemsKey][i];
      // only add items with non empty name field
      if (item[nameKey] != '') {
        Map<String, dynamic> newItem = {};
        item.forEach((key, value) => newItem[key] = value);
        items.add(newItem);
      }
    }
    return {...formData, itemsKey: items};
  }

  static void initializeFormData(BuildContext context, ItemFormData formDataNotifier,
      ItemFormData settingsDataNotifier, String transactionType,
      {Transaction? transaction, DbCache? transactionDbCache}) {
    // note here if transaction is null, it it equivalent to calling
    // formDataNotifier.intialize();
    formDataNotifier.initialize(initialData: transaction?.toMap());
    // add empty row of items for both new forms & updating forms
    formDataNotifier.updateSubProperties(itemsKey, {
      itemCodeKey: null,
      itemNameKey: '',
      itemSellingPriceKey: 0,
      itemWeightKey: 0,
      itemSoldQuantityKey: 0,
      itemGiftQuantityKey: 0,
      itemTotalAmountKey: 0,
      itemTotalWeightKey: 0,
      itemStockQuantityKey: 0,
      itemTotalProfitKey: 0,
      itemSalesmanTotalCommissionKey: 0,
    });
    if (transaction != null) return; // if we are in edit, we don't need further initialization
    String paymentType = settingsDataNotifier.getProperty(settingsPaymentTypeKey) ??
        S.of(context).transaction_payment_credit;
    String currenctyType = settingsDataNotifier.getProperty(settingsCurrencyKey) ??
        S.of(context).transaction_payment_Dinar;
    final transactionsData = transactionDbCache?.data;
    int? transactionNumber =
        getHighestTransactionNumber(context, transactionsData!, transactionType);
    formDataNotifier.updateProperties({
      currencyKey: translateDbTextToScreenText(context, currenctyType),
      paymentTypeKey: translateDbTextToScreenText(context, paymentType),
      discountKey: 0.0,
      transTypeKey: transactionType,
      dateKey: DateTime.now(),
      totalAmountKey: 0,
      totalWeightKey: 0,
      subTotalAmountKey: 0,
      transactionTotalProfitKey: 0,
      itemSalesmanTotalCommissionKey: 0,
      // if transaction is damaged item, then we set name here, because we can't easily do that
      // inside the form
      nameKey:
          transactionType == TransactionType.damagedItems.name ? S.of(context).damagedItems : '',
      salesmanKey: '',
      numberKey: transactionNumber,
      totalAsTextKey: '',
      notesKey: "",
      isPrintedKey: false,
    });
  }

  // for below text field we need to add  controllers because the are updated by other fields
  // for example total price it updated by the item prices
  static void initializeTextFieldControllers(
      TextControllerNotifier textEditingNotifier, ItemFormData formDataNotifier) {
    // before creating new controllers, I dispose previous ones,
    // I previously disposed them on form close, but I did cause error say there are
    // controllers called after being disposed, so I moved the dispose here
    textEditingNotifier.disposeControllers();
    List items = formDataNotifier.getProperty(itemsKey);
    for (var i = 0; i < items.length; i++) {
      final code = formDataNotifier.getSubProperty(itemsKey, i, itemCodeKey);
      final price = formDataNotifier.getSubProperty(itemsKey, i, itemSellingPriceKey);
      final weight = formDataNotifier.getSubProperty(itemsKey, i, itemWeightKey);
      final soldQuantity = formDataNotifier.getSubProperty(itemsKey, i, itemSoldQuantityKey);
      final giftQuantity = formDataNotifier.getSubProperty(itemsKey, i, itemGiftQuantityKey);
      textEditingNotifier.updateSubControllers(itemsKey, {
        itemCodeKey: code,
        itemSellingPriceKey: price,
        itemSoldQuantityKey: soldQuantity,
        itemGiftQuantityKey: giftQuantity,
        itemTotalAmountKey: soldQuantity == null || price == null ? 0 : soldQuantity * price,
        itemTotalWeightKey: soldQuantity == null || weight == null ? 0 : soldQuantity * weight,
      });
      // I create textEditingControllers for fields that:
      // (1) changed by other fields (2) displayed in UI
      // formData like itemWeight & totalItemAmounts doesn't comply to these two condistions
      final totalAmount = formDataNotifier.getProperty(totalAmountKey);
      final totalWeight = formDataNotifier.getProperty(totalWeightKey);
      textEditingNotifier
          .updateControllers({totalAmountKey: totalAmount, totalWeightKey: totalWeight});
    }
  }

  // for every different transaction, we calculate the next number which is the last reached +1
  static int? getHighestTransactionNumber(
      BuildContext context, List<Map<String, dynamic>> transactions, String type) {
    // Step 1: Filter the list for the given transaction type
    final filteredTransactions =
        transactions.where((transaction) => transaction[transactionTypeKey] == type);
    if (filteredTransactions.isEmpty) return 1;
    // Step 2: Extract the transaction numbers and convert them to integers
    final transactionNumbers =
        filteredTransactions.map((transaction) => transaction[numberKey] as int?);
    // Step 3: Find the maximum transaction number
    int maxNumber = transactionNumbers
            .reduce((a, b) => (a != null && b != null) ? (a > b ? a : b) : (a ?? b)) ??
        0;
    return maxNumber + 1;
  }
}
