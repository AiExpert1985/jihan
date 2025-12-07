import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/providers/page_is_loading_notifier.dart';
import 'package:tablets/src/common/providers/screen_cache_service.dart';
import 'package:tablets/src/common/providers/user_info_provider.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/empty_screen.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/common/widgets/main_screen_list_cells.dart';
import 'package:tablets/src/common/widgets/page_loading.dart';
import 'package:tablets/src/features/authentication/model/user_account.dart';
import 'package:tablets/src/features/home/view/home_screen.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_drawer_provider.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_form_controller.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_report_controller.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_screen_controller.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_screen_data_notifier.dart';
import 'package:tablets/src/features/salesmen/model/salesman.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_db_cache_provider.dart';
import 'package:tablets/src/features/salesmen/view/salesman_form.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/settings/view/settings_keys.dart';

class SalesmanScreen extends ConsumerWidget {
  const SalesmanScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(salesmanDbCacheProvider);
    ref.watch(salesmanScreenDataNotifier);
    final settingsDataNotifier = ref.read(settingsFormDataProvider.notifier);
    final settingsData = settingsDataNotifier.data;
    // if settings data is empty it means user has refresh the web page &
    // didn't reach the page through pressing the page button
    // in this case he didn't load required dbCaches so, I should hide buttons because
    // using them might cause bugs in the program
    Widget screenWidget = settingsData.isEmpty
        ? const HomeScreen()
        : const AppScreenFrame(
            SalesmanList(),
            buttonsWidget: SalesmanFloatingButtons(),
          );
    return screenWidget;
  }
}

class SalesmanList extends ConsumerWidget {
  const SalesmanList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(salesmanScreenDataNotifier);
    ref.watch(pageIsLoadingNotifier);
    final dbCache = ref.read(salesmanDbCacheProvider.notifier);
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
    final screenDataNotifier = ref.read(salesmanScreenDataNotifier.notifier);
    final screenData = screenDataNotifier.data;
    ref.watch(salesmanScreenDataNotifier);
    return Expanded(
      child: ListView.builder(
        itemCount: screenData.length,
        itemBuilder: (ctx, index) {
          final vendorData = screenData[index];
          return Column(
            children: [
              DataRow(vendorData),
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
    final screenDataNotifier = ref.read(salesmanScreenDataNotifier.notifier);
    final settingsController = ref.read(settingsFormDataProvider.notifier);
    final userInfo = ref.watch(userInfoProvider);
    final isAccountant = userInfo?.privilage == UserPrivilage.accountant.name;
    final hideSalesmanProfit =
        settingsController.getProperty(hideSalesmanProfitKey) || isAccountant;
    final hideMainScreenColumnTotals =
        settingsController.getProperty(hideMainScreenColumnTotalsKey);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const MainScreenPlaceholder(width: 20, isExpanded: false),
            SortableMainScreenHeaderCell(screenDataNotifier, salesmanNameKey,
                S.of(context).salesman_name),
            SortableMainScreenHeaderCell(screenDataNotifier, commissionKey,
                S.of(context).sum_of_commissions),
            SortableMainScreenHeaderCell(
                screenDataNotifier, customersKey, S.of(context).customers),
            SortableMainScreenHeaderCell(
                screenDataNotifier, totalDebtsKey, S.of(context).debts),
            SortableMainScreenHeaderCell(screenDataNotifier, openInvoicesKey,
                S.of(context).open_invoices),
            SortableMainScreenHeaderCell(screenDataNotifier, numReceiptsKey,
                S.of(context).receipts_number),
            SortableMainScreenHeaderCell(screenDataNotifier, receiptsAmountKey,
                S.of(context).receipts_amount),
            SortableMainScreenHeaderCell(screenDataNotifier, numInvoicesKey,
                S.of(context).invoices_number),
            SortableMainScreenHeaderCell(screenDataNotifier, invoicesAmountKey,
                S.of(context).invoices_amount),
            SortableMainScreenHeaderCell(screenDataNotifier, numReturnsKey,
                S.of(context).returns_number),
            SortableMainScreenHeaderCell(screenDataNotifier, receiptsAmountKey,
                S.of(context).returns_amount),
            if (!hideSalesmanProfit)
              SortableMainScreenHeaderCell(
                  screenDataNotifier, profitKey, S.of(context).profits),
          ],
        ),
        VerticalGap.m,
        if (!hideMainScreenColumnTotals) const HeaderTotalsRow()
      ],
    );
  }
}

class HeaderTotalsRow extends ConsumerWidget {
  const HeaderTotalsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsController = ref.read(settingsFormDataProvider.notifier);
    final userInfo = ref.watch(userInfoProvider);
    final isAccountant = userInfo?.privilage == UserPrivilage.accountant.name;
    final hideSalesmanProfit =
        settingsController.getProperty(hideSalesmanProfitKey) || isAccountant;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const MainScreenPlaceholder(width: 20, isExpanded: false),
        const MainScreenPlaceholder(),
        const MainScreenPlaceholder(),
        const MainScreenPlaceholder(),
        const MainScreenPlaceholder(),
        const MainScreenPlaceholder(),
        const MainScreenPlaceholder(),
        const MainScreenPlaceholder(),
        const MainScreenPlaceholder(),
        const MainScreenPlaceholder(),
        const MainScreenPlaceholder(),
        const MainScreenPlaceholder(),
        if (!hideSalesmanProfit) const MainScreenPlaceholder(),
      ],
    );
  }
}

class DataRow extends ConsumerWidget {
  const DataRow(this.salesmanScreenData, {super.key});
  final Map<String, dynamic> salesmanScreenData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsController = ref.read(settingsFormDataProvider.notifier);
    final userInfo = ref.watch(userInfoProvider);
    final isAccountant = userInfo?.privilage == UserPrivilage.accountant.name;
    final hideSalesmanProfit =
        settingsController.getProperty(hideSalesmanProfitKey) || isAccountant;
    final reportController = ref.read(salesmanReportControllerProvider);
    final customerRef = salesmanScreenData[salesmanDbRefKey];
    final salesmanDbCache = ref.read(salesmanDbCacheProvider.notifier);
    final customerData = salesmanDbCache.getItemByDbRef(customerRef);
    final salesman = Salesman.fromMap(customerData);
    final name = salesmanScreenData[salesmanNameKey] as String;
    final commission = salesmanScreenData[commissionKey].toDouble();
    // Lazy Calculation: Lists are empty in cache, calculated on click.
    // final commissionDetails =
    //     toNestedList(salesmanScreenData[commissionDetailsKey]);
    final numCustomers = salesmanScreenData[customersKey].toDouble();
    // final customersList = toNestedList(salesmanScreenData[customersDetailsKey]);
    final totalDebt = salesmanScreenData[totalDebtsKey].toDouble();
    final dueDebt = salesmanScreenData[dueDbetsKey].toDouble();
    // final debtDetails = toNestedList(salesmanScreenData[debtsDetailsKey]);
    final openInvoices = salesmanScreenData[openInvoicesKey].toDouble();
    final dueInvoices = salesmanScreenData[dueInvoicesKey].toDouble();
    // final openInvoicesDetails =
    //     toNestedList(salesmanScreenData[openInvoicesDetailsKey]);
    final profit = salesmanScreenData[profitKey].toDouble();
    // final profitTransactions =
    //     toNestedList(salesmanScreenData[profitDetailsKey]);
    final numInvoices = salesmanScreenData[numInvoicesKey].toDouble();
    // final invoices = toNestedList(salesmanScreenData[invoicesKey]);
    final numReceipts = salesmanScreenData[numReceiptsKey].toDouble();
    // final receipts = toNestedList(salesmanScreenData[receiptsKey]);
    final invoicesAmount = salesmanScreenData[invoicesAmountKey].toDouble();
    final receiptAmount = salesmanScreenData[receiptsAmountKey].toDouble();
    // final returns = toNestedList(salesmanScreenData[returnsKey]);
    final numReturns = salesmanScreenData[numReturnsKey].toDouble();
    final returnsAmount = salesmanScreenData[returnsAmountKey].toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MainScreenEditButton(
            defaultImageUrl,
            () => _showEditSalesmanForm(context, ref, salesman),
          ),
          MainScreenTextCell(name),
          MainScreenClickableCell(
            commission,
            () {
              final controller = ref.read(salesmanScreenControllerProvider);
              final fullData =
                  controller.getItemScreenData(context, customerData);
              final details = toNestedList(fullData[commissionDetailsKey]);
              reportController.showTransactionReport(context, details, name,
                  sumIndex: 6, isProfit: true);
            },
          ),
          MainScreenClickableCell(
            numCustomers,
            () {
              final controller = ref.read(salesmanScreenControllerProvider);
              final fullData =
                  controller.getItemScreenData(context, customerData);
              final details = toNestedList(fullData[customersDetailsKey]);
              reportController.showCustomers(context, details, name);
            },
          ),
          MainScreenClickableCell(
            '${doubleToStringWithComma(totalDebt)} \n (${doubleToStringWithComma(dueDebt)})',
            () {
              final controller = ref.read(salesmanScreenControllerProvider);
              final fullData =
                  controller.getItemScreenData(context, customerData);
              final details = toNestedList(fullData[debtsDetailsKey]);
              reportController.showDebtReport(context, details, name);
            },
          ),
          MainScreenClickableCell(
            '${doubleToStringWithComma(openInvoices)} (${doubleToStringWithComma(dueInvoices)})',
            () {
              final controller = ref.read(salesmanScreenControllerProvider);
              final fullData =
                  controller.getItemScreenData(context, customerData);
              final details = toNestedList(fullData[openInvoicesDetailsKey]);
              reportController.showInvoicesReport(context, details, name);
            },
          ),
          MainScreenClickableCell(
            numReceipts,
            () {
              final controller = ref.read(salesmanScreenControllerProvider);
              final fullData =
                  controller.getItemScreenData(context, customerData);
              final details = toNestedList(fullData[receiptsKey]);
              reportController.showTransactionReport(context, details, name);
            },
          ),
          MainScreenClickableCell(
            receiptAmount,
            () {
              final controller = ref.read(salesmanScreenControllerProvider);
              final fullData =
                  controller.getItemScreenData(context, customerData);
              final details = toNestedList(fullData[receiptsKey]);
              reportController.showTransactionReport(context, details, name,
                  sumIndex: 6);
            },
          ),
          MainScreenClickableCell(
            numInvoices,
            () {
              final controller = ref.read(salesmanScreenControllerProvider);
              final fullData =
                  controller.getItemScreenData(context, customerData);
              final details = toNestedList(fullData[invoicesKey]);
              reportController.showTransactionReport(context, details, name);
            },
          ),
          MainScreenClickableCell(
            invoicesAmount,
            () {
              final controller = ref.read(salesmanScreenControllerProvider);
              final fullData =
                  controller.getItemScreenData(context, customerData);
              final details = toNestedList(fullData[invoicesKey]);
              reportController.showTransactionReport(context, details, name,
                  sumIndex: 6);
            },
          ),
          MainScreenClickableCell(
            numReturns,
            () {
              final controller = ref.read(salesmanScreenControllerProvider);
              final fullData =
                  controller.getItemScreenData(context, customerData);
              final details = toNestedList(fullData[returnsKey]);
              reportController.showTransactionReport(context, details, name);
            },
          ),
          MainScreenClickableCell(
            returnsAmount,
            () {
              final controller = ref.read(salesmanScreenControllerProvider);
              final fullData =
                  controller.getItemScreenData(context, customerData);
              final details = toNestedList(fullData[returnsKey]);
              reportController.showTransactionReport(context, details, name,
                  sumIndex: 6);
            },
          ),
          if (!hideSalesmanProfit)
            MainScreenClickableCell(
              profit,
              () {
                final controller = ref.read(salesmanScreenControllerProvider);
                final fullData =
                    controller.getItemScreenData(context, customerData);
                final details = toNestedList(fullData[profitDetailsKey]);
                reportController.showTransactionReport(context, details, name,
                    sumIndex: 6, isProfit: true);
              },
            ),
        ],
      ),
    );
  }

  void _showEditSalesmanForm(
      BuildContext context, WidgetRef ref, Salesman salesman) {
    ref
        .read(salesmanFormDataProvider.notifier)
        .initialize(initialData: salesman.toMap());
    final imagePicker = ref.read(imagePickerProvider.notifier);
    imagePicker.initialize(urls: salesman.imageUrls);
    showDialog(
      context: context,
      builder: (BuildContext ctx) => const SalesmanForm(
        isEditMode: true,
      ),
    ).whenComplete(imagePicker.close);
  }
}

class SalesmanFloatingButtons extends ConsumerWidget {
  const SalesmanFloatingButtons({super.key});

  Future<void> _refreshScreenData(BuildContext context, WidgetRef ref) async {
    successUserMessage(context, "تحديث البيانات");
    final cacheService = ref.read(screenCacheServiceProvider);
    await cacheService.refreshSalesmanScreenData(context);
    if (context.mounted) {
      successUserMessage(context, "تم تحديث البيانات بنجاح");
    }
  }

  void showAddSalesmanForm(BuildContext context, WidgetRef ref) {
    ref.read(salesmanFormDataProvider.notifier).initialize();
    final imagePicker = ref.read(imagePickerProvider.notifier);
    imagePicker.initialize();
    showDialog(
      context: context,
      builder: (BuildContext ctx) => const SalesmanForm(),
    ).whenComplete(imagePicker.close);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawerController = ref.watch(salesmanDrawerControllerProvider);
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
          onTap: () => _refreshScreenData(context, ref),
        ),
        SpeedDialChild(
          child: const Icon(Icons.search, color: Colors.white),
          backgroundColor: iconsColor,
          onTap: () => drawerController.showSearchForm(context),
        ),
        SpeedDialChild(
          child: const Icon(Icons.add, color: Colors.white),
          backgroundColor: iconsColor,
          onTap: () => showAddSalesmanForm(context, ref),
        ),
      ],
    );
  }
}
