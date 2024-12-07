import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/widgets/form_fields/edit_box.dart';
import 'package:tablets/src/features/regions/controllers/region_form_controller.dart';

class RegionFormFields extends ConsumerWidget {
  const RegionFormFields({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.watch(regionFormDataProvider.notifier);
    return FormInputField(
      onChangedFn: (value) {
        formDataNotifier.updateProperties({'name': value});
      },
      dataType: FieldDataType.text,
      name: 'name',
      label: S.of(context).region_name,
      initialValue: formDataNotifier.getProperty('name'),
    );
  }
}
