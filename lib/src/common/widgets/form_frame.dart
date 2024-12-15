import 'package:flutter/material.dart';

class FormFrame extends StatelessWidget {
  const FormFrame(
      {super.key,
      this.title,
      this.backgroundColor,
      // required this.formKey,
      required this.fields,
      required this.buttons,
      this.width = 800,
      this.height = 900});
  final Widget? title;
  final Color? backgroundColor;
  final Widget fields;
  final List<Widget> buttons;
  // final GlobalKey<FormState> formKey;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(0),
        width: 1000,
        // height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            title ?? const SizedBox(height: 100),
            Container(width: width, padding: const EdgeInsets.all(0), child: fields),
            Container(
              padding: const EdgeInsets.all(0),
              width: 300,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: buttons,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
