import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/features/daily_tasks/controllers/selected_date_provider.dart';
import 'package:tablets/src/features/daily_tasks/model/point.dart';
import 'package:tablets/src/features/daily_tasks/repo/tasks_repository_provider.dart';
import 'package:tablets/src/features/daily_tasks/repo/weekly_tasks_repo.dart';

void copyWeeklyDayTasks(WidgetRef ref) async {
  final tasksRepo = ref.read(tasksRepositoryProvider);
  final weekDayRepo = ref.read(weeklyTasksRepositoryProvider);
  final selectedDate = ref.read(selectedDateProvider) ?? DateTime.now();
  final weekDay = selectedDate.weekday;
  final weekTasks = await weekDayRepo.fetchItemListAsMaps();
  final dayTasks = weekTasks.where((item) => item['weekDay'] == weekDay).toList();
  final tasks = dayTasks.isEmpty ? [] : dayTasks.first['tasks'];
  for (var task in tasks) {
    final salesPoint = SalesPoint.fromMap(task);
    // important to give unqiue dbRef, face bug without ti
    salesPoint.dbRef = generateRandomString(len: 8);
    salesPoint.isVisited = false;
    salesPoint.hasTransaction = false;
    salesPoint.date = selectedDate;
    tasksRepo.addItem(salesPoint);
  }
}
