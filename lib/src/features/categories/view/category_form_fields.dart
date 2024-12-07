import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/widgets/form_fields/edit_box.dart';
import 'package:tablets/src/features/categories/controllers/category_form_controller.dart';

class CategoryFormFields extends ConsumerWidget {
  const CategoryFormFields({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.watch(categoryFormDataProvider.notifier);
    return FormInputField(
      onChangedFn: (value) {
        formDataNotifier.updateProperties({'name': value});
      },
      dataType: FieldDataType.text,
      name: 'name',
      label: S.of(context).category_name,
      initialValue: formDataNotifier.getProperty('name'),
    );
  }
}
