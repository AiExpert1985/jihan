import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/values/form_dimenssions.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/read_only_transaction_forms/read_only_form_field.dart';
import 'package:tablets/src/common/widgets/read_only_transaction_forms/read_only_item_list.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/settings/view/settings_keys.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';

class ReadOnlyTransactionInvoice extends ConsumerWidget {
  const ReadOnlyTransactionInvoice(this.transaction,
      {this.isVendor = false, this.hideGifts = true, super.key});
  final Transaction transaction;
  final bool hideGifts;
  final bool isVendor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsController = ref.read(settingsFormDataProvider.notifier);
    final hideTransactionAmountAsText =
        settingsController.getProperty(hideTransactionAmountAsTextKey);
    return SingleChildScrollView(
      child: Container(
        // color: backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VerticalGap.xl,
            _buildFirstRow(context, transaction, isVendor),
            VerticalGap.m,
            _buildSecondRow(context, transaction),
            VerticalGap.m,
            _buildThirdRow(context, transaction),
            VerticalGap.m,
            _buildForthRow(context, transaction),
            VerticalGap.m,
            _buildFifthRow(context, transaction, hideTransactionAmountAsText),
            VerticalGap.m,
            buildReadOnlyItemList(context, transaction, hideGifts, false),
            VerticalGap.xxl,
            _buildTotalsRow(context, transaction),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstRow(BuildContext context, Transaction transaction, bool isVendor) {
    final nameLabel = isVendor ? S.of(context).vendor : S.of(context).customer;
    final salesmanLabel = S.of(context).transaction_salesman;
    return Row(
      children: [
        readOnlyTextFormField(transaction.name, label: nameLabel),
        if (!isVendor) HorizontalGap.l,
        if (!isVendor) readOnlyTextFormField(transaction.salesman, label: salesmanLabel),
      ],
    );
  }

  Widget _buildSecondRow(BuildContext context, Transaction transaction) {
    final currencyLabel = S.of(context).transaction_currency;
    final discountLabel = S.of(context).transaction_discount;
    return Row(
      children: [
        readOnlyTextFormField(transaction.currency, label: currencyLabel),
        HorizontalGap.l,
        readOnlyTextFormField(transaction.discount, label: discountLabel),
      ],
    );
  }

  Widget _buildThirdRow(BuildContext context, Transaction transaction) {
    final numberLabel = S.of(context).transaction_number;
    final paymentTypeLabel = S.of(context).transaction_payment_type;
    final dateLabel = S.of(context).transaction_date;
    return Row(
      children: [
        readOnlyTextFormField(transaction.number, label: numberLabel),
        HorizontalGap.l,
        readOnlyTextFormField(transaction.currency, label: paymentTypeLabel),
        HorizontalGap.l,
        readOnlyTextFormField(transaction.date, label: dateLabel),
      ],
    );
  }

  Widget _buildForthRow(BuildContext context, Transaction transaction) {
    final notesLabel = S.of(context).transaction_notes;
    return Row(
      children: [
        readOnlyTextFormField(transaction.notes, label: notesLabel),
      ],
    );
  }

  Widget _buildFifthRow(
      BuildContext context, Transaction transaction, bool hideTransactionAmountAsText) {
    final totalAsTextlLabel = S.of(context).transaction_total_amount_as_text;
    return Visibility(
      visible: !hideTransactionAmountAsText,
      child: Row(
        children: [
          readOnlyTextFormField(transaction.totalAsText, label: totalAsTextlLabel),
        ],
      ),
    );
  }

  Widget _buildTotalsRow(BuildContext context, Transaction transaction) {
    final totalSumLabel = S.of(context).invoice_total_price;
    final totalWeightLabel = S.of(context).invoice_total_weight;
    return SizedBox(
        width: customerInvoiceFormWidth * 0.6,
        child: Row(
          children: [
            readOnlyTextFormField(transaction.totalAmount, label: totalSumLabel),
            HorizontalGap.xxl,
            readOnlyTextFormField(transaction.totalWeight, label: totalWeightLabel),
          ],
        ));
  }
}
