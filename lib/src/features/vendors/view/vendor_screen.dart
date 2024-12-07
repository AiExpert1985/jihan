import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/providers/page_is_loading_notifier.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/features/home/view/home_screen.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/widgets/main_screen_list_cells.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/settings/view/settings_keys.dart';
import 'package:tablets/src/features/vendors/controllers/vendor_drawer_provider.dart';
import 'package:tablets/src/features/vendors/controllers/vendor_form_controller.dart';
import 'package:tablets/src/features/vendors/controllers/vendor_report_controller.dart';
import 'package:tablets/src/features/vendors/controllers/vendor_screen_controller.dart';
import 'package:tablets/src/features/vendors/controllers/vendor_screen_data_notifier.dart';
import 'package:tablets/src/features/vendors/repository/vendor_db_cache_provider.dart';
import 'package:tablets/src/features/vendors/view/vendor_form.dart';
import 'package:tablets/src/features/vendors/model/vendor.dart';

class VendorScreen extends ConsumerWidget {
  const VendorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(vendorScreenDataNotifier);
    final settingsDataNotifier = ref.read(settingsFormDataProvider.notifier);
    final settingsData = settingsDataNotifier.data;
    // if settings data is empty it means user has refresh the web page &
    // didn't reach the page through pressing the page button
    // in this case he didn't load required dbCaches so, I should hide buttons because
    // using them might cause bugs in the program
    Widget screenWidget = settingsData.isEmpty
        ? const HomeScreen()
        : const AppScreenFrame(
            VendorList(),
            buttonsWidget: VendorFloatingButtons(),
          );
    return screenWidget;
  }
}

class VendorList extends ConsumerWidget {
  const VendorList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(vendorScreenDataNotifier);
    ref.watch(pageIsLoadingNotifier);
    final dbCache = ref.read(vendorDbCacheProvider.notifier);
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
    final screenDataNotifier = ref.read(vendorScreenDataNotifier.notifier);
    final screenData = screenDataNotifier.data;
    ref.watch(vendorScreenDataNotifier);
    return Expanded(
      child: ListView.builder(
        itemCount: screenData.length,
        itemBuilder: (ctx, index) {
          final vendorData = screenData[index];
          return Column(
            children: [
              DataRow(vendorData, index + 1),
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
    final screenDataNotifier = ref.read(vendorScreenDataNotifier.notifier);
    final settingsController = ref.read(settingsFormDataProvider.notifier);
    final hideMainScreenColumnTotals =
        settingsController.getProperty(hideMainScreenColumnTotalsKey);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const MainScreenPlaceholder(width: 20, isExpanded: false),
            SortableMainScreenHeaderCell(screenDataNotifier, vendorNameKey, S.of(context).vendor),
            SortableMainScreenHeaderCell(screenDataNotifier, vendorPhoneKey, S.of(context).phone),
            SortableMainScreenHeaderCell(
                screenDataNotifier, vendorTotalDebtKey, S.of(context).current_debt),
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
    ref.watch(vendorScreenDataNotifier);
    final screenDataNotifier = ref.read(vendorScreenDataNotifier.notifier);
    final summary = screenDataNotifier.summary;
    final totalDebt = summary[vendorTotalDebtKey]?['value'] ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const MainScreenPlaceholder(width: 20, isExpanded: false),
        const MainScreenPlaceholder(),
        const MainScreenPlaceholder(),
        MainScreenHeaderCell(totalDebt, isColumnTotal: true),
      ],
    );
  }
}

class DataRow extends ConsumerWidget {
  const DataRow(this.vendorScreenData, this.sequence, {super.key});
  final Map<String, dynamic> vendorScreenData;
  final int sequence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportController = ref.read(vendorReportControllerProvider);
    final productRef = vendorScreenData[vendorDbRefKey];
    final productDbCache = ref.read(vendorDbCacheProvider.notifier);
    final customerData = productDbCache.getItemByDbRef(productRef);
    final vendor = Vendor.fromMap(customerData);
    final name = vendorScreenData[vendorNameKey] as String;
    final phone = vendorScreenData[vendorPhoneKey] as String;
    final totalDebt = vendorScreenData[vendorTotalDebtKey] as double;
    final matchingList = vendorScreenData[vendorTotalDebtDetailsKey] as List<List<dynamic>>;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MainScreenNumberedEditButton(sequence, () => _showEditVendorForm(context, ref, vendor)),
          MainScreenTextCell(name),
          MainScreenTextCell(phone),
          MainScreenClickableCell(
            totalDebt,
            () => reportController.showVendorMatchingReport(context, matchingList, name),
          ),
        ],
      ),
    );
  }

  void _showEditVendorForm(BuildContext context, WidgetRef ref, Vendor vendor) {
    ref.read(vendorFormDataProvider.notifier).initialize(initialData: vendor.toMap());
    final imagePicker = ref.read(imagePickerProvider.notifier);
    imagePicker.initialize(urls: vendor.imageUrls);
    showDialog(
      context: context,
      builder: (BuildContext ctx) => const VendorForm(
        isEditMode: true,
      ),
    ).whenComplete(imagePicker.close);
  }
}

class VendorFloatingButtons extends ConsumerWidget {
  const VendorFloatingButtons({super.key});

  void showAddVendorForm(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.read(vendorFormDataProvider.notifier);
    formDataNotifier.initialize();
    formDataNotifier.updateProperties({
      'initialDate': DateTime.now(),
    });
    final imagePicker = ref.read(imagePickerProvider.notifier);
    imagePicker.initialize();
    showDialog(
      context: context,
      builder: (BuildContext ctx) => const VendorForm(),
    ).whenComplete(imagePicker.close);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawerController = ref.watch(vendorDrawerControllerProvider);
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
          onTap: () => showAddVendorForm(context, ref),
        ),
      ],
    );
  }
}
