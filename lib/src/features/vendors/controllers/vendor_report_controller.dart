import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/widgets/report_dialog.dart';

final vendorReportControllerProvider = Provider<VendorReportController>((ref) {
  return VendorReportController();
});

class VendorReportController {
  VendorReportController();

  void showVendorMatchingReport(
      BuildContext context, List<List<dynamic>> transactionList, String title) {
    showReportDialog(context, _getVendorMatchingReportTitles(context), transactionList,
        dateIndex: 3,
        title: title,
        dropdownIndex: 1,
        dropdownLabel: S.of(context).transaction_type,
        // this index is after removing first column of transaction (i.e it is accually 4)
        summaryIndexes: [3],
        useOriginalTransaction: true);
  }

  List<String> _getVendorMatchingReportTitles(BuildContext context) {
    return [
      S.of(context).transaction_type,
      S.of(context).transaction_number,
      S.of(context).transaction_date,
      S.of(context).transaction_amount,
    ];
  }
}
