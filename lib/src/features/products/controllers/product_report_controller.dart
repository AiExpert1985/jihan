import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/widgets/report_dialog.dart';

final productReportControllerProvider = Provider<ProductReportController>((ref) {
  return ProductReportController();
});

class ProductReportController {
  ProductReportController();
  void showHistoryReport(
      BuildContext context, List<List<dynamic>> productTransactions, String title) {
    //last two indexes (profit & commission) are not needed in this report
    final trimmedList = trimLastXIndicesFromInnerLists(productTransactions, 2);

    showReportDialog(context, _getHistoryTitles(context), trimmedList,
        dropdownIndex: 1,
        dropdownLabel: S.of(context).transaction_type,
        dateIndex: 3,
        title: title,
        // this index is after removing first column of transaction (i.e it is accually 4)
        summaryIndexes: [3],
        useOriginalTransaction: true);
  }

  void showProfitReport(
      BuildContext context, List<List<dynamic>> productTransactions, String title) {
    //last two indexes (profit & commission) are not needed in this report
    final trimmedList = removeIndicesFromInnerLists(productTransactions, [4, 6]);

    showReportDialog(context, _getProfitTitles(context), trimmedList,
        dropdownIndex: 1,
        dropdownLabel: S.of(context).transaction_type,
        dateIndex: 3,
        title: title,
        // this index is after removing first column of transaction (i.e it is accually 4)
        summaryIndexes: [3],
        useOriginalTransaction: true);
  }

  void showInvontoryReport(BuildContext context, List<List<dynamic>> inventory, String title) {
    showReportDialog(context, ['المادة', 'العدد'], inventory,
        dropdownIndex: 0,
        dropdownLabel: 'المادة',
        title: title,
        summaryIndexes: [1],
        useOriginalTransaction: false);
  }

  List<String> _getHistoryTitles(BuildContext context) {
    return [
      S.of(context).transaction_type,
      S.of(context).transaction_number,
      S.of(context).transaction_date,
      S.of(context).quantity,
    ];
  }

  List<String> _getProfitTitles(BuildContext context) {
    return [
      S.of(context).transaction_type,
      S.of(context).transaction_number,
      S.of(context).transaction_date,
      S.of(context).product_profits,
    ];
  }
}
