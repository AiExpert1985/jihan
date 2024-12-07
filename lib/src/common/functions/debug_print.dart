import 'package:flutter/material.dart';
import 'package:tablets/src/common/classes/error_logger.dart';

void errorPrint(dynamic message, {stackTrace}) {
  // Sometime the stack trace is shorter than 225, so I need to have protection against that
  String stackText = stackTrace.toString();
  int trimEnd = stackText.length < 225 ? stackText.length : 225;
  String details = stackText.substring(0, trimEnd);
  debugPrint('||===== Catched Error ====> $message =====> $details======||');
}

/// printing for debug puprose, which needs to be later removedd
void tempPrint(dynamic message) {
  debugPrint('||===== Debug Print ====> $message ======||');
}

void errorLog(dynamic message) {
  Logger.logError('$message');
}

void successLog(dynamic message) {
  errorLog(message);
}
