import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/interfaces/screen_controller.dart';
import 'package:tablets/src/common/providers/screen_data_notifier.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:flutter/material.dart';
import 'package:tablets/src/features/pending_transactions/controllers/pending_transaction_screen_data_notifier.dart';
import 'package:tablets/src/features/pending_transactions/repository/pending_transaction_db_cache_provider.dart';

final pendingTransactionScreenControllerProvider =
    Provider<PendingTransactionScreenController>((ref) {
  final screenDataNotifier = ref.read(pendingTransactionScreenDataNotifier.notifier);
  final dbCache = ref.read(pendingTransactionDbCacheProvider.notifier);
  return PendingTransactionScreenController(screenDataNotifier, dbCache);
});

class PendingTransactionScreenController implements ScreenDataController {
  PendingTransactionScreenController(
    this._screenDataNotifier,
    this._dbCache,
  );
  final ScreenDataNotifier _screenDataNotifier;
  final DbCache _dbCache;

  @override
  void setFeatureScreenData(BuildContext context) {
    final dbCacheDataCopy = deepCopyDbCache(_dbCache.data);
    _screenDataNotifier.initialize({});
    for (var mapData in dbCacheDataCopy) {
      mapData['transactionType'] = translateDbTextToScreenText(context, mapData['transactionType']);
    }
    _screenDataNotifier.set(dbCacheDataCopy);
  }

  /// create a list of lists, where each resulting list contains transaction info
  /// [type, number, date, totalQuantity, totalProfit, totalSalesmanCommission, ]
  @override
  Map<String, dynamic> getItemScreenData(
      BuildContext context, Map<String, dynamic> transactionData) {
    final dbRef = transactionData['dbRefKey'];
    return _dbCache.getItemByDbRef(dbRef);
  }
}
