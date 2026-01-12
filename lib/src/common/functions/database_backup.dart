import 'dart:convert';
import 'dart:io'; // Import dart:io for file handling
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/db_cache_inialization.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/file_system_path.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:archive/archive.dart';
import 'package:tablets/src/common/providers/daily_backup_provider.dart';
import 'package:tablets/src/common/providers/user_info_provider.dart';
import 'package:tablets/src/features/authentication/model/user_account.dart';

Future<void> backupDataBase(BuildContext context, WidgetRef ref,
    {bool isAuto = false}) async {
  final userInfo = ref.read(userInfoProvider);
  if (userInfo == null ||
      !userInfo.hasAccess ||
      userInfo.privilage != UserPrivilage.admin.name) {
    // only admin (who has access) can make backup
    return;
  }
  try {
    final dataBaseNames = _getDataBaseNames(context);
    final dataBaseMaps = await _getDataBaseMaps(context, ref, isAuto);
    if (context.mounted) {
      await _saveDbFiles(context, ref, dataBaseMaps, dataBaseNames, isAuto);
    }
  } catch (e) {
    errorPrint('Error during database backup -- $e');
  }
}

Future<List<List<Map<String, dynamic>>>> _getDataBaseMaps(
    BuildContext context, WidgetRef ref, bool isAuto) async {
  await initializeAllDbCaches(context, ref);
  final salesmanData = getSalesmenDbCacheData(ref);
  final regionsData = getRegionsDbCacheData(ref);
  final categoriesData = getCategoriesDbCacheData(ref);
  final settingsData = getSettingsDbCacheData(ref);
  // because json can't deal with Date classes, we need to convert to String
  final transactionData =
      formatDateForJson(getTransactionDbCacheData(ref), 'date');
  final productsData =
      formatDateForJson(getProductsDbCacheData(ref), 'initialDate');
  final customersData =
      formatDateForJson(getCustomersDbCacheData(ref), 'initialDate');
  final vendorsData =
      formatDateForJson(getVendorsDbCacheData(ref), 'initialDate');
  final weeklyTasksData = formatAllTimestampsForJson(getWeeklyTasksDbCacheData(ref));
  final deletedTransactionData = formatAllTimestampsForJson(getDeletedTransactionsDbCacheData(ref));
  final accountsData = formatAllTimestampsForJson(getAccountsDbCacheData(ref));
  // final dailyBackupNotifier = ref.read(dailyDatabaseBackupNotifier.notifier);
  // final dailyBackupStatus = dailyBackupNotifier.state;
  if (context.mounted && !isAuto) {
    // note that we only remove dialog when it is not auto daily backup
    Navigator.of(context).pop();
  }
  final dataBaseMaps = [
    transactionData,
    salesmanData,
    productsData,
    customersData,
    vendorsData,
    regionsData,
    categoriesData,
    settingsData,
    weeklyTasksData,
    deletedTransactionData,
    accountsData,
  ];
  return dataBaseMaps;
}

List<String> _getDataBaseNames(BuildContext context) {
  return [
    S.of(context).transactions,
    S.of(context).salesmen,
    S.of(context).products,
    S.of(context).customers,
    S.of(context).vendors,
    S.of(context).regions,
    S.of(context).categories,
    S.of(context).settings,
    'المهام الاسبوعية',
    S.of(context).deleted_transactions,
    'الحسابات',
  ];
}

// Change the name of the function to _saveDbFiles
Future<void> _saveDbFiles(
    BuildContext context,
    WidgetRef ref,
    List<List<Map<String, dynamic>>> allData,
    List<String> fileNames,
    bool isAuto) async {
  try {
    final zipFilePath = getBackupFilePath();
    if (zipFilePath == null) {
      return;
    }

    final params = {
      'allData': allData,
      'fileNames': fileNames,
      'zipFilePath': zipFilePath,
    };

    // Use compute to run the heavy lifting in an isolate
    // We can't pass the context or ref to the isolate, only data
    await compute(_backupInIsolate, params);

    final dailyBackupNotifier = ref.read(dailyDatabaseBackupNotifier.notifier);
    final dailyBackupStatus = dailyBackupNotifier.state;
    if (context.mounted && dailyBackupStatus && !isAuto) {
      successUserMessage(context, S.of(context).db_backup_success);
    }
  } catch (e) {
    if (context.mounted && !isAuto) {
      failureUserMessage(context, S.of(context).db_backup_failure);
    }
    errorPrint('backup database failed -- $e');
  }
}

/// This function runs in a separate isolate.
/// It must be static or a top-level function.
Future<void> _backupInIsolate(Map<String, dynamic> params) async {
  final allData = params['allData'] as List<List<Map<String, dynamic>>>;
  final fileNames = params['fileNames'] as List<String>;
  final zipFilePath = params['zipFilePath'] as String;

  final archive = Archive();
  for (int i = 0; i < allData.length; i++) {
    List<Map<String, dynamic>> data = allData[i];
    String jsonString = jsonEncode(data);
    List<int> bytes = utf8.encode(jsonString);
    archive.addFile(ArchiveFile('${fileNames[i]}.json', bytes.length, bytes));
  }
  final zipData = ZipEncoder().encode(archive);
  final zipFile = File(zipFilePath);
  if (zipData != null) {
    await zipFile.writeAsBytes(zipData);
  }
}

/// every time app runs, I create backup. if backup is done, it will not updated
/// unless user manually modify it through pressing backup button
Future<void> autoDatabaseBackup(BuildContext context, WidgetRef ref) async {
  try {
    final dailyBackupNotifier = ref.read(dailyDatabaseBackupNotifier.notifier);
    final dailyBackupStatus = dailyBackupNotifier.state;
    if (!dailyBackupStatus) {
      // we don't await this, so it runs in the background and doesn't block the UI
      backupDataBase(context, ref, isAuto: true);
      dailyBackupNotifier.update((state) => true);
    }
  } catch (e) {
    errorPrint('Error during database auto backup (e)');
  }
}
