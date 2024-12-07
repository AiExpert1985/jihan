import 'package:anydrawer/anydrawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/screen_data_filters.dart';
import 'package:tablets/src/common/values/features_keys.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/search_form.dart';
import 'package:tablets/src/features/products/controllers/product_filter_controller.dart';
import 'package:tablets/src/features/products/controllers/product_screen_controller.dart';
import 'package:tablets/src/features/products/controllers/product_screen_data_notifier.dart';

class ProductSearchForm extends ConsumerWidget {
  const ProductSearchForm(this._drawerController, {super.key});

  final AnyDrawerController _drawerController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterController = ref.read(productFilterController);
    final screenDataController = ref.read(productScreenControllerProvider);
    final screenDataNotifier = ref.read(productScreenDataNotifier.notifier);
    final bodyWidgets = _buildBodyWidgets(filterController, context);
    final title = S.of(context).product_search;
    return SearchForm(
      title,
      _drawerController,
      filterController,
      screenDataController,
      screenDataNotifier,
      bodyWidgets,
    );
  }

  List<Widget> _buildBodyWidgets(ScreenDataFilters filterController, BuildContext context) {
    return [
      NumberMatchSearchField(
          filterController, 'codeEquals', productCodeKey, S.of(context).product_code),
      VerticalGap.l,
      TextSearchField(filterController, 'nameContains', productNameKey, S.of(context).product_name),
      VerticalGap.l,
      TextSearchField(
          filterController, 'categoryContains', productCategoryKey, S.of(context).product_category),
      VerticalGap.l,
      NumberRangeSearchField(filterController, 'commissionMoreThanOrEqual',
          'commissionLessThanOrEqual', productCommissionKey, S.of(context).commission),
      VerticalGap.l,
      NumberRangeSearchField(filterController, 'buyingPriceMoreThanOrEqual',
          'buyingPriceLessThanOrEqual', productBuyingPriceKey, S.of(context).product_buying_price),
      VerticalGap.l,
      NumberRangeSearchField(
          filterController,
          'sellingWholeMoreThanOrEqual',
          'SellingWholeLessThanOrEqual',
          productSellingWholeSaleKey,
          S.of(context).product_sell_whole_price),
      VerticalGap.l,
      NumberRangeSearchField(
          filterController,
          'sellingRetailMoreThanOrEqual',
          'SellingRetailLessThanOrEqual',
          productSellingRetailKey,
          S.of(context).product_sell_retail_price),
      VerticalGap.l,
      NumberRangeSearchField(filterController, 'quantityMoreThanOrEqual', 'quantityLessThanOrEqual',
          productQuantityKey, S.of(context).product_stock_quantity),
      VerticalGap.l,
      NumberRangeSearchField(
          filterController,
          'StockPriceMoreThanOrEqual',
          'StockPriceLessThanOrEqual',
          productTotalStockPriceKey,
          S.of(context).product_stock_amount),
      VerticalGap.l,
      NumberRangeSearchField(filterController, 'ProfitThanOrEqual', 'ProfitLessThanOrEqual',
          productProfitKey, S.of(context).product_profits),
    ];
  }
}
