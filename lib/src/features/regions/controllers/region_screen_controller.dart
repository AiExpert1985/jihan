import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/interfaces/screen_controller.dart';
import 'package:tablets/src/common/providers/screen_data_notifier.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:flutter/material.dart';
import 'package:tablets/src/features/regions/controllers/region_screen_data_notifier.dart';
import 'package:tablets/src/features/regions/repository/region_db_cache_provider.dart';

const String regionDbRefKey = 'dbRef';
const String regionNameKey = 'name';

final regionScreenControllerProvider = Provider<RegionScreenController>((ref) {
  final screenDataNotifier = ref.read(regionScreenDataNotifier.notifier);
  final regionDbCache = ref.read(regionDbCacheProvider.notifier);
  return RegionScreenController(screenDataNotifier, regionDbCache);
});

class RegionScreenController implements ScreenDataController {
  RegionScreenController(
    this._screenDataNotifier,
    this._regionDbCache,
  );
  final ScreenDataNotifier _screenDataNotifier;
  final DbCache _regionDbCache;

  @override
  void setFeatureScreenData(BuildContext context) {
    final dbCache = [..._regionDbCache.data];
    _screenDataNotifier.initialize({});
    _screenDataNotifier.set(dbCache);
  }

  /// create a list of lists, where each resulting list contains transaction info
  /// [type, number, date, totalQuantity, totalProfit, totalSalesmanCommission, ]
  @override
  Map<String, dynamic> getItemScreenData(BuildContext context, Map<String, dynamic> regionsData) {
    final dbRef = regionsData['dbRefKey'];
    return _regionDbCache.getItemByDbRef(dbRef);
  }
}
