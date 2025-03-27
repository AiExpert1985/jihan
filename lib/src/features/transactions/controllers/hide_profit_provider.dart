import 'package:flutter_riverpod/flutter_riverpod.dart';

// Create a StateProvider for a boolean value
final showProfitProvider = StateProvider<bool>((ref) {
  return false; // Initial value
});