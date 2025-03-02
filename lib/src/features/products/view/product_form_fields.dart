import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';
import 'package:tablets/src/common/widgets/form_fields/date_picker.dart';
import 'package:tablets/src/common/widgets/form_fields/drop_down_with_search.dart';
import 'package:tablets/src/common/widgets/form_fields/edit_box.dart';
import 'package:tablets/src/features/categories/repository/category_db_cache_provider.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/features/products/controllers/product_form_data_notifier.dart';

class ProductFormFields extends ConsumerWidget {
  const ProductFormFields({super.key, this.editMode = false});
  final bool editMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.read(productFormDataProvider.notifier);
    final dbCache = ref.read(categoryDbCacheProvider.notifier);

    return Column(
      children: [
        _buildRow(context, formDataNotifier, [
          _createFormField('code', FieldDataType.num, S.of(context).product_code, formDataNotifier),
          HorizontalGap.m,
          _createFormField(
              'name', FieldDataType.text, S.of(context).product_name, formDataNotifier),
          HorizontalGap.m,
          _createDropdownField(S.of(context).category_selection, formDataNotifier, dbCache),
        ]),
        VerticalGap.m,
        _buildRow(context, formDataNotifier, [
          _createFormField('buyingPrice', FieldDataType.num, S.of(context).product_buying_price,
              formDataNotifier),
          HorizontalGap.m,
          _createFormField('sellWholePrice', FieldDataType.num,
              S.of(context).product_sell_whole_price, formDataNotifier),
          HorizontalGap.m,
          _createFormField('sellRetailPrice', FieldDataType.num,
              S.of(context).product_sell_retail_price, formDataNotifier),
        ]),
        VerticalGap.m,
        _buildRow(context, formDataNotifier, [
          _createFormField('salesmanCommission', FieldDataType.num,
              S.of(context).product_salesman_commission, formDataNotifier),
          HorizontalGap.m,
          _createFormField('altertWhenLessThan', FieldDataType.num,
              S.of(context).product_altert_when_less_than, formDataNotifier),
          HorizontalGap.m,
          _createFormField('alertWhenExceeds', FieldDataType.num,
              S.of(context).product_alert_when_exceeds, formDataNotifier),
        ]),
        VerticalGap.m,
        _buildRow(context, formDataNotifier, [
          _createFormField('packageType', FieldDataType.text, S.of(context).product_package_type,
              formDataNotifier),
          HorizontalGap.m,
          _createFormField('packageWeight', FieldDataType.num, S.of(context).product_package_weight,
              formDataNotifier),
          HorizontalGap.m,
          _createFormField('numItemsInsidePackage', FieldDataType.num,
              S.of(context).product_num_items_inside_package, formDataNotifier),
        ]),
        VerticalGap.m,
        _buildRow(context, formDataNotifier, [
          _createFormField('initialQuantity', FieldDataType.num,
              S.of(context).product_initial_quantitiy, formDataNotifier),
          HorizontalGap.m,
          _createDatePickerField(context, formDataNotifier),
        ]),
        VerticalGap.m,
        _buildRow(context, formDataNotifier, [
          _createFormField('notes', FieldDataType.text, S.of(context).notes, formDataNotifier,
              isRequired: false),
        ]),
        VerticalGap.m,
        const HideProductCheckBox(),
      ],
    );
  }

  Widget _buildRow(BuildContext context, ItemFormData formDataNotifier, List<Widget> fields) {
    return Row(
      children: fields.map((field) => field).toList(),
    );
  }

  Widget _createFormField(
      String name, FieldDataType dataType, String label, ItemFormData formDataNotifier,
      {bool isRequired = true}) {
    return FormInputField(
      dataType: dataType,
      name: name,
      label: label,
      initialValue: formDataNotifier.getProperty(name),
      onChangedFn: (value) {
        formDataNotifier.updateProperties({name: value});
      },
      isRequired: isRequired,
    );
  }

  Widget _createDropdownField(String label, ItemFormData formDataNotifier, DbCache dbCache) {
    return DropDownWithSearchFormField(
      label: label,
      initialValue: formDataNotifier.getProperty('category'),
      itemsList: dbCache.data,
      onChangedFn: (item) {
        formDataNotifier.updateProperties({
          'category': item['name'],
          'categoryDbRef': item['dbRef'],
        });
      },
    );
  }

  Widget _createDatePickerField(BuildContext context, ItemFormData formDataNotifier) {
    return FormDatePickerField(
      initialValue: formDataNotifier.getProperty('initialDate') is Timestamp
          ? formDataNotifier.getProperty('initialDate').toDate()
          : formDataNotifier.getProperty('initialDate'),
      name: 'initialDate',
      label: S.of(context).date_entery_date,
      onChangedFn: (date) {
        formDataNotifier.updateProperties({'initialDate': Timestamp.fromDate(date!)});
      },
    );
  }
}

class HideProductCheckBox extends ConsumerWidget {
  const HideProductCheckBox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.read(productFormDataProvider.notifier);
    ref.watch(productFormDataProvider);
    return Container(
        padding: const EdgeInsets.all(0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(S.of(context).hide_from_special_reports),
            HorizontalGap.l,
            Checkbox(
              value: formDataNotifier.getProperty('isHiddenInSpecialReports') ?? false,
              onChanged: (value) {
                formDataNotifier.updateProperties({'isHiddenInSpecialReports': value});
              },
            ),
          ],
        ));
  }
}
