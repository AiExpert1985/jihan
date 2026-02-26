import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/providers/text_editing_controllers_provider.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/features/customers/repository/customer_db_cache_provider.dart';
import 'package:tablets/src/features/deleted_transactions/repository/deleted_transaction_db_cache_provider.dart';
import 'package:tablets/src/features/settings/view/settings_keys.dart';
import 'package:tablets/src/features/transactions/controllers/customer_debt_info_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_controller.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/features/transactions/view/transaction_form.dart';
import 'package:tablets/src/features/counters/repository/counter_repository_provider.dart';

class TransactionShowForm {
  static Future<void> showForm(
      BuildContext context,
      WidgetRef ref,
      ImageSliderNotifier imagePickerNotifier,
      ItemFormData formDataNotifier,
      ItemFormData settingsDataNotifier,
      TextControllerNotifier textEditingNotifier,
      {String? formType,
      Transaction? transaction,
      DbCache? transactionDbCache,
      bool useReplacement = false}) async {
    if (formType == null && transaction?.transactionType == null) {
      errorPrint(
          'both formType and transaction can not be null, one of them is needed for transactionType');
      return;
    }
    String transactionType = formType ?? transaction?.transactionType as String;
    imagePickerNotifier.initialize();
    try {
      await initializeFormData(
        context,
        formDataNotifier,
        settingsDataNotifier,
        transactionType,
        ref,
        transaction: transaction,
        transactionDbCache: transactionDbCache,
      );
    } catch (e) {
      if (context.mounted) {
        failureUserMessage(context, "تحقق من الاتصال بالانترنت");
      }
      return;
    }

    // Note: Don't check context.mounted here as context may be from a popped widget
    // when navigating from "new" button. Navigator.push will handle invalid context gracefully.

    initializeTextFieldControllers(textEditingNotifier, formDataNotifier);
    bool isEditMode = transaction != null;

    if (!isEditMode) {
      // if the transaction is new, we save it directly with empty data
      if (context.mounted) {
        TransactionForm.saveTransaction(
            context, ref, formDataNotifier.data, false);
      }
    }

    // if we are loading a transaction (not new) for (customer invoices only) we update the debt info
    final customerName = formDataNotifier.data[nameKey];
    if ((transactionType == TransactionType.customerInvoice.name ||
            transactionType == TransactionType.customerReceipt.name) &&
        customerName is String &&
        customerName.isNotEmpty &&
        context.mounted) {
      try {
        final customerDbCache = ref.read(customerDbCacheProvider.notifier);
        final customerData =
            customerDbCache.getItemByProperty('name', customerName);
        final customerDebtInfo =
            ref.read(customerDebtNotifierProvider.notifier);
        customerDebtInfo.update(context, customerData);
      } catch (e) {
        errorPrint('unable to load debt info for $customerName - $e');
      }
    }

    // Use pushReplacement when navigating from within form (e.g., "new" button)
    // Use push when opening form from outside (e.g., from home screen)
    if (!context.mounted) return;

    try {
      if (useReplacement) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (BuildContext ctx) =>
                  TransactionForm(isEditMode, transactionType)),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext ctx) =>
                  TransactionForm(isEditMode, transactionType)),
        );
      }
    } catch (e) {
      errorPrint('Error pushing transaction form: $e');
    }
  }

  static Future<void> initializeFormData(
      BuildContext context,
      ItemFormData formDataNotifier,
      ItemFormData settingsDataNotifier,
      String transactionType,
      WidgetRef ref,
      {Transaction? transaction,
      DbCache? transactionDbCache}) async {
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
      itemBuyingPriceKey: 0,
    });
    if (transaction != null)
      return; // if we are in edit, we don't need further initialization

    // Get context-dependent values BEFORE async call
    String paymentType =
        settingsDataNotifier.getProperty(settingsPaymentTypeKey) ??
            S.of(context).transaction_payment_credit;
    String currenctyType =
        settingsDataNotifier.getProperty(settingsCurrencyKey) ??
            S.of(context).transaction_payment_Dinar;
    String translatedCurrency =
        translateDbTextToScreenText(context, currenctyType);
    String translatedPaymentType =
        translateDbTextToScreenText(context, paymentType);
    String damagedItemsName =
        transactionType == TransactionType.damagedItems.name
            ? S.of(context).damagedItems
            : '';

    // Get next transaction number from Firestore counter (multi-user safe)
    int transactionNumber =
        await getNextTransactionNumber(transactionType, ref);

    // No context.mounted check needed - context not used after async
    formDataNotifier.updateProperties({
      currencyKey: translatedCurrency,
      paymentTypeKey: translatedPaymentType,
      discountKey: 0.0,
      transTypeKey: transactionType,
      dateKey: DateTime.now(),
      totalAmountKey: 0,
      totalWeightKey: 0,
      subTotalAmountKey: 0,
      transactionTotalProfitKey: 0,
      itemSalesmanTotalCommissionKey: 0,
      nameKey: damagedItemsName,
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
      TextControllerNotifier textEditingNotifier,
      ItemFormData formDataNotifier) {
    // before creating new controllers, I dispose previous ones,
    // I previously disposed them on form close, but I did cause error say there are
    // controllers called after being disposed, so I moved the dispose here
    textEditingNotifier.disposeControllers();
    List items = formDataNotifier.getProperty(itemsKey);
    for (var i = 0; i < items.length; i++) {
      final code = formDataNotifier.getSubProperty(itemsKey, i, itemCodeKey);
      final sellingPrice =
          formDataNotifier.getSubProperty(itemsKey, i, itemSellingPriceKey);
      final weight =
          formDataNotifier.getSubProperty(itemsKey, i, itemWeightKey);
      final soldQuantity =
          formDataNotifier.getSubProperty(itemsKey, i, itemSoldQuantityKey);
      final giftQuantity =
          formDataNotifier.getSubProperty(itemsKey, i, itemGiftQuantityKey);
      final buyingPrice =
          formDataNotifier.getSubProperty(itemsKey, i, itemBuyingPriceKey);
      textEditingNotifier.updateSubControllers(itemsKey, {
        itemCodeKey: code,
        itemSellingPriceKey: sellingPrice,
        itemBuyingPriceKey: buyingPrice,
        itemSoldQuantityKey: soldQuantity,
        itemGiftQuantityKey: giftQuantity,
        itemTotalAmountKey: soldQuantity == null || sellingPrice == null
            ? 0
            : soldQuantity * sellingPrice,
        itemTotalWeightKey:
            soldQuantity == null || weight == null ? 0 : soldQuantity * weight,
      });
      // I create textEditingControllers for fields that:
      // (1) changed by other fields (2) displayed in UI
      // formData like itemWeight & totalItemAmounts doesn't comply to these two condistions
      final totalAmount = formDataNotifier.getProperty(totalAmountKey);
      final totalWeight = formDataNotifier.getProperty(totalWeightKey);
      final totalProfit =
          formDataNotifier.getProperty(transactionTotalProfitKey);
      // below 4 (number, discount, notes,) are need for form navigation, when loadng new data inside form, this is the way to update
      // data seen by user
      final number = formDataNotifier.getProperty(transactionNumberKey);
      final discount = formDataNotifier.getProperty(discountKey);
      final notes = formDataNotifier.getProperty(notesKey);
      textEditingNotifier.updateControllers({
        totalAmountKey: totalAmount,
        totalWeightKey: totalWeight,
        transactionTotalProfitKey: totalProfit,
        transactionNumberKey: number,
        discountKey: discount,
        notesKey: notes,
      });
    }
  }

  // Get next transaction number from Firestore counter
  // Uses atomic increment to prevent duplicate numbers in multi-user environment
  static Future<int> getNextTransactionNumber(
      String transactionType, WidgetRef ref) async {
    final counterRepository = ref.read(counterRepositoryProvider);
    return await counterRepository.getNextNumber(transactionType);
  }

// here I am giving the next number after the maximumn number previously given in both transactions & deleted
// transactions
  static int getNextTransactionNumberFromLocalData(BuildContext context,
      List<Map<String, dynamic>> transactions, String type, WidgetRef ref) {
    int maxDeletedNumber = getHighestDeletedTransactionNumber(ref, type) ?? 0;
    int maxTransactionNumber =
        getHighestTransactionNumber(context, transactions, type) ?? 0;
    return max(maxDeletedNumber, maxTransactionNumber) + 1;
  }

  // for every different transaction, we calculate the next number which is the last reached +1
  static int? getHighestTransactionNumber(BuildContext context,
      List<Map<String, dynamic>> transactions, String type) {
    // Step 1: Filter the list for the given transaction type
    final filteredTransactions = transactions
        .where((transaction) => transaction[transactionTypeKey] == type);
    if (filteredTransactions.isEmpty) return 0;
    // Step 2: Extract the transaction numbers and convert them to integers
    final transactionNumbers = filteredTransactions.map((transaction) =>
        transaction[numberKey] is int
            ? transaction[numberKey]
            : transaction[numberKey].toInt());
    // Step 3: Find the maximum transaction number
    int maxNumber = transactionNumbers.reduce(
            (a, b) => (a != null && b != null) ? (a > b ? a : b) : (a ?? b)) ??
        0;
    return maxNumber;
  }

  static int? getHighestDeletedTransactionNumber(WidgetRef ref, String type) {
    final dbCache = ref.read(deletedTransactionDbCacheProvider.notifier);
    final dbCacheData = dbCache.data;
    // Step 1: Filter the list for the given transaction type
    final filteredTransactions = dbCacheData
        .where((transaction) => transaction[transactionTypeKey] == type);
    if (filteredTransactions.isEmpty) return 0;
    // Step 2: Extract the transaction numbers and convert them to integers
    final transactionNumbers = filteredTransactions.map((transaction) =>
        transaction[numberKey] is int
            ? transaction[numberKey]
            : transaction[numberKey].toInt());
    // Step 3: Find the maximum transaction number
    int maxNumber = transactionNumbers.reduce(
            (a, b) => (a != null && b != null) ? (a > b ? a : b) : (a ?? b)) ??
        0;
    return maxNumber;
  }
}
