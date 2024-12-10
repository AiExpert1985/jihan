import 'package:flutter/material.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/widgets/form_fields/edit_box.dart';

Widget readOnlyTextFormField(dynamic fieldValue, {String? label}) {
  String stringFieldValue;
  if (fieldValue is DateTime) {
    stringFieldValue = formatDate(fieldValue); // Assuming formatDate is defined elsewhere
  } else if (fieldValue is int || fieldValue is double || fieldValue is num) {
    stringFieldValue = doubleToStringWithComma(fieldValue);
  } else if (fieldValue is String) {
    stringFieldValue = fieldValue;
  } else {
    stringFieldValue = ''; // Default value if the type is not recognized
  }
  final name = generateRandomString();
  return FormInputField(
    label: label,
    initialValue: stringFieldValue,
    onChangedFn: (item) {},
    dataType: FieldDataType.text,
    name: name,
    isReadOnly: true,
  );
}
