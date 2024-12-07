import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/providers/page_is_loading_notifier.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/features/home/view/home_screen.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/widgets/main_screen_list_cells.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_drawer_provider.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_form_controller.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_report_controller.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_screen_controller.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_screen_data_notifier.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_db_cache_provider.dart';
import 'package:tablets/src/features/salesmen/view/salesman_form.dart';
import 'package:tablets/src/features/salesmen/model/salesman.dart';
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
    final hideSalesmanProfit = settingsController.getProperty(hideSalesmanProfitKey);
    final hideMainScreenColumnTotals =
        settingsController.getProperty(hideMainScreenColumnTotalsKey);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const MainScreenPlaceholder(width: 20, isExpanded: false),
            SortableMainScreenHeaderCell(
                screenDataNotifier, salesmanNameKey, S.of(context).salesman_name),
            SortableMainScreenHeaderCell(
                screenDataNotifier, commissionKey, S.of(context).sum_of_commissions),
            SortableMainScreenHeaderCell(screenDataNotifier, customersKey, S.of(context).customers),
            SortableMainScreenHeaderCell(screenDataNotifier, totalDebtsKey, S.of(context).debts),
            SortableMainScreenHeaderCell(
                screenDataNotifier, openInvoicesKey, S.of(context).open_invoices),
            SortableMainScreenHeaderCell(
                screenDataNotifier, numReceiptsKey, S.of(context).receipts_number),
            SortableMainScreenHeaderCell(
                screenDataNotifier, receiptsAmountKey, S.of(context).receipts_amount),
            SortableMainScreenHeaderCell(
                screenDataNotifier, numInvoicesKey, S.of(context).invoices_number),
            SortableMainScreenHeaderCell(
                screenDataNotifier, invoicesAmountKey, S.of(context).invoices_amount),
            SortableMainScreenHeaderCell(
                screenDataNotifier, numReturnsKey, S.of(context).returns_number),
            SortableMainScreenHeaderCell(
                screenDataNotifier, receiptsAmountKey, S.of(context).returns_amount),
            if (!hideSalesmanProfit)
              SortableMainScreenHeaderCell(screenDataNotifier, profitKey, S.of(context).profits),
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
    final hideSalesmanProfit = settingsController.getProperty(hideSalesmanProfitKey);
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
    final hideSalesmanProfit = settingsController.getProperty(hideSalesmanProfitKey);
    final reportController = ref.read(salesmanReportControllerProvider);
    final customerRef = salesmanScreenData[salesmanDbRefKey];
    final salesmanDbCache = ref.read(salesmanDbCacheProvider.notifier);
    final customerData = salesmanDbCache.getItemByDbRef(customerRef);
    final salesman = Salesman.fromMap(customerData);
    final name = salesmanScreenData[salesmanNameKey] as String;
    final commission = salesmanScreenData[commissionKey].toDouble();
    final commissionDetails = salesmanScreenData[commissionDetailsKey] as List<List<dynamic>>;
    final numCustomers = salesmanScreenData[customersKey].toDouble();
    final customersList = salesmanScreenData[customersDetailsKey] as List<List<dynamic>>;
    final totalDebt = salesmanScreenData[totalDebtsKey].toDouble();
    final dueDebt = salesmanScreenData[dueDbetsKey].toDouble();
    final debtDetails = salesmanScreenData[debtsDetailsKey] as List<List<dynamic>>;
    final openInvoices = salesmanScreenData[openInvoicesKey].toDouble();
    final dueInvoices = salesmanScreenData[dueInvoicesKey].toDouble();
    final openInvoicesDetails = salesmanScreenData[openInvoicesDetailsKey] as List<List<dynamic>>;
    final profit = salesmanScreenData[profitKey].toDouble();
    final profitTransactions = salesmanScreenData[profitDetailsKey] as List<List<dynamic>>;
    final numInvoices = salesmanScreenData[numInvoicesKey].toDouble();
    final invoices = salesmanScreenData[invoicesKey] as List<List<dynamic>>;
    final numReceipts = salesmanScreenData[numReceiptsKey].toDouble();
    final receipts = salesmanScreenData[receiptsKey] as List<List<dynamic>>;
    final invoicesAmount = salesmanScreenData[invoicesAmountKey].toDouble();
    final receiptAmount = salesmanScreenData[receiptsAmountKey].toDouble();
    final returns = salesmanScreenData[returnsKey] as List<List<dynamic>>;
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
            () => reportController.showTransactionReport(context, commissionDetails, name,
                sumIndex: 4),
          ),
          MainScreenClickableCell(
            numCustomers,
            () => reportController.showCustomers(context, customersList, name),
          ),
          MainScreenClickableCell(
            '${doubleToStringWithComma(totalDebt)} \n (${doubleToStringWithComma(dueDebt)})',
            () => reportController.showDebtReport(context, debtDetails, name),
          ),
          MainScreenClickableCell(
            '${doubleToStringWithComma(openInvoices)} (${doubleToStringWithComma(dueInvoices)})',
            () => reportController.showInvoicesReport(context, openInvoicesDetails, name),
          ),
          MainScreenClickableCell(
            numReceipts,
            () => reportController.showTransactionReport(context, receipts, name, isCount: true),
          ),
          MainScreenClickableCell(
            receiptAmount,
            () => reportController.showTransactionReport(context, receipts, name, sumIndex: 4),
          ),
          MainScreenClickableCell(
            numInvoices,
            () => reportController.showTransactionReport(context, invoices, name, isCount: true),
          ),
          MainScreenClickableCell(
            invoicesAmount,
            () => reportController.showTransactionReport(context, invoices, name, sumIndex: 4),
          ),
          MainScreenClickableCell(
            numReturns,
            () => reportController.showTransactionReport(context, returns, name, isCount: true),
          ),
          MainScreenClickableCell(
            returnsAmount,
            () => reportController.showTransactionReport(context, returns, name, sumIndex: 4),
          ),
          if (!hideSalesmanProfit)
            MainScreenClickableCell(
              profit,
              () => reportController.showTransactionReport(context, profitTransactions, name,
                  isProfit: true),
            ),
        ],
      ),
    );
  }

  void _showEditSalesmanForm(BuildContext context, WidgetRef ref, Salesman salesman) {
    ref.read(salesmanFormDataProvider.notifier).initialize(initialData: salesman.toMap());
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
        // SpeedDialChild(
        //   child: const Icon(Icons.pie_chart, color: Colors.white),
        //   backgroundColor: iconsColor,
        //   onTap: () => drawerController.showReports(context),
        // ),
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
