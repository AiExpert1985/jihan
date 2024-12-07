import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/features/customers/controllers/customer_screen_controller.dart';
import 'package:tablets/src/features/customers/model/customer.dart';

final transactionUtilsControllerProvider = Provider<TransactionsUtils>((ref) {
  return TransactionsUtils();
});

class TransactionsUtils {
  // customer used for checking whether customer is valid or not (to color form with red if invalid)
  Customer? customer;

  /// only customer invoices are profitable,
  /// customer returns profit is itemsProfit (it is actually a loss but dealts with else where)
  /// damageItems profit is the itemsPrice (it is actually a loss but dealts with else where)
  /// all other forms profit is 0
  double getTransactionProfit(ItemFormData formDataNotifier, String transactionType,
      double itemsTotalProfit, double discount, double salesmanTransactionComssion) {
    if (transactionType == TransactionType.customerInvoice.name) {
      return itemsTotalProfit - discount - salesmanTransactionComssion;
    }
    if (transactionType == TransactionType.customerReturn.name) {
      return itemsTotalProfit;
    }
    if (transactionType == TransactionType.damagedItems.name ||
        transactionType == TransactionType.gifts.name) {
      return formDataNotifier.getProperty(subTotalAmountKey);
    }
    return 0;
  }

  // this method is different from the method that checks validation inside customer screen
  // becasuse here it checks customer validity plus the Invoice amount, so even if his is valid
  // as a customer but with this invoice amount he exceeds the debt limit, then it will return
  // that this transaction is invalid
  bool inValidTransaction(
    BuildContext context,
    Customer selectedCustomer,
    ItemFormData formDataNotifier,
    CustomerScreenController customerScreenController,
  ) {
    final customerScreenData =
        customerScreenController.getItemScreenData(context, selectedCustomer.toMap());
    if (customerScreenData[inValidUserKey]) return true;
    final creditLimit = selectedCustomer.creditLimit;
    final totalDebt = customerScreenData[totalDebtKey];
    final totalAfterCurrentTransaction = totalDebt + formDataNotifier.getProperty(totalAmountKey);
    return totalAfterCurrentTransaction > creditLimit;
  }
}
