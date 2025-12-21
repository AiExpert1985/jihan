import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/interfaces/screen_controller.dart';
import 'package:tablets/src/common/providers/screen_data_notifier.dart';
import 'package:tablets/src/common/values/features_keys.dart';
import 'package:tablets/src/features/products/controllers/product_screen_data_notifier.dart';
import 'package:tablets/src/features/products/repository/product_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:flutter/material.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/features/products/model/product.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'dart:collection';

final productScreenControllerProvider =
    Provider<ProductScreenController>((ref) {
  final screenDataNotifier = ref.read(productScreenDataNotifier.notifier);
  final transactionsDbCache = ref.read(transactionDbCacheProvider.notifier);
  final productDbCache = ref.read(productDbCacheProvider.notifier);
  return ProductScreenController(
      screenDataNotifier, transactionsDbCache, productDbCache);
});

class ProductScreenController implements ScreenDataController {
  ProductScreenController(
    this._screenDataNotifier,
    this._transactionsDbCache,
    this._productDbCache,
  );

  final ScreenDataNotifier _screenDataNotifier;
  final DbCache _transactionsDbCache;
  final DbCache _productDbCache;

  @override
  void setFeatureScreenData(BuildContext context) {
    final allProductsData = _productDbCache.data;
    // Pre-process and group transactions by product dbRef for efficient lookup.
    final transactionsByProduct = _groupTransactionsByProduct();

    List<Map<String, dynamic>> screenData = [];
    for (var productData in allProductsData) {
      final product = Product.fromMap(productData);
      final productTransactions = transactionsByProduct[product.dbRef] ?? [];
      final newRow =
          _createProductScreenData(context, product, productTransactions);
      screenData.add(newRow);
    }

    Map<String, dynamic> summaryTypes = {
      productTotalStockPriceKey: 'sum',
    };
    _screenDataNotifier.initialize(summaryTypes);
    _screenDataNotifier.set(screenData);
  }

  /// Groups all transactions by product `dbRef`.
  /// This is the corrected version that prevents double-counting transactions.
  Map<String, List<Transaction>> _groupTransactionsByProduct() {
    final transactions = _transactionsDbCache.data;
    final Map<String, List<Transaction>> groupedTransactions = {};

    for (var transactionMap in transactions) {
      final convertedMap = _convertTransactionMap(transactionMap);
      final transaction = Transaction.fromMap(convertedMap);

      // Use a HashSet to find the unique product dbRefs within a single transaction.
      // This prevents adding the same transaction multiple times for a product.
      final productDbRefsInTransaction = HashSet<String>();
      for (var item in transaction.items ?? []) {
        if (item['dbRef'] != null) {
          productDbRefsInTransaction.add(item['dbRef']);
        }
      }

      // Associate the transaction with each unique product it contains.
      for (var dbRef in productDbRefsInTransaction) {
        if (!groupedTransactions.containsKey(dbRef)) {
          groupedTransactions[dbRef] = [];
        }
        groupedTransactions[dbRef]!.add(transaction);
      }
    }
    return groupedTransactions;
  }

  /// Handles the type conversion for a single transaction map.
  Map<String, dynamic> _convertTransactionMap(
      Map<String, dynamic> transactionMap) {
    final newMap = Map<String, dynamic>.from(transactionMap);
    newMap.forEach((key, value) {
      if (value is int) {
        newMap[key] = value.toDouble();
      }
    });
    newMap['number'] = (newMap['number'] as double).toInt();
    return newMap;
  }

  @override
  Map<String, dynamic> getItemScreenData(
      BuildContext context, Map<String, dynamic>? productData) {
    // If no product data is provided, we can't calculate anything.
    if (productData == null) {
      // Return a map with a zero quantity to be safe.
      return {productQuantityKey: 0};
    }

    // 1. Convert the incoming map to a proper Product object.
    final product = Product.fromMap(productData);

    // 2. Find all transactions that involve this specific product.
    final allTransactions = _transactionsDbCache.data;
    final List<Transaction> productTransactions = [];

    for (var transactionMap in allTransactions) {
      // Check if the transaction's items list contains our product
      final hasProduct = (transactionMap['items'] as List<dynamic>? ?? [])
          .any((item) => item['dbRef'] == product.dbRef);

      if (hasProduct) {
        final convertedMap = _convertTransactionMap(transactionMap);
        productTransactions.add(Transaction.fromMap(convertedMap));
      }
    }

    // 3. Use your existing logic to do the final calculation for this single product.
    final screenDataMap =
        _createProductScreenData(context, product, productTransactions);

    // 4. Return the complete data map.
    return screenDataMap;
  }

  /// Creates the data row for a single product.
  Map<String, dynamic> _createProductScreenData(
      BuildContext context, Product product, List<Transaction> transactions) {
    List<List<dynamic>> productProcessedTransactions = [];

    // Add initial quantity transaction if it exists.
    if (product.initialQuantity > 0) {
      productProcessedTransactions
          .add(_createInitialTransactionRow(context, product));
    }

    // Process all other transactions for this product.
    for (var transaction in transactions) {
      productProcessedTransactions.addAll(
          _processTransactionItems(context, transaction, product.dbRef));
    }

    // Sort transactions by date.
    sortListOfListsByDate(productProcessedTransactions, 3);

    final productTotals = _getProductTotals(productProcessedTransactions);
    final totalQuantity = productTotals[0];
    final totalProfit = productTotals[1];

    return {
      productDbRefKey: product.dbRef,
      productCodeKey: product.code,
      productNameKey: product.name,
      productCategoryKey: product.category,
      productCommissionKey: product.salesmanCommission,
      productSellingWholeSaleKey: product.sellWholePrice,
      productSellingRetailKey: product.sellRetailPrice,
      productBuyingPriceKey: product.buyingPrice,
      productQuantityKey: totalQuantity,
      productQuantityDetailsKey: productProcessedTransactions,
      productProfitKey: totalProfit,
      productProfitDetailsKey:
          _getOnlyProfitInvoices(productProcessedTransactions, 5),
      productTotalStockPriceKey: totalQuantity * product.buyingPrice,
    };
  }

  /// Creates a row for the initial product quantity.
  List<dynamic> _createInitialTransactionRow(
      BuildContext context, Product product) {
    final initialTransaction = _createInitialQuantityTransaction(product);
    return [
      initialTransaction,
      translateDbTextToScreenText(context, TransactionType.initialCredit.name),
      '',
      product.initialDate,
      product.initialQuantity,
      0,
      0
    ];
  }

  /// Processes the items within a single transaction for a specific product.
  List<List<dynamic>> _processTransactionItems(
      BuildContext context, Transaction transaction, String productDbRef) {
    List<List<dynamic>> processedItems = [];
    final type = transaction.transactionType;

    for (var item in transaction.items ?? []) {
      if (item['dbRef'] != productDbRef) continue;

      num totalQuantity = 0;
      num totalProfit = 0;
      num totalSalesmanCommission = 0;

      if (type == TransactionType.customerInvoice.name ||
          type == TransactionType.vendorReturn.name) {
        totalQuantity -=
            (item['soldQuantity'] ?? 0) + (item['giftQuantity'] ?? 0);
        totalProfit += item['itemTotalProfit'] ?? 0;
        totalSalesmanCommission += item['salesmanTotalCommission'] ?? 0;
      } else if (type == TransactionType.vendorInvoice.name ||
          type == TransactionType.customerReturn.name) {
        totalQuantity +=
            (item['soldQuantity'] ?? 0) + (item['giftQuantity'] ?? 0);
        if (type == TransactionType.customerReturn.name) {
          totalProfit -= item['itemTotalProfit'] ?? 0;
        }
      } else if (type == TransactionType.damagedItems.name) {
        totalQuantity -= item['soldQuantity'] ?? 0;
        totalProfit -= (item['soldQuantity'] ?? 0) * (item['buyingPrice'] ?? 0);
      } else {
        continue;
      }

      processedItems.add([
        transaction,
        translateDbTextToScreenText(context, type),
        '${transaction.number}',
        transaction.date,
        totalQuantity,
        totalProfit,
        totalSalesmanCommission
      ]);
    }
    return processedItems;
  }

  /// creates a temp transaction using product initial quantity, the transaction is used in the
  /// calculation of product qunaity
  Transaction _createInitialQuantityTransaction(Product product) {
    return Transaction(
        dbRef: 'na',
        name: 'na',
        imageUrls: ['na'],
        number: 1000001,
        date: product.initialDate,
        currency: 'na',
        transactionType: TransactionType.initialCredit.name,
        totalAmount: double.parse(product.initialQuantity.toString()),
        transactionTotalProfit: 0,
        isPrinted: false);
  }

  List<dynamic> _getProductTotals(List<List<dynamic>> productTransactions) {
    num totalQuantity = 0;
    num totalProfit = 0.0;
    num totalSalesmanCommission = 0.0;
    for (var transaction in productTransactions) {
      totalQuantity += transaction[4];
      totalProfit += transaction[5];
      totalSalesmanCommission += transaction[6];
    }
    return [totalQuantity, totalProfit, totalSalesmanCommission];
  }

  List<List<dynamic>> _getOnlyProfitInvoices(
      List<List<dynamic>> processedTransactions, int profitIndex) {
    List<List<dynamic>> result = [];
    for (var innerList in processedTransactions) {
      if (innerList.length > profitIndex && innerList[profitIndex] != 0) {
        result.add(List.from(innerList));
      }
    }
    return result;
  }
}
