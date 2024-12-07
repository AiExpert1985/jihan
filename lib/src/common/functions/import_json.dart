import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/features/settings/model/settings.dart';
import 'package:tablets/src/features/settings/repository/settings_repository_provider.dart';

Future<List<dynamic>> loadJsonFromAssets(String filePath) async {
  try {
    String jsonString = await rootBundle.loadString(filePath);
    return jsonDecode(jsonString) as List<dynamic>;
  } catch (e) {
    errorPrint('error during uploading default settings - $e');
  }
  return [];
}

Future<Map<String, dynamic>> importDefaultSettings() async {
  final defaultSettings = await loadJsonFromAssets('assets/settings/settings.json');
  Map<String, dynamic> settingsMap = {};
  for (var map in defaultSettings) {
    map.forEach((key, value) {
      settingsMap[key] = value;
    });
  }
  return settingsMap;
}

void uploadDefaultSettings(WidgetRef ref) async {
  final repository = ref.read(settingsRepositoryProvider);
  final defaultSettings = await importDefaultSettings();

  repository.addItem(Settings.fromMap(defaultSettings));
}
