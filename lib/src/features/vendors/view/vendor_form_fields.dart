import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/form_fields/date_picker.dart';
import 'package:tablets/src/common/widgets/form_fields/edit_box.dart';
import 'package:tablets/src/features/vendors/controllers/vendor_form_controller.dart';

class VendorFormFields extends ConsumerWidget {
  const VendorFormFields({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.watch(vendorFormDataProvider.notifier);
    return Expanded(
      child: Column(
        children: [
          FormInputField(
            onChangedFn: (value) {
              formDataNotifier.updateProperties({'name': value});
            },
            initialValue: formDataNotifier.getProperty('name'),
            dataType: FieldDataType.text,
            name: 'name',
            label: S.of(context).salesman_name,
          ),
          VerticalGap.l,
          FormInputField(
            onChangedFn: (value) {
              formDataNotifier.updateProperties({'phone': value});
            },
            initialValue: formDataNotifier.getProperty('phone'),
            dataType: FieldDataType.text,
            name: 'phone',
            label: S.of(context).phone,
            isRequired: false,
          ),
          VerticalGap.l,
          Expanded(
            child: Row(children: [
              FormInputField(
                onChangedFn: (value) {
                  formDataNotifier.updateProperties({'initialAmount': value});
                },
                initialValue: formDataNotifier.getProperty('initialAmount'),
                dataType: FieldDataType.num,
                name: 'initialAmount',
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
            ]),
          )
        ],
      ),
    );
  }
}
