import 'package:flutter/material.dart';

class FormFrame extends StatelessWidget {
  const FormFrame(
      {super.key,
      this.backgroundColor,
      required this.formKey,
      required this.fields,
      required this.buttons,
      this.width = 800,
      this.height = 800});
  final Color? backgroundColor;
  final Widget fields;
  final List<Widget> buttons;
  final GlobalKey<FormState> formKey;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: backgroundColor,
      alignment: Alignment.center,
      insetPadding: const EdgeInsets.all(10),
      scrollable: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 30),
      // title: Text(S.of(context).add_new_user),
      content: Container(
        padding: const EdgeInsets.all(10),
        width: width,
        height: height,
        child: Form(
          key: formKey,
          child: fields,
        ),
      ),

      actions: [OverflowBar(alignment: MainAxisAlignment.center, children: buttons)],
    );
  }
}
