import 'package:flutter/material.dart';

/// An IconButton that shows a spinner while its async onPressed is running,
/// preventing double-clicks. Drop-in replacement for IconButton.
class SpinnerIconButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  final Widget icon;

  const SpinnerIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
  });

  @override
  State<SpinnerIconButton> createState() => _SpinnerIconButtonState();
}

class _SpinnerIconButtonState extends State<SpinnerIconButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isLoading ? null : _handlePress,
      icon: _isLoading
          ? const SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : widget.icon,
    );
  }
}
