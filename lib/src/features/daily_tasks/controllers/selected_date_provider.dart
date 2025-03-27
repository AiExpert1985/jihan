import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterNotifier extends StateNotifier<DateTime?> {
  FilterNotifier() : super(null);

  void setDate(DateTime? date) {
    state = date;
  }
}

// Create a provider for the FilterNotifier
final selectedDateProvider = StateNotifierProvider<FilterNotifier, DateTime?>((ref) {
  return FilterNotifier();
});
