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

final productScreenControllerProvider = Provider<ProductScreenController>((ref) {
  final screenDataNotifier = ref.read(productScreenDataNotifier.notifier);
  final transactionsDbCache = ref.read(transactionDbCacheProvider.notifier);
  final productDbCache = ref.read(productDbCacheProvider.notifier);
  return ProductScreenController(screenDataNotifier, transactionsDbCache, productDbCache);
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
    List<Map<String, dynamic>> screenData = [];
    for (var productData in allProductsData) {
      final newRow = getItemScreenData(context, productData);
      screenData.add(newRow);
    }
    Map<String, dynamic> summaryTypes = {
      productTotalStockPriceKey: 'sum',
    };
    _screenDataNotifier.initialize(summaryTypes);
    _screenDataNotifier.set(screenData);
  }

  /// create a list of lists, where each resulting list contains transaction info
  /// [type, number, date, totalQuantity, totalProfit, totalSalesmanCommission, ]
  @override
  Map<String, dynamic> getItemScreenData(BuildContext context, Map<String, dynamic> productData) {
    final product = Product.fromMap(productData);
    List<List<dynamic>> productProcessedTransactions = [];
    if (product.initialQuantity > 0) {
      final initialTransaction = _createInitialQuantityTransaction(product);
      productProcessedTransactions.add([
        initialTransaction,
        translateDbTextToScreenText(context, TransactionType.initialCredit.name),
        '',
        product.initialDate,
        product.initialQuantity,
        0,
        0
      ]);
    }
    final transactions = _transactionsDbCache.data;
    for (var transactionMap in transactions) {
      // below type conversion were done after changing from web to windows,
      // the error was int are not acceptable as doubles
      transactionMap.forEach((key, value) {
        if (transactionMap[key] is int) {
          transactionMap[key] = transactionMap[key].toDouble();
        }
      });
      transactionMap['number'] = transactionMap['number'].toInt();
      // end of conversion
      Transaction transaction = Transaction.fromMap(transactionMap);

      String type = transaction.transactionType;
      String number = '${transaction.number}';
      DateTime date = transaction.date;
      for (var item in transaction.items ?? []) {
        num totalQuantity = 0;
        num totalProfit = 0;
        num totalSalesmanCommission = 0;
        if (item['dbRef'] != product.dbRef) continue;
        if (type == TransactionType.customerInvoice.name ||
            type == TransactionType.vendorReturn.name) {
          totalQuantity -= item['soldQuantity'];
          totalQuantity -= item['giftQuantity'];
          totalProfit += item['itemTotalProfit'] ?? 0;
          totalSalesmanCommission += item['salesmanTotalCommission'] ?? 0;
        } else if (type == TransactionType.vendorInvoice.name ||
            type == TransactionType.customerReturn.name) {
          totalQuantity += item['soldQuantity'];
          totalQuantity += item['giftQuantity'];
          if (type == TransactionType.customerReturn.name) {
            totalProfit -= item['itemTotalProfit'] ?? 0;
          }
        } else if (type == TransactionType.damagedItems.name) {
          totalQuantity -= item['soldQuantity'];
          totalProfit -= (item['soldQuantity'] ?? 0) * (item['buyingPrice'] ?? 0);
        } else {
          continue;
        }
        List<dynamic> transactionDetails = [
          transaction,
          translateDbTextToScreenText(context, type),
          number,
          date,
          totalQuantity,
          totalProfit,
          totalSalesmanCommission
        ];
        productProcessedTransactions.add(transactionDetails);
      }
    }
    sortListOfListsByDate(productProcessedTransactions, 3);
    final productTotals = _getProductTotals(productProcessedTransactions);
    Map<String, dynamic> newDataRow = {
      productDbRefKey: product.dbRef,
      productCodeKey: product.code,
      productNameKey: product.name,
      productCategoryKey: product.category,
      productCommissionKey: product.salesmanCommission,
      productSellingWholeSaleKey: product.sellRetailPrice,
      productSellingRetailKey: product.sellWholePrice,
      productBuyingPriceKey: product.buyingPrice,
      productQuantityKey: productTotals[0],
      productQuantityDetailsKey: productProcessedTransactions,
      productProfitKey: productTotals[1],
      productProfitDetailsKey: _getOnlyProfitInvoices(productProcessedTransactions, 5),
      productTotalStockPriceKey: productTotals[0] * product.buyingPrice,
    };
    return newDataRow;
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
