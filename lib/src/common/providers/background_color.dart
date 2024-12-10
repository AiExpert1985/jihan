import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final normalColor = Colors.grey[200];
const warningColor = Color.fromARGB(255, 245, 184, 180);

final backgroundColorProvider = StateProvider<Color>((ref) {
  return normalColor!; // Default color
});
