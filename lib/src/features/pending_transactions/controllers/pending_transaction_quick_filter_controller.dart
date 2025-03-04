import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/screen_quick_filter.dart';
import 'package:tablets/src/features/pending_transactions/controllers/pending_transaction_screen_controller.dart';
import 'package:tablets/src/features/pending_transactions/controllers/pending_transaction_screen_data_notifier.dart';

final pendingTransactionQuickFiltersProvider =
    StateNotifierProvider<ScreenDataQuickFilters, List<QuickFilter>>((ref) {
  final screenDataNotifier = ref.read(pendingTransactionScreenDataNotifier.notifier);
  final screenController = ref.read(pendingTransactionScreenControllerProvider);
  return ScreenDataQuickFilters(screenDataNotifier, screenController);
});
