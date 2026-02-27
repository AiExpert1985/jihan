import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/providers/page_is_loading_notifier.dart';
import 'package:tablets/src/common/providers/screen_cache_service.dart';
import 'package:tablets/src/common/providers/user_info_provider.dart';
import 'package:tablets/src/common/values/features_keys.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/empty_screen.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/common/widgets/main_screen_list_cells.dart';
import 'package:tablets/src/common/widgets/page_loading.dart';
import 'package:tablets/src/features/authentication/model/user_account.dart';
import 'package:tablets/src/features/home/view/home_screen.dart';
import 'package:tablets/src/features/products/controllers/product_drawer_provider.dart';
import 'package:tablets/src/features/products/controllers/product_form_data_notifier.dart';
import 'package:tablets/src/features/products/controllers/product_report_controller.dart';
import 'package:tablets/src/features/products/controllers/product_screen_controller.dart';
import 'package:tablets/src/features/products/controllers/product_screen_data_notifier.dart';
import 'package:tablets/src/features/products/model/product.dart';
import 'package:tablets/src/features/products/printing/printing_inventory.dart';
import 'package:tablets/src/features/products/repository/product_db_cache_provider.dart';
import 'package:tablets/src/features/products/repository/product_repository_provider.dart';
import 'package:tablets/src/features/products/view/product_form.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/settings/view/settings_keys.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(productScreenDataNotifier);
    final settingsDataNotifier = ref.read(settingsFormDataProvider.notifier);
    final settingsData = settingsDataNotifier.data;
    // if settings data is empty it means user has refresh the web page &
    // didn't reach the page through pressing the page button
    // in this case he didn't load required dbCaches so, I should hide buttons because
    // using them might cause bugs in the program

    Widget screenWidget = settingsData.isEmpty
        ? const HomeScreen()
        : const AppScreenFrame(
            ProductsList(),
            buttonsWidget: ProductFloatingButtons(),
          );
    return screenWidget;
  }
}

class ProductsList extends ConsumerWidget {
  const ProductsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(productScreenDataNotifier);
    ref.watch(pageIsLoadingNotifier);
    final dbCache = ref.read(productDbCacheProvider.notifier);
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
    final screenDataNotifier = ref.read(productScreenDataNotifier.notifier);
    final screenData = screenDataNotifier.data;
    ref.watch(productScreenDataNotifier);
    return Expanded(
      child: ListView.builder(
        itemCount: screenData.length,
        itemBuilder: (ctx, index) {
          final productData = screenData[index];
          return Column(
            children: [
              DataRow(productData, index + 1),
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
    final userInfo = ref.watch(userInfoProvider);
    final isAccountant = userInfo?.privilage == UserPrivilage.accountant.name;
    final screenDataNotifier = ref.read(productScreenDataNotifier.notifier);
    final settingsController = ref.read(settingsFormDataProvider.notifier);
    final hideProductBuyingPrice =
        settingsController.getProperty(hideProductBuyingPriceKey);
    final hideProductProfit =
        settingsController.getProperty(hideProductProfitKey) || isAccountant;
    final hideMainScreenColumnTotals =
        settingsController.getProperty(hideMainScreenColumnTotalsKey) ||
            isAccountant;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const MainScreenPlaceholder(width: 20, isExpanded: false),
            SortableMainScreenHeaderCell(
                screenDataNotifier, productNameKey, S.of(context).product_name),
            SortableMainScreenHeaderCell(
                screenDataNotifier, productCodeKey, S.of(context).product_code),
            SortableMainScreenHeaderCell(screenDataNotifier, productCategoryKey,
                S.of(context).product_category),
            SortableMainScreenHeaderCell(
                screenDataNotifier,
                productCommissionKey,
                S.of(context).product_salesman_commission),
            if (!hideProductBuyingPrice)
              SortableMainScreenHeaderCell(screenDataNotifier,
                  productBuyingPriceKey, S.of(context).product_buying_price),
            SortableMainScreenHeaderCell(
                screenDataNotifier,
                productSellingWholeSaleKey,
                S.of(context).product_sell_whole_price),
            SortableMainScreenHeaderCell(
                screenDataNotifier,
                productSellingRetailKey,
                S.of(context).product_sell_retail_price),
            SortableMainScreenHeaderCell(screenDataNotifier, productQuantityKey,
                S.of(context).product_stock_quantity),
            SortableMainScreenHeaderCell(screenDataNotifier,
                productTotalStockPriceKey, S.of(context).product_stock_amount),
            if (!hideProductProfit)
              SortableMainScreenHeaderCell(screenDataNotifier, productProfitKey,
                  S.of(context).product_profits),
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
    final userInfo = ref.watch(userInfoProvider);
    final isAccountant = userInfo?.privilage == UserPrivilage.accountant.name;
    ref.watch(productScreenDataNotifier);
    final screenDataNotifier = ref.read(productScreenDataNotifier.notifier);
    final summary = screenDataNotifier.summary;
    final totalStockPrice = summary[productTotalStockPriceKey]?['value'] ?? '';
    final settingsController = ref.read(settingsFormDataProvider.notifier);
    final hideProductBuyingPrice =
        settingsController.getProperty(hideProductBuyingPriceKey);
    final hideProductProfit =
        settingsController.getProperty(hideProductProfitKey) || isAccountant;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const MainScreenPlaceholder(width: 20, isExpanded: false),
        const MainScreenPlaceholder(),
        const MainScreenPlaceholder(),
        const MainScreenPlaceholder(),
        const MainScreenPlaceholder(),
        if (!hideProductBuyingPrice) const MainScreenPlaceholder(),
        const MainScreenPlaceholder(),
        const MainScreenPlaceholder(),
        const MainScreenPlaceholder(),
        MainScreenHeaderCell(totalStockPrice, isColumnTotal: true),
        if (!hideProductProfit) const MainScreenPlaceholder(),
      ],
    );
  }
}

class DataRow extends ConsumerWidget {
  const DataRow(this.productScreenData, this.sequence, {super.key});
  final Map<String, dynamic> productScreenData;
  final int sequence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfo = ref.watch(userInfoProvider);
    final isAccountant = userInfo?.privilage == UserPrivilage.accountant.name;
    final settingsController = ref.read(settingsFormDataProvider.notifier);
    final hideProductBuyingPrice =
        settingsController.getProperty(hideProductBuyingPriceKey);
    final hideProductProfit =
        settingsController.getProperty(hideProductProfitKey) || isAccountant;
    final reportController = ref.read(productReportControllerProvider);
    final productRef = productScreenData[productDbRefKey];
    final productDbCache = ref.read(productDbCacheProvider.notifier);
    final productData = productDbCache.getItemByDbRef(productRef);
    final productCode = productScreenData[productCodeKey];
    final product = Product.fromMap(productData);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MainScreenNumberedEditButton(
              sequence, () => _showEditProductForm(context, ref, product)),
          MainScreenTextCell(productScreenData[productNameKey]),
          MainScreenTextCell(productCode),
          MainScreenTextCell(productScreenData[productCategoryKey]),
          MainScreenTextCell(productScreenData[productCommissionKey]),
          if (!hideProductBuyingPrice)
            MainScreenTextCell(productScreenData[productBuyingPriceKey]),
          MainScreenTextCell(productScreenData[productSellingWholeSaleKey]),
          MainScreenTextCell(productScreenData[productSellingRetailKey]),
          MainScreenClickableCell(productScreenData[productQuantityKey], () {
            final controller = ref.read(productScreenControllerProvider);
            // productData is already fetched above (line 222)
            final fullData = controller.getItemScreenData(context, productData);
            final details = fullData[productQuantityDetailsKey];
            reportController.showHistoryReport(context, details, product.name);
          }),
          MainScreenTextCell(productScreenData[productTotalStockPriceKey]),
          if (!hideProductProfit)
            MainScreenClickableCell((productScreenData[productProfitKey]), () {
              final controller = ref.read(productScreenControllerProvider);
              final fullData =
                  controller.getItemScreenData(context, productData);
              final details = fullData[productProfitDetailsKey];
              reportController.showProfitReport(context, details, product.name);
            }),
        ],
      ),
    );
  }
}

// this method return List of Maps, in the form {'productName': 'بطيخ احمر', 'productQuantity': 10}
// filter product if it is hidden, and if it is equal or less than zero
List<Map<String, dynamic>> getFilterProductInventory(
    WidgetRef ref, bool specialReport) {
  final productDbCache = ref.read(productDbCacheProvider.notifier);

  final screenDataNotifier = ref.read(productScreenDataNotifier.notifier);
  final screenData = screenDataNotifier.data;
  tempPrint(screenData.length);
  List<Map<String, dynamic>> filteredProductInventory = [];
  for (var productData in screenData) {
    final productRef = productData[productDbRefKey];
    final productMap = productDbCache.getItemByDbRef(productRef);
    final product = Product.fromMap(productMap);
    final productQuantity = productData[productQuantityKey];
    if (!specialReport) {
      filteredProductInventory.add(
          {'productName': product.name, 'productQuantity': productQuantity});
    } else if (specialReport &&
        productQuantity > 0 &&
        product.isHiddenInSpecialReports != null &&
        !product.isHiddenInSpecialReports!) {
      filteredProductInventory.add(
          {'productName': product.name, 'productQuantity': productQuantity});
    } else {
      errorPrint('error when printing inventory');
    }
  }
  // --- SORTING THE INPUT LIST BY PRODUCT NAME ---
  // We sort the productMaps list directly.
  // If you need to preserve the original order of productMaps outside this function,
  // you should sort a copy: final sortedProductMaps = List<Map<String, dynamic>>.from(productMaps);
  // and then use sortedProductMaps below. For this function's purpose, sorting in place is fine.
  filteredProductInventory.sort((a, b) {
    final aNameObj = a['productName'];
    final bNameObj = b['productName'];

    // Ensure both are strings for comparison.
    // Dart's String.compareTo() works well for Arabic alphabetical sorting.
    if (aNameObj is String && bNameObj is String) {
      return aNameObj.compareTo(bNameObj);
    }
    // Handle cases where one or both might not be strings or are null,
    // to prevent runtime errors during sort, though the filter below is stricter.
    else if (aNameObj is String) {
      return -1; // Valid names come before invalid/null ones
    } else if (bNameObj is String) {
      return 1; // Invalid/null names come after valid ones
    }
    return 0; // If both are not strings or null, keep their relative order
  });
  // --- END OF SORTING ---
  return filteredProductInventory;
}

// if sepcialReport = true, then we will hide products, and also hide zero (or less) items
Future<void> _printProducts(BuildContext context, WidgetRef ref,
    {bool specialReport = false}) async {
  try {
    final myProductsData = getFilterProductInventory(ref, specialReport);
    final Uint8List pdfBytes = await ProductListPdfGenerator.generatePdf(
      myProductsData,
      reportTitle: "تقرير المخزون",
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'product_list_map_${DateTime.now().toIso8601String()}.pdf');
  } catch (e) {
    debugPrint("Error generating PDF: $e");
  }
}

void _showPrintDialog(BuildContext context, WidgetRef ref) {
  // Define desired button height, padding and spacing
  const double buttonHeight = 50.0; // Adjust as needed
  const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0); // Adjust padding
  const double spacingBelowButtons = 20.0; // Adjust as needed
  const double spacingBetweenButtons = 20.0;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          'اختر نوع الطباعة', // "Choose print type"
          textAlign: TextAlign.right, // Align title to the right for Arabic
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Make buttons stretch
          children: <Widget>[
            const SizedBox(
              height: 10,
            ),
            // Button 1 with increased height and padding
            SizedBox(
              height: buttonHeight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: buttonPadding,
                ),
                child: const Text('طباعة جرد شركة جيهان'),
                onPressed: () {
                  // Action for "طباعة جرد شركة جيهان"
                  Navigator.of(context).pop(); // Close the dialog
                  _printProducts(context, ref, specialReport: true);
                },
              ),
            ),
            const SizedBox(
                height: spacingBetweenButtons), // Space between buttons

            // Button 2 with increased height and padding
            SizedBox(
              height: buttonHeight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: buttonPadding,
                ),
                child: const Text('طباعة جرد مخزني عام'),
                onPressed: () {
                  // Action for "طباعة جرد مخزني عام"
                  Navigator.of(context).pop(); // Close the dialog
                  _printProducts(context, ref);
                },
              ),
            ),
            const SizedBox(
                height: spacingBelowButtons), // Space below the buttons
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('إلغاء'), // "Cancel"
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
        ],
      );
    },
  );
}

void _showEditProductForm(
    BuildContext context, WidgetRef ref, Product product) {
  final imagePickerNotifier = ref.read(imagePickerProvider.notifier);
  final formDataNotifier = ref.read(productFormDataProvider.notifier);
  formDataNotifier.initialize(initialData: product.toMap());
  imagePickerNotifier.initialize(urls: product.imageUrls);
  showDialog(
    context: context,
    builder: (BuildContext ctx) => const ProductForm(isEditMode: true),
  ).whenComplete(imagePickerNotifier.close);
}

class ProductFloatingButtons extends ConsumerWidget {
  const ProductFloatingButtons({super.key});

  Future<void> _refreshScreenData(BuildContext context, WidgetRef ref) async {
    successUserMessage(context, "تحديث البيانات");
    final newData =
        await ref.read(productRepositoryProvider).fetchItemListAsMaps();
    ref.read(productDbCacheProvider.notifier).set(newData);
    final cacheService = ref.read(screenCacheServiceProvider);
    // ignore: use_build_context_synchronously
    await cacheService.refreshProductScreenData(context);
    if (context.mounted) {
      successUserMessage(context, "تم تحديث البيانات بنجاح");
    }
  }

  void showAddProductForm(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.read(productFormDataProvider.notifier);

    formDataNotifier.initialize();
    formDataNotifier.updateProperties({'initialDate': DateTime.now()});
    final imagePicker = ref.read(imagePickerProvider.notifier);
    imagePicker.initialize();
    showDialog(
      context: context,
      builder: (BuildContext ctx) => const ProductForm(),
    ).whenComplete(imagePicker.close);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawerController = ref.watch(productsDrawerControllerProvider);
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
          child: const Icon(Icons.print, color: Colors.white),
          backgroundColor: iconsColor,
          onTap: () => _showPrintDialog(context, ref),
        ),
        SpeedDialChild(
          child: const Icon(Icons.search, color: Colors.white),
          backgroundColor: iconsColor,
          onTap: () => drawerController.showSearchForm(context),
        ),
        SpeedDialChild(
          child: const Icon(Icons.add, color: Colors.white),
          backgroundColor: iconsColor,
          onTap: () => showAddProductForm(context, ref),
        ),
      ],
    );
  }
}
