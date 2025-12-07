import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/interfaces/screen_controller.dart';
import 'package:tablets/src/common/providers/screen_data_notifier.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/features/customers/controllers/customer_screen_data_notifier.dart';
import 'package:tablets/src/features/customers/repository/customer_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/features/customers/model/customer.dart';

const customerDbRefKey = 'dbRef';
const customerNameKey = 'name';
const customerSalesmanKey = 'salesman';
const customerRegionKey = 'region';
const totalDebtKey = 'totalDebt';
const totalDebtDetailsKey = 'totalDebtDetails';
const openInvoicesKey = 'openInvoices';
const openInvoicesDetailsKey = 'openInvoicesDetails';
const dueInvoicesKey = 'dueInvoices';
const dueDebtKey = 'dueDebt';
const dueDebtDetailsKey = 'dueDebtDetails';
const avgClosingDaysKey = 'avgClosingDays';
const avgClosingDaysDetailsKey = 'avgClosingDaysDetails';
const invoicesProfitKey = 'invoicesProfit';
const invoicesProfitDetailsKey = 'invoicesProfitDetails';
const giftsKey = 'gifts';
const giftsDetailsKey = 'giftsDetails';
const inValidUserKey = 'inValid';

final customerScreenControllerProvider =
    Provider<CustomerScreenController>((ref) {
  final transactionDbCache = ref.read(transactionDbCacheProvider.notifier);
  final screenDataNotifier = ref.read(customerScreenDataNotifier.notifier);
  final customerDbCache = ref.read(customerDbCacheProvider.notifier);
  return CustomerScreenController(
      screenDataNotifier, transactionDbCache, customerDbCache);
});

class CustomerScreenController implements ScreenDataController {
  CustomerScreenController(
    this._screenDataNotifier,
    this._transactionDbCache,
    this._customerDbCache,
  );
  final ScreenDataNotifier _screenDataNotifier;
  final DbCache _transactionDbCache;
  final DbCache _customerDbCache;

  @override
  void setFeatureScreenData(BuildContext context) {
    final allCustomersData = _customerDbCache.data;
    List<Map<String, dynamic>> screenData = [];
    final allCustomersTransactions = _getAllCustomersTransactions();
    for (var customerData in allCustomersData) {
      final customerDbRef = customerData['dbRef'];
      final customerTransactions = allCustomersTransactions[customerDbRef]!;
      final newRow = getItemScreenData(context, customerData,
          customerTransactions: customerTransactions);
      screenData.add(newRow);
    }
    Map<String, dynamic> summaryTypes = {
      totalDebtKey: 'sum',
      openInvoicesKey: 'sum',
      dueInvoicesKey: 'sum',
      dueDebtKey: 'sum',
      avgClosingDaysKey: 'avg',
      invoicesProfitKey: 'sum',
      giftsKey: 'sum',
    };
    _screenDataNotifier.initialize(summaryTypes);
    _screenDataNotifier.set(screenData);
  }

  /// create a map, its keys are salesman dbRef, and value is a list of all customers belong the the
  /// salesman, this will be used later for fetching salesman's custoemrs. this idea is used to avoid
  /// going throught the list of customers for every salesman to get his customers (performance
  /// imporvement)
  Map<String, List<Map<String, dynamic>>> _getAllCustomersTransactions() {
    // first initialize empty map with empty list for each customer dbRef
    Map<String, List<Map<String, dynamic>>> customersMap = {};
    for (var customer in _customerDbCache.data) {
      final customerDbRef = customer['dbRef'];
      customersMap[customerDbRef] = [];
    }
    // add transactions to their customer
    final allTransactions = _transactionDbCache.data;
    for (var transaction in allTransactions) {
      // only add transactions for customers (discard other transactions)
      if (customersMap.containsKey(transaction['nameDbRef'])) {
        customersMap[transaction['nameDbRef']]!.add(transaction);
      }
    }
    return customersMap;
  }

  /// if customerTransactions provided, it will not calculate it
  /// I made that design decision because this method is called in two different cases
  /// one case is when the feature screen is loaded, in this case we need to calculate customer
  /// screen data for all customers, so we will not loop through all transactions for every customer
  /// because it is bad in performance, and we will divide transactions between all customers in
  /// one loop by using getAllCustomersTransactions method
  /// the second case is when a specific customer is needed by other features, for example when
  /// checking customer validity in new transaction, in this case we don't provide customer
  /// transactions and calculate them inside this functions
  @override
  Map<String, dynamic> getItemScreenData(
      BuildContext context, Map<String, dynamic> customerData,
      {List<Map<String, dynamic>>? customerTransactions}) {
    final customer = Customer.fromMap(customerData);
    // Use a copy to avoid modifying the original cache
    List<Map<String, dynamic>> localCustomerTransactions =
        List<Map<String, dynamic>>.from(
            customerTransactions ?? getCustomerTransactions(customer.dbRef));

    if (customer.initialCredit > 0) {
      localCustomerTransactions.add(_createInitialDebtTransaction(customer));
    }

    // *** OPTIMIZATION: All invoice processing is now consolidated into one function call ***
    final invoiceMetrics = processAndCategorizeInvoices(
        context, localCustomerTransactions, customer);

    // These functions have distinct logic and are kept separate for clarity.
    final matchingList = customerMatching(context, localCustomerTransactions);
    final giftTransactions =
        _getGiftsAndDiscounts(context, localCustomerTransactions);

    // Calculations using the results from the optimized functions
    final totalDebt = matchingList.isEmpty
        ? 0.0
        : matchingList.map((item) => item[4] as double).reduce((a, b) => a + b);
    final totalGiftsAmount = _getTotalGiftsAndDiscounts(giftTransactions, 4);
    final inValidCustomer =
        _inValidCustomer(invoiceMetrics.dueDebt, totalDebt, customer);

    // Calculate lastReceiptDate and lastInvoiceDate for salesman mobile app
    DateTime? lastReceiptDate;
    DateTime? lastInvoiceDate;
    for (var tx in localCustomerTransactions) {
      final txType = tx['transactionType'] as String?;
      final txDate = tx['date'];
      if (txDate == null) continue;

      final date = txDate is DateTime ? txDate : txDate.toDate();

      if (txType == TransactionType.customerReceipt.name) {
        if (lastReceiptDate == null || date.isAfter(lastReceiptDate)) {
          lastReceiptDate = date;
        }
      } else if (txType == TransactionType.customerInvoice.name) {
        if (lastInvoiceDate == null || date.isAfter(lastInvoiceDate)) {
          lastInvoiceDate = date;
        }
      }
    }

    // Assemble the final data row
    Map<String, dynamic> newDataRow = {
      openInvoicesKey: invoiceMetrics.openInvoices.length,
      openInvoicesDetailsKey: invoiceMetrics.openInvoices,
      dueInvoicesKey: invoiceMetrics.dueInvoices.length,
      totalDebtKey: totalDebt,
      totalDebtDetailsKey: matchingList,
      invoicesProfitKey: invoiceMetrics.totalProfit,
      invoicesProfitDetailsKey: invoiceMetrics.invoicesWithProfit,
      avgClosingDaysKey: invoiceMetrics.averageClosingDays,
      avgClosingDaysDetailsKey: invoiceMetrics.closedInvoices,
      dueDebtKey: invoiceMetrics.dueDebt,
      dueDebtDetailsKey: invoiceMetrics.dueInvoices,
      giftsKey: totalGiftsAmount,
      giftsDetailsKey: giftTransactions,
      inValidUserKey: inValidCustomer,
      customerDbRefKey: customer.dbRef,
      customerNameKey: customer.name,
      customerSalesmanKey: customer.salesman,
      // New fields for salesman mobile app
      'lastReceiptDate': lastReceiptDate,
      'lastInvoiceDate': lastInvoiceDate,
    };
    return newDataRow;
  }

  /// creates a temp transaction using customer initial debt, the transaction is used in the
  /// calculation of customer debt
  Map<String, dynamic> _createInitialDebtTransaction(Customer customer) {
    return Transaction(
      dbRef: 'na',
      name: customer.name,
      imageUrls: ['na'],
      number: 1000001,
      date: customer.initialDate,
      currency: 'na',
      transactionType: TransactionType.initialCredit.name,
      totalAmount: customer.initialCredit,
      transactionTotalProfit: 0,
      isPrinted: false,
    ).toMap();
  }

  /// we stop transactions if customer either exceeded limit of debt, or has dueDebt
  /// which is transactions that are not closed within allowed time (for example 20 days)
  bool _inValidCustomer(double dueDebt, double totalDebt, Customer customer) {
    return totalDebt > customer.creditLimit || dueDebt > 0;
  }

  /// takes dataRows and returns a map of summaries for desired properties
  /// sumProperties are properties that will store sum
  /// avgProperties are properties that avgProperties are properties that will store average
  /// *** OPTIMIZATION: Loop is swapped to iterate the list once. ***
  Map<String, dynamic> sumProperties(List<Map<String, dynamic>> list,
      List<String> sumProperties, List<String> avgProperties) {
    Map<String, dynamic> result = {};
    // Initialize properties to 0
    for (var property in sumProperties) {
      result[property] = 0.0;
    }
    // Iterate list once and update all sums
    for (var item in list) {
      for (var property in sumProperties) {
        if (item.containsKey(property) && item[property] is num) {
          result[property] += item[property];
        }
      }
    }
    return result;
  }

  List<Map<String, dynamic>> getCustomerTransactions(String dbRef) {
    // Filter transactions for the given database reference
    final allTransactions = _transactionDbCache.data;
    List<Map<String, dynamic>> customerTransactions =
        allTransactions.where((item) => item['nameDbRef'] == dbRef).toList();

    sortMapsByProperty(customerTransactions, 'date');
    return customerTransactions;
  }

  List<List<dynamic>> customerMatching(
      BuildContext context, List<Map<String, dynamic>> customerTransactions) {
    List<List<dynamic>> matchingTransactions = [];
    final sortedTransactions = deepCopyDbCache(customerTransactions);
    sortedTransactions.sort((a, b) {
      final dateA = a['date'] is DateTime ? a['date'] : a['date'].toDate();
      final dateB = b['date'] is DateTime ? b['date'] : b['date'].toDate();
      return dateB.compareTo(dateA);
    });
    double startingDebt = 0;
    for (int i = sortedTransactions.length - 1; i >= 0; i--) {
      final transaction = Transaction.fromMap(sortedTransactions[i]);
      final transactionType = transaction.transactionType;
      if (transactionType == TransactionType.gifts.name) continue;
      double amountSign =
          (transactionType == TransactionType.customerReceipt.name ||
                  transactionType == TransactionType.customerReturn.name)
              ? -1
              : 1;
      final transactionAmount = transaction.totalAmount * amountSign;
      startingDebt = startingDebt + transactionAmount;
      matchingTransactions.add([
        transaction,
        translateDbTextToScreenText(context, transactionType),
        transaction.transactionType == TransactionType.initialCredit.name
            ? ''
            : transaction.number.toString(),
        transaction.date,
        transactionAmount,
        startingDebt,
      ]);
    }
    return matchingTransactions.toList();
  }

// filter transactions and keep only gifts and customerInvoices that contains a discount
// or gift items and return it in a list of lists, where each list contains
// [Transaction, num, type, date, amount]
  List<List<dynamic>> _getGiftsAndDiscounts(
      BuildContext context, List<Map<String, dynamic>> customerTransactions) {
    List<List<dynamic>> giftsAndDiscounts = [];
    for (var transactionMap in customerTransactions) {
      if (transactionMap['transactionType'] == TransactionType.gifts.name) {
        final transaction = Transaction.fromMap(transactionMap);
        giftsAndDiscounts.add([
          transaction,
          transaction.number,
          translateDbTextToScreenText(context, transaction.transactionType),
          transaction.date,
          transaction.transactionTotalProfit,
        ]);
      } else if (transactionMap['transactionType'] ==
          TransactionType.customerInvoice.name) {
        final transaction = Transaction.fromMap(transactionMap);
        final items = transaction.items;
        final discount = transaction.discount ?? 0;
        double giftItemsAmount = 0;
        for (var item in items ?? []) {
          giftItemsAmount += item['giftQuantity'] * item['buyingPrice'];
        }
        if (giftItemsAmount > 0 || discount > 0) {
          giftsAndDiscounts.add([
            transaction,
            transaction.number,
            translateDbTextToScreenText(context, transaction.transactionType),
            transaction.date,
            giftItemsAmount + discount,
          ]);
        }
      }
    }

    return sortListOfListsByDate(giftsAndDiscounts, 3);
  }

  double _getTotalGiftsAndDiscounts(
      List<List<dynamic>> giftsList, int amountIndex) {
    if (giftsList.isEmpty) return 0;
    return giftsList
        .map((item) => item[amountIndex] as double)
        .reduce((a, b) => a + b);
  }
}

// ----------------------------------------------------------------------
// below is a full code that process invoices & compares them to receipts
// it was generated by AI, I need to check it later
// ---------------------------------------------------------------------

/// Helper class for returning multiple values from the processing function.
class ProcessedInvoiceMetrics {
  final List<List<dynamic>> openInvoices;
  final List<List<dynamic>> dueInvoices;
  final List<List<dynamic>> closedInvoices;
  final List<List<dynamic>> invoicesWithProfit;
  final double dueDebt;
  final double totalProfit;
  final int averageClosingDays;

  ProcessedInvoiceMetrics({
    required this.openInvoices,
    required this.dueInvoices,
    required this.closedInvoices,
    required this.invoicesWithProfit,
    required this.dueDebt,
    required this.totalProfit,
    required this.averageClosingDays,
  });
}

class ReceiptUsed {
  String type;
  String number;
  DateTime date;
  double amount;
  double amountUsed;

  ReceiptUsed(this.type, this.number, this.date, this.amount, this.amountUsed);
}

class InvoiceInfo {
  String type;
  String number;
  DateTime date;
  double totalAmount;
  double amountLeft;
  String status;
  List<ReceiptUsed> receiptsUsed;
  Duration durationToClose;
  double profit;
  // store a copy of orignal tranasction to be used later to display a read only version of
  // the transaction
  Transaction originalTransaction;

  InvoiceInfo(
      this.type,
      this.number,
      this.date,
      this.totalAmount,
      this.amountLeft,
      this.status,
      this.receiptsUsed,
      this.durationToClose,
      this.profit,
      this.originalTransaction);
}

List<InvoiceInfo> processTransactions(List<Map<String, dynamic>> transactions) {
  List<Transaction> invoices = [];
  List<Transaction> receipts = [];
  for (var trans in transactions) {
    Transaction transaction = Transaction.fromMap(trans);
    if (transaction.transactionType == TransactionType.customerInvoice.name ||
        transaction.transactionType == TransactionType.initialCredit.name) {
      invoices.add(transaction);
    } else if (transaction.transactionType ==
            TransactionType.customerReceipt.name ||
        transaction.transactionType == TransactionType.customerReturn.name) {
      receipts.add(transaction);
    }
  }
  invoices.sort((a, b) => a.date.compareTo(b.date));
  receipts.sort((a, b) => a.date.compareTo(b.date));
  List<InvoiceInfo> result = [];
  double remainingAmount = 0;
  List<ReceiptUsed> usedReceipts = [];
  int receiptIndex = 0;
  for (var invoice in invoices) {
    remainingAmount = invoice.totalAmount;
    usedReceipts = [];
    DateTime lastReceiptDate = invoice.date; // Initialize to the invoice date
    final profit = invoice.transactionTotalProfit;
    while (remainingAmount > 0 && receiptIndex < receipts.length) {
      var receipt = receipts[receiptIndex];
      if (receipt.totalAmount > 0) {
        double amountToUse = (receipt.totalAmount >= remainingAmount)
            ? remainingAmount
            : receipt.totalAmount;
        usedReceipts.add(ReceiptUsed(
            receipt.transactionType,
            receipt.number.toString(),
            receipt.date,
            receipt.totalAmount,
            amountToUse));
        remainingAmount -= amountToUse;
        receipt.totalAmount -= amountToUse;
        lastReceiptDate = receipt.date;
        if (receipt.totalAmount <= 0) {
          receiptIndex++;
        }
      } else {
        receiptIndex++;
      }
    }
    String status = remainingAmount > 0 ? 'open' : 'closed';
    double amountLeft = remainingAmount > 0 ? remainingAmount : 0;
    Duration durationToClose = status == 'closed'
        ? lastReceiptDate.difference(invoice.date)
        : DateTime.now().difference(invoice.date);
    result.add(InvoiceInfo(
        invoice.transactionType,
        invoice.number.toString(),
        invoice.date,
        invoice.totalAmount,
        amountLeft,
        status,
        usedReceipts,
        durationToClose,
        profit,
        invoice));
  }
  return result;
}

/// *** NEW OPTIMIZED METHOD ***
/// This function replaces the old `getCustomerProcessedInvoices` and several other helper
/// methods by processing all invoice-related metrics in a single, efficient loop.
ProcessedInvoiceMetrics processAndCategorizeInvoices(BuildContext context,
    List<Map<String, dynamic>> transactions, Customer customer) {
  // Initialize accumulators and lists
  final List<List<dynamic>> openInvoicesDetails = [];
  final List<List<dynamic>> dueInvoicesDetails = [];
  final List<List<dynamic>> closedInvoicesDetails = [];
  final List<List<dynamic>> invoicesWithProfitDetails = [];
  double dueDebt = 0.0;
  double totalProfit = 0.0;
  int totalClosingDays = 0;

  // Use the existing AI-generated function to get structured invoice info
  final List<InvoiceInfo> processedInvoices = processTransactions(transactions);

  final String openStatus = S.of(context).invoice_status_open;
  final String dueStatus = S.of(context).invoice_status_due;
  final String closedStatus = S.of(context).invoice_status_closed;

  // *** SINGLE LOOP over all processed invoices ***
  for (var invoice in processedInvoices) {
    // Determine if an open invoice is now due
    if (invoice.status == InvoiceStatus.open.name &&
        invoice.durationToClose.inDays > customer.paymentDurationLimit) {
      invoice.status = InvoiceStatus.due.name;
    }
    final String status = translateDbTextToScreenText(context, invoice.status);

    // Build receipt info string
    String receiptInfo = '';
    for (var i = 0; i < invoice.receiptsUsed.length; i++) {
      final receipt = invoice.receiptsUsed[i];
      final receiptType = translateDbTextToScreenText(context, receipt.type);
      final receiptDate = formatDate(receipt.date);
      receiptInfo +=
          '$receiptType (${receipt.number}) $receiptDate (${doubleToStringWithComma(receipt.amountUsed)}) ';
      if (i + 1 < invoice.receiptsUsed.length) {
        receiptInfo += '\n';
      }
    }

    // Create the detailed rows for display lists
    final invoiceRowWithoutProfit = [
      invoice.originalTransaction,
      invoice.type == TransactionType.initialCredit.name ? '' : invoice.number,
      invoice.date,
      invoice.totalAmount,
      receiptInfo,
      status,
      invoice.durationToClose.inDays,
      invoice.amountLeft,
    ];

    // 1. Categorize invoices and update aggregates
    if (status == openStatus || status == dueStatus) {
      openInvoicesDetails.add(invoiceRowWithoutProfit);
    }
    if (status == dueStatus) {
      dueInvoicesDetails.add(invoiceRowWithoutProfit);
      dueDebt += invoice.amountLeft;
    }
    if (status == closedStatus) {
      closedInvoicesDetails.add(invoiceRowWithoutProfit);
      totalClosingDays += invoice.durationToClose.inDays;
    }

    // 2. Handle profit calculation
    totalProfit += invoice.profit;

    // Create the filtered list for profit details (replicating original _getInvoicesWithProfit)
    final invoicesWithProfitRow = [
      invoice.originalTransaction,
      invoice.type == TransactionType.initialCredit.name
          ? ''
          : invoice.number, // index 1
      invoice.date, // index 2
      invoice.totalAmount, // index 3
      // index 4 (receiptInfo) is skipped
      status, // index 5 in new list
      invoice.profit, // index 8 -> now index 5 in new list
    ];
    invoicesWithProfitDetails.add(invoicesWithProfitRow);
  }

  // Final calculations
  final int averageClosingDays = closedInvoicesDetails.isNotEmpty
      ? (totalClosingDays / closedInvoicesDetails.length).round()
      : 0;

  // Return all computed values in a single object
  return ProcessedInvoiceMetrics(
    openInvoices: openInvoicesDetails,
    dueInvoices: dueInvoicesDetails,
    closedInvoices: closedInvoicesDetails,
    invoicesWithProfit: invoicesWithProfitDetails,
    dueDebt: dueDebt,
    totalProfit: totalProfit,
    averageClosingDays: averageClosingDays,
  );
}
