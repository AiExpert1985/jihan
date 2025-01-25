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
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/settings/view/settings_keys.dart';
import 'package:tablets/src/features/transactions/controllers/customer_debt_info_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_navigator_provider.dart';
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
    final formNavigator = ref.read(formNavigatorProvider);
    ref.watch(transactionFormDataProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFirstRow(context, formDataNotifier, counterPartyDbCache, salesmanDbCache,
                isVendor, formNavigator, ref),
            VerticalGap.l,
            _buildSecondRow(
                context, formDataNotifier, textEditingNotifier, isVendor, formNavigator),
            VerticalGap.l,
            _buildForthRow(context, formDataNotifier, formNavigator),
            VerticalGap.l,
            _buildFifthRow(context, formDataNotifier, hideTransactionAmountAsText, formNavigator),
            VerticalGap.xxl,
            _buildTotalsRow(context, formDataNotifier, textEditingNotifier, formNavigator),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstRow(
      BuildContext context,
      ItemFormData formDataNotifier,
      DbCache counterPartyDbCache,
      DbCache salesmanDbCache,
      bool isVendor,
      FromNavigator formNavigator,
      WidgetRef ref) {
    return Row(
      children: [
        DropDownWithSearchFormField(
          isReadOnly: formNavigator.isReadOnly,
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
            // update customerDebtInfo so that it will be used to show preview of customer debt in form screen
            if (!isVendor) {
              final customerDebtInfo = ref.read(customerDebtNotifierProvider.notifier);
              customerDebtInfo.update(context, item);
            }
          },
        ),
        if (!isVendor) HorizontalGap.l,
        if (!isVendor)
          DropDownWithSearchFormField(
            isReadOnly: formNavigator.isReadOnly,
            label: S.of(context).transaction_salesman,
            initialValue: formDataNotifier.getProperty(salesmanKey),
            dbCache: salesmanDbCache,
            onChangedFn: (item) {
              formDataNotifier.updateProperties({salesmanKey: item[nameKey]});
            },
          ),
        HorizontalGap.l,
        FormDatePickerField(
          isReadOnly: formNavigator.isReadOnly,
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
      TextControllerNotifier textEditingNotifier, bool isVendor, FromNavigator formNavigator) {
    return Row(
      children: [
        FormInputField(
          isReadOnly: formNavigator.isReadOnly,
          isDisabled: formNavigator.isReadOnly,
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
          isReadOnly: formNavigator.isReadOnly,
          isDisabled: formNavigator.isReadOnly,
          initialValue: formDataNotifier.getProperty(subTotalAmountKey),
          name: subTotalAmountKey,
          dataType: constants.FieldDataType.num,
          label: S.of(context).transaction_subTotal_amount,
          onChangedFn: (value) {
            formDataNotifier.updateProperties({subTotalAmountKey: value});
            final discount = formDataNotifier.getProperty(discountKey) ?? 0;
            // note that discount is added (not subtracted) to the subtotal
            final totalAmount = value + discount;
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
            isReadOnly: formNavigator.isReadOnly,
            isDisabled: formNavigator.isReadOnly,
            initialValue: formDataNotifier.getProperty(discountKey),
            name: discountKey,
            dataType: constants.FieldDataType.num,
            label: S.of(context).transaction_discount,
            onChangedFn: (value) {
              formDataNotifier.updateProperties({discountKey: value});
              final subTotalAmount = formDataNotifier.getProperty(subTotalAmountKey);
              // note that discount is added (not subtracted) to the subtotal
              final totalAmount = subTotalAmount + value;
              final updatedProperties = {totalAmountKey: totalAmount, transactionTotalProfitKey: 0};
              formDataNotifier.updateProperties(updatedProperties);
              textEditingNotifier.updateControllers(updatedProperties);
            },
          ),
        HorizontalGap.l,
        DropDownListFormField(
          isReadOnly: formNavigator.isReadOnly,
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

  Widget _buildForthRow(
      BuildContext context, ItemFormData formDataNotifier, FromNavigator formNavigator) {
    return Row(
      children: [
        FormInputField(
          isReadOnly: formNavigator.isReadOnly,
          isDisabled: formNavigator.isReadOnly,
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

  Widget _buildFifthRow(BuildContext context, ItemFormData formDataNotifier,
      bool hideTransactionAmountAsText, FromNavigator formNavigator) {
    return Visibility(
      visible: !hideTransactionAmountAsText,
      child: Row(
        children: [
          FormInputField(
            isReadOnly: formNavigator.isReadOnly,
            isDisabled: formNavigator.isReadOnly,
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
      TextControllerNotifier textEditingNotifier, FromNavigator formNavigator) {
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
              isDisabled: formNavigator.isReadOnly,
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
