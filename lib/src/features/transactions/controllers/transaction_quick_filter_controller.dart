import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/screen_quick_filter.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_controller.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_data_notifier.dart';

final transactionQuickFiltersProvider =
    StateNotifierProvider<ScreenDataQuickFilters, List<QuickFilter>>((ref) {
  final screenDataNotifier = ref.read(transactionScreenDataNotifier.notifier);
  final screenController = ref.read(transactionScreenControllerProvider);
  return ScreenDataQuickFilters(screenDataNotifier, screenController);
});
