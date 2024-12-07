String? validateNumberField(String? fieldValue, String errorMessage) {
  if (fieldValue == null || double.tryParse(fieldValue) == null) {
    return errorMessage;
  }
  return null;
}

/// used in form validation to check if entered name is valid
String? validateTextField(String? fieldValue, String errorMessage) {
  if (fieldValue == null || fieldValue.trim().isEmpty || fieldValue.trim().length < 2) {
    return errorMessage;
  }
  return null;
}

String? validateDropDownField(String? fieldValue, String errorMessage) {
  if (fieldValue == null) {
    return errorMessage;
  }
  return null;
}

String? validateDatePicker(DateTime? fieldValue, String errorMessage) {
  if (fieldValue == null) {
    return errorMessage;
  }
  return null;
}
