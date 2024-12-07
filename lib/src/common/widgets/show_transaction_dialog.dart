import 'package:flutter/material.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/widgets/form_title.dart';
import 'package:tablets/src/common/widgets/read_only_transaction_forms/read_only_expenditure_form.dart';
import 'package:tablets/src/common/widgets/read_only_transaction_forms/read_only_form_field.dart';
import 'package:tablets/src/common/widgets/read_only_transaction_forms/read_only_invoice_form.dart';
import 'package:tablets/src/common/widgets/read_only_transaction_forms/read_only_receipt_form.dart';
import 'package:tablets/src/common/widgets/read_only_transaction_forms/read_only_statement_form.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';

void showReadOnlyTransaction(BuildContext context, Transaction transaction) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
          title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: buildFormTitle(
                  translateDbTextToScreenText(context, transaction.transactionType))),
          content: _selectTransactionForm(transaction));
    },
  );
}

Widget _selectTransactionForm(Transaction transaction) {
  // return TransactionReadOnlyInvoice(transaction);
  if (transaction.transactionType == TransactionType.customerInvoice.name) {
    return ReadOnlyTransactionInvoice(transaction, hideGifts: false);
  }
  if (transaction.transactionType == TransactionType.vendorInvoice.name) {
    return ReadOnlyTransactionInvoice(transaction, isVendor: true);
  }
  if (transaction.transactionType == TransactionType.customerReturn.name) {
    return ReadOnlyTransactionInvoice(transaction);
  }
  if (transaction.transactionType == TransactionType.vendorReturn.name) {
    return ReadOnlyTransactionInvoice(transaction, isVendor: true);
  }
  if (transaction.transactionType == TransactionType.customerReceipt.name) {
    return ReadOnlyTransactionReceipt(transaction);
  }
  if (transaction.transactionType == TransactionType.vendorReceipt.name) {
    return ReadOnlyTransactionReceipt(transaction, isVendor: true);
  }
  if (transaction.transactionType == TransactionType.gifts.name) {
    return ReadOnlyStatementTransaction(transaction, isGift: true);
  }
  if (transaction.transactionType == TransactionType.damagedItems.name) {
    return ReadOnlyStatementTransaction(transaction);
  }
  if (transaction.transactionType == TransactionType.expenditures.name) {
    return ReadOnlyExpenditureTransaction(transaction);
  }
  if (transaction.transactionType == TransactionType.initialCredit.name) {
    return _buildInitialCredit(transaction);
  }
  return const Text('transaction type is not know');
}

Widget _buildInitialCredit(Transaction transaction) {
  return Row(
    children: [
      readOnlyTextFormField(transaction.totalAmount),
    ],
  );
}
