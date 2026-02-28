import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tablets/src/common/classes/screen_quick_filter.dart';
import 'package:tablets/src/common/providers/page_is_loading_notifier.dart';
import 'package:tablets/src/features/counters/repository/counter_repository_provider.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/features_keys.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/common/widgets/empty_screen.dart';
import 'package:tablets/src/common/widgets/form_fields/drop_down_with_search.dart';
import 'package:tablets/src/common/widgets/form_fields/edit_box.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:tablets/src/common/providers/background_color.dart';
import 'package:tablets/src/common/widgets/page_loading.dart';
import 'package:tablets/src/features/customers/repository/customer_db_cache_provider.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_db_cache_provider.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/controllers/form_navigator_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_drawer_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_quick_filter_controller.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_controller.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_data_notifier.dart';
import 'package:tablets/src/features/transactions/repository/transaction_repository_provider.dart';
import 'package:tablets/src/features/transactions/view/transaction_from_selection_dialog.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/providers/user_info_provider.dart';
import 'package:tablets/src/features/authentication/model/user_account.dart';
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
    ref.watch(transactionQuickFiltersProvider);
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
                TransactionsFilters(),
                VerticalGap.l,
                ListHeaders(),
                VerticalGap.m,
                Divider(),
                VerticalGap.s,
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
        SortableMainScreenHeaderCell(screenDataNotifier, transactionTypeKey,
            S.of(context).transaction_type),
        SortableMainScreenHeaderCell(screenDataNotifier, transactionNumberKey,
            S.of(context).transaction_number),
        SortableMainScreenHeaderCell(screenDataNotifier, transactionDateKey,
            S.of(context).transaction_date),
        SortableMainScreenHeaderCell(screenDataNotifier, transactionNameKey,
            S.of(context).transaction_name),
        SortableMainScreenHeaderCell(screenDataNotifier, transactionSalesmanKey,
            S.of(context).salesman_selection),
        SortableMainScreenHeaderCell(screenDataNotifier,
            transactionTotalAmountKey, S.of(context).transaction_amount),
        MainScreenHeaderCell(S.of(context).print_status),
        SortableMainScreenHeaderCell(
            screenDataNotifier, transactionNotesKey, S.of(context).notes),
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
    final userInfo = ref.watch(userInfoProvider);
    final isAccountant = userInfo?.privilage == UserPrivilage.accountant.name;
    final productRef = transactionScreenData[productDbRefKey];
    final productDbCache = ref.read(transactionDbCacheProvider.notifier);
    final transactionData = productDbCache.getItemByDbRef(productRef);
    final translatedTransactionType = translateScreenTextToDbText(
        context, transactionData[transactionTypeKey]);
    final transaction = Transaction.fromMap(
        {...transactionData, transactionTypeKey: translatedTransactionType});
    final date = transactionScreenData[transactionDateKey].toDate();
    final color = _getSequnceColor(transaction.transactionType);
    final transactionType = transactionScreenData[transactionTypeKey];
    bool isWarning = transactionType
            .contains(S.of(context).transaction_type_customer_receipt) ||
        transactionType
            .contains(S.of(context).transaction_type_customer_return);
    final printStatus = transactionScreenData[isPrintedKey]
        ? S.of(context).printed
        : S.of(context).not_printed;

    // Check if accountant should not be able to click this transaction
    final isReceiptTransaction =
        transaction.transactionType == TransactionType.customerReceipt.name;
    final isDisabled = isAccountant && isReceiptTransaction;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MainScreenNumberedEditButton(
                sequence,
                isDisabled
                    ? () {}
                    : () => _showEditTransactionForm(context, ref, transaction),
                color: color,
              ),
              MainScreenTextCell(transactionScreenData[transactionTypeKey],
                  isWarning: isWarning),
              // we don't add thousand separators to transaction number, so I made it String here
              MainScreenTextCell(
                  transactionScreenData[transactionNumberKey]
                      .round()
                      .toString(),
                  isWarning: isWarning),
              MainScreenTextCell(date, isWarning: isWarning),
              MainScreenTextCell(transactionScreenData[transactionNameKey],
                  isWarning: isWarning),
              MainScreenTextCell(transactionScreenData[transactionSalesmanKey],
                  isWarning: isWarning),
              MainScreenTextCell(
                  transactionScreenData[transactionTotalAmountKey],
                  isWarning: isWarning),
              MainScreenTextCell(printStatus, isWarning: isWarning),
              MainScreenTextCell(transactionScreenData[transactionNotesKey],
                  isWarning: isWarning),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditTransactionForm(
      BuildContext context, WidgetRef ref, Transaction transaction) {
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
    final userInfo = ref.watch(userInfoProvider);
    final isAccountant = userInfo?.privilage == UserPrivilage.accountant.name;
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
          child: const Icon(Icons.refresh, color: Colors.white),
          backgroundColor: iconsColor,
          onTap: () async {
            ref.read(pageIsLoadingNotifier.notifier).state = true;
            final newData = await ref
                .read(transactionRepositoryProvider)
                .fetchItemListAsMaps(source: Source.server);
            ref.read(transactionDbCacheProvider.notifier).set(newData);
            if (context.mounted) {
              ref
                  .read(transactionScreenControllerProvider)
                  .setFeatureScreenData(context);
            }
            // Also refresh counters from server to keep cache in sync
            // ignore: unawaited_futures
            ref.read(counterRepositoryProvider).refreshCountersFromServer();
            ref.read(pageIsLoadingNotifier.notifier).state = false;
          },
        ),
        if (!isAccountant)
          SpeedDialChild(
              child: const Icon(Icons.pie_chart, color: Colors.white),
              backgroundColor: iconsColor,
              onTap: () async {
                final allTransactions = await ref
                    .read(transactionRepositoryProvider)
                    .fetchItemListAsMaps();
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
              CupertinoPageRoute(
                  builder: (context) => const TransactionGroupSelection()),
            );
          },
        ),
      ],
    );
  }
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

    final quickFilters = ref.watch(transactionQuickFiltersProvider);

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
        ],
      ),
    );
  }

  Widget _buildClearButton(BuildContext context, WidgetRef ref) {
    return IconButton(
        onPressed: () {
          ref.read(transactionQuickFiltersProvider.notifier).reset(context);
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
    final dbCache = ref.read(customerDbCacheProvider.notifier);
    const propertyName = 'name';
    return DropDownWithSearchFormField(
        initialValue: ref
            .read(transactionQuickFiltersProvider.notifier)
            .getFilterValue(propertyName),
        onChangedFn: (customer) {
          QuickFilter filter = QuickFilter(
              propertyName, QuickFilterType.equals, customer['name']);
          ref
              .read(transactionQuickFiltersProvider.notifier)
              .updateFilters(filter);
          ref
              .read(transactionQuickFiltersProvider.notifier)
              .applyListFilter(context);
        },
        itemsList: dbCache.data);
  }

  Widget _buildSalesmanQuickFilter(BuildContext context, WidgetRef ref) {
    final dbCache = ref.read(salesmanDbCacheProvider.notifier);
    const propertyName = 'salesman';
    return DropDownWithSearchFormField(
        initialValue: ref
            .read(transactionQuickFiltersProvider.notifier)
            .getFilterValue(propertyName),
        onChangedFn: (salesman) {
          QuickFilter filter = QuickFilter(
              propertyName, QuickFilterType.equals, salesman['name']);
          ref
              .read(transactionQuickFiltersProvider.notifier)
              .updateFilters(filter);
          ref
              .read(transactionQuickFiltersProvider.notifier)
              .applyListFilter(context);
        },
        itemsList: dbCache.data);
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
            .read(transactionQuickFiltersProvider.notifier)
            .getFilterValue(propertyName),
        onChangedFn: (type) {
          QuickFilter filter =
              QuickFilter(propertyName, QuickFilterType.equals, type['name']);
          ref
              .read(transactionQuickFiltersProvider.notifier)
              .updateFilters(filter);
          ref
              .read(transactionQuickFiltersProvider.notifier)
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
            .read(transactionQuickFiltersProvider.notifier)
            .getFilterValue(propertyName),
        onChangedFn: (type) {
          final boolValue =
              type['name'] == S.of(context).printed ? true : false;
          QuickFilter filter =
              QuickFilter(propertyName, QuickFilterType.equals, boolValue);
          ref
              .read(transactionQuickFiltersProvider.notifier)
              .updateFilters(filter);
          ref
              .read(transactionQuickFiltersProvider.notifier)
              .applyListFilter(context);
        },
        itemsList: printStatusMap);
  }

  Widget _buildNumberQuickFilter(BuildContext context, WidgetRef ref) {
    const propertyName = 'number';
    return FormInputField(
      initialValue: ref
          .read(transactionQuickFiltersProvider.notifier)
          .getFilterValue(propertyName),
      onChangedFn: (transactionNumber) {
        QuickFilter filter = QuickFilter(
            propertyName, QuickFilterType.equals, transactionNumber);
        ref
            .read(transactionQuickFiltersProvider.notifier)
            .updateFilters(filter);
        ref
            .read(transactionQuickFiltersProvider.notifier)
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
          .read(transactionQuickFiltersProvider.notifier)
          .getFilterValue(propertyName),
      onChangedFn: (amount) {
        QuickFilter filter =
            QuickFilter(propertyName, QuickFilterType.equals, amount);
        ref
            .read(transactionQuickFiltersProvider.notifier)
            .updateFilters(filter);
        ref
            .read(transactionQuickFiltersProvider.notifier)
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
          .read(transactionQuickFiltersProvider.notifier)
          .getFilterValue(propertyName),
      onChangedFn: (notes) {
        QuickFilter filter =
            QuickFilter(propertyName, QuickFilterType.contains, notes);
        ref
            .read(transactionQuickFiltersProvider.notifier)
            .updateFilters(filter);
        ref
            .read(transactionQuickFiltersProvider.notifier)
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
                .read(transactionQuickFiltersProvider.notifier)
                .updateFilters(filter);
            ref
                .read(transactionQuickFiltersProvider.notifier)
                .applyListFilter(context);
            // _dateController.text = DateFormat('dd-MM-yyyy').format(date);
          }
        },
      ),
    );
  }
}
