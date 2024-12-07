import 'package:flutter/material.dart';

class ReportColumn extends StatelessWidget {
  final String title;
  final List<Widget> buttons;

  const ReportColumn({super.key, required this.title, required this.buttons});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ReportTile(title),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 250), // Space between title and buttons
              ...buttons.map((button) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0), // Space between buttons
                  child: button,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class ReportButton extends StatelessWidget {
  const ReportButton(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.blueGrey, // Light border color
          width: 0.2, // Border width
        ),

        borderRadius: BorderRadius.circular(10), // Rounded corners
      ),
      padding: const EdgeInsets.all(10.0),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class ReportTile extends StatelessWidget {
  const ReportTile(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}
