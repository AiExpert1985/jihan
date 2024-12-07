import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

void successUserMessage(BuildContext context, String message) =>
    _message(context, message, ToastificationType.success);

void failureUserMessage(BuildContext context, String message) =>
    _message(context, message, ToastificationType.error);

void infoUserMessage(BuildContext context, String message) =>
    _message(context, message, ToastificationType.info);

void _message(BuildContext context, String message, type) {
  toastification.show(
    context: context, // optional if you use ToastificationWrapper
    title: Text(message),
    autoCloseDuration: const Duration(seconds: 5),
    type: type,
    style: ToastificationStyle.flatColored,
    alignment: Alignment.topCenter,
    showProgressBar: false,
    showIcon: false,
  );
}
