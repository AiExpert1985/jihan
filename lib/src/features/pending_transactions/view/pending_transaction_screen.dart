import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/providers/page_is_loading_notifier.dart';
import 'package:tablets/src/common/providers/text_editing_controllers_provider.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/dialog_delete_confirmation.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:tablets/src/common/widgets/show_transaction_dialog.dart';
import 'package:tablets/src/features/deleted_transactions/model/deleted_transactions.dart';
import 'package:tablets/src/features/deleted_transactions/repository/deleted_transaction_db_cache_provider.dart';
import 'package:tablets/src/features/deleted_transactions/repository/deleted_transaction_repository_provider.dart';

import 'package:tablets/src/features/pending_transactions/controllers/pending_transaction_drawer_provider.dart';
import 'package:tablets/src/features/pending_transactions/controllers/pending_transaction_form_controller.dart';
import 'package:tablets/src/features/pending_transactions/controllers/pending_transaction_screen_controller.dart';
import 'package:tablets/src/features/pending_transactions/controllers/pending_transaction_screen_data_notifier.dart';
import 'package:tablets/src/features/pending_transactions/repository/pending_transaction_db_cache_provider.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/controllers/form_navigator_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_controller.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_controller.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/features/home/view/home_screen.dart';
import 'package:tablets/src/common/widgets/main_screen_list_cells.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/view/transaction_show_form.dart';

class PendingTransactions extends ConsumerWidget {
  const PendingTransactions({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pendingTransactionScreenDataNotifier);
    final settingsDataNotifier = ref.read(settingsFormDataProvider.notifier);
    final settingsData = settingsDataNotifier.data;
    // if settings data is empty it means user has refresh the web page &
    // didn't reach the page through pressing the page button
    // in this case he didn't load required dbCaches so, I should hide buttons because
    // using them might cause bugs in the program
    Widget screenWidget = settingsData.isEmpty
        ? const HomeScreen()
        : const AppScreenFrame(
            PendingTransactionsList(),
            buttonsWidget: PendingTransactionsFloatingButtons(),
          );
    return screenWidget;
  }
}

class PendingTransactionsList extends ConsumerWidget {
  const PendingTransactionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pendingTransactionScreenDataNotifier);
    ref.watch(pageIsLoadingNotifier);
    final dbCache = ref.read(pendingTransactionDbCacheProvider.notifier);
    final dbData = dbCache.data;
    final pageIsLoading = ref.read(pageIsLoadingNotifier);
    if (pageIsLoading) {
      return const PageLoading();
    }
    Widget screenWidget = dbData.isNotEmpty
        ? const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ListHeaders(),
                Divider(),
                ListData(),
              ],
            ),
          )
        : const EmptyPage();
    return screenWidget;
  }
}

class ListData extends ConsumerWidget {
  const ListData({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenDataNotifier = ref.read(pendingTransactionScreenDataNotifier.notifier);
    final screenData = screenDataNotifier.data;
    ref.watch(pendingTransactionScreenDataNotifier);
    return Expanded(
      child: ListView.builder(
        itemCount: screenData.length,
        itemBuilder: (ctx, index) {
          final pendingTransactionData = screenData[index];
          return Column(
            children: [
              DataRow(pendingTransactionData, index + 1),
              const Divider(thickness: 0.2, color: Colors.grey),
            ],
          );
        },
      ),
    );
  }
}

class ListHeaders extends ConsumerWidget {
  const ListHeaders({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenDataNotifier = ref.read(pendingTransactionScreenDataNotifier.notifier);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const MainScreenPlaceholder(width: 20, isExpanded: false),
        SortableMainScreenHeaderCell(
            screenDataNotifier, 'transactionType', S.of(context).transaction_type),
        SortableMainScreenHeaderCell(
            screenDataNotifier, 'number', S.of(context).transaction_number),
        SortableMainScreenHeaderCell(screenDataNotifier, 'date', S.of(context).transaction_date),
        SortableMainScreenHeaderCell(screenDataNotifier, 'name', S.of(context).transaction_name),
        SortableMainScreenHeaderCell(
            screenDataNotifier, 'salesman', S.of(context).salesman_selection),
        SortableMainScreenHeaderCell(
            screenDataNotifier, 'totalAmount', S.of(context).transaction_amount),
        MainScreenHeaderCell(S.of(context).print_status),
        SortableMainScreenHeaderCell(screenDataNotifier, 'notes', S.of(context).notes),
        const MainScreenPlaceholder(width: 40, isExpanded: false),
        const MainScreenPlaceholder(width: 40, isExpanded: false),
      ],
    );
  }
}

class DataRow extends ConsumerWidget {
  const DataRow(this.transactionScreenData, this.sequence, {super.key});
  final Map<String, dynamic> transactionScreenData;
  final int sequence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pendingTransactionScreenDataNotifier);
    final dbRef = transactionScreenData['dbRef'];
    final dbCache = ref.read(pendingTransactionDbCacheProvider.notifier);
    final transactionData = dbCache.getItemByDbRef(dbRef);
    final translatedTransactionType =
        translateScreenTextToDbText(context, transactionData[transactionTypeKey]);
    final transaction =
        Transaction.fromMap({...transactionData, transactionTypeKey: translatedTransactionType});
    final date = transactionScreenData[transactionDateKey].toDate();
    final color = _getSequnceColor(transaction.transactionType);
    final transactionType = transactionScreenData[transactionTypeKey];
    bool isWarning = transactionType.contains(S.of(context).transaction_type_customer_receipt) ||
        transactionType.contains(S.of(context).transaction_type_customer_return);
    final printStatus =
        transactionScreenData[isPrintedKey] ? S.of(context).printed : S.of(context).not_printed;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MainScreenNumberedEditButton(
                sequence,
                () => showReadOnlyTransaction(context, transaction),
                color: color,
              ),
              MainScreenTextCell(transactionScreenData[transactionTypeKey], isWarning: isWarning),
              // we don't add thousand separators to transaction number, so I made it String here
              MainScreenTextCell(transactionScreenData[transactionNumberKey].round().toString(),
                  isWarning: isWarning),
              MainScreenTextCell(date, isWarning: isWarning),
              MainScreenTextCell(transactionScreenData[transactionNameKey], isWarning: isWarning),
              MainScreenTextCell(transactionScreenData[transactionSalesmanKey],
                  isWarning: isWarning),
              MainScreenTextCell(transactionScreenData[transactionTotalAmountKey],
                  isWarning: isWarning),
              MainScreenTextCell(printStatus, isWarning: isWarning),
              MainScreenTextCell(transactionScreenData[transactionNotesKey], isWarning: isWarning),
              IconButton(
                  onPressed: () {
                    showEditTransactionForm(context, ref, transaction);
                  },
                  icon: const SaveIcon()),
              IconButton(
                onPressed: () {
                  deletePendingTransaction(context, ref, transaction);
                },
                icon: const DeleteIcon(),
              )
            ],
          ),
        ),
      ],
    );
  }

  Color _getSequnceColor(String transactionType) {
    if (transactionType == TransactionType.customerReturn.name ||
        transactionType == TransactionType.customerReceipt.name) {
      return Colors.red; // use default color
    }
    if (transactionType == TransactionType.vendorInvoice.name ||
        transactionType == TransactionType.vendorReceipt.name ||
        transactionType == TransactionType.vendorReturn.name) {
      return Colors.green;
    }
    return const Color.fromARGB(255, 75, 63, 141);
  }
}

class PendingTransactionsFloatingButtons extends ConsumerWidget {
  const PendingTransactionsFloatingButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawerController = ref.watch(pendingTransactionDrawerControllerProvider);
    const iconsColor = Color.fromARGB(255, 126, 106, 211);
    return SpeedDial(
      direction: SpeedDialDirection.up,
      switchLabelPosition: false,
      animatedIcon: AnimatedIcons.menu_close,
      spaceBetweenChildren: 10,
      animatedIconTheme: const IconThemeData(size: 28.0),
      visible: true,
      curve: Curves.bounceInOut,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.search, color: Colors.white),
          backgroundColor: iconsColor,
          onTap: () => drawerController.showSearchForm(context),
        ),
      ],
    );
  }
}

void deletePendingTransaction(BuildContext context, WidgetRef ref, Transaction transaction,
    {addToDeletedTransaction = true}) async {
  final Map<String, dynamic> formData = transaction.toMap();
  // only show dialog when user press delete button, in case addToDeletedTransaction = false, it means the item
  // is deleted after being saved to Transactions.
  if (addToDeletedTransaction) {
    final confirmation = await showDeleteConfirmationDialog(
        context: context,
        messagePart1: S.of(context).alert_before_delete,
        messagePart2:
            '${translateDbTextToScreenText(context, formData[transTypeKey])}  ${formData[numberKey]}');
    if (confirmation == null) return;
  }
  final formImagesNotifier = ref.read(imagePickerProvider.notifier);
  final imageUrls = formImagesNotifier.saveChanges();
  final formController = ref.read(pendingTransactionFormControllerProvider);
  final itemData = {...formData, 'imageUrls': imageUrls};
  final dbCache = ref.read(pendingTransactionDbCacheProvider.notifier);
  if (context.mounted) {
    formController.deleteItemFromDb(context, transaction, keepDialogOpen: true);
    // when when process pending transaction, we will delete it any way, but when action is delete,
    // we need to add it to deleted transaction database
    if (addToDeletedTransaction) {
      addToDeletedTransactionsDb(ref, itemData);
    }
    // update the bdCache (database mirror) so that we don't need to fetch data from db
    const operationType = DbCacheOperationTypes.delete;
    dbCache.update(itemData, operationType);
    // redo screenData calculations
    final screenController = ref.read(pendingTransactionScreenControllerProvider);
    screenController.setFeatureScreenData(context);
    if (addToDeletedTransaction) {
      successUserMessage(context, 'تم حذف التعامل');
    }
  }
}

void addToDeletedTransactionsDb(WidgetRef ref, Map<String, dynamic> itemData) {
  final deletionItemData = {...itemData, 'deleteDateTime': DateTime.now()};
  final deletedTransaction = DeletedTransaction.fromMap(deletionItemData);
  final deletedTransactionRepository = ref.read(deletedTransactionRepositoryProvider);
  deletedTransactionRepository.addItem(deletedTransaction);
  final deletedTransactionsDbCache = ref.read(deletedTransactionDbCacheProvider.notifier);
  // update the bdCache (database mirror) so that we don't need to fetch data from db
  if (deletionItemData[transactionDateKey] is DateTime) {
    // in our form the data type usually is DateTime, but the date type in dbCache should be
    // Timestamp, as to mirror the datatype of firebase
    deletionItemData[transactionDateKey] =
        firebase.Timestamp.fromDate(deletionItemData[transactionDateKey]);
  }
  // update the bdCache (database mirror) so that we don't need to fetch data from db
  if (deletionItemData['deleteDateTime'] is DateTime) {
    // in our form the data type usually is DateTime, but the date type in dbCache should be
    // Timestamp, as to mirror the datatype of firebase
    deletionItemData['deleteDateTime'] =
        firebase.Timestamp.fromDate(deletionItemData['deleteDateTime']);
  }
  deletedTransactionsDbCache.update(deletionItemData, DbCacheOperationTypes.add);
}

void showEditTransactionForm(BuildContext context, WidgetRef ref, Transaction transaction) {
  final imagePickerNotifier = ref.read(imagePickerProvider.notifier);
  final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
  final textEditingNotifier = ref.read(textFieldsControllerProvider.notifier);
  final settingsDataNotifier = ref.read(settingsFormDataProvider.notifier);
  final formNavigator = ref.read(formNavigatorProvider);
  // first of all, we delete the transaction (before changing its number)
  deletePendingTransaction(context, ref, transaction, addToDeletedTransaction: false);
  // then we udpate the transaction number if transaction is a customer invoice
  // for receipts, the number is given by the salesman in the mobile app
  if (transaction.transactionType == TransactionType.customerInvoice.name) {
    final invoiceNumber = getNextCustomerInvoiceNumber(context, ref);
    transaction.number = invoiceNumber;
  }
  // save transaction to transaction database
  saveTransaction(context, ref, transaction);
  // finally, we open it form edit (it opens unEditable, if user want he press the edit button)
  formNavigator.isReadOnly = true;
  TransactionShowForm.showForm(
    context,
    ref,
    imagePickerNotifier,
    formDataNotifier,
    settingsDataNotifier,
    textEditingNotifier,
    transaction: transaction,
    formType: transaction.transactionType,
  );
}

void saveTransaction(
  BuildContext context,
  WidgetRef ref,
  Transaction transaction,
) {
  final formController = ref.read(transactionFormControllerProvider);
  final screenController = ref.read(transactionScreenControllerProvider);
  final dbCache = ref.read(transactionDbCacheProvider.notifier);
  formController.saveItemToDb(context, transaction, false, keepDialogOpen: true);
  const operationType = DbCacheOperationTypes.add;
  dbCache.update(transaction.toMap(), operationType);
  // redo screenData calculations
  if (context.mounted) {
    screenController.setFeatureScreenData(context);
  }
}

// here I am giving the next number after the maximumn number previously given in both transactions & deleted
// transactions
int getNextCustomerInvoiceNumber(BuildContext context, WidgetRef ref) {
  final transactionDbCache = ref.read(transactionDbCacheProvider.notifier);
  final transactions = transactionDbCache.data;
  int maxDeletedNumber = getHighestDeletedCustomerInvoiceNumber(ref) ?? 0;
  int maxTransactionNumber = getHighestCustomerInvoiceNumber(context, transactions) ?? 0;
  return max(maxDeletedNumber, maxTransactionNumber) + 1;
}

// for every different transaction, we calculate the next number which is the last reached +1
int? getHighestCustomerInvoiceNumber(
  BuildContext context,
  List<Map<String, dynamic>> transactions,
) {
  // Step 1: Filter the list for the given transaction type
  final filteredTransactions = transactions.where(
      (transaction) => transaction[transactionTypeKey] == TransactionType.customerInvoice.name);
  if (filteredTransactions.isEmpty) return 0;
  // Step 2: Extract the transaction numbers and convert them to integers
  final transactionNumbers = filteredTransactions.map((transaction) =>
      transaction[numberKey] is int ? transaction[numberKey] : transaction[numberKey].toInt());
  // Step 3: Find the maximum transaction number
  int maxNumber =
      transactionNumbers.reduce((a, b) => (a != null && b != null) ? (a > b ? a : b) : (a ?? b)) ??
          0;
  return maxNumber;
}

int? getHighestDeletedCustomerInvoiceNumber(WidgetRef ref) {
  final dbCache = ref.read(deletedTransactionDbCacheProvider.notifier);
  final dbCacheData = dbCache.data;
  // Step 1: Filter the list for the given transaction type
  final filteredTransactions = dbCacheData.where(
      (transaction) => transaction[transactionTypeKey] == TransactionType.customerInvoice.name);
  if (filteredTransactions.isEmpty) return 0;
  // Step 2: Extract the transaction numbers and convert them to integers
  final transactionNumbers = filteredTransactions.map((transaction) =>
      transaction[numberKey] is int ? transaction[numberKey] : transaction[numberKey].toInt());
  // Step 3: Find the maximum transaction number
  int maxNumber =
      transactionNumbers.reduce((a, b) => (a != null && b != null) ? (a > b ? a : b) : (a ?? b)) ??
          0;
  return maxNumber;
}
