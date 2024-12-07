import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/form_validation.dart';
import 'package:tablets/src/common/functions/utils.dart' as utils;

class DropDownListFormField extends StatelessWidget {
  const DropDownListFormField(
      {this.initialValue,
      required this.onChangedFn,
      this.label,
      required this.name,
      required this.itemList,
      this.isRequired = true,
      this.hideBorders = false,
      super.key});
  final String? label; // label displayed in the field
  final String name; // used by the widget, not used by me
  final List<String> itemList; // list of items to be show
  final bool hideBorders; // hide borders in decoration, used if the field in sub list
  final bool isRequired; // if isRequired = false, then the field will not be validated
  final String? initialValue;
  final void Function(String?) onChangedFn;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FormBuilderDropdown(
          initialValue: initialValue,
          decoration: utils.formFieldDecoration(label: label, hideBorders: hideBorders),
          validator: isRequired
              ? (value) => validateTextField(
                  value.toString(), S.of(context).input_validation_error_message_for_text)
              : null,
          onChanged: onChangedFn,
          name: name,
          items: itemList
              .map((item) => DropdownMenuItem(
                    alignment: AlignmentDirectional.center,
                    value: item,
                    child: Text(item),
                  ))
              .toList()),
    );
  }
}
