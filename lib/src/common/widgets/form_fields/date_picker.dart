import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/form_validation.dart';
import 'package:tablets/src/common/functions/utils.dart' as utils;

class FormDatePickerField extends StatelessWidget {
  const FormDatePickerField({
    this.initialValue,
    required this.onChangedFn,
    required this.name,
    this.label,
    this.isRequired = true,
    this.hideBorders = false,
    this.isReadOnly = false,
    super.key,
  });
  final String? label; // label displayed on the field (can be shown in Arabic)
  final DateTime? initialValue;
  final String name; // Widget needs it, not used by me
  final bool hideBorders; // hide borders in decoration, used if the field in sub list
  final bool isRequired; // if isRequired = false, then the field will not be validated
  final bool isReadOnly;
  final void Function(DateTime?) onChangedFn;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FormBuilderDateTimePicker(
        enabled: !isReadOnly,
        decoration: utils.formFieldDecoration(label: label, hideBorders: hideBorders),
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        name: name,
        initialValue: initialValue,
        fieldHintText: S.of(context).date_picker_hint,
        inputType: InputType.date,
        onChanged: onChangedFn,
        validator: (value) => _validateDate(value, context),
        format: DateFormat('dd-MM-yyyy', 'en_US'),
      ),
    );
  }

  String? _validateDate(DateTime? value, BuildContext context) {
    return isRequired
        ? validateDatePicker(value, S.of(context).input_validation_error_message_for_date)
        : null;
  }
}
