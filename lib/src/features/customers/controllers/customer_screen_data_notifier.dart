import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/providers/screen_data_notifier.dart';

final customerScreenDataNotifier = StateNotifierProvider<ScreenDataNotifier, Map<String, dynamic>>(
  (ref) => ScreenDataNotifier(),
);
