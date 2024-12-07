import 'package:anydrawer/anydrawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_report_controller.dart';
import 'package:tablets/src/features/transactions/view/transaction_filters.dart';

class TransactionDrawer {
  TransactionDrawer(this._reportController);

  final TransactionReportController _reportController;
  final AnyDrawerController drawerController = AnyDrawerController();

  void showSearchForm(BuildContext context) {
    showDrawer(
      context,
      builder: (context) {
        return Center(
          child: SafeArea(
            top: true,
            child: TransactionSearchForm(drawerController),
          ),
        );
      },
      config: const DrawerConfig(
        side: DrawerSide.left,
        widthPercentage: 0.25,
        dragEnabled: false,
        closeOnClickOutside: true,
        backdropOpacity: 0.3,
      ),
      onOpen: () {},
      onClose: () {},
      controller: drawerController,
    );
  }

  void showReports(BuildContext context, List<Map<String, dynamic>> allTransactions) {
    showDrawer(
      context,
      builder: (context) {
        return _reportController.buildReportWidgets(context, allTransactions, drawerController);
      },
      config: const DrawerConfig(
        side: DrawerSide.left,
        widthPercentage: 0.2,
        dragEnabled: false,
        closeOnClickOutside: true,
        backdropOpacity: 0.3,
        borderRadius: 10,
      ),
      onOpen: () {},
      onClose: () {},
      controller: drawerController,
    );
  }
}

final transactionDrawerControllerProvider = Provider<TransactionDrawer>((ref) {
  final reportController = ref.read(transactionReportControllerProvider);
  return TransactionDrawer(reportController);
});
