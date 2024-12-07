import 'package:anydrawer/anydrawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/transaction_type_drowdop_list.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/widgets/report_dialog.dart';
import 'package:tablets/src/common/widgets/report_side_drawer_column.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';

final transactionReportControllerProvider = Provider<TransactionReportController>((ref) {
  return TransactionReportController();
});

class TransactionReportController {
  TransactionReportController();

  final Map<String, List<String>> _dailyIncomeFilters = {
    'subtract': [
      TransactionType.vendorReceipt.name,
      TransactionType.expenditures.name,
    ],
    'add': [TransactionType.customerReceipt.name]
  };
  final Map<String, List<String>> _monthlyProfitFilters = {
    'subtract': [
      TransactionType.gifts.name,
      TransactionType.expenditures.name,
      TransactionType.damagedItems.name,
      TransactionType.customerReturn.name,
    ],
    'add': [TransactionType.customerInvoice.name],
  };
  final Map<String, List<String>> _printTransactionsFilters = {
    'subtract': [],
    'add': [
      TransactionType.expenditures.name,
      TransactionType.damagedItems.name,
      TransactionType.vendorReceipt.name,
      TransactionType.vendorReturn.name,
      TransactionType.customerReturn.name,
      TransactionType.customerReceipt.name,
      TransactionType.gifts.name,
      TransactionType.customerInvoice.name,
      TransactionType.vendorInvoice.name,
    ]
  };

  Widget buildReportWidgets(
    BuildContext context,
    List<Map<String, dynamic>> transactions,
    AnyDrawerController drawerController,
  ) {
    final title = S.of(context).transaction_reports;
    final buttons = [
      _buildReportButton(context, transactions, drawerController, _dailyIncomeFilters,
          S.of(context).daily_income_report),
      _buildReportButton(context, transactions, drawerController, _monthlyProfitFilters,
          S.of(context).monthly_profit_report,
          isProfitReport: true),
      _buildReportButton(context, transactions, drawerController, _printTransactionsFilters,
          S.of(context).printing_transactions,
          includeNotes: true)
    ];
    return ReportColumn(
      title: title,
      buttons: buttons,
    );
  }

// returns [type, date, number, name, amount, salesman]
  List<List<dynamic>> _getProcessedTransactions(
      BuildContext context,
      List<Map<String, dynamic>> allTransactions,
      Map<String, List<String>> filters,
      bool isProfitReport,
      bool includeNotes) {
    List<List<dynamic>> processedTransactions = [];
    for (var trans in allTransactions) {
      final transaction = Transaction.fromMap(trans);
      final type = transaction.transactionType;
      final addFilters = filters['add'] ?? [];
      final subtractFilters = filters['subtract'] ?? [];
      final salesman = transaction.salesman ?? '';
      if (addFilters.contains(type)) {
        processedTransactions.add([
          transaction,
          translateDbTextToScreenText(context, type),
          transaction.date,
          transaction.number,
          transaction.name,
          salesman,
          isProfitReport ? transaction.transactionTotalProfit : transaction.totalAmount,
          transaction.notes,
        ]);
      } else if (subtractFilters.contains(type)) {
        processedTransactions.add([
          transaction,
          translateDbTextToScreenText(context, type),
          transaction.date,
          transaction.number,
          transaction.name,
          salesman,
          isProfitReport ? -transaction.transactionTotalProfit : -transaction.totalAmount,
          transaction.notes,
        ]);
      }
    }
    if (!includeNotes) {
      processedTransactions = trimLastXIndicesFromInnerLists(processedTransactions, 1);
    }
    return processedTransactions;
  }

  List<String> _getReportTitles(BuildContext context, bool includeNotes) {
    final titles = [
      S.of(context).transaction_type,
      S.of(context).transaction_date,
      S.of(context).transaction_number,
      S.of(context).transaction_name,
      S.of(context).transaction_salesman,
      S.of(context).amount,
      S.of(context).notes,
    ];
    if (!includeNotes) titles.removeLast();
    return titles;
  }

  Widget _buildReportButton(BuildContext context, List<Map<String, dynamic>> allTransactions,
      AnyDrawerController drawerController, Map<String, List<String>> filters, String title,
      {bool isProfitReport = false, bool includeNotes = false}) {
    List<List<dynamic>> processedTransactions =
        _getProcessedTransactions(context, allTransactions, filters, isProfitReport, includeNotes);
    List<String> reportTitles = _getReportTitles(context, includeNotes);
    List<String> transactionTypeDropdown = getTransactionTypeDropList(context);
    return InkWell(
      child: ReportButton(title),
      onTap: () {
        // Close the drawer when the button is tapped
        drawerController.close();
        // Show the daily income report dialog
        showReportDialog(
          context,
          reportTitles,
          processedTransactions,
          title: title,
          dateIndex: 2,
          sumIndex: 6,
          dropdownList: transactionTypeDropdown,
          dropdownLabel: S.of(context).transaction_type,
          dropdownIndex: 1,
          useOriginalTransaction: true,
        );
      },
    );
  }
}
