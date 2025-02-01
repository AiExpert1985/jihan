import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/providers/page_is_loading_notifier.dart';
import 'package:tablets/src/common/values/features_keys.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/empty_screen.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/widgets/page_loading.dart';
import 'package:tablets/src/features/products/controllers/product_drawer_provider.dart';
import 'package:tablets/src/features/products/controllers/product_form_data_notifier.dart';
import 'package:tablets/src/features/products/controllers/product_report_controller.dart';
import 'package:tablets/src/features/products/controllers/product_screen_data_notifier.dart';
import 'package:tablets/src/features/products/view/product_form.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/features/home/view/home_screen.dart';
import 'package:tablets/src/common/widgets/main_screen_list_cells.dart';
import 'package:tablets/src/features/products/repository/product_db_cache_provider.dart';
import 'package:tablets/src/features/products/model/product.dart';
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
    final screenDataNotifier = ref.read(productScreenDataNotifier.notifier);
    final settingsController = ref.read(settingsFormDataProvider.notifier);
    final hideProductBuyingPrice = settingsController.getProperty(hideProductBuyingPriceKey);
    final hideProductProfit = settingsController.getProperty(hideProductProfitKey);
    final hideMainScreenColumnTotals =
        settingsController.getProperty(hideMainScreenColumnTotalsKey);
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
            SortableMainScreenHeaderCell(
                screenDataNotifier, productCategoryKey, S.of(context).product_category),
            SortableMainScreenHeaderCell(screenDataNotifier, productCommissionKey,
                S.of(context).product_salesman_commission),
            if (!hideProductBuyingPrice)
              SortableMainScreenHeaderCell(
                  screenDataNotifier, productBuyingPriceKey, S.of(context).product_buying_price),
            SortableMainScreenHeaderCell(screenDataNotifier, productSellingWholeSaleKey,
                S.of(context).product_sell_whole_price),
            SortableMainScreenHeaderCell(screenDataNotifier, productSellingRetailKey,
                S.of(context).product_sell_retail_price),
            SortableMainScreenHeaderCell(
                screenDataNotifier, productQuantityKey, S.of(context).product_stock_quantity),
            SortableMainScreenHeaderCell(
                screenDataNotifier, productTotalStockPriceKey, S.of(context).product_stock_amount),
            if (!hideProductProfit)
              SortableMainScreenHeaderCell(
                  screenDataNotifier, productProfitKey, S.of(context).product_profits),
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
    ref.watch(productScreenDataNotifier);
    final screenDataNotifier = ref.read(productScreenDataNotifier.notifier);
    final summary = screenDataNotifier.summary;
    final totalStockPrice = summary[productTotalStockPriceKey]?['value'] ?? '';
    final settingsController = ref.read(settingsFormDataProvider.notifier);
    final hideProductBuyingPrice = settingsController.getProperty(hideProductBuyingPriceKey);
    final hideProductProfit = settingsController.getProperty(hideProductProfitKey);

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
    final settingsController = ref.read(settingsFormDataProvider.notifier);
    final hideProductBuyingPrice = settingsController.getProperty(hideProductBuyingPriceKey);
    final hideProductProfit = settingsController.getProperty(hideProductProfitKey);
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
          MainScreenNumberedEditButton(sequence, () => _showEditProductForm(context, ref, product)),
          MainScreenTextCell(productScreenData[productNameKey]),
          MainScreenTextCell(productCode),
          MainScreenTextCell(productScreenData[productCategoryKey]),
          MainScreenTextCell(productScreenData[productCommissionKey]),
          if (!hideProductBuyingPrice) MainScreenTextCell(productScreenData[productBuyingPriceKey]),
          MainScreenTextCell(productScreenData[productSellingWholeSaleKey]),
          MainScreenTextCell(productScreenData[productSellingRetailKey]),
          MainScreenClickableCell(
              productScreenData[productQuantityKey],
              () => reportController.showHistoryReport(
                  context, productScreenData[productQuantityDetailsKey], product.name)),
          MainScreenTextCell(productScreenData[productTotalStockPriceKey]),
          if (!hideProductProfit)
            MainScreenClickableCell(
                (productScreenData[productProfitKey]),
                () => reportController.showProfitReport(
                    context, productScreenData[productProfitDetailsKey], product.name)),
        ],
      ),
    );
  }
}

void _showEditProductForm(BuildContext context, WidgetRef ref, Product product) {
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
          onTap: () => showAddProductForm(context, ref),
        ),
      ],
    );
  }
}
