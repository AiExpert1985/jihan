import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/features/customers/controllers/customer_screen_controller.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_controller.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';

class CustomerDebtState {
  final String totalDebt;

  final String dueDebt;

  final String lastReceiptDate;

  CustomerDebtState({
    required this.totalDebt,
    required this.dueDebt,
    required this.lastReceiptDate,
  });

  CustomerDebtState copyWith({
    String? totalDebt,
    String? dueDebt,
    String? lastReceiptDate,
  }) {
    return CustomerDebtState(
      totalDebt: totalDebt ?? this.totalDebt,
      dueDebt: dueDebt ?? this.dueDebt,
      lastReceiptDate: lastReceiptDate ?? this.lastReceiptDate,
    );
  }
}

class CustomerDebtNotifier extends StateNotifier<CustomerDebtState> {
  CustomerDebtNotifier(this.customerScreenController, this.transactionDbCache)
      : super(CustomerDebtState(totalDebt: '', dueDebt: '', lastReceiptDate: ''));

  final CustomerScreenController customerScreenController;
  final DbCache transactionDbCache;

  void update(BuildContext context, Map<String, dynamic> customerData) {
    Map<String, dynamic> customerScreenData =
        customerScreenController.getItemScreenData(context, customerData);

    String totalDebt = doubleToStringWithComma(customerScreenData[totalDebtKey]);
    String dueDebt = doubleToStringWithComma(customerScreenData[dueDebtKey]);

    final allTransactions = transactionDbCache.data;
    final receiptDates = [];

    for (var transaction in allTransactions) {
      if (transaction[nameDbRefKey] == customerData['dbRef'] &&
          transaction[transactionTypeKey] == TransactionType.customerReceipt.name) {
        final date = transaction[dateKey];

        receiptDates.add(date is DateTime ? date : date.toDate());
      }
    }

    String lastReceiptDate;
    if (receiptDates.isNotEmpty) {
      final newestDate = receiptDates.reduce((a, b) => a.isAfter(b) ? a : b);
      lastReceiptDate = formatDate(newestDate);
    } else {
      lastReceiptDate = S.of(context).there_is_no_customer_receipt;
    }

    // Update the state
    state = state.copyWith(
      totalDebt: totalDebt,
      dueDebt: dueDebt,
      lastReceiptDate: lastReceiptDate,
    );
  }

  CustomerDebtState get data => state;

  void reset() {
    state = state.copyWith(
      totalDebt: '',
      dueDebt: '',
      lastReceiptDate: '',
    );
  }
}

final customerDebtNotifierProvider =
    StateNotifierProvider<CustomerDebtNotifier, CustomerDebtState>((ref) {
  final customerScreenController = ref.read(customerScreenControllerProvider);
  final transactionDbCache = ref.read(transactionDbCacheProvider.notifier);
  return CustomerDebtNotifier(customerScreenController, transactionDbCache);
});
