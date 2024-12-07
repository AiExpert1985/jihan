import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';
import 'package:tablets/src/common/providers/text_editing_controllers_provider.dart';
import 'package:tablets/src/common/widgets/form_fields/date_picker.dart';
import 'package:tablets/src/common/values/constants.dart' as constants;
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/form_fields/drop_down.dart';
import 'package:tablets/src/common/widgets/form_fields/drop_down_with_search.dart';
import 'package:tablets/src/common/widgets/form_fields/edit_box.dart';
import 'package:tablets/src/features/customers/repository/customer_db_cache_provider.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_db_cache_provider.dart';
import 'package:tablets/src/common/widgets/form_title.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/settings/view/settings_keys.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_data_notifier.dart';
import 'package:tablets/src/features/vendors/repository/vendor_db_cache_provider.dart';

class ReceiptForm extends ConsumerWidget {
  const ReceiptForm(this.title, {this.isVendor = false, super.key});

  final String title;
  final bool isVendor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final textEditingNotifier = ref.read(textFieldsControllerProvider.notifier);
    final salesmanDbCache = ref.read(salesmanDbCacheProvider.notifier);
    final customerDbCacje = ref.read(customerDbCacheProvider.notifier);
    final vendorDbCache = ref.read(vendorDbCacheProvider.notifier);
    final counterPartyDbCache = isVendor ? vendorDbCache : customerDbCacje;
    final settingsController = ref.read(settingsFormDataProvider.notifier);
    final hideTransactionAmountAsText =
        settingsController.getProperty(hideTransactionAmountAsTextKey);
    ref.watch(transactionFormDataProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildFormTitle(title),
            VerticalGap.xl,
            _buildFirstRow(
                context, formDataNotifier, counterPartyDbCache, salesmanDbCache, isVendor),
            VerticalGap.l,
            _buildSecondRow(context, formDataNotifier, textEditingNotifier, isVendor),
            VerticalGap.l,
            _buildForthRow(context, formDataNotifier),
            VerticalGap.l,
            _buildFifthRow(context, formDataNotifier, hideTransactionAmountAsText),
            VerticalGap.xxl,
            _buildTotalsRow(context, formDataNotifier, textEditingNotifier),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstRow(BuildContext context, ItemFormData formDataNotifier,
      DbCache counterPartyDbCache, DbCache salesmanDbCache, bool isVendor) {
    return Row(
      children: [
        DropDownWithSearchFormField(
          label: isVendor ? S.of(context).vendor : S.of(context).customer,
          initialValue: formDataNotifier.getProperty(nameKey),
          dbCache: counterPartyDbCache,
          onChangedFn: (item) {
            final properties = {
              nameKey: item['name'],
              nameDbRefKey: item['dbRef'],
              salesmanKey: item['salesman'],
              salesmanDbRefKey: item['salesmanDbRef']
            };
            formDataNotifier.updateProperties(properties);
          },
        ),
        if (!isVendor) HorizontalGap.l,
        if (!isVendor)
          DropDownWithSearchFormField(
            label: S.of(context).transaction_salesman,
            initialValue: formDataNotifier.getProperty(salesmanKey),
            dbCache: salesmanDbCache,
            onChangedFn: (item) {
              formDataNotifier.updateProperties({salesmanKey: item[nameKey]});
            },
          ),
        HorizontalGap.l,
        FormDatePickerField(
          initialValue: formDataNotifier.getProperty(dateKey) is Timestamp
              ? formDataNotifier.getProperty(dateKey).toDate()
              : formDataNotifier.getProperty(dateKey),
          name: dateKey,
          label: S.of(context).transaction_date,
          onChangedFn: (date) {
            formDataNotifier.updateProperties({dateKey: Timestamp.fromDate(date!)});
          },
        ),
      ],
    );
  }

  Widget _buildSecondRow(BuildContext context, ItemFormData formDataNotifier,
      TextControllerNotifier textEditingNotifier, bool isVendor) {
    return Row(
      children: [
        FormInputField(
          dataType: constants.FieldDataType.num,
          name: numberKey,
          label: S.of(context).transaction_number,
          initialValue: formDataNotifier.getProperty(numberKey),
          onChangedFn: (value) {
            formDataNotifier.updateProperties({numberKey: value});
          },
        ),
        HorizontalGap.l,
        FormInputField(
          initialValue: formDataNotifier.getProperty(subTotalAmountKey),
          name: subTotalAmountKey,
          dataType: constants.FieldDataType.num,
          label: S.of(context).transaction_subTotal_amount,
          onChangedFn: (value) {
            formDataNotifier.updateProperties({subTotalAmountKey: value});
            final discount = formDataNotifier.getProperty(discountKey);
            final totalAmount = value - discount;
            final updatedProperties = {totalAmountKey: totalAmount, transactionTotalProfitKey: 0};
            formDataNotifier.updateProperties(updatedProperties);
            textEditingNotifier.updateControllers(updatedProperties);
          },
        ),

        // hide for vendors, because there is no discount
        if (!isVendor) HorizontalGap.l,
        // hide for vendors, because there is no discount
        if (!isVendor)
          FormInputField(
            initialValue: formDataNotifier.getProperty(discountKey),
            name: discountKey,
            dataType: constants.FieldDataType.num,
            label: S.of(context).transaction_discount,
            onChangedFn: (value) {
              formDataNotifier.updateProperties({discountKey: value});
              final subTotalAmount = formDataNotifier.getProperty(subTotalAmountKey);
              final totalAmount = subTotalAmount - value;
              final updatedProperties = {totalAmountKey: totalAmount, transactionTotalProfitKey: 0};
              formDataNotifier.updateProperties(updatedProperties);
              textEditingNotifier.updateControllers(updatedProperties);
            },
          ),
        HorizontalGap.l,
        DropDownListFormField(
          initialValue: formDataNotifier.getProperty(currencyKey),
          itemList: [
            S.of(context).transaction_payment_Dinar,
            S.of(context).transaction_payment_Dollar,
          ],
          label: S.of(context).transaction_currency,
          name: currencyKey,
          onChangedFn: (value) {
            formDataNotifier.updateProperties({currencyKey: value});
          },
        ),
      ],
    );
  }

  Widget _buildForthRow(BuildContext context, ItemFormData formDataNotifier) {
    return Row(
      children: [
        FormInputField(
          isRequired: false,
          dataType: constants.FieldDataType.text,
          name: notesKey,
          label: S.of(context).transaction_notes,
          initialValue: formDataNotifier.getProperty(notesKey),
          onChangedFn: (value) {
            formDataNotifier.updateProperties({notesKey: value});
          },
        ),
      ],
    );
  }

  Widget _buildFifthRow(
      BuildContext context, ItemFormData formDataNotifier, bool hideTransactionAmountAsText) {
    return Visibility(
      visible: !hideTransactionAmountAsText,
      child: Row(
        children: [
          FormInputField(
            isRequired: false,
            dataType: constants.FieldDataType.text,
            name: totalAsTextKey,
            label: S.of(context).transaction_total_amount_as_text,
            initialValue: formDataNotifier.getProperty(totalAsTextKey),
            onChangedFn: (value) {
              formDataNotifier.updateProperties({totalAsTextKey: value});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsRow(BuildContext context, ItemFormData formDataNotifier,
      TextControllerNotifier textEditingNotifier) {
    return Container(
        color: const Color.fromARGB(255, 227, 240, 247),
        // width: customerInvoiceFormWidth * 0.6,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const SizedBox(width: 200),
            Text(
              S.of(context).invoice_total_price,
              style: const TextStyle(fontSize: 16),
            ),
            FormInputField(
              hideBorders: true,
              // textColor: Colors.white,
              fontSize: 18,
              controller: textEditingNotifier.getController(totalAmountKey),
              isReadOnly: true,
              dataType: constants.FieldDataType.num,
              // label: S.of(context).invoice_total_price,
              name: totalAmountKey,
              initialValue: formDataNotifier.getProperty(totalAmountKey),
              onChangedFn: (value) {
                formDataNotifier
                    .updateProperties({totalAmountKey: value, transactionTotalProfitKey: 0});
              },
            ),
          ],
        ));
  }
}
