import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/interfaces/screen_controller.dart';
import 'package:tablets/src/common/providers/screen_data_notifier.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/features/customers/controllers/customer_screen_controller.dart';
import 'package:tablets/src/features/customers/controllers/customer_screen_controller.dart'
    as cust;
import 'package:tablets/src/features/customers/controllers/customer_screen_data_notifier.dart';
import 'package:tablets/src/features/customers/model/customer.dart';
import 'package:tablets/src/features/customers/repository/customer_db_cache_provider.dart';
import 'package:tablets/src/features/products/model/product.dart';
import 'package:tablets/src/features/products/repository/product_db_cache_provider.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_screen_data_notifier.dart';
import 'package:tablets/src/features/salesmen/model/salesman.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_controller.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';

// --- Constants ---
const salesmanDbRefKey = 'dbRef';
const salesmanNameKey = 'name';
const commissionKey = 'commission';
const customersKey = 'customers';
const customersDetailsKey = 'customersDetails';
const commissionDetailsKey = 'salaryDetails';
const totalDebtsKey = 'debts';
const dueDbetsKey = 'dueDebts';
const debtsDetailsKey = 'totalDebtDetails';
const openInvoicesKey = 'openInvoices';
const openInvoicesDetailsKey = 'openInvoicesDetails';
const dueInvoicesKey = 'dueInvoices';
const profitKey = 'profit';
const profitDetailsKey = 'profitDetails';
const numInvoicesKey = 'numInvoices';
const invoicesKey = 'numInvoicesDetails';
const numReceiptsKey = 'numReceipts';
const receiptsKey = 'numReceiptsDetails';
const invoicesAmountKey = 'invoicesAmount';
const receiptsAmountKey = 'receiptsAmount';
const numReturnsKey = 'numReturns';
const returnsKey = 'numReturnsDetails';
const returnsAmountKey = 'returnsAmount';

// --- Provider ---
final salesmanScreenControllerProvider =
    Provider<SalesmanScreenController>((ref) {
  final transactionDbCache = ref.read(transactionDbCacheProvider.notifier);
  final salesmanDbCache = ref.read(salesmanDbCacheProvider.notifier);
  final customerDbCache = ref.read(customerDbCacheProvider.notifier);
  final screenDataNotifier = ref.read(salesmanScreenDataNotifier.notifier);
  final customerScreenController = ref.read(customerScreenControllerProvider);
  final customersScreenDataNotifier =
      ref.read(customerScreenDataNotifier.notifier);
  final productDbCache = ref.read(productDbCacheProvider.notifier);
  return SalesmanScreenController(
      screenDataNotifier,
      transactionDbCache,
      salesmanDbCache,
      customerDbCache,
      customerScreenController,
      customersScreenDataNotifier,
      productDbCache);
});

// --- Data Payload for Isolate ---
class _SalesmanDataPayload {
  final List<Map<String, dynamic>> allSalesmenData;
  final Map<String, List<Customer>> allSalesmenCustomers;
  final Map<String, List<Transaction>> allSalesmenTransactions;
  final Map<String, Map<String, dynamic>> customerDebtInfoMap;
  final Map<String, String> translations;
  final Set<String> hiddenProductDbRefs;

  _SalesmanDataPayload({
    required this.allSalesmenData,
    required this.allSalesmenCustomers,
    required this.allSalesmenTransactions,
    required this.customerDebtInfoMap,
    required this.translations,
    required this.hiddenProductDbRefs,
  });
}

class SalesmanScreenController implements ScreenDataController {
  SalesmanScreenController(
    this._screenDataNotifier,
    this._transactionDbCache,
    this._salesmanDbCache,
    this._customerDbCache,
    this._customerScreenController,
    this._customerScreenDataNotifier,
    this._productDbCache,
  );
  final ScreenDataNotifier _screenDataNotifier;
  final DbCache _transactionDbCache;
  final DbCache _salesmanDbCache;
  final DbCache _customerDbCache;
  final CustomerScreenController _customerScreenController;
  final ScreenDataNotifier _customerScreenDataNotifier;
  final DbCache _productDbCache;

  @override
  Future<void> setFeatureScreenData(BuildContext context) async {
    _customerScreenController.setFeatureScreenData(context);

    final allSalesmenData = _salesmanDbCache.data;
    final allSalesmenCustomers = _getSalesmenCustomers();
    final allSalesmenTransactions = _getSalesmenTransactions();

    final allCustomerDbRefs = allSalesmenCustomers.values
        .expand((customers) => customers.map((c) => c.dbRef))
        .toSet();
    final customerDebtInfoMap = <String, Map<String, dynamic>>{};
    for (var dbRef in allCustomerDbRefs) {
      final screenData = _customerScreenDataNotifier.getItem(dbRef);
      if (screenData.isNotEmpty) {
        customerDebtInfoMap[dbRef] = screenData;
      }
    }

    final translations = {
      TransactionType.customerInvoice.name: translateDbTextToScreenText(
          context, TransactionType.customerInvoice.name),
      TransactionType.customerReceipt.name: translateDbTextToScreenText(
          context, TransactionType.customerReceipt.name),
      TransactionType.customerReturn.name: translateDbTextToScreenText(
          context, TransactionType.customerReturn.name),
    };

    // Prepare hidden products data for the isolate
    final hiddenProductDbRefs = _productDbCache.data
        .where((p) => Product.fromMap(p).isHiddenInSpecialReports == true)
        .map<String>((p) => p['dbRef'] as String)
        .toSet();

    final payload = _SalesmanDataPayload(
      allSalesmenData: allSalesmenData,
      allSalesmenCustomers: allSalesmenCustomers,
      allSalesmenTransactions: allSalesmenTransactions,
      customerDebtInfoMap: customerDebtInfoMap,
      translations: translations,
      hiddenProductDbRefs: hiddenProductDbRefs,
    );

    final screenData = kIsWeb
        ? _processSalesmanDataInIsolate(payload)
        : await Isolate.run(() => _processSalesmanDataInIsolate(payload));

    Map<String, dynamic> summaryTypes = {
      commissionKey: 'sum',
      profitKey: 'sum'
    };
    _screenDataNotifier.initialize(summaryTypes);
    _screenDataNotifier.set(screenData);
  }

  Map<String, List<Customer>> _getSalesmenCustomers() {
    Map<String, List<Customer>> salesmenMap = {};
    for (var salesman in _salesmanDbCache.data) {
      salesmenMap[salesman['dbRef']] = [];
    }
    for (var customer in _customerDbCache.data) {
      if (salesmenMap.containsKey(customer['salesmanDbRef'])) {
        salesmenMap[customer['salesmanDbRef']]?.add(Customer.fromMap(customer));
      }
    }
    return salesmenMap;
  }

  Map<String, List<Transaction>> _getSalesmenTransactions() {
    Map<String, List<Transaction>> salesmenMap = {};
    for (var salesman in _salesmanDbCache.data) {
      salesmenMap[salesman['dbRef']] = [];
    }
    for (var transaction in _transactionDbCache.data) {
      if (salesmenMap.containsKey(transaction['salesmanDbRef'])) {
        salesmenMap[transaction['salesmanDbRef']]
            ?.add(Transaction.fromMap(transaction));
      }
    }
    return salesmenMap;
  }

  // FIXED: This method is now restored to the class to resolve the error.
  // It calls the static version of the logic.
  Map<String, dynamic> getCustomersInfo(
    List<Customer> salesmanCustomers,
    List<Transaction> salesmanTransactions, {
    bool isSuperVisor = false,
    WidgetRef? ref, // WidgetRef is used here for provider access
  }) {
    Set<String> hiddenProductDbRefs = {};
    if (isSuperVisor && ref != null) {
      final productDbCache = ref.read(productDbCacheProvider.notifier);
      hiddenProductDbRefs = productDbCache.data
          .where((p) => Product.fromMap(p).isHiddenInSpecialReports == true)
          .map<String>((p) => p['dbRef'] as String)
          .toSet();
    }
    // Delegate to the static method
    return SalesmanScreenController._getCustomersInfo(
        salesmanCustomers, salesmanTransactions, hiddenProductDbRefs);
  }

  // --- Static methods for Isolate processing ---
  // These are now static so they belong to the class but don't need an instance.
  // This allows them to be called from an Isolate.

  static List<Map<String, dynamic>> _processSalesmanDataInIsolate(
      _SalesmanDataPayload payload) {
    final screenData = <Map<String, dynamic>>[];
    for (var salesmanData in payload.allSalesmenData) {
      final salesmanDbRef = salesmanData['dbRef'];
      final salesmanCustomers =
          payload.allSalesmenCustomers[salesmanDbRef] ?? [];
      final salesmanTransactions =
          payload.allSalesmenTransactions[salesmanDbRef] ?? [];

      final newRow = _getSalesmanScreenData(
        salesmanData,
        salesmanCustomers,
        salesmanTransactions,
        payload.customerDebtInfoMap,
        payload.translations,
        payload.hiddenProductDbRefs,
      );
      screenData.add(newRow);
    }
    return screenData;
  }

  static Map<String, dynamic> _getSalesmanScreenData(
      Map<String, dynamic> salesmanData,
      List<Customer> salesmanCustomers,
      List<Transaction> salesmanTransactions,
      Map<String, Map<String, dynamic>> customerDebtInfoMap,
      Map<String, String> translations,
      Set<String> hiddenProductDbRefs) {
    salesmanData['salary'] = salesmanData['salary'].toDouble();
    final salesman = Salesman.fromMap(salesmanData);
    final customersInfo = _getCustomersInfo(
        salesmanCustomers, salesmanTransactions, hiddenProductDbRefs);
    final customersBasicData =
        customersInfo['customersData'] as List<List<dynamic>>;
    final customersDbRef = customersInfo['customersDbRef'] as List<String>;
    final customersDebtInfo =
        _getCustomersDebtInfo(customersDbRef, customerDebtInfoMap);

    final processedTransactionsMap =
        _getProcessedTransactions(salesmanTransactions, translations);

    final invoices = _getInvoices(processedTransactionsMap, 'invoicesList');
    final receipts = _getInvoices(processedTransactionsMap, 'reciptsList');
    final returns = _getInvoices(processedTransactionsMap, 'returnsList');
    final profits = _getProfitableInvoices(processedTransactionsMap);
    final commissions = _getCommissions(processedTransactionsMap);

    return {
      salesmanDbRefKey: salesman.dbRef,
      salesmanNameKey: salesman.name,
      commissionKey: sumAtIndex(commissions, 7),
      commissionDetailsKey: commissions,
      customersKey: salesmanCustomers.length,
      customersDetailsKey: customersBasicData,
      totalDebtsKey: customersDebtInfo[totalDebtsKey],
      debtsDetailsKey: customersDebtInfo[debtsDetailsKey],
      openInvoicesKey: customersDebtInfo[openInvoicesKey],
      openInvoicesDetailsKey: customersDebtInfo[openInvoicesDetailsKey],
      profitKey: sumAtIndex(profits, 7),
      profitDetailsKey: profits,
      numInvoicesKey: invoices.length,
      invoicesKey: invoices,
      numReceiptsKey: receipts.length,
      receiptsKey: receipts,
      invoicesAmountKey: sumAtIndex(invoices, 7),
      receiptsAmountKey: sumAtIndex(receipts, 7),
      numReturnsKey: returns.length,
      returnsKey: returns,
      returnsAmountKey: sumAtIndex(returns, 7),
      dueDbetsKey: customersDebtInfo[dueDbetsKey],
      dueInvoicesKey: customersDebtInfo[dueInvoicesKey],
    };
  }

  static Map<String, dynamic> _getCustomersInfo(
      List<Customer> salesmanCustomers,
      List<Transaction> salesmanTransactions,
      Set<String> hiddenProductDbRefs) {
    final customerTransactionInfo = <String, Map<String, num>>{};
    for (final trans in salesmanTransactions) {
      if (trans.nameDbRef == null) continue;
      if (trans.transactionType != TransactionType.customerInvoice.name &&
          trans.transactionType != TransactionType.customerReturn.name) {
        continue;
      }

      final info = customerTransactionInfo.putIfAbsent(
          trans.nameDbRef!, () => {'numInvoices': 0, 'numItems': 0});
      if (trans.transactionType == TransactionType.customerInvoice.name) {
        info['numInvoices'] = info['numInvoices']! + 1;
      }

      final items = trans.items ?? [];
      for (final item in items) {
        // FIXED: Restore supervisor logic using the pre-fetched set of hidden products.
        final productDbRef = item['dbRef'];
        if (hiddenProductDbRefs.contains(productDbRef)) {
          continue;
        }

        final quantity = item[itemSoldQuantityKey] ?? 0;
        info['numItems'] = info['numItems']! +
            (trans.transactionType == TransactionType.customerInvoice.name
                ? quantity
                : -quantity);
      }
    }

    final customerData = <List<dynamic>>[];
    final customerDbRef = <String>[];
    for (final customer in salesmanCustomers) {
      final info = customerTransactionInfo[customer.dbRef] ??
          {'numInvoices': 0, 'numItems': 0};
      customerData.add([
        customer.name,
        customer.region,
        customer.phone,
        info['numInvoices'],
        info['numItems']
      ]);
      customerDbRef.add(customer.dbRef);
    }
    customerData.sort((a, b) => (a[1] as String).compareTo(b[1] as String));

    return {'customersDbRef': customerDbRef, 'customersData': customerData};
  }

  static Map<String, dynamic> _getCustomersDebtInfo(List<String> dbRefList,
      Map<String, Map<String, dynamic>> customerDebtInfoMap) {
    double totalDebt = 0, dueDebt = 0, openInvoices = 0, dueInvoices = 0;
    List<List<dynamic>> debtsDetails = [], invoicesDetails = [];
    for (var dbRef in dbRefList) {
      final screenData = customerDebtInfoMap[dbRef];
      if (screenData == null || screenData.isEmpty) continue;

      final customerName = screenData[cust.customerNameKey] ?? '';
      final customerTotalDebt = screenData[cust.totalDebtKey] ?? 0.0;
      final customerDueDebt = screenData[cust.dueDebtKey] ?? 0.0;
      final customerOpenInvoices = screenData[cust.openInvoicesKey] ?? 0.0;
      final customerDueInvoices = screenData[cust.dueInvoicesKey] ?? 0.0;

      totalDebt += customerTotalDebt;
      dueDebt += customerDueDebt;
      openInvoices += customerOpenInvoices;
      dueInvoices += customerDueInvoices;
      debtsDetails.add([customerName, customerTotalDebt, customerDueDebt]);
      invoicesDetails
          .add([customerName, customerOpenInvoices, customerDueInvoices]);
    }
    return {
      totalDebtsKey: totalDebt,
      dueDbetsKey: dueDebt,
      openInvoicesKey: openInvoices,
      dueInvoicesKey: dueInvoices,
      debtsDetailsKey: sortListOfListsByNumber(debtsDetails, 1),
      openInvoicesDetailsKey: sortListOfListsByNumber(invoicesDetails, 1)
    };
  }

  static Map<String, List<List<dynamic>>> _getProcessedTransactions(
      List<Transaction> salesmanTransactions,
      Map<String, String> translations) {
    List<List<dynamic>> invoicesList = [], receiptsList = [], returnsList = [];
    for (var t in salesmanTransactions) {
      final processed = [
        t,
        translations[t.transactionType] ?? t.transactionType,
        t.date,
        t.name,
        t.number,
        t.subTotalAmount,
        t.discount,
        t.totalAmount,
        t.transactionTotalProfit,
        t.salesmanTransactionComssion
      ];
      if (t.transactionType == TransactionType.customerInvoice.name) {
        invoicesList.add(processed);
      } else if (t.transactionType == TransactionType.customerReceipt.name) {
        receiptsList.add(processed);
      } else if (t.transactionType == TransactionType.customerReturn.name) {
        processed[8] = -1 * ((processed[8] ?? 0.0) as double);
        processed[9] = -1 * ((processed[9] ?? 0.0) as double);
        returnsList.add(processed);
      }
    }
    return {
      'invoicesList': invoicesList,
      'reciptsList': receiptsList,
      'returnsList': returnsList
    };
  }

  static List<List<dynamic>> _getInvoices(
      Map<String, List<List<dynamic>>> map, String name) {
    final transactions = map[name] ?? [];
    return transactions.isEmpty
        ? []
        : trimLastXIndicesFromInnerLists(transactions, 2);
  }

  static List<List<dynamic>> _getProfitableInvoices(
      Map<String, List<List<dynamic>>> map) {
    final invoices = map['invoicesList'] ?? [];
    final returns = map['returnsList'] ?? [];
    return invoices.isEmpty && returns.isEmpty
        ? []
        : removeIndicesFromInnerLists([...invoices, ...returns], [7, 9]);
  }

  static List<List<dynamic>> _getCommissions(
      Map<String, List<List<dynamic>>> map) {
    final invoices = map['invoicesList'] ?? [];
    final returns = map['returnsList'] ?? [];
    return invoices.isEmpty && returns.isEmpty
        ? []
        : removeIndicesFromInnerLists([...invoices, ...returns], [7, 8]);
  }

  // --- Instance method to calculate screen data for a single salesman ---
  @override
  Map<String, dynamic> getItemScreenData(
      BuildContext context, Map<String, dynamic> salesmanData) {
    // First, ensure customer screen data is calculated (salesman depends on it)
    _customerScreenController.setFeatureScreenData(context);

    final salesman = Salesman.fromMap(salesmanData);

    // Get this salesman's customers
    final salesmanCustomers = _customerDbCache.data
        .where((c) => c['salesmanDbRef'] == salesman.dbRef)
        .map((c) => Customer.fromMap(c))
        .toList();

    // Get this salesman's transactions
    final salesmanTransactions = _transactionDbCache.data
        .where((t) => t['salesmanDbRef'] == salesman.dbRef)
        .map((t) => Transaction.fromMap(t))
        .toList();

    // Build customer debt info map from the customer screen data notifier
    final customerDebtInfoMap = <String, Map<String, dynamic>>{};
    for (var customer in salesmanCustomers) {
      final screenData = _customerScreenDataNotifier.getItem(customer.dbRef);
      if (screenData.isNotEmpty) {
        customerDebtInfoMap[customer.dbRef] = screenData;
      }
    }

    // Build translations
    final translations = {
      TransactionType.customerInvoice.name: translateDbTextToScreenText(
          context, TransactionType.customerInvoice.name),
      TransactionType.customerReceipt.name: translateDbTextToScreenText(
          context, TransactionType.customerReceipt.name),
      TransactionType.customerReturn.name: translateDbTextToScreenText(
          context, TransactionType.customerReturn.name),
    };

    // Get hidden product dbRefs
    final hiddenProductDbRefs = _productDbCache.data
        .where((p) => Product.fromMap(p).isHiddenInSpecialReports == true)
        .map<String>((p) => p['dbRef'] as String)
        .toSet();

    // Use the existing static method to calculate the screen data
    return _getSalesmanScreenData(
      salesmanData,
      salesmanCustomers,
      salesmanTransactions,
      customerDebtInfoMap,
      translations,
      hiddenProductDbRefs,
    );
  }

  List<Map<String, dynamic>> filterTransactions(
      List<Map<String, dynamic>> allTransactions,
      DateTime? startDate,
      DateTime? endDate,
      String salesmanDbRef) {
    return allTransactions.where((transaction) {
      DateTime transactionDate = transaction['date'] is DateTime
          ? transaction['date']
          : transaction['date'].toDate();
      bool isAfterStartDate =
          startDate == null || !transactionDate.isBefore(startDate);
      bool isBeforeEndDate =
          endDate == null || !transactionDate.isAfter(endDate);
      return salesmanDbRef == transaction['salesmanDbRef'] &&
          isAfterStartDate &&
          isBeforeEndDate;
    }).toList();
  }

  List<List<dynamic>> salesmanItemsSold(String salesmanDbRef,
      DateTime? startDate, DateTime? endDate, WidgetRef ref) {
    final productDbCache = ref.read(productDbCacheProvider.notifier);
    List<Map<String, dynamic>> fliteredTransactions = filterTransactions(
        _transactionDbCache.data, startDate, endDate, salesmanDbRef);
    Map<String, Map<String, num>> summary = {};
    for (var transaction in fliteredTransactions) {
      final items = transaction[itemsKey];
      if (items == null) continue;
      for (var item in transaction[itemsKey]) {
        String itemName = item[itemNameKey];
        num soldQuantity = 0, giftQuantity = 0, returnedQuanity = 0;
        if (transaction[transactionTypeKey] ==
            TransactionType.customerInvoice.name) {
          soldQuantity = item[itemSoldQuantityKey] ?? 0;
          giftQuantity = item[itemGiftQuantityKey] ?? 0;
        } else if (transaction[transactionTypeKey] ==
            TransactionType.customerReturn.name) {
          returnedQuanity = item[itemSoldQuantityKey] ?? 0;
        }
        summary.putIfAbsent(
            itemName,
            () => {
                  itemSoldQuantityKey: 0,
                  itemGiftQuantityKey: 0,
                  'returnedQuantity': 0
                });
        summary[itemName]![itemSoldQuantityKey] =
            summary[itemName]![itemSoldQuantityKey]! + soldQuantity;
        summary[itemName]![itemGiftQuantityKey] =
            summary[itemName]![itemGiftQuantityKey]! + giftQuantity;
        summary[itemName]!['returnedQuantity'] =
            summary[itemName]!['returnedQuantity']! + returnedQuanity;
      }
    }
    List<List<dynamic>> result = [];
    summary.forEach((itemName, quantities) {
      final product = productDbCache.getItemByProperty('name', itemName);
      if (product.isNotEmpty) {
        final commission = product['salesmanCommission'];
        final netQuantity =
            quantities[itemSoldQuantityKey]! - quantities['returnedQuantity']!;
        result.add([
          itemName,
          quantities[itemSoldQuantityKey],
          quantities[itemGiftQuantityKey],
          quantities['returnedQuantity'],
          netQuantity,
          commission,
          commission * netQuantity
        ]);
      } else {
        errorPrint('product $itemName not found in dbCacche');
      }
    });
    return result;
  }
}
