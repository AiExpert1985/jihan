import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/providers/page_is_loading_notifier.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/features_keys.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:tablets/src/common/providers/background_color.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/controllers/form_navigator_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_drawer_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_controller.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_data_notifier.dart';
import 'package:tablets/src/features/transactions/repository/transaction_repository_provider.dart';
import 'package:tablets/src/features/transactions/view/transaction_from_selection_dialog.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/providers/text_editing_controllers_provider.dart';
import 'package:tablets/src/features/home/view/home_screen.dart';
import 'package:tablets/src/common/widgets/main_screen_list_cells.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/features/transactions/view/transaction_show_form.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(transactionScreenDataNotifier);
    final settingsDataNotifier = ref.read(settingsFormDataProvider.notifier);
    final settingsData = settingsDataNotifier.data;
    // if settings data is empty it means user has refresh the web page &
    // didn't reach the page through pressing the page button
    // in this case he didn't load required dbCaches so, I should hide buttons because
    // using them might cause bugs in the program
    Widget screenWidget = settingsData.isEmpty
        ? const HomeScreen()
        : const AppScreenFrame(
            TransactionsList(),
            buttonsWidget: TransactionsFloatingButtons(),
          );
    return screenWidget;
  }
}

class TransactionsList extends ConsumerWidget {
  const TransactionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(transactionScreenDataNotifier);
    ref.watch(pageIsLoadingNotifier);
    final dbCache = ref.read(transactionDbCacheProvider.notifier);
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
    final screenDataNotifier = ref.read(transactionScreenDataNotifier.notifier);
    final screenData = screenDataNotifier.data;
    ref.watch(transactionScreenDataNotifier);
    return Expanded(
      child: ListView.builder(
        itemCount: screenData.length,
        itemBuilder: (ctx, index) {
          final transactionData = screenData[index];
          return Column(
            children: [
              DataRow(transactionData, index + 1),
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
    final screenDataNotifier = ref.read(transactionScreenDataNotifier.notifier);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const MainScreenPlaceholder(width: 20, isExpanded: false),
        SortableMainScreenHeaderCell(
            screenDataNotifier, transactionTypeKey, S.of(context).transaction_type),
        SortableMainScreenHeaderCell(
            screenDataNotifier, transactionNumberKey, S.of(context).transaction_number),
        SortableMainScreenHeaderCell(
            screenDataNotifier, transactionDateKey, S.of(context).transaction_date),
        SortableMainScreenHeaderCell(
            screenDataNotifier, transactionNameKey, S.of(context).transaction_name),
        SortableMainScreenHeaderCell(
            screenDataNotifier, transactionSalesmanKey, S.of(context).salesman_selection),
        SortableMainScreenHeaderCell(
            screenDataNotifier, transactionTotalAmountKey, S.of(context).transaction_amount),
        MainScreenHeaderCell(S.of(context).print_status),
        SortableMainScreenHeaderCell(screenDataNotifier, transactionNotesKey, S.of(context).notes),
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
    final productRef = transactionScreenData[productDbRefKey];
    final productDbCache = ref.read(transactionDbCacheProvider.notifier);
    final transactionData = productDbCache.getItemByDbRef(productRef);
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
                () => _showEditTransactionForm(context, ref, transaction),
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
            ],
          ),
        ),
      ],
    );
  }

  void _showEditTransactionForm(BuildContext context, WidgetRef ref, Transaction transaction) {
    final imagePickerNotifier = ref.read(imagePickerProvider.notifier);
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final textEditingNotifier = ref.read(textFieldsControllerProvider.notifier);
    final settingsDataNotifier = ref.read(settingsFormDataProvider.notifier);
    final formNavigator = ref.read(formNavigatorProvider);
    // transactions opens unEditable, if user want he press the edit button
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

class TransactionsFloatingButtons extends ConsumerWidget {
  const TransactionsFloatingButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawerController = ref.watch(transactionDrawerControllerProvider);
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
            child: const Icon(Icons.pie_chart, color: Colors.white),
            backgroundColor: iconsColor,
            onTap: () async {
              final allTransactions =
                  await ref.read(transactionRepositoryProvider).fetchItemListAsMaps();
              if (context.mounted) {
                drawerController.showReports(context, allTransactions);
              }
            }),
        SpeedDialChild(
          child: const Icon(Icons.search, color: Colors.white),
          backgroundColor: iconsColor,
          onTap: () => drawerController.showSearchForm(context),
        ),
        SpeedDialChild(
          child: const Icon(Icons.add, color: Colors.white),
          backgroundColor: iconsColor,
          onTap: () {
            // reset background color when form is closed
            ref.read(backgroundColorProvider.notifier).state = normalColor!;
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => const TransactionGroupSelection()),
            );
          },
        ),
      ],
    );
  }
}
