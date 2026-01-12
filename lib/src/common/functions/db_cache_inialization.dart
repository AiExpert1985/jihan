import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/features/categories/repository/category_db_cache_provider.dart';
import 'package:tablets/src/features/categories/repository/category_repository_provider.dart';
import 'package:tablets/src/features/customers/repository/customer_db_cache_provider.dart';
import 'package:tablets/src/features/customers/repository/customer_repository_provider.dart';
import 'package:tablets/src/features/deleted_transactions/repository/deleted_transaction_db_cache_provider.dart';
import 'package:tablets/src/features/deleted_transactions/repository/deleted_transaction_repository_provider.dart';
import 'package:tablets/src/features/pending_transactions/repository/pending_transaction_db_cache_provider.dart';
import 'package:tablets/src/features/pending_transactions/repository/pending_transaction_repository_provider.dart';
import 'package:tablets/src/features/products/repository/product_db_cache_provider.dart';
import 'package:tablets/src/features/products/repository/product_repository_provider.dart';
import 'package:tablets/src/features/regions/repository/region_db_cache_provider.dart';
import 'package:tablets/src/features/regions/repository/region_repository_provider.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_db_cache_provider.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_repository_provider.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/settings/repository/settings_db_cache_provider.dart';
import 'package:tablets/src/features/settings/repository/settings_repository_provider.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/repository/transaction_repository_provider.dart';
import 'package:tablets/src/features/vendors/repository/vendor_db_cache_provider.dart';
import 'package:tablets/src/features/vendors/repository/vendor_repository_provider.dart';
import 'package:tablets/src/common/providers/daily_reconciliation_service.dart';
import 'package:tablets/src/features/daily_tasks/repo/weekly_tasks_db_cache_provider.dart';
import 'package:tablets/src/features/daily_tasks/repo/weekly_tasks_repo.dart';
import 'package:tablets/src/features/authentication/repository/accounts_db_cache_provider.dart';
import 'package:tablets/src/features/authentication/repository/accounts_repository.dart';

//! Important note
//! setting the values in the dbCache is done only once for each feature
//! when we load data from database (firebase) for the first time, that means, whenever a
//! change happened to a feature (add, update, delete), we update the cache and
//! database with same data (whether create, update or delete), so there will be no need to fetch
//! from database again

void initializeSettings(BuildContext context, WidgetRef ref) {
  final settingsDataNotifier = ref.read(settingsFormDataProvider.notifier);
  if (settingsDataNotifier.data.isEmpty) {
    final settingsData = ref.read(settingsDbCacheProvider);
    if (settingsData.isEmpty) {
      debugLog('try to access settingDbCache, while it is not loaded yet');
      failureUserMessage(context, 'try to access settingDbCache, while it is not loaded yet');
      return;
    }
    settingsDataNotifier.initialize(initialData: settingsData[0]);
  }
}

Future<void> resetDbCaches(BuildContext context, WidgetRef ref) async {
  ref.read(customerDbCacheProvider.notifier).reset();
  ref.read(transactionDbCacheProvider.notifier).reset();
  ref.read(productDbCacheProvider.notifier).reset();
  ref.read(vendorDbCacheProvider.notifier).reset();
  ref.read(salesmanDbCacheProvider.notifier).reset();
  ref.read(categoryDbCacheProvider.notifier).reset();
  ref.read(regionDbCacheProvider.notifier).reset();
  ref.read(deletedTransactionDbCacheProvider.notifier).reset();
  ref.read(pendingTransactionDbCacheProvider.notifier).reset();
  ref.read(weeklyTasksDbCacheProvider.notifier).reset();
  ref.read(accountsDbCacheProvider.notifier).reset();
  await initializeAllDbCaches(context, ref);
}

Future<void> initializeAllDbCaches(BuildContext context, WidgetRef ref) async {
  await _initializeTransactionDbCache(context, ref);

  // initialize related dbCaches
  if (context.mounted) {
    await _initializeCustomerDbCache(context, ref);
  }
  if (context.mounted) {
    await _initializeProductDbCache(context, ref);
  }
  if (context.mounted) {
    await _initializeVendorDbCache(context, ref);
  }
  if (context.mounted) {
    await _initializeSalesmanDbCache(context, ref);
  }
  if (context.mounted) {
    await _initializeCategoriesDbCache(context, ref);
  }
  if (context.mounted) {
    await _initializeRegionsDbCache(context, ref);
  }
  if (context.mounted) {
    await _initializeSettingsDbCache(context, ref);
  }
  if (context.mounted) {
    await _initializeDeletedTransactionsDbCache(context, ref);
  }
  if (context.mounted) {
    await initializePendingTransactionsDbCache(context, ref);
  }
  if (context.mounted) {
    await _initializeWeeklyTasksDbCache(context, ref);
  }
  if (context.mounted) {
    await _initializeAccountsDbCache(context, ref);
  }

  // Check and schedule daily reconciliation for screen cache
  if (context.mounted) {
    final reconciliationService = ref.read(dailyReconciliationServiceProvider);
    reconciliationService.checkAndScheduleReconciliation(context);
  }
}

Future<void> _initializeCustomerDbCache(BuildContext context, WidgetRef ref) async {
  final customerDbCache = ref.read(customerDbCacheProvider.notifier);
  if (customerDbCache.data.isEmpty) {
    final customerData = await ref.read(customerRepositoryProvider).fetchItemListAsMaps();
    customerDbCache.set(customerData);
  }
}

Future<void> _initializeTransactionDbCache(BuildContext context, WidgetRef ref) async {
  final transactionDbCache = ref.read(transactionDbCacheProvider.notifier);
  if (transactionDbCache.data.isEmpty) {
    final transactionData = await ref.read(transactionRepositoryProvider).fetchItemListAsMaps();
    transactionDbCache.set(transactionData);
  }
}

Future<void> _initializeProductDbCache(BuildContext context, WidgetRef ref) async {
  final productDbCache = ref.read(productDbCacheProvider.notifier);
  if (productDbCache.data.isEmpty) {
    final productData = await ref.read(productRepositoryProvider).fetchItemListAsMaps();
    productDbCache.set(productData);
  }
}

Future<void> _initializeVendorDbCache(BuildContext context, WidgetRef ref) async {
  final vendorDbCache = ref.read(vendorDbCacheProvider.notifier);
  if (vendorDbCache.data.isEmpty) {
    final vendorData = await ref.read(vendorRepositoryProvider).fetchItemListAsMaps();
    vendorDbCache.set(vendorData);
  }
}

Future<void> _initializeSalesmanDbCache(BuildContext context, WidgetRef ref) async {
  final salesmanDbCache = ref.read(salesmanDbCacheProvider.notifier);
  if (salesmanDbCache.data.isEmpty) {
    final salesmanData = await ref.read(salesmanRepositoryProvider).fetchItemListAsMaps();
    salesmanDbCache.set(salesmanData);
  }
}

Future<void> _initializeCategoriesDbCache(BuildContext context, WidgetRef ref) async {
  final categoriesDbCache = ref.read(categoryDbCacheProvider.notifier);
  if (categoriesDbCache.data.isEmpty) {
    final salesmanData = await ref.read(categoryRepositoryProvider).fetchItemListAsMaps();
    categoriesDbCache.set(salesmanData);
  }
}

Future<void> _initializeRegionsDbCache(BuildContext context, WidgetRef ref) async {
  final regionDbCache = ref.read(regionDbCacheProvider.notifier);
  if (regionDbCache.data.isEmpty) {
    final salesmanData = await ref.read(regionRepositoryProvider).fetchItemListAsMaps();
    regionDbCache.set(salesmanData);
  }
}

Future<void> _initializeSettingsDbCache(BuildContext context, WidgetRef ref) async {
  final settingsDbCache = ref.read(settingsDbCacheProvider.notifier);
  if (settingsDbCache.data.isEmpty) {
    final settingsData = await ref.read(settingsRepositoryProvider).fetchItemListAsMaps();
    settingsDbCache.set(settingsData);
  }
}

Future<void> _initializeDeletedTransactionsDbCache(BuildContext context, WidgetRef ref) async {
  final dbCache = ref.read(deletedTransactionDbCacheProvider.notifier);
  if (dbCache.data.isEmpty) {
    final dbCacheData = await ref.read(deletedTransactionRepositoryProvider).fetchItemListAsMaps();
    dbCache.set(dbCacheData);
  }
}

Future<void> initializePendingTransactionsDbCache(BuildContext context, WidgetRef ref) async {
  final dbCache = ref.read(pendingTransactionDbCacheProvider.notifier);
  final dbCacheData = await ref.read(pendingTransactionRepositoryProvider).fetchItemListAsMaps();
  dbCache.set(dbCacheData);
}

List<Map<String, dynamic>> getPendingTransactionDbCacheData(WidgetRef ref) {
  final dbCache = ref.read(pendingTransactionDbCacheProvider.notifier);
  return dbCache.data;
}

List<Map<String, dynamic>> getTransactionDbCacheData(WidgetRef ref) {
  final transactionsDbCache = ref.read(transactionDbCacheProvider.notifier);
  return transactionsDbCache.data;
}

List<Map<String, dynamic>> getProductsDbCacheData(WidgetRef ref) {
  final dbCache = ref.read(productDbCacheProvider.notifier);
  return dbCache.data;
}

List<Map<String, dynamic>> getCategoriesDbCacheData(WidgetRef ref) {
  final dbCache = ref.read(categoryDbCacheProvider.notifier);
  return dbCache.data;
}

List<Map<String, dynamic>> getVendorsDbCacheData(WidgetRef ref) {
  final dbCache = ref.read(vendorDbCacheProvider.notifier);
  return dbCache.data;
}

List<Map<String, dynamic>> getSalesmenDbCacheData(WidgetRef ref) {
  final dbCache = ref.read(salesmanDbCacheProvider.notifier);
  return dbCache.data;
}

List<Map<String, dynamic>> getCustomersDbCacheData(WidgetRef ref) {
  final dbCache = ref.read(customerDbCacheProvider.notifier);
  return dbCache.data;
}

List<Map<String, dynamic>> getRegionsDbCacheData(WidgetRef ref) {
  final dbCache = ref.read(regionDbCacheProvider.notifier);
  return dbCache.data;
}

List<Map<String, dynamic>> getSettingsDbCacheData(WidgetRef ref) {
  final dbCache = ref.read(settingsDbCacheProvider.notifier);
  return dbCache.data;
}

List<Map<String, dynamic>> getDeletedTransactionsDbCacheData(WidgetRef ref) {
  final dbCache = ref.read(deletedTransactionDbCacheProvider.notifier);
  return dbCache.data;
}

Future<void> _initializeWeeklyTasksDbCache(BuildContext context, WidgetRef ref) async {
  final dbCache = ref.read(weeklyTasksDbCacheProvider.notifier);
  if (dbCache.data.isEmpty) {
    final dbCacheData = await ref.read(weeklyTasksRepositoryProvider).fetchItemListAsMaps();
    dbCache.set(dbCacheData);
  }
}

Future<void> _initializeAccountsDbCache(BuildContext context, WidgetRef ref) async {
  final dbCache = ref.read(accountsDbCacheProvider.notifier);
  if (dbCache.data.isEmpty) {
    final dbCacheData = await ref.read(accountsRepositoryProvider).fetchItemListAsMaps();
    dbCache.set(dbCacheData);
  }
}

List<Map<String, dynamic>> getWeeklyTasksDbCacheData(WidgetRef ref) {
  final dbCache = ref.read(weeklyTasksDbCacheProvider.notifier);
  return dbCache.data;
}

List<Map<String, dynamic>> getAccountsDbCacheData(WidgetRef ref) {
  final dbCache = ref.read(accountsDbCacheProvider.notifier);
  return dbCache.data;
}
