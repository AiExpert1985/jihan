import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/providers/page_is_loading_notifier.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/features_keys.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/dialog_delete_confirmation.dart';
import 'package:tablets/src/common/widgets/empty_screen.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:tablets/src/common/widgets/page_loading.dart';
import 'package:tablets/src/common/widgets/show_transaction_dialog.dart';
import 'package:tablets/src/features/deleted_transactions/model/deleted_transactions.dart';
import 'package:tablets/src/features/deleted_transactions/repository/deleted_transaction_db_cache_provider.dart';
import 'package:tablets/src/features/deleted_transactions/repository/deleted_transaction_repository_provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/screen_quick_filter.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/form_fields/drop_down_with_search.dart';
import 'package:tablets/src/common/widgets/form_fields/edit_box.dart';
import 'package:tablets/src/features/pending_transactions/controllers/pending_transaction_quick_filter_controller.dart';
import 'package:tablets/src/features/products/controllers/product_screen_controller.dart';
import 'package:tablets/src/features/products/repository/product_db_cache_provider.dart';
import 'package:tablets/src/features/pending_transactions/controllers/pending_transaction_drawer_provider.dart';
import 'package:tablets/src/features/pending_transactions/controllers/pending_transaction_form_controller.dart';
import 'package:tablets/src/features/pending_transactions/controllers/pending_transaction_screen_controller.dart';
import 'package:tablets/src/features/pending_transactions/repository/pending_transaction_repository_provider.dart';
import 'package:tablets/src/features/pending_transactions/controllers/pending_transaction_screen_data_notifier.dart';
import 'package:tablets/src/features/pending_transactions/repository/pending_transaction_db_cache_provider.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_controller.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_controller.dart';
import 'package:tablets/src/features/home/view/home_screen.dart';
import 'package:tablets/src/common/widgets/main_screen_list_cells.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/view/forms/item_list.dart';
import 'package:tablets/src/features/counters/repository/counter_repository_provider.dart';
import 'package:tablets/src/common/providers/screen_cache_update_service.dart';

/// Queue that ensures pending transaction approvals execute one at a time.
/// Each approval chains onto the previous Future, so they run sequentially.
Future<void> _approvalQueue = Future.value();

class PendingTransactions extends ConsumerWidget {
  const PendingTransactions({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pendingTransactionScreenDataNotifier);
    final settingsDataNotifier = ref.read(settingsFormDataProvider.notifier);
    final settingsData = settingsDataNotifier.data;
    ref.watch(pendingTransactionQuickFiltersProvider);
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
                TransactionsFilters(),
                VerticalGap.l,
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
    final screenDataNotifier =
        ref.read(pendingTransactionScreenDataNotifier.notifier);
    final screenData = screenDataNotifier.data;
    ref.watch(pendingTransactionScreenDataNotifier);
    return Expanded(
      child: ListView.builder(
        itemCount: screenData.length,
        itemBuilder: (ctx, index) {
          final pendingTransactionData = screenData[index];
          return Column(
            children: [
              DataRow(
                pendingTransactionData,
                index + 1,
                key: ValueKey(pendingTransactionData['dbRef']),
              ),
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
    final screenDataNotifier =
        ref.read(pendingTransactionScreenDataNotifier.notifier);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const MainScreenPlaceholder(width: 20, isExpanded: false),
        SortableMainScreenHeaderCell(screenDataNotifier, 'transactionType',
            S.of(context).transaction_type),
        SortableMainScreenHeaderCell(
            screenDataNotifier, 'number', S.of(context).transaction_number),
        SortableMainScreenHeaderCell(
            screenDataNotifier, 'date', S.of(context).transaction_date),
        SortableMainScreenHeaderCell(
            screenDataNotifier, 'name', S.of(context).transaction_name),
        SortableMainScreenHeaderCell(
            screenDataNotifier, 'salesman', S.of(context).salesman_selection),
        SortableMainScreenHeaderCell(screenDataNotifier, 'totalAmount',
            S.of(context).transaction_amount),
        MainScreenHeaderCell(S.of(context).print_status),
        SortableMainScreenHeaderCell(
            screenDataNotifier, 'notes', S.of(context).notes),
        const MainScreenPlaceholder(width: 40, isExpanded: false),
        const MainScreenPlaceholder(width: 40, isExpanded: false),
      ],
    );
  }
}

class DataRow extends ConsumerStatefulWidget {
  const DataRow(this.transactionScreenData, this.sequence, {super.key});
  final Map<String, dynamic> transactionScreenData;
  final int sequence;

  @override
  ConsumerState<DataRow> createState() => _DataRowState();
}

class _DataRowState extends ConsumerState<DataRow> {
  bool _isApproving = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(pendingTransactionScreenDataNotifier);
    final dbRef = widget.transactionScreenData['dbRef'];
    final dbCache = ref.read(pendingTransactionDbCacheProvider.notifier);
    final transactionData = dbCache.getItemByDbRef(dbRef);
    final translatedTransactionType = translateScreenTextToDbText(
        context, transactionData[transactionTypeKey]);
    final transaction = Transaction.fromMap(
        {...transactionData, transactionTypeKey: translatedTransactionType});
    final date = widget.transactionScreenData[transactionDateKey].toDate();
    final color = _getSequnceColor(transaction.transactionType);
    final transactionType = widget.transactionScreenData[transactionTypeKey];
    bool isWarning = transactionType
            .contains(S.of(context).transaction_type_customer_receipt) ||
        transactionType
            .contains(S.of(context).transaction_type_customer_return);
    final printStatus = widget.transactionScreenData[isPrintedKey]
        ? S.of(context).printed
        : S.of(context).not_printed;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MainScreenNumberedEditButton(
                widget.sequence,
                () => showReadOnlyTransaction(context, transaction),
                color: color,
              ),
              MainScreenTextCell(
                  widget.transactionScreenData[transactionTypeKey],
                  isWarning: isWarning),
              // we don't add thousand separators to transaction number, so I made it String here
              MainScreenTextCell(
                  widget.transactionScreenData[transactionNumberKey]
                      .round()
                      .toString(),
                  isWarning: isWarning),
              MainScreenTextCell(date, isWarning: isWarning),
              MainScreenTextCell(
                  widget.transactionScreenData[transactionNameKey],
                  isWarning: isWarning),
              MainScreenTextCell(
                  widget.transactionScreenData[transactionSalesmanKey],
                  isWarning: isWarning),
              MainScreenTextCell(
                  widget.transactionScreenData[transactionTotalAmountKey],
                  isWarning: isWarning),
              MainScreenTextCell(printStatus, isWarning: isWarning),
              MainScreenTextCell(
                  widget.transactionScreenData[transactionNotesKey],
                  isWarning: isWarning),
              if (!_isApproving)
                IconButton(
                    onPressed: () {
                      setState(() => _isApproving = true);
                      _approvalQueue = _approvalQueue.then((_) async {
                        if (!context.mounted) return;
                        try {
                          final success = await approveTransaction(
                                  context, ref, transaction)
                              .timeout(const Duration(seconds: 5));
                          if (!context.mounted) return;
                          if (!success) {
                            setState(() => _isApproving = false);
                            return;
                          }
                          ref
                              .read(pendingTransactionQuickFiltersProvider
                                  .notifier)
                              .applyListFilter(context);
                        } on TimeoutException {
                          if (!context.mounted) return;
                          failureUserMessage(context,
                              "فشل اعتماد التعامل، يرجى المحاولة مرة أخرى");
                          setState(() => _isApproving = false);
                        }
                      });
                    },
                    icon: const SaveIcon())
              else
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              IconButton(
                onPressed: () {
                  deletePendingTransaction(context, ref, transaction);
                  ref
                      .read(pendingTransactionQuickFiltersProvider.notifier)
                      .applyListFilter(context);
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
    final drawerController =
        ref.watch(pendingTransactionDrawerControllerProvider);
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
          child: const Icon(Icons.refresh, color: Colors.white),
          backgroundColor: iconsColor,
          onTap: () async {
            ref.read(pageIsLoadingNotifier.notifier).state = true;
            final newData = await ref
                .read(pendingTransactionRepositoryProvider)
                .fetchItemListAsMaps();
            ref.read(pendingTransactionDbCacheProvider.notifier).set(newData);
            if (context.mounted) {
              ref
                  .read(pendingTransactionScreenControllerProvider)
                  .setFeatureScreenData(context);
            }
            ref.read(pageIsLoadingNotifier.notifier).state = false;
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.search, color: Colors.white),
          backgroundColor: iconsColor,
          onTap: () => drawerController.showSearchForm(context),
        ),
      ],
    );
  }
}

void deletePendingTransaction(
    BuildContext context, WidgetRef ref, Transaction transaction,
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
    final screenController =
        ref.read(pendingTransactionScreenControllerProvider);
    screenController.setFeatureScreenData(context);
    if (addToDeletedTransaction) {
      successUserMessage(context, 'تم حذف التعامل');
    }
  }
}

void addToDeletedTransactionsDb(WidgetRef ref, Map<String, dynamic> itemData) {
  final deletionItemData = {...itemData, 'deleteDateTime': DateTime.now()};
  final deletedTransaction = DeletedTransaction.fromMap(deletionItemData);
  final deletedTransactionRepository =
      ref.read(deletedTransactionRepositoryProvider);
  deletedTransactionRepository.addItem(deletedTransaction);
  final deletedTransactionsDbCache =
      ref.read(deletedTransactionDbCacheProvider.notifier);
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
  deletedTransactionsDbCache.update(
      deletionItemData, DbCacheOperationTypes.add);
}

/// Checks if a Customer Receipt with the same number already exists in transactions collection.
/// Returns true if duplicate found, false otherwise.
bool _isDuplicateCustomerReceipt(WidgetRef ref, Transaction transaction) {
  if (transaction.transactionType != TransactionType.customerReceipt.name) {
    return false;
  }

  final transactionDbCache = ref.read(transactionDbCacheProvider.notifier);
  return transactionDbCache.data.any((t) =>
      t['transactionType'] == TransactionType.customerReceipt.name &&
      t['number'] == transaction.number);
}

/// Approves a pending transaction by saving it to transactions collection.
/// Returns true if approval succeeded, false otherwise.
Future<bool> approveTransaction(
    BuildContext context, WidgetRef ref, Transaction transaction) async {
  final transactionDbCache = ref.read(transactionDbCacheProvider.notifier);
  // below check is added to prevent the bug of duplicating of pressing approve button multiple times
  if (transactionDbCache.getItemByDbRef(transaction.dbRef).isNotEmpty) {
    errorPrint('item was previously approved, duplication is not allowed');
    return false;
  }

  // Check for duplicate Customer Receipt number
  if (_isDuplicateCustomerReceipt(ref, transaction)) {
    if (context.mounted) {
      failureUserMessage(context, "رقم الوصل مكرر");
    }
    return false;
  }
  // then we udpate the transaction number if transaction is a customer invoice
  // for receipts, the number is given by the salesman in the mobile app
  if (transaction.transactionType == TransactionType.customerInvoice.name) {
    try {
      final invoiceNumber = await getNextCustomerInvoiceNumber(ref);
      transaction.number = invoiceNumber;
    } catch (e) {
      if (context.mounted) {
        failureUserMessage(context, "تحقق من الاتصال بالانترنت");
      }
      return false;
    }
  }

  if (!context.mounted) return false;

  // save transaction to transaction database (MUST happen before deleting from pending)
  final success = await saveToTransactionCollection(context, ref, transaction);

  // CRITICAL: Check if widget is still mounted after async operation
  if (!context.mounted) return success;

  if (!success) {
    // Show error message to user - Firebase save failed
    failureUserMessage(context, "فشل اعتماد التعامل، يرجى المحاولة مرة أخرى");
    return false;
  }

  // Only delete pending transaction if save to transactions collection succeeded
  deletePendingTransaction(context, ref, transaction,
      addToDeletedTransaction: false);
  return true;
}

/// Saves transaction to transactions collection in Firebase.
/// Returns true if save succeeded, false if failed.
Future<bool> saveToTransactionCollection(
  BuildContext context,
  WidgetRef ref,
  Transaction transaction,
) async {
  final formController = ref.read(transactionFormControllerProvider);
  final screenController = ref.read(transactionScreenControllerProvider);
  final dbCache = ref.read(transactionDbCacheProvider.notifier);
  // since Item buyingPrice added by Salesman is the default (not the correct one) we need to update it
  // note that I can't calculate buyingPrice at mobile, because it is CPU expensive
  updateBuyingPricesAndProfit(context, ref, transaction);

  // Await Firebase save and check result
  final success = await formController.saveItemToDb(context, transaction, false,
      keepDialogOpen: true);

  // CRITICAL: Check if widget is still mounted after async operation
  if (!context.mounted) return success;

  if (!success) {
    // Firebase save failed - don't update cache
    return false;
  }

  // Only update cache if Firebase save succeeded
  // update the bdCache (database mirror) so that we don't need to fetch data from db
  final itemData = transaction.toMap();

  if (itemData[transactionDateKey] is DateTime) {
    // in our form the data type usually is DateTime, but the date type in dbCache should be
    // Timestamp, as to mirror the datatype of firebase
    itemData[transactionDateKey] =
        firebase.Timestamp.fromDate(itemData[transactionDateKey]);
  }
  const operationType = DbCacheOperationTypes.add;
  dbCache.update(itemData, operationType);
  // redo screenData calculations
  if (context.mounted) {
    screenController.setFeatureScreenData(context);
  }

  // Update customer/product/salesman screen caches in Firebase
  final cacheUpdateService = ref.read(screenCacheUpdateServiceProvider);
  if (context.mounted) {
    final preCalculatedData = cacheUpdateService.calculateAffectedEntities(
      context,
      null, // no old transaction (this is a new add)
      itemData,
      TransactionOperation.add,
    );
    // Save to Firebase asynchronously
    Future.delayed(Duration.zero, () async {
      await cacheUpdateService.savePreCalculatedData(preCalculatedData);
    });
  }
  return true;
}

void updateBuyingPricesAndProfit(
    BuildContext context, WidgetRef ref, Transaction transaction) {
  try {
    if (transaction.items == null) return;
    double itemsTotalProfit = 0;
    for (var item in transaction.items!) {
      item['buyingPrice'] = _getItemPrice(context, ref, item['dbRef']);
      final oneItemProfit = item['sellingPrice'] - item['buyingPrice'];
      final sellingProfit = oneItemProfit * item['soldQuantity'];
      final giftLoss = item['giftQuantity'] * item['buyingPrice'];
      item['itemTotalProfit'] = sellingProfit - giftLoss;
      itemsTotalProfit += item['itemTotalProfit'];
    }
    transaction.itemsTotalProfit = itemsTotalProfit;
    final discount = transaction.discount ?? 0;
    transaction.transactionTotalProfit = itemsTotalProfit - discount;
  } catch (e) {
    errorPrint('error during updateBuyingPricesAndProfit, $e');
  }
}

double _getItemPrice(BuildContext context, WidgetRef ref, String productDbRef) {
  tempPrint(productDbRef);
  final productDbCache = ref.read(productDbCacheProvider.notifier);
  final productData = productDbCache.getItemByDbRef(productDbRef);
  final productScreenController = ref.read(productScreenControllerProvider);
  final prodcutScreenData =
      productScreenController.getItemScreenData(context, productData);
  final productQuantity = prodcutScreenData[productQuantityKey];
  return getBuyingPrice(ref, productQuantity, productData['dbRef']);
}

// Get next customer invoice number from Firestore counter
// Uses atomic increment to prevent duplicate numbers in multi-user environment
Future<int> getNextCustomerInvoiceNumber(WidgetRef ref) async {
  final counterRepository = ref.read(counterRepositoryProvider);
  return await counterRepository
      .getNextNumber(TransactionType.customerInvoice.name);
}

// here I am giving the next number after the maximumn number previously given in both transactions & deleted
// transactions
int getNextCustomerInvoiceNumberFromLocalData(
    BuildContext context, WidgetRef ref) {
  final transactionDbCache = ref.read(transactionDbCacheProvider.notifier);
  final transactions = transactionDbCache.data;
  int maxDeletedNumber = getHighestDeletedCustomerInvoiceNumber(ref) ?? 0;
  int maxTransactionNumber =
      getHighestCustomerInvoiceNumber(context, transactions) ?? 0;
  return max(maxDeletedNumber, maxTransactionNumber) + 1;
}

// for every different transaction, we calculate the next number which is the last reached +1
int? getHighestCustomerInvoiceNumber(
  BuildContext context,
  List<Map<String, dynamic>> transactions,
) {
  // Step 1: Filter the list for the given transaction type
  final filteredTransactions = transactions.where((transaction) =>
      transaction[transactionTypeKey] == TransactionType.customerInvoice.name);
  if (filteredTransactions.isEmpty) return 0;
  // Step 2: Extract the transaction numbers and convert them to integers
  final transactionNumbers = filteredTransactions.map((transaction) =>
      transaction[numberKey] is int
          ? transaction[numberKey]
          : transaction[numberKey].toInt());
  // Step 3: Find the maximum transaction number
  int maxNumber = transactionNumbers.reduce(
          (a, b) => (a != null && b != null) ? (a > b ? a : b) : (a ?? b)) ??
      0;
  return maxNumber;
}

int? getHighestDeletedCustomerInvoiceNumber(WidgetRef ref) {
  final dbCache = ref.read(deletedTransactionDbCacheProvider.notifier);
  final dbCacheData = dbCache.data;
  // Step 1: Filter the list for the given transaction type
  final filteredTransactions = dbCacheData.where((transaction) =>
      transaction[transactionTypeKey] == TransactionType.customerInvoice.name);
  if (filteredTransactions.isEmpty) return 0;
  // Step 2: Extract the transaction numbers and convert them to integers
  final transactionNumbers = filteredTransactions.map((transaction) =>
      transaction[numberKey] is int
          ? transaction[numberKey]
          : transaction[numberKey].toInt());
  // Step 3: Find the maximum transaction number
  int maxNumber = transactionNumbers.reduce(
          (a, b) => (a != null && b != null) ? (a > b ? a : b) : (a ?? b)) ??
      0;
  return maxNumber;
}

class TransactionsFilters extends ConsumerStatefulWidget {
  const TransactionsFilters({super.key});

  @override
  ConsumerState<TransactionsFilters> createState() =>
      _TransactionsFiltersState();
}

class _TransactionsFiltersState extends ConsumerState<TransactionsFilters> {
  late TextEditingController _dateController;
  late TextEditingController _numberController;
  late TextEditingController _notesController;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();

    _dateController = TextEditingController();
    _numberController = TextEditingController();
    _notesController = TextEditingController();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _numberController.dispose();
    _notesController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to rebuild when the state changes

    final quickFilters = ref.watch(pendingTransactionQuickFiltersProvider);

    return Container(
      padding: const EdgeInsets.all(5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          quickFilters.isNotEmpty
              ? _buildClearButton(context, ref)
              : const SizedBox(width: 40),
          HorizontalGap.l,
          _buildTypeQuickFilter(context, ref),
          HorizontalGap.xxl,
          _buildNumberQuickFilter(context, ref),
          HorizontalGap.xxl,
          _buildDateQuickFilter(context, ref),
          HorizontalGap.xxl,
          _buildCustomerQuickFilter(context, ref),
          HorizontalGap.xxl,
          _buildSalesmanQuickFilter(context, ref),
          HorizontalGap.xxl,
          _buildAmountQuickFilter(context, ref),
          HorizontalGap.xxl,
          _buildPrintStatusQuickFilter(context, ref),
          HorizontalGap.xxl,
          _buildNotesQuickFilter(context, ref),
          const SizedBox(width: 110)
        ],
      ),
    );
  }

  Widget _buildClearButton(BuildContext context, WidgetRef ref) {
    return IconButton(
        onPressed: () {
          ref
              .read(pendingTransactionQuickFiltersProvider.notifier)
              .reset(context);
          _dateController.text = '';
          _numberController.text = '';
          _notesController.text = '';
          _amountController.text = '';
        },
        icon: const Icon(
          Icons.cancel_outlined,
          color: Colors.red,
        ));
  }

  Widget _buildCustomerQuickFilter(BuildContext context, WidgetRef ref) {
    final pendingTransactionsDbCache =
        ref.read(pendingTransactionDbCacheProvider.notifier);
    const propertyName = 'name';

    // Extract unique customer names from pending transactions to ensure exact match
    // This prevents mismatch due to whitespace or data inconsistencies
    final customersInTransactions = <String, Map<String, dynamic>>{};
    for (var transaction in pendingTransactionsDbCache.data) {
      final customerName = transaction['name'];
      if (customerName != null && customerName.toString().isNotEmpty) {
        customersInTransactions[customerName] = {'name': customerName};
      }
    }
    final customerList = customersInTransactions.values.toList();

    return DropDownWithSearchFormField(
        initialValue: ref
            .read(pendingTransactionQuickFiltersProvider.notifier)
            .getFilterValue(propertyName),
        onChangedFn: (customer) {
          final customerName = customer['name'];
          QuickFilter filter =
              QuickFilter(propertyName, QuickFilterType.equals, customerName);
          ref
              .read(pendingTransactionQuickFiltersProvider.notifier)
              .updateFilters(filter);
          ref
              .read(pendingTransactionQuickFiltersProvider.notifier)
              .applyListFilter(context);
        },
        itemsList: customerList);
  }

  Widget _buildSalesmanQuickFilter(BuildContext context, WidgetRef ref) {
    final pendingTransactionsDbCache =
        ref.read(pendingTransactionDbCacheProvider.notifier);
    const propertyName = 'salesman';

    // Extract unique salesman names from pending transactions to ensure exact match
    // This prevents mismatch due to whitespace or data inconsistencies
    final salesmenInTransactions = <String, Map<String, dynamic>>{};
    for (var transaction in pendingTransactionsDbCache.data) {
      final salesmanName = transaction['salesman'];
      if (salesmanName != null && salesmanName.toString().isNotEmpty) {
        salesmenInTransactions[salesmanName] = {'name': salesmanName};
      }
    }
    final salesmanList = salesmenInTransactions.values.toList();

    return DropDownWithSearchFormField(
        initialValue: ref
            .read(pendingTransactionQuickFiltersProvider.notifier)
            .getFilterValue(propertyName),
        onChangedFn: (salesman) {
          final salesmanName = salesman['name'];
          QuickFilter filter =
              QuickFilter(propertyName, QuickFilterType.equals, salesmanName);
          ref
              .read(pendingTransactionQuickFiltersProvider.notifier)
              .updateFilters(filter);
          ref
              .read(pendingTransactionQuickFiltersProvider.notifier)
              .applyListFilter(context);
        },
        itemsList: salesmanList);
  }

  Widget _buildTypeQuickFilter(BuildContext context, WidgetRef ref) {
    final typesList = [
      translateDbTextToScreenText(
          context, TransactionType.customerInvoice.name),
      translateDbTextToScreenText(
          context, TransactionType.customerReceipt.name),
      translateDbTextToScreenText(context, TransactionType.customerReturn.name),
      translateDbTextToScreenText(context, TransactionType.gifts.name),
      translateDbTextToScreenText(context, TransactionType.vendorInvoice.name),
      translateDbTextToScreenText(context, TransactionType.vendorReceipt.name),
      translateDbTextToScreenText(context, TransactionType.vendorReturn.name),
      translateDbTextToScreenText(context, TransactionType.expenditures.name),
      translateDbTextToScreenText(context, TransactionType.damagedItems.name),
    ];
    final typesListMap = typesList.map((type) => {'name': type}).toList();
    const propertyName = 'transactionType';
    return DropDownWithSearchFormField(
        initialValue: ref
            .read(pendingTransactionQuickFiltersProvider.notifier)
            .getFilterValue(propertyName),
        onChangedFn: (type) {
          final typeName = type['name']?.toString().trim() ?? '';
          QuickFilter filter =
              QuickFilter(propertyName, QuickFilterType.equals, typeName);
          ref
              .read(pendingTransactionQuickFiltersProvider.notifier)
              .updateFilters(filter);
          ref
              .read(pendingTransactionQuickFiltersProvider.notifier)
              .applyListFilter(context);
        },
        itemsList: typesListMap);
  }

  Widget _buildPrintStatusQuickFilter(BuildContext context, WidgetRef ref) {
    final printStatus = [S.of(context).printed, S.of(context).not_printed];
    final printStatusMap = printStatus.map((type) => {'name': type}).toList();
    const propertyName = 'isPrinted';
    return DropDownWithSearchFormField(
        initialValue: ref
            .read(pendingTransactionQuickFiltersProvider.notifier)
            .getFilterValue(propertyName),
        onChangedFn: (type) {
          final boolValue =
              type['name'] == S.of(context).printed ? true : false;
          QuickFilter filter =
              QuickFilter(propertyName, QuickFilterType.equals, boolValue);
          ref
              .read(pendingTransactionQuickFiltersProvider.notifier)
              .updateFilters(filter);
          ref
              .read(pendingTransactionQuickFiltersProvider.notifier)
              .applyListFilter(context);
        },
        itemsList: printStatusMap);
  }

  Widget _buildNumberQuickFilter(BuildContext context, WidgetRef ref) {
    const propertyName = 'number';
    return FormInputField(
      initialValue: ref
          .read(pendingTransactionQuickFiltersProvider.notifier)
          .getFilterValue(propertyName),
      onChangedFn: (transactionNumber) {
        final trimmedNumber = transactionNumber?.toString().trim() ?? '';
        QuickFilter filter =
            QuickFilter(propertyName, QuickFilterType.equals, trimmedNumber);
        ref
            .read(pendingTransactionQuickFiltersProvider.notifier)
            .updateFilters(filter);
        ref
            .read(pendingTransactionQuickFiltersProvider.notifier)
            .applyListFilter(context);
      },
      controller: _numberController,
      isOnSubmit: true,
      dataType: FieldDataType.num,
      name: 'number',
    );
  }

  Widget _buildAmountQuickFilter(BuildContext context, WidgetRef ref) {
    const propertyName = 'totalAmount';
    return FormInputField(
      initialValue: ref
          .read(pendingTransactionQuickFiltersProvider.notifier)
          .getFilterValue(propertyName),
      onChangedFn: (amount) {
        QuickFilter filter =
            QuickFilter(propertyName, QuickFilterType.equals, amount);
        ref
            .read(pendingTransactionQuickFiltersProvider.notifier)
            .updateFilters(filter);
        ref
            .read(pendingTransactionQuickFiltersProvider.notifier)
            .applyListFilter(context);
      },
      controller: _amountController,
      isOnSubmit: true,
      dataType: FieldDataType.num,
      name: 'totalAmount',
    );
  }

  Widget _buildNotesQuickFilter(BuildContext context, WidgetRef ref) {
    const propertyName = 'notes';
    return FormInputField(
      initialValue: ref
          .read(pendingTransactionQuickFiltersProvider.notifier)
          .getFilterValue(propertyName),
      onChangedFn: (notes) {
        final trimmedNotes = notes?.toString().trim() ?? '';
        QuickFilter filter =
            QuickFilter(propertyName, QuickFilterType.contains, trimmedNotes);
        ref
            .read(pendingTransactionQuickFiltersProvider.notifier)
            .updateFilters(filter);
        ref
            .read(pendingTransactionQuickFiltersProvider.notifier)
            .applyListFilter(context);
      },
      controller: _notesController,
      isOnSubmit: true,
      dataType: FieldDataType.text,
      name: 'notes',
    );
  }

  Widget _buildDateQuickFilter(BuildContext context, WidgetRef ref) {
    const propertyName = 'date';
    return Expanded(
      child: FormBuilderDateTimePicker(
        textAlign: TextAlign.center,
        name: 'startDate',
        decoration: formFieldDecoration(),
        controller: _dateController,
        inputType: InputType.date,
        format: DateFormat('dd-MM-yyyy'),
        onChanged: (date) {
          if (date != null) {
            QuickFilter filter =
                QuickFilter(propertyName, QuickFilterType.dateSameDay, date);
            ref
                .read(pendingTransactionQuickFiltersProvider.notifier)
                .updateFilters(filter);
            ref
                .read(pendingTransactionQuickFiltersProvider.notifier)
                .applyListFilter(context);
            // _dateController.text = DateFormat('dd-MM-yyyy').format(date);
          }
        },
      ),
    );
  }
}
