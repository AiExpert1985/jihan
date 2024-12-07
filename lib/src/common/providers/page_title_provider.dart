import 'package:flutter_riverpod/flutter_riverpod.dart';

/// contains the name of currently viewed screen
/// used to show screen name in the main app top bar
final pageTitleProvider = StateProvider<String>((ref) {
  return ''; // Default color
});
