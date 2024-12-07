import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/functions/utils.dart' as utils;
import 'package:tablets/src/common/functions/form_validation.dart' as validation;

class FormInputField extends ConsumerWidget {
  const FormInputField({
    required this.onChangedFn,
    this.initialValue,
    this.label,
    this.isRequired = true,
    this.hideBorders = false,
    this.isReadOnly = false,
    required this.dataType,
    this.controller,
    required this.name,
    super.key,
    this.textColor = Colors.black,
    this.fontSize = 14,
  });

  final double fontSize;
  final Color textColor;
  final dynamic initialValue;
  final String? label; // label displayed in the fiedl
  final FieldDataType dataType; // used mainly for validation (based on datatype) purpose
  final void Function(dynamic) onChangedFn;
  // isReadOnly used for fields that I don't want to be edited by user, for example
  // totalprice of an invoice which is the sum of item prices in the invoice
  final bool isReadOnly; // can't be edited by user
  final bool isRequired; // if !isRequired, it will not be validated (optional field)
  final bool hideBorders; // usually used for fields inside the item list
  // I mainly use controller to reflect changes caused by other fields
  // for example when an adjacent dropdown is select, this field is changed
  final TextEditingController? controller;
  final String name; // used by the widget, not used by me

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: FormBuilderTextField(
        // if controller is used, initialValue should be neglected
        initialValue: _getInitialValue(),
        readOnly: isReadOnly,
        controller: controller,
        // enabled: !isReadOnly,
        textAlign: TextAlign.center,
        style: TextStyle(color: textColor, fontSize: fontSize),
        name: name,
        decoration: utils.formFieldDecoration(label: label, hideBorders: hideBorders),
        onChanged: _onChanged,
        validator: isRequired ? _validator(context) : null,
      ),
    );
  }

  dynamic _getInitialValue() {
    if (controller != null) return null;
    return initialValue is! String ? doubleToIntString(initialValue) : initialValue;
  }

  void _onChanged(String? value) {
    // use try catch for cases where wrong type is entered by user
    // ex, insert text instead of number
    try {
      if (value == null) return;
      if (dataType == FieldDataType.num) {
        if (value.toString().trim().isEmpty) return;
        final parsedValue = double.parse(value);
        onChangedFn(parsedValue);
        return;
      }
      if (value.toString().isEmpty) return;
      onChangedFn(value);
    } catch (e) {
      return;
    }
  }

  FormFieldValidator<String>? _validator(BuildContext context) {
    return (value) {
      if (dataType == FieldDataType.text) {
        return validation.validateTextField(
            value, S.of(context).input_validation_error_message_for_text);
      }
      if (dataType == FieldDataType.num) {
        return validation.validateNumberField(
            value, S.of(context).input_validation_error_message_for_numbers);
      }
      return null;
    };
  }
}
