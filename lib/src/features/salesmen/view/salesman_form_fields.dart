import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/widgets/form_fields/edit_box.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_form_controller.dart';

class SalesmanFormFields extends ConsumerWidget {
  const SalesmanFormFields({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.watch(salesmanFormDataProvider.notifier);
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FormInputField(
            dataType: FieldDataType.text,
            name: 'name',
            label: S.of(context).salesman_name,
            initialValue: formDataNotifier.getProperty('name'),
            onChangedFn: (value) {
              formDataNotifier.updateProperties({'name': value});
            },
          ),
          FormInputField(
            dataType: FieldDataType.text,
            isRequired: false,
            name: 'phone',
            label: S.of(context).phone,
            initialValue: formDataNotifier.getProperty('phone'),
            onChangedFn: (value) {
              formDataNotifier.updateProperties({'phone': value});
            },
          ),
          FormInputField(
            dataType: FieldDataType.num,
            name: 'salary',
            label: S.of(context).basic_salary,
            initialValue: formDataNotifier.getProperty('salary'),
            onChangedFn: (value) {
              formDataNotifier.updateProperties({'salary': value});
            },
          ),
        ],
      ),
    );
  }
}
