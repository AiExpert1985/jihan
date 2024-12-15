import 'package:flutter/material.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/constants.dart';

List<String> getTransactionTypeDropList(BuildContext context) {
  return [
    translateDbTextToScreenText(context, TransactionType.customerInvoice.name),
    translateDbTextToScreenText(context, TransactionType.customerReceipt.name),
    translateDbTextToScreenText(context, TransactionType.customerReturn.name),
    translateDbTextToScreenText(context, TransactionType.gifts.name),
    translateDbTextToScreenText(context, TransactionType.vendorInvoice.name),
    translateDbTextToScreenText(context, TransactionType.vendorReceipt.name),
    translateDbTextToScreenText(context, TransactionType.vendorReturn.name),
    translateDbTextToScreenText(context, TransactionType.expenditures.name),
    translateDbTextToScreenText(context, TransactionType.damagedItems.name),
    translateDbTextToScreenText(context, TransactionType.initialCredit.name),
  ];
}
