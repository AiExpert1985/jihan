import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';
import 'package:tablets/src/common/widgets/form_fields/date_picker.dart';
import 'package:tablets/src/common/values/constants.dart' as constants;
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/form_fields/drop_down_with_search.dart';
import 'package:tablets/src/common/widgets/form_fields/edit_box.dart';
import 'package:tablets/src/features/customers/repository/customer_db_cache_provider.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_db_cache_provider.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/settings/view/settings_keys.dart';
import 'package:tablets/src/features/transactions/controllers/form_navigator_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/view/forms/item_list.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/features/vendors/repository/vendor_db_cache_provider.dart';

// used for gifts and damages items
class StatementForm extends ConsumerWidget {
  const StatementForm(this.title, this.transactionType, {this.isGift = false, super.key});

  final String title;
  final bool isGift;
  final String transactionType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final salesmanDbCache = ref.read(salesmanDbCacheProvider.notifier);
    final customerCache = ref.read(customerDbCacheProvider.notifier);
    final vendorDbCache = ref.read(vendorDbCacheProvider.notifier);
    final counterPartyDbCache = isGift ? customerCache : vendorDbCache;
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
            if (isGift)
              _buildFirstRow(
                  context, formDataNotifier, counterPartyDbCache, salesmanDbCache, formNavigator),
            VerticalGap.m,
            _buildSecondRow(context, formDataNotifier, formNavigator),
            VerticalGap.m,
            _buildThirdRow(context, formDataNotifier, formNavigator),
            VerticalGap.m,
            _buildFourthRow(context, formDataNotifier, hideTransactionAmountAsText, formNavigator),
            VerticalGap.m,
            ItemsList(true, true, transactionType),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstRow(BuildContext context, ItemFormData formDataNotifier,
      DbCache counterPartyDbCache, DbCache salesmanDbCache, FromNavigator formNavigator) {
    return Row(
      children: [
        DropDownWithSearchFormField(
          isReadOnly: formNavigator.isReadOnly,
          label: S.of(context).customer,
          initialValue: formDataNotifier.getProperty(nameKey),
          itemsList: counterPartyDbCache.data,
          onChangedFn: (item) {
            formDataNotifier.updateProperties({
              if (isGift) nameDbRefKey: item['dbRef'],
              nameKey: item['name'],
              if (isGift) salesmanKey: item['salesman'],
              if (isGift) salesmanDbRefKey: item['salesmanDbRef'],
            });
          },
        ),
        HorizontalGap.l,
        DropDownWithSearchFormField(
          isReadOnly: formNavigator.isReadOnly,
          label: S.of(context).transaction_salesman,
          initialValue: formDataNotifier.getProperty(salesmanKey),
          itemsList: salesmanDbCache.data,
          onChangedFn: (item) {
            formDataNotifier.updateProperties({
              salesmanKey: item[nameKey],
            });
          },
        ),
      ],
    );
  }

  Widget _buildSecondRow(
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
            // we need to add damaged item name here because there is no selection as in other forms
            // so, when user enter transaction number, if the type is damaged items, then the name
            // we be inserted automatically
            formDataNotifier.updateProperties({
              numberKey: value,
            });
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

  Widget _buildThirdRow(
      BuildContext context, ItemFormData formDataNotifier, FromNavigator formNavigator) {
    return Row(
      children: [
        FormInputField(
          isReadOnly: formNavigator.isReadOnly,
          isDisabled: formNavigator.isReadOnly,
          isRequired: false,
          dataType: constants.FieldDataType.text,
          name: notesKey,
          allowEmptyString: true,
          label: S.of(context).transaction_notes,
          initialValue: formDataNotifier.getProperty(notesKey),
          onChangedFn: (value) {
            formDataNotifier.updateProperties({notesKey: value});
          },
        ),
      ],
    );
  }

  Widget _buildFourthRow(BuildContext context, ItemFormData formDataNotifier,
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
}
