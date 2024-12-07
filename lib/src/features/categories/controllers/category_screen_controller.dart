import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/interfaces/screen_controller.dart';
import 'package:tablets/src/common/providers/screen_data_notifier.dart';
import 'package:tablets/src/features/categories/controllers/category_screen_data_notifier.dart';
import 'package:tablets/src/features/categories/repository/category_db_cache_provider.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:flutter/material.dart';

const String categoryDbRefKey = 'dbRef';
const String categoryNameKey = 'name';

final categoryScreenControllerProvider = Provider<CategoryScreenController>((ref) {
  final screenDataNotifier = ref.read(categoryScreenDataNotifier.notifier);
  final categoriesDbCache = ref.read(categoryDbCacheProvider.notifier);
  return CategoryScreenController(screenDataNotifier, categoriesDbCache);
});

class CategoryScreenController implements ScreenDataController {
  CategoryScreenController(
    this._screenDataNotifier,
    this._categoriesDbCache,
  );
  final ScreenDataNotifier _screenDataNotifier;
  final DbCache _categoriesDbCache;

  @override
  void setFeatureScreenData(BuildContext context) {
    final dbCache = [..._categoriesDbCache.data];
    _screenDataNotifier.initialize({});
    _screenDataNotifier.set(dbCache);
  }

  /// create a list of lists, where each resulting list contains transaction info
  /// [type, number, date, totalQuantity, totalProfit, totalSalesmanCommission, ]
  @override
  Map<String, dynamic> getItemScreenData(BuildContext context, Map<String, dynamic> categoryData) {
    final dbRef = categoryData['dbRefKey'];
    return _categoriesDbCache.getItemByDbRef(dbRef);
  }
}
