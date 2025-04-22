import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_repository.dart';
import 'package:tablets/src/features/daily_tasks/view/weekly_tasks_screen.dart';

final weeklyTasksRepositoryProvider = Provider<DbRepository>((ref) => DbRepository('weekly-tasks'));

final weeklyTasksStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final transactionRepository = ref.watch(weeklyTasksRepositoryProvider);
  final weekDay = ref.watch(selectedWeekdayIndexProvider);
  return transactionRepository.watchItemListAsFilteredMaps('weekDay', weekDay);
});
