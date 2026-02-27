import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_repository.dart';
import 'package:tablets/src/common/classes/screen_cache_item.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/screen_cache_helper.dart';
import 'package:tablets/src/common/providers/screen_cache_repository_providers.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/features/customers/controllers/customer_screen_controller.dart';
import 'package:tablets/src/features/customers/repository/customer_db_cache_provider.dart';
import 'package:tablets/src/features/products/controllers/product_screen_controller.dart';
import 'package:tablets/src/features/products/repository/product_db_cache_provider.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_screen_controller.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_db_cache_provider.dart';

/// Provider for the ScreenCacheUpdateService
final screenCacheUpdateServiceProvider =
    Provider<ScreenCacheUpdateService>((ref) {
  return ScreenCacheUpdateService(ref);
});

/// Enum for transaction operation types
enum TransactionOperation { add, edit, delete }

/// Holds pre-calculated screen data for affected entities
class PreCalculatedCacheData {
  final List<Map<String, dynamic>> customerData;
  final List<Map<String, dynamic>> productData;
  final List<Map<String, dynamic>> salesmanData;

  PreCalculatedCacheData({
    required this.customerData,
    required this.productData,
    required this.salesmanData,
  });
}

/// Service that handles updating screen cache when transactions change
///
/// This service uses a two-phase approach:
/// 1. calculateAffectedEntities - runs SYNCHRONOUSLY while context is valid
/// 2. savePreCalculatedData - runs ASYNCHRONOUSLY to save to Firebase
class ScreenCacheUpdateService {
  ScreenCacheUpdateService(this._ref);

  final Ref _ref;

  /// Phase 1: Calculate screen data for affected entities SYNCHRONOUSLY
  /// This must be called while BuildContext is still valid
  PreCalculatedCacheData calculateAffectedEntities(
    BuildContext context,
    Map<String, dynamic>? oldTransaction,
    Map<String, dynamic>? newTransaction,
    TransactionOperation operation,
  ) {
    debugLog('Calculating affected entities for: $operation');

    // Get affected entity dbRefs
    final affectedEntities =
        _getAffectedEntities(oldTransaction, newTransaction);

    debugLog('Affected customers: ${affectedEntities.customerDbRefs}');
    debugLog('Affected products: ${affectedEntities.productDbRefs}');
    debugLog('Affected salesmen: ${affectedEntities.salesmanDbRefs}');

    // Pre-calculate all screen data while context is valid
    final customerData = <Map<String, dynamic>>[];
    final productData = <Map<String, dynamic>>[];
    final salesmanData = <Map<String, dynamic>>[];

    // Calculate product data
    final productDbCache = _ref.read(productDbCacheProvider.notifier);
    final productController = _ref.read(productScreenControllerProvider);
    for (var productDbRef in affectedEntities.productDbRefs) {
      final rawData = productDbCache.getItemByDbRef(productDbRef);
      if (rawData.isNotEmpty) {
        final screenData =
            productController.getItemScreenData(context, rawData);
        productData.add(screenData);
      }
    }

    // Calculate customer data
    final customerDbCache = _ref.read(customerDbCacheProvider.notifier);
    final customerController = _ref.read(customerScreenControllerProvider);
    for (var customerDbRef in affectedEntities.customerDbRefs) {
      final rawData = customerDbCache.getItemByDbRef(customerDbRef);
      if (rawData.isNotEmpty) {
        final screenData =
            customerController.getItemScreenData(context, rawData);
        customerData.add(screenData);
      }
    }

    // Calculate salesman data
    final salesmanDbCache = _ref.read(salesmanDbCacheProvider.notifier);
    final salesmanController = _ref.read(salesmanScreenControllerProvider);
    for (var salesmanDbRef in affectedEntities.salesmanDbRefs) {
      final rawData = salesmanDbCache.getItemByDbRef(salesmanDbRef);
      if (rawData.isNotEmpty) {
        final screenData =
            salesmanController.getItemScreenData(context, rawData);
        salesmanData.add(screenData);
      }
    }

    debugLog(
        'Pre-calculated: ${productData.length} products, ${customerData.length} customers, ${salesmanData.length} salesmen');

    return PreCalculatedCacheData(
      customerData: customerData,
      productData: productData,
      salesmanData: salesmanData,
    );
  }

  /// Phase 2: Save pre-calculated data to Firebase ASYNCHRONOUSLY
  /// This can run after navigation - no context needed
  Future<void> savePreCalculatedData(PreCalculatedCacheData data) async {
    debugLog('Saving pre-calculated data to Firebase...');

    // Save products
    try {
      final productRepository = _ref.read(productScreenCacheRepositoryProvider);
      for (var screenData in data.productData) {
        await _saveItemToCache(screenData, productRepository);
      }
    } catch (e) {
      errorPrint('Error saving product cache data: $e');
    }

    // Save customers
    try {
      final customerRepository =
          _ref.read(customerScreenCacheRepositoryProvider);
      for (var screenData in data.customerData) {
        await _saveItemToCache(screenData, customerRepository);
      }
    } catch (e) {
      errorPrint('Error saving customer cache data: $e');
    }

    // Save salesmen
    try {
      final salesmanRepository =
          _ref.read(salesmanScreenCacheRepositoryProvider);
      for (var screenData in data.salesmanData) {
        await _saveItemToCache(screenData, salesmanRepository);
      }
    } catch (e) {
      errorPrint('Error saving salesman cache data: $e');
    }

    debugLog('Pre-calculated data saved to Firebase');
  }

  /// Get all entities affected by transaction change
  _AffectedEntities _getAffectedEntities(
    Map<String, dynamic>? oldTransaction,
    Map<String, dynamic>? newTransaction,
  ) {
    final Set<String> customerDbRefs = {};
    final Set<String> salesmanDbRefs = {};
    final Set<String> productDbRefs = {};

    // Extract from old transaction
    if (oldTransaction != null) {
      _extractEntitiesFromTransaction(
        oldTransaction,
        customerDbRefs,
        salesmanDbRefs,
        productDbRefs,
      );
    }

    // Extract from new transaction
    if (newTransaction != null) {
      _extractEntitiesFromTransaction(
        newTransaction,
        customerDbRefs,
        salesmanDbRefs,
        productDbRefs,
      );
    }

    return _AffectedEntities(
      customerDbRefs: customerDbRefs,
      salesmanDbRefs: salesmanDbRefs,
      productDbRefs: productDbRefs,
    );
  }

  /// Extract entity dbRefs from a transaction
  void _extractEntitiesFromTransaction(
    Map<String, dynamic> transaction,
    Set<String> customerDbRefs,
    Set<String> salesmanDbRefs,
    Set<String> productDbRefs,
  ) {
    final type = transaction['transactionType'] as String?;

    // Customer transactions have nameDbRef pointing to customer
    if (type != null && _isCustomerTransaction(type)) {
      final nameDbRef = transaction['nameDbRef'] as String?;
      if (nameDbRef != null && nameDbRef.isNotEmpty) {
        customerDbRefs.add(nameDbRef);
      }
    }

    // Salesman dbRef
    final salesmanDbRef = transaction['salesmanDbRef'] as String?;
    if (salesmanDbRef != null && salesmanDbRef.isNotEmpty) {
      salesmanDbRefs.add(salesmanDbRef);
    }

    // Product dbRefs from items
    final items = transaction['items'] as List<dynamic>?;
    if (items != null) {
      for (var item in items) {
        if (item is Map) {
          final productDbRef = item['dbRef'] as String?;
          if (productDbRef != null && productDbRef.isNotEmpty) {
            productDbRefs.add(productDbRef);
          }
        }
      }
    }
  }

  /// Check if transaction type is customer-related
  bool _isCustomerTransaction(String type) {
    return type == TransactionType.customerInvoice.name ||
        type == TransactionType.customerReceipt.name ||
        type == TransactionType.customerReturn.name ||
        type == TransactionType.gifts.name ||
        type == TransactionType.initialCredit.name;
  }

  /// Save a single item to cache collection
  Future<void> _saveItemToCache(
    Map<String, dynamic> screenData,
    DbRepository repository,
  ) async {
    final cacheItem = convertForCacheSave(screenData);
    final screenCacheItem = ScreenCacheItem(cacheItem);
    await repository.addOrUpdateItemWithRef(screenCacheItem);
  }
}

/// Helper class to hold affected entities
class _AffectedEntities {
  final Set<String> customerDbRefs;
  final Set<String> salesmanDbRefs;
  final Set<String> productDbRefs;

  _AffectedEntities({
    required this.customerDbRefs,
    required this.salesmanDbRefs,
    required this.productDbRefs,
  });
}
