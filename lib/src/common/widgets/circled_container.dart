import 'package:flutter/material.dart';

class CircledContainer extends StatelessWidget {
  const CircledContainer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 25.0, // Set the width of the circle
        height: 25.0, // Set the height of the circle
        decoration: BoxDecoration(
          color: Colors.red, // Circle color
          shape: BoxShape.circle, // Make the shape a circle
          border: Border.all(color: Colors.red, width: 1), // Optional: Add a border
        ),
        child: Center(child: child));
  }
}
