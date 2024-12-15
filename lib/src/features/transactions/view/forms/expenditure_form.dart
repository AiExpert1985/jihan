import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';
import 'package:tablets/src/common/providers/text_editing_controllers_provider.dart';
import 'package:tablets/src/common/widgets/form_fields/date_picker.dart';
import 'package:tablets/src/common/values/constants.dart' as constants;
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/form_fields/drop_down.dart';
import 'package:tablets/src/common/widgets/form_fields/edit_box.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/settings/view/settings_keys.dart';
import 'package:tablets/src/features/transactions/controllers/form_navigator_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_data_notifier.dart';

class ExpenditureForm extends ConsumerWidget {
  const ExpenditureForm(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final textEditingNotifier = ref.read(textFieldsControllerProvider.notifier);
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
            _buildFirstRow(context, formDataNotifier, formNavigator),
            VerticalGap.l,
            _buildSecondRow(context, formDataNotifier, textEditingNotifier, formNavigator),
            VerticalGap.l,
            _buildThirdRow(context, formDataNotifier, formNavigator),
            VerticalGap.l,
            _buildForthRow(context, formDataNotifier, formNavigator),
            VerticalGap.l,
            _buildFifthRow(context, formDataNotifier, hideTransactionAmountAsText, formNavigator),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstRow(
      BuildContext context, ItemFormData formDataNotifier, FromNavigator formNavigator) {
    return Row(
      children: [
        DropDownListFormField(
          isReadOnly: formNavigator.isReadOnly,
          initialValue: formDataNotifier.getProperty(nameKey),
          itemList: [
            S.of(context).transaction_expenditure_salary,
            S.of(context).transaction_expenditure_rent,
            S.of(context).transaction_expenditure_bills,
            S.of(context).transaction_expenditure_money_transer,
            S.of(context).transaction_expenditure_others,
          ],
          label: S.of(context).transaction_expenditure_type,
          name: nameKey,
          onChangedFn: (value) {
            formDataNotifier.updateProperties({nameKey: value});
          },
        ),
      ],
    );
  }

  Widget _buildSecondRow(BuildContext context, ItemFormData formDataNotifier,
      TextControllerNotifier textEditingNotifier, FromNavigator formNavigator) {
    return Row(
      children: [
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
        FormInputField(
          initialValue: formDataNotifier.getProperty(subTotalAmountKey),
          name: subTotalAmountKey,
          isReadOnly: formNavigator.isReadOnly,
          isDisabled: formNavigator.isReadOnly,
          dataType: constants.FieldDataType.num,
          label: S.of(context).transaction_subTotal_amount,
          onChangedFn: (value) {
            formDataNotifier.updateProperties({subTotalAmountKey: value});
            final discount = formDataNotifier.getProperty(discountKey);
            final totalAmount = value - discount;
            final updatedProperties = {
              totalAmountKey: totalAmount,
              transactionTotalProfitKey: totalAmount
            };
            formDataNotifier.updateProperties(updatedProperties);
            textEditingNotifier.updateControllers(updatedProperties);
          },
        ),
      ],
    );
  }

  Widget _buildThirdRow(
      BuildContext context, ItemFormData formDataNotifier, FromNavigator formNavigator) {
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
      bool hideTransactionAmountAsTextKey, FromNavigator formNavigator) {
    return Visibility(
      visible: !hideTransactionAmountAsTextKey,
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
}
