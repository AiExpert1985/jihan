import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/screen_data_filters.dart';

final pendingTransactionFilterController = Provider<ScreenDataFilters>((ref) {
  return ScreenDataFilters({});
});
