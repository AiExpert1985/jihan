import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_repository.dart';
import 'package:tablets/src/common/classes/screen_cache_item.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/screen_cache_helper.dart';
import 'package:tablets/src/common/providers/screen_cache_repository_providers.dart';
import 'package:tablets/src/common/values/features_keys.dart';
import 'package:tablets/src/features/customers/controllers/customer_screen_controller.dart';
import 'package:tablets/src/features/customers/controllers/customer_screen_data_notifier.dart';
import 'package:tablets/src/features/products/controllers/product_screen_controller.dart';
import 'package:tablets/src/features/products/controllers/product_screen_data_notifier.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_screen_controller.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_screen_data_notifier.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';

/// Provider for the ScreenCacheService
final screenCacheServiceProvider = Provider<ScreenCacheService>((ref) {
  return ScreenCacheService(ref);
});

/// Central service for managing screen data cache
/// Handles loading from Firebase cache, falling back to calculation, and refreshing cache
class ScreenCacheService {
  ScreenCacheService(this._ref);

  final Ref _ref;

  // Summary types for each screen (used when initializing ScreenDataNotifier)
  static const Map<String, dynamic> _customerSummaryTypes = {
    'totalDebt': 'sum',
    'openInvoices': 'sum',
    'dueInvoices': 'sum',
    'dueDebt': 'sum',
    'avgClosingDays': 'avg',
    'invoicesProfit': 'sum',
    'gifts': 'sum',
  };

  static const Map<String, dynamic> _productSummaryTypes = {
    productTotalStockPriceKey: 'sum',
  };

  static const Map<String, dynamic> _salesmanSummaryTypes = {
    'commission': 'sum',
    'profit': 'sum',
  };

  /// Load customer screen data - tries cache first, falls back to calculation
  Future<void> loadCustomerScreenData(BuildContext context) async {
    final repository = _ref.read(customerScreenCacheRepositoryProvider);
    final screenDataNotifier = _ref.read(customerScreenDataNotifier.notifier);
    final transactionDbCache = _ref.read(transactionDbCacheProvider);

    try {
      debugLog('Attempting to load customer screen data from cache...');
      // Try to fetch from cache
      final cachedData = await repository.fetchItemListAsMaps();
      debugLog('Cache returned ${cachedData.length} items');

      if (cachedData.isNotEmpty) {
        // Enrich with transactions and set to notifier
        final enrichedData =
            enrichScreenDataList(cachedData, transactionDbCache);
        screenDataNotifier.initialize(_customerSummaryTypes);
        screenDataNotifier.set(enrichedData);
        debugLog(
            'Customer screen data loaded from cache (${cachedData.length} items)');
      } else {
        // Cache is empty - calculate and save
        debugLog('Customer cache is empty, falling back to calculation...');

        if (!context.mounted) return;
        await _calculateAndSaveCustomerData(context);
      }
    } catch (e) {
      errorPrint('Error loading customer screen cache: $e');
      // Fall back to calculation
      if (!context.mounted) return;
      await _calculateAndSaveCustomerData(context);
    }
  }

  /// Load product screen data - tries cache first, falls back to calculation
  Future<void> loadProductScreenData(BuildContext context) async {
    final repository = _ref.read(productScreenCacheRepositoryProvider);
    final screenDataNotifier = _ref.read(productScreenDataNotifier.notifier);
    final transactionDbCache = _ref.read(transactionDbCacheProvider);

    try {
      debugLog('Attempting to load product screen data from cache...');
      // Try to fetch from cache
      final cachedData = await repository.fetchItemListAsMaps();
      debugLog('Cache returned ${cachedData.length} items');

      if (cachedData.isNotEmpty) {
        // Enrich with transactions and set to notifier
        final enrichedData =
            enrichScreenDataList(cachedData, transactionDbCache);
        screenDataNotifier.initialize(_productSummaryTypes);
        screenDataNotifier.set(enrichedData);
        debugLog(
            'Product screen data loaded from cache (${cachedData.length} items)');
      } else {
        // Cache is empty - calculate and save
        debugLog('Product cache is empty, falling back to calculation...');
        if (!context.mounted) return;
        await _calculateAndSaveProductData(context);
      }
    } catch (e) {
      errorPrint('Error loading product screen cache: $e');
      // Fall back to calculation
      if (!context.mounted) return;
      await _calculateAndSaveProductData(context);
    }
  }

  /// Load salesman screen data - tries cache first, falls back to calculation
  Future<void> loadSalesmanScreenData(BuildContext context) async {
    final repository = _ref.read(salesmanScreenCacheRepositoryProvider);
    final screenDataNotifier = _ref.read(salesmanScreenDataNotifier.notifier);
    final transactionDbCache = _ref.read(transactionDbCacheProvider);

    try {
      debugLog('Attempting to load salesman screen data from cache...');
      // Try to fetch from cache
      final cachedData = await repository.fetchItemListAsMaps();
      debugLog('Cache returned ${cachedData.length} items');

      if (cachedData.isNotEmpty) {
        // Enrich with transactions and set to notifier
        final enrichedData =
            enrichScreenDataList(cachedData, transactionDbCache);
        screenDataNotifier.initialize(_salesmanSummaryTypes);
        screenDataNotifier.set(enrichedData);
        debugLog(
            'Salesman screen data loaded from cache (${cachedData.length} items)');
      } else {
        // Cache is empty - calculate and save
        debugLog('Salesman cache is empty, falling back to calculation...');
        if (!context.mounted) return;
        await _calculateAndSaveSalesmanData(context);
      }
    } catch (e) {
      errorPrint('Error loading salesman screen cache: $e');
      // Fall back to calculation
      if (!context.mounted) return;
      await _calculateAndSaveSalesmanData(context);
    }
  }

  /// Refresh customer screen data - recalculates from transactions and saves to cache
  Future<void> refreshCustomerScreenData(BuildContext context) async {
    await _calculateAndSaveCustomerData(context);
  }

  /// Refresh product screen data - recalculates from transactions and saves to cache
  Future<void> refreshProductScreenData(BuildContext context) async {
    await _calculateAndSaveProductData(context);
  }

  /// Refresh salesman screen data - recalculates from transactions and saves to cache
  Future<void> refreshSalesmanScreenData(BuildContext context) async {
    await _calculateAndSaveSalesmanData(context);
  }

  /// Refresh all screen data - recalculates all screens
  Future<void> refreshAllScreenData(BuildContext context) async {
    debugLog('Starting full cache refresh...');
    await refreshProductScreenData(context);
    if (!context.mounted) return;
    await refreshCustomerScreenData(context);
    if (!context.mounted) return;
    await refreshSalesmanScreenData(context);
    debugLog('Full cache refresh completed');
  }

  /// Calculate customer data using ScreenController and save to cache
  Future<void> _calculateAndSaveCustomerData(BuildContext context) async {
    final controller = _ref.read(customerScreenControllerProvider);
    final repository = _ref.read(customerScreenCacheRepositoryProvider);
    final screenDataNotifier = _ref.read(customerScreenDataNotifier.notifier);

    // Use existing controller to calculate
    controller.setFeatureScreenData(context);

    // Get the calculated data from notifier
    final calculatedData =
        screenDataNotifier.data as List<Map<String, dynamic>>;

    // Save each item to cache (with transactions converted to dbRefs)
    await _saveToCacheCollection(calculatedData, repository);

    debugLog('Customer screen cache saved (${calculatedData.length} items)');
  }

  /// Calculate product data using ScreenController and save to cache
  Future<void> _calculateAndSaveProductData(BuildContext context) async {
    final controller = _ref.read(productScreenControllerProvider);
    final repository = _ref.read(productScreenCacheRepositoryProvider);
    final screenDataNotifier = _ref.read(productScreenDataNotifier.notifier);

    // Use existing controller to calculate
    controller.setFeatureScreenData(context);

    // Get the calculated data from notifier
    final calculatedData =
        screenDataNotifier.data as List<Map<String, dynamic>>;

    // Save each item to cache (with transactions converted to dbRefs)
    await _saveToCacheCollection(calculatedData, repository);

    debugLog('Product screen cache saved (${calculatedData.length} items)');
  }

  /// Calculate salesman data using ScreenController and save to cache
  Future<void> _calculateAndSaveSalesmanData(BuildContext context) async {
    final controller = _ref.read(salesmanScreenControllerProvider);
    final repository = _ref.read(salesmanScreenCacheRepositoryProvider);
    final screenDataNotifier = _ref.read(salesmanScreenDataNotifier.notifier);

    // Use existing controller to calculate (this is async for salesman)
    await controller.setFeatureScreenData(context);

    // Get the calculated data from notifier
    final calculatedData =
        screenDataNotifier.data as List<Map<String, dynamic>>;

    // Save each item to cache (with transactions converted to dbRefs)
    await _saveToCacheCollection(calculatedData, repository);

    debugLog('Salesman screen cache saved (${calculatedData.length} items)');
  }

  /// Save calculated data to a cache collection using batch writes
  /// This is MUCH faster than individual writes for large collections
  Future<void> _saveToCacheCollection(
    List<Map<String, dynamic>> data,
    DbRepository repository,
  ) async {
    // Convert all items first
    final List<ScreenCacheItem> cacheItems = [];
    for (var item in data) {
      try {
        final cacheItem = convertForCacheSave(item);
        cacheItems.add(ScreenCacheItem(cacheItem));
      } catch (e) {
        errorPrint('Error converting item for cache: $e');
      }
    }

    // Use batch write for all items at once
    await repository.batchAddOrUpdateItemsWithRef(cacheItems);
  }
}
