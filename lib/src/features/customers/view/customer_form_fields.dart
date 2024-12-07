import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/form_fields/date_picker.dart';
import 'package:tablets/src/common/widgets/form_fields/drop_down.dart';
import 'package:tablets/src/common/widgets/form_fields/drop_down_with_search.dart';
import 'package:tablets/src/common/widgets/form_fields/edit_box.dart';
import 'package:tablets/src/features/customers/controllers/customer_form_data_notifier.dart';
import 'package:tablets/src/features/regions/repository/region_db_cache_provider.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_db_cache_provider.dart';

class CustomerFormFields extends ConsumerWidget {
  const CustomerFormFields({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.watch(customerFormDataProvider.notifier);
    final salesmanDbCache = ref.watch(salesmanDbCacheProvider.notifier);
    final regionDbCache = ref.watch(regionDbCacheProvider.notifier);
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: Row(children: [
              FormInputField(
                onChangedFn: (value) {
                  formDataNotifier.updateProperties({'name': value});
                },
                initialValue: formDataNotifier.getProperty('name'),
                dataType: FieldDataType.text,
                name: 'name',
                label: S.of(context).salesman_name,
              ),
              HorizontalGap.l,
              DropDownWithSearchFormField(
                label: S.of(context).salesman_selection,
                initialValue: formDataNotifier.getProperty('salesman'),
                dbCache: salesmanDbCache,
                onChangedFn: (item) {
                  formDataNotifier
                      .updateProperties({'salesman': item['name'], 'salesmanDbRef': item['dbRef']});
                },
              ),
            ]),
          ),
          VerticalGap.m,
          Expanded(
            child: Row(
              children: [
                DropDownWithSearchFormField(
                  label: S.of(context).region_name,
                  initialValue: formDataNotifier.getProperty('region'),
                  dbCache: regionDbCache,
                  onChangedFn: (item) {
                    formDataNotifier
                        .updateProperties({'region': item['name'], 'regionDbRef': item['dbRef']});
                  },
                ),
                HorizontalGap.l,
                FormInputField(
                  isRequired: false,
                  onChangedFn: (value) {
                    formDataNotifier.updateProperties({'phone': value});
                  },
                  initialValue: formDataNotifier.getProperty('phone'),
                  dataType: FieldDataType.text,
                  name: 'phone',
                  label: S.of(context).phone,
                ),
              ],
            ),
          ),
          VerticalGap.m,
          Expanded(
            child: Row(
              children: [
                FormInputField(
                  isRequired: false,
                  onChangedFn: (value) {
                    formDataNotifier.updateProperties({'x': value});
                  },
                  initialValue: formDataNotifier.getProperty('x'),
                  dataType: FieldDataType.num,
                  name: 'x',
                  label: S.of(context).gps_x,
                ),
                HorizontalGap.l,
                FormInputField(
                  isRequired: false,
                  onChangedFn: (value) {
                    formDataNotifier.updateProperties({'y': value});
                  },
                  initialValue: formDataNotifier.getProperty('y'),
                  dataType: FieldDataType.num,
                  name: 'y',
                  label: S.of(context).gps_y,
                ),
                HorizontalGap.l,
                FormInputField(
                  isRequired: false,
                  onChangedFn: (value) {
                    formDataNotifier.updateProperties({'address': value});
                  },
                  initialValue: formDataNotifier.getProperty('address'),
                  dataType: FieldDataType.text,
                  name: 'address',
                  label: S.of(context).address,
                ),
              ],
            ),
          ),
          VerticalGap.m,
          Expanded(
            child: Row(
              children: [
                FormInputField(
                  onChangedFn: (value) {
                    formDataNotifier.updateProperties({'initialCredit': value});
                  },
                  initialValue: formDataNotifier.getProperty('initialCredit'),
                  dataType: FieldDataType.num,
                  name: 'initialCredit',
                  label: S.of(context).initialAmount,
                ),
                HorizontalGap.l,
                FormDatePickerField(
                  initialValue: formDataNotifier.getProperty('initialDate') is Timestamp
                      ? formDataNotifier.getProperty('initialDate').toDate()
                      : formDataNotifier.getProperty('initialDate'),
                  name: 'initialDate',
                  label: S.of(context).initialDate,
                  onChangedFn: (date) {
                    formDataNotifier.updateProperties({'initialDate': Timestamp.fromDate(date!)});
                  },
                ),
              ],
            ),
          ),
          VerticalGap.m,
          Expanded(
            child: Row(
              children: [
                DropDownListFormField(
                  initialValue: translateDbTextToScreenText(
                      context, formDataNotifier.getProperty('sellingPriceType')),
                  itemList: [
                    S.of(context).selling_price_type_whole,
                    S.of(context).selling_price_type_retail,
                  ],
                  label: S.of(context).selling_price_type,
                  name: 'sellingPriceType',
                  onChangedFn: (value) {
                    if (value == null) return;
                    final sellingPriceType = translateScreenTextToDbText(context, value);
                    formDataNotifier.updateProperties({'sellingPriceType': sellingPriceType});
                  },
                ),
                HorizontalGap.l,
                FormInputField(
                  onChangedFn: (value) {
                    formDataNotifier.updateProperties({'creditLimit': value});
                  },
                  initialValue: formDataNotifier.getProperty('creditLimit'),
                  dataType: FieldDataType.num,
                  name: 'creditLimit',
                  label: S.of(context).credit_limit,
                ),
                HorizontalGap.l,
                FormInputField(
                  onChangedFn: (value) {
                    formDataNotifier.updateProperties({'paymentDurationLimit': value});
                  },
                  initialValue: formDataNotifier.getProperty('paymentDurationLimit'),
                  dataType: FieldDataType.num,
                  name: 'paymentDurationLimit',
                  label: S.of(context).payment_duration_limit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
