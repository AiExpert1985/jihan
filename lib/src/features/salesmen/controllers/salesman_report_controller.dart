import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/widgets/report_dialog.dart';

final salesmanReportControllerProvider = Provider<SalesmanReportController>((ref) {
  return SalesmanReportController();
});

class SalesmanReportController {
  SalesmanReportController();

  void showDebtReport(BuildContext context, List<List<dynamic>> detailsList, String salesmanName) {
    showReportDialog(
      context,
      _getDebtReportTitles(context),
      detailsList,
      title: salesmanName,
    );
  }

  void showInvoicesReport(
      BuildContext context, List<List<dynamic>> detailsList, String salesmanName) {
    showReportDialog(
      context,
      _getOpenInvoicesReportTitles(context),
      detailsList,
      title: salesmanName,
    );
  }

  void showTransactionReport(
    BuildContext context,
    List<List<dynamic>> transactionList,
    String salesmanName, {
    int? sumIndex,
    bool isProfit = false,
    bool isCount = false,
  }) {
    showReportDialog(
      context,
      _getTransactionsReportTitles(context, isProfit: isProfit),
      transactionList,
      dateIndex: 2,
      title: salesmanName,
      useOriginalTransaction: true,
      sumIndex: sumIndex,
      isCount: isCount,
    );
  }

  void showCustomers(BuildContext context, List<List<dynamic>> detailsList, String salesmanName) {
    showReportDialog(
      context,
      [S.of(context).customer, S.of(context).region_name],
      detailsList,
      title: salesmanName,
      width: 400,
    );
  }

  List<String> _getTransactionsReportTitles(BuildContext context, {bool isProfit = false}) {
    return [
      S.of(context).transaction_type,
      S.of(context).transaction_date,
      S.of(context).transaction_name,
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

  List<String> _getDebtReportTitles(BuildContext context) {
    return [
      S.of(context).customer,
      S.of(context).current_debt,
      S.of(context).due_debt_amount,
    ];
  }
}
