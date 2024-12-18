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
    title: Text(
      message,
      style: const TextStyle(fontSize: 17),
      textAlign: TextAlign.center,
    ),
    autoCloseDuration: const Duration(seconds: 10),
    type: type,
    style: ToastificationStyle.flatColored,
    alignment: Alignment.center,
    showProgressBar: false,
    showIcon: false,
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
  );
}
