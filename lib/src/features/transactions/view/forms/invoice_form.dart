import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/features/customers/controllers/customer_screen_controller.dart';
import 'package:tablets/src/common/providers/background_color.dart';
import 'package:tablets/src/common/providers/text_editing_controllers_provider.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/form_dimenssions.dart';
import 'package:tablets/src/common/widgets/form_fields/date_picker.dart';
import 'package:tablets/src/common/values/constants.dart' as constants;
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/form_fields/drop_down.dart';
import 'package:tablets/src/common/widgets/form_fields/drop_down_with_search.dart';
import 'package:tablets/src/common/widgets/form_fields/edit_box.dart';
import 'package:tablets/src/features/customers/model/customer.dart';
import 'package:tablets/src/features/customers/repository/customer_db_cache_provider.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_db_cache_provider.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/settings/view/settings_keys.dart';
import 'package:tablets/src/features/transactions/controllers/customer_debt_info_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_navigator_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_utils_controller.dart';
import 'package:tablets/src/features/transactions/view/forms/item_list.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/features/vendors/repository/vendor_db_cache_provider.dart';

class InvoiceForm extends ConsumerWidget {
  const InvoiceForm(this.title, this.transactionType,
      {this.isVendor = false, this.hideGifts = true, super.key, this.backgroundColor});

  final String title;
  final bool hideGifts;
  final bool isVendor;
  final String transactionType;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(transactionFormDataProvider);

    return SingleChildScrollView(
      child: Container(
        color: backgroundColor,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FirstRow(isVendor, transactionType),
            VerticalGap.m,
            SecondRow(transactionType),
            VerticalGap.m,
            const ForthRow(),
            VerticalGap.m,
            const FifthRow(),
            VerticalGap.m,
            ItemsList(hideGifts, false, transactionType),
            VerticalGap.xxl,
            TotalsRow(transactionType),
          ],
        ),
      ),
    );
  }
}

class FirstRow extends ConsumerWidget {
  const FirstRow(this.isVendor, this.transactionType, {super.key});

  final bool isVendor;
  final String transactionType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final customerDbCache = ref.read(customerDbCacheProvider.notifier);
    final vendorDbCache = ref.read(vendorDbCacheProvider.notifier);
    final dbCache = isVendor ? vendorDbCache : customerDbCache;
    final transactionUtils = ref.read(transactionUtilsControllerProvider);
    final backgroundColorNotifier = ref.read(backgroundColorProvider.notifier);
    final salesmanDbCache = ref.read(salesmanDbCacheProvider.notifier);
    final customerScreenController = ref.read(customerScreenControllerProvider);
    final formNavigator = ref.read(formNavigatorProvider);
    final customerDebtInfo = ref.read(customerDebtNotifierProvider.notifier);
    return Row(
      children: [
        DropDownWithSearchFormField(
          isReadOnly: formNavigator.isReadOnly,
          label: isVendor ? S.of(context).vendor : S.of(context).customer,
          initialValue: formDataNotifier.getProperty(nameKey),
          dbCache: dbCache,
          onChangedFn: (item) {
            // update customer field & related fields
            final properties = {
              nameKey: item['name'],
              nameDbRefKey: item['dbRef'],
              salesmanKey: item['salesman'],
              salesmanDbRefKey: item['salesmanDbRef'],
              sellingPriceTypeKey: item['sellingPriceType']
            };
            formDataNotifier.updateProperties(properties);
            // check wether customer exceeded the debt or time limits
            // below applies only for customer invoices not any other transaction
            if (transactionType != TransactionType.customerInvoice.name) {
              return;
            }
            final customer = Customer.fromMap(item);
            // the value is used by other Widgets so we update it in the provider
            transactionUtils.customer = customer;
            final inValidCustomer = transactionUtils.inValidTransaction(
                context, customer, formDataNotifier, customerScreenController);
            final invoiceColor =
                inValidCustomer ? const Color.fromARGB(255, 245, 187, 184) : Colors.white;
            backgroundColorNotifier.state = invoiceColor;
            // update customerDebtInfo so that it will be used to show preview of customer debt in form screen
            if (!isVendor) {
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
              formDataNotifier
                  .updateProperties({salesmanKey: item['name'], salesmanDbRefKey: item['dbRef']});
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
}

class SecondRow extends ConsumerWidget {
  const SecondRow(this.transactionType, {super.key});
  final String transactionType;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final textEditingNotifier = ref.read(textFieldsControllerProvider.notifier);
    final transactionUtils = ref.read(transactionUtilsControllerProvider);
    final formNavigator = ref.read(formNavigatorProvider);
    return Row(
      children: [
        FormInputField(
          isReadOnly:
              formNavigator.isReadOnly || transactionType == TransactionType.customerInvoice.name,
          isDisabled: formNavigator.isReadOnly,
          dataType: constants.FieldDataType.num,
          name: numberKey,
          controller: textEditingNotifier.getController(numberKey),
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
          initialValue: formDataNotifier.getProperty(discountKey),
          name: discountKey,
          dataType: constants.FieldDataType.num,
          controller: textEditingNotifier.getController(discountKey),
          label: S.of(context).transaction_discount,
          onChangedFn: (value) {
            formDataNotifier.updateProperties({discountKey: value});

            final subTotalAmount = formDataNotifier.getProperty(subTotalAmountKey);
            final totalAmount = subTotalAmount - value;
            final itemsTotalProfit = formDataNotifier.getProperty(itemsTotalProfitKey) ?? 0;
            final salesmanTransactionComssion =
                formDataNotifier.getProperty(salesmanTransactionComssionKey) ?? 0;
            double transactionTotalProfit = transactionUtils.getTransactionProfit(formDataNotifier,
                transactionType, itemsTotalProfit, value, salesmanTransactionComssion);
            final updatedProperties = {
              transactionTotalProfitKey: transactionTotalProfit,
              totalAmountKey: totalAmount,
            };
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
        HorizontalGap.l,
        DropDownListFormField(
          isReadOnly: formNavigator.isReadOnly,
          initialValue: formDataNotifier.getProperty(paymentTypeKey),
          itemList: [
            S.of(context).transaction_payment_cash,
            S.of(context).transaction_payment_credit,
          ],
          label: S.of(context).transaction_payment_type,
          name: paymentTypeKey,
          onChangedFn: (value) {
            formDataNotifier.updateProperties({paymentTypeKey: value});
          },
        ),
      ],
    );
  }
}

class ForthRow extends ConsumerWidget {
  const ForthRow({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final formNavigator = ref.read(formNavigatorProvider);
    // final textEditingNotifier = ref.read(textFieldsControllerProvider.notifier);
    return Row(
      children: [
        FormInputField(
          isReadOnly: formNavigator.isReadOnly,
          isDisabled: formNavigator.isReadOnly,
          isRequired: false,
          dataType: constants.FieldDataType.text,
          name: notesKey,
          // controller: textEditingNotifier.getController(notesKey),
          label: S.of(context).transaction_notes,
          initialValue: formDataNotifier.getProperty(notesKey),
          onChangedFn: (value) {
            formDataNotifier.updateProperties({notesKey: value});
          },
        ),
      ],
    );
  }
}

class FifthRow extends ConsumerWidget {
  const FifthRow({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsController = ref.read(settingsFormDataProvider.notifier);
    final hideTransactionAmountAsText =
        settingsController.getProperty(hideTransactionAmountAsTextKey);
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final formNavigator = ref.read(formNavigatorProvider);
    return Visibility(
      visible: !hideTransactionAmountAsText,
      child: Row(
        children: [
          FormInputField(
            isReadOnly: formNavigator.isReadOnly,
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
}

class TotalsRow extends ConsumerWidget {
  const TotalsRow(this.transactionType, {super.key});
  final String transactionType;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final customerScreenController = ref.read(customerScreenControllerProvider);
    final textEditingNotifier = ref.read(textFieldsControllerProvider.notifier);
    final backgroundColorNotifier = ref.read(backgroundColorProvider.notifier);
    // final customerScreenData = ref.read(customerScreenDataProvider);
    final transactionUtils = ref.read(transactionUtilsControllerProvider);
    final formNavigator = ref.read(formNavigatorProvider);
    return SizedBox(
        width: customerInvoiceFormWidth * 0.6,
        child: Row(
          children: [
            FormInputField(
              controller: textEditingNotifier.getController(totalAmountKey),
              isReadOnly: true,
              isDisabled: formNavigator.isReadOnly,
              dataType: constants.FieldDataType.num,
              label: S.of(context).invoice_total_price,
              name: totalAmountKey,
              initialValue: formDataNotifier.getProperty(totalAmountKey),
              onChangedFn: (value) {
                formDataNotifier.updateProperties({totalAmountKey: value});
                // check wether customer exceeded the debt or time limits
                // below applies only for customer invoices not any other transaction
                if (transactionUtils.customer == null ||
                    transactionType != TransactionType.customerInvoice.name) {
                  return;
                }
                final inValidCustomer = transactionUtils.inValidTransaction(
                  context,
                  transactionUtils.customer!,
                  formDataNotifier,
                  customerScreenController,
                );
                final invoiceColor = inValidCustomer ? warningColor : normalColor;
                backgroundColorNotifier.state = invoiceColor!;
              },
            ),
            HorizontalGap.xxl,
            FormInputField(
              controller: textEditingNotifier.getController(totalWeightKey),
              isReadOnly: true,
              isDisabled: formNavigator.isReadOnly,
              dataType: constants.FieldDataType.num,
              label: S.of(context).invoice_total_weight,
              name: totalWeightKey,
              initialValue: formDataNotifier.getProperty(totalWeightKey),
              onChangedFn: (value) {
                formDataNotifier.updateProperties({totalWeightKey: value});
              },
            ),
          ],
        ));
  }
}
