import 'package:anydrawer/anydrawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/features/deleted_transactions/view/deleted_transaction_filters.dart';

class DeletedTransactionDrawer {
  DeletedTransactionDrawer();

  final AnyDrawerController drawerController = AnyDrawerController();

  void showSearchForm(BuildContext context) {
    showDrawer(
      context,
      builder: (context) {
        return Center(
          child: SafeArea(
            top: true,
            child: DeletedTransactionSearchForm(drawerController),
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
}

final deletedTransactionDrawerControllerProvider = Provider<DeletedTransactionDrawer>((ref) {
  return DeletedTransactionDrawer();
});
