import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/form_fields/date_picker.dart';
import 'package:tablets/src/common/widgets/form_fields/drop_down_with_search.dart';
import 'package:tablets/src/common/widgets/form_fields/edit_box.dart';
import 'package:tablets/src/features/products/repository/product_db_cache_provider.dart';
import 'package:tablets/src/features/supplier_discount/controllers/supplier_discount_form_controller.dart';
import 'package:tablets/src/features/vendors/repository/vendor_db_cache_provider.dart';

class SupplierDiscountFormFields extends ConsumerWidget {
  const SupplierDiscountFormFields({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildFirstRow(ref),
        VerticalGap.xl,
        _buildSecondRow(ref),
        VerticalGap.xl,
        _buildThirdRow(ref),
      ],
    );
  }

  Widget _buildFirstRow(WidgetRef ref) {
    return Row(children: [
      _buildSupplierName(ref),
      HorizontalGap.xl,
      _buildProductName(ref),
    ]);
  }

  Widget _buildSecondRow(WidgetRef ref) {
    return Row(children: [
      _buildQuantity(ref),
      HorizontalGap.xl,
      _buildDiscountAmount(ref),
    ]);
  }

  Widget _buildThirdRow(WidgetRef ref) {
    return Row(children: [
      _buildDate(ref),
      HorizontalGap.xl,
      _buildNewPrice(ref),
    ]);
  }

  Widget _buildSupplierName(WidgetRef ref) {
    final formDataNotifier = ref.watch(supplierDiscountFormDataProvider.notifier);
    final dbCache = ref.read(vendorDbCacheProvider.notifier);
    return DropDownWithSearchFormField(
      label: 'اسم المجهز',
      initialValue: formDataNotifier.getProperty('supplierName'),
      itemsList: dbCache.data,
      onChangedFn: (item) {
        formDataNotifier.updateProperties({
          'supplierName': item['name'],
          'supplierDbRef': item['dbRef'],
        });
      },
    );
  }

  Widget _buildProductName(WidgetRef ref) {
    final formDataNotifier = ref.watch(supplierDiscountFormDataProvider.notifier);
    final dbCache = ref.read(productDbCacheProvider.notifier);
    return DropDownWithSearchFormField(
      label: 'اسم المادة',
      initialValue: formDataNotifier.getProperty('productName'),
      itemsList: dbCache.data,
      onChangedFn: (item) {
        formDataNotifier.updateProperties({
          'productName': item['name'],
          'productDbRef': item['dbRef'],
        });
      },
    );
  }

  Widget _buildQuantity(WidgetRef ref) {
    final formDataNotifier = ref.watch(supplierDiscountFormDataProvider.notifier);
    return FormInputField(
      onChangedFn: (value) {
        formDataNotifier.updateProperties({'quantity': value});
      },
      dataType: FieldDataType.num,
      name: 'quantity',
      label: 'العدد',
      initialValue: formDataNotifier.getProperty('quantity'),
    );
  }

  Widget _buildDiscountAmount(WidgetRef ref) {
    final formDataNotifier = ref.watch(supplierDiscountFormDataProvider.notifier);
    return FormInputField(
      onChangedFn: (value) {
        formDataNotifier.updateProperties({'discountAmount': value});
      },
      dataType: FieldDataType.num,
      name: 'discountAmount',
      label: 'مبلغ التخفيض',
      initialValue: formDataNotifier.getProperty('discountAmount'),
    );
  }

  Widget _buildDate(WidgetRef ref) {
    final formDataNotifier = ref.watch(supplierDiscountFormDataProvider.notifier);
    return FormDatePickerField(
      initialValue: formDataNotifier.getProperty('date') is Timestamp
          ? formDataNotifier.getProperty('date').toDate()
          : formDataNotifier.getProperty('date'),
      name: 'date',
      label: 'التاريخ',
      onChangedFn: (date) {
        formDataNotifier.updateProperties({'date': Timestamp.fromDate(date!)});
      },
    );
  }

  Widget _buildNewPrice(WidgetRef ref) {
    final formDataNotifier = ref.watch(supplierDiscountFormDataProvider.notifier);
    return FormInputField(
      onChangedFn: (value) {
        formDataNotifier.updateProperties({'newPrice': value});
      },
      dataType: FieldDataType.num,
      name: 'name',
      label: 'السعر الجديد',
      initialValue: formDataNotifier.getProperty('newPrice'),
    );
  }
}
