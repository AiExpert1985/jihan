import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:tablets/src/common/interfaces/base_item.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/features/daily_tasks/model/point.dart';

class WeeklyTask implements BaseItem {
  int weekDay;
  List<SalesPoint> tasks;
  @override
  String name;
  @override
  String dbRef;
  @override
  List<String> imageUrls;
  WeeklyTask({
    required this.weekDay,
    required this.tasks,
    required this.name,
    required this.dbRef,
    required this.imageUrls,
  });

  @override
  String get coverImageUrl => defaultImageUrl;

  WeeklyTask copyWith({
    int? weekDay,
    List<SalesPoint>? tasks,
    String? name,
    String? dbRef,
    List<String>? imageUrls,
  }) {
    return WeeklyTask(
      weekDay: weekDay ?? this.weekDay,
      tasks: tasks ?? this.tasks,
      name: name ?? this.name,
      dbRef: dbRef ?? this.dbRef,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'weekDay': weekDay,
      'tasks': tasks.map((x) => x.toMap()).toList(),
      'name': name,
      'dbRef': dbRef,
      'imageUrls': imageUrls,
    };
  }

  factory WeeklyTask.fromMap(Map<String, dynamic> map) {
    return WeeklyTask(
      weekDay: map['weekDay']?.toInt() ?? 0,
      tasks: List<SalesPoint>.from(map['tasks']?.map((x) => SalesPoint.fromMap(x))),
      name: map['name'] ?? '',
      dbRef: map['dbRef'] ?? '',
      imageUrls: List<String>.from(map['imageUrls']),
    );
  }

  String toJson() => json.encode(toMap());

  factory WeeklyTask.fromJson(String source) => WeeklyTask.fromMap(json.decode(source));

  @override
  String toString() {
    return 'WeeklyTask(weekDay: $weekDay, tasks: $tasks, name: $name, dbRef: $dbRef, imageUrls: $imageUrls)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WeeklyTask &&
        other.weekDay == weekDay &&
        listEquals(other.tasks, tasks) &&
        other.name == name &&
        other.dbRef == dbRef &&
        listEquals(other.imageUrls, imageUrls);
  }

  @override
  int get hashCode {
    return weekDay.hashCode ^ tasks.hashCode ^ name.hashCode ^ dbRef.hashCode ^ imageUrls.hashCode;
  }
}
