import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/widgets/report_dialog.dart';

final salesmanReportControllerProvider = Provider<SalesmanReportController>((ref) {
  return SalesmanReportController();
});

class SalesmanReportController {
  SalesmanReportController();

  void showDebtReport(BuildContext context, List<List<dynamic>> detailsList, String salesmanName) {
    // filter debt to show only debts > zero
    List<List<dynamic>> filteredList = detailsList.where((list) => list[1] > 0).toList();
    showReportDialog(
      context,
      _getDebtReportTitles(context),
      filteredList,
      title: salesmanName,
      // this index is after removing first column of transaction (i.e it is accually [2])
      summaryIndexes: [1, 2],
      dropdownLabel: S.of(context).customer,
      dropdownIndex: 0,
    );
  }

  void showInvoicesReport(
      BuildContext context, List<List<dynamic>> detailsList, String salesmanName) {
    showReportDialog(
      context,
      _getOpenInvoicesReportTitles(context),
      detailsList,
      title: salesmanName,
      // this index is after removing first column of transaction (i.e it is accually [2, 3])
      summaryIndexes: [1, 2],
    );
  }

  void showSoldItemsReport(
      BuildContext context, List<List<dynamic>> detailsList, String title, bool isSupervisor) {
    if (!isSupervisor) {
      showReportDialog(
        context,
        _getSoldItemsReportTitles(context),
        detailsList,
        title: title,
        // this index is after removing first column of transaction (i.e it is accually [5, 7])
        summaryIndexes: [4, 6],
      );
    } else {
      showReportDialog(
        context,
        _getSoldItemsReportTitles(context).sublist(0, 5),
        trimLastXIndicesFromInnerLists(detailsList, 2),
        title: title,
        // this index is after removing first column of transaction (i.e it is accually 5)
        summaryIndexes: [4],
      );
    }
  }

  void showTransactionReport(
    BuildContext context,
    List<List<dynamic>> transactionList,
    String salesmanName, {
    int? sumIndex,
    bool isProfit = false,
  }) {
    showReportDialog(
      context,
      _getTransactionsReportTitles(context, isProfit: isProfit),
      transactionList,
      dateIndex: 2,
      title: salesmanName,
      useOriginalTransaction: true,
      // this index is after removing first column of transaction (i.e it is accually sumIndex + 1)
      summaryIndexes: sumIndex == null ? [] : [sumIndex],
    );
  }

  void showCustomers(BuildContext context, List<List<dynamic>> detailsList, String reportTitle) {
    showReportDialog(
        context,
        [
          S.of(context).customer,
          S.of(context).region_name,
          S.of(context).phone,
          S.of(context).invoices_number,
          S.of(context).package_number
        ],
        detailsList,
        title: reportTitle,
        dropdownLabel: S.of(context).regions,
        dropdownIndex: 1,
        // this index is after removing first column of transaction (i.e it is accually [4, 5])
        summaryIndexes: [3, 4]);
  }

  List<String> _getTransactionsReportTitles(BuildContext context, {bool isProfit = false}) {
    return [
      S.of(context).transaction_type,
      S.of(context).transaction_date,
      S.of(context).transaction_name,
      S.of(context).transaction_number,
      S.of(context).transaction_subTotal_amount,
      S.of(context).transaction_discount,
      isProfit ? S.of(context).profits : S.of(context).transaction_amount,
    ];
  }

  List<String> _getOpenInvoicesReportTitles(BuildContext context) {
    return [
      S.of(context).customer,
      S.of(context).num_open_invoice,
      S.of(context).num_due_invoices,
    ];
  }

  List<String> _getSoldItemsReportTitles(BuildContext context) {
    return [
      S.of(context).product_name,
      S.of(context).sold,
      S.of(context).item_gifts_quantity,
      S.of(context).returned,
      S.of(context).net_amount,
      S.of(context).commission,
      S.of(context).amount,
    ];
  }

  List<String> _getDebtReportTitles(BuildContext context) {
    return [
      S.of(context).customer,
      S.of(context).current_debt,
      S.of(context).due_debt_amount,
    ];
  }
}
