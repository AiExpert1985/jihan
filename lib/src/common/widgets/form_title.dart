import 'package:flutter/material.dart';

Widget buildFormTitle(String title) {
  return Center(
    child: Text(title,
        style: const TextStyle(
            fontSize: 26, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 184, 7, 7))),
  );
}
