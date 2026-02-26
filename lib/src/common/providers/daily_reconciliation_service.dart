import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_repository.dart';
import 'package:tablets/src/common/classes/screen_cache_item.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/providers/screen_cache_service.dart';

/// Provider for the reconciliation settings repository
final reconciliationSettingsRepositoryProvider = Provider<DbRepository>((ref) {
  return DbRepository('app_settings');
});

/// Provider for the DailyReconciliationService
final dailyReconciliationServiceProvider =
    Provider<DailyReconciliationService>((ref) {
  return DailyReconciliationService(ref);
});

/// Service that handles daily automatic reconciliation of screen cache data
class DailyReconciliationService {
  DailyReconciliationService(this._ref);

  final Ref _ref;
  static const String _settingsDocId = 'reconciliation_config';
  static const int _reconciliationIntervalHours = 1;

  /// Check if reconciliation is needed and schedule it if so
  /// Call this when the app starts
  Future<void> checkAndScheduleReconciliation(BuildContext context) async {
    try {
      final settings = await _fetchSettings();

      if (settings.isEmpty) {
        // First time - save current timestamp and don't reconcile yet
        await _updateLastReconciliationTimestamp(isFirstTime: true);
        debugLog('First app start - no reconciliation needed');
        return;
      }

      final lastReconciliation =
          settings['lastReconciliationTimestamp'] as int?;
      if (lastReconciliation == null) {
        await _updateLastReconciliationTimestamp(isFirstTime: false);
        return;
      }

      final lastReconciliationDate =
          DateTime.fromMillisecondsSinceEpoch(lastReconciliation);
      final hoursSinceLastReconciliation =
          DateTime.now().difference(lastReconciliationDate).inHours;

      debugLog(
          'Hours since last reconciliation: $hoursSinceLastReconciliation');

      if (hoursSinceLastReconciliation >= _reconciliationIntervalHours) {
        debugLog(
            'Running reconciliation (${_reconciliationIntervalHours}+ hours since last)');
        if (!context.mounted) return;
        // ignore: unawaited_futures - intentionally fire-and-forget, doesn't block app startup
        _runReconciliation(context);
      } else {
        debugLog('No reconciliation needed yet');
      }
    } catch (e) {
      errorPrint('Error checking reconciliation schedule: $e');
    }
  }

  /// Fetch settings from Firebase
  Future<Map<String, dynamic>> _fetchSettings() async {
    final repository = _ref.read(reconciliationSettingsRepositoryProvider);
    final allSettings = await repository.fetchItemListAsMaps(
      filterKey: 'dbRef',
      filterValue: _settingsDocId,
    );
    if (allSettings.isEmpty) return {};
    return allSettings.first;
  }

  /// Run the actual reconciliation
  Future<void> _runReconciliation(BuildContext context) async {
    try {
      debugLog('Starting scheduled daily reconciliation...');

      final cacheService = _ref.read(screenCacheServiceProvider);

      // Refresh all screen data
      await cacheService.refreshAllScreenData(context);

      // Update timestamp
      await _updateLastReconciliationTimestamp(isFirstTime: false);

      debugLog('Daily reconciliation completed successfully');
    } catch (e) {
      errorPrint('Error during daily reconciliation: $e');
    }
  }

  /// Update the last reconciliation timestamp in Firebase
  Future<void> _updateLastReconciliationTimestamp(
      {required bool isFirstTime}) async {
    try {
      final repository = _ref.read(reconciliationSettingsRepositoryProvider);
      final data = {
        'dbRef': _settingsDocId,
        'name': 'Reconciliation Config',
        'lastReconciliationTimestamp': DateTime.now().millisecondsSinceEpoch,
      };
      final item = ScreenCacheItem(data);

      if (isFirstTime) {
        await repository.addItem(item);
      } else {
        await repository.updateItem(item);
      }
    } catch (e) {
      errorPrint('Error updating reconciliation timestamp: $e');
    }
  }

  /// Force run reconciliation immediately (for manual trigger)
  Future<void> forceReconciliation(BuildContext context) async {
    debugLog('Force running reconciliation...');
    await _runReconciliation(context);
  }

  /// Get the last reconciliation date
  Future<DateTime?> getLastReconciliationDate() async {
    try {
      final settings = await _fetchSettings();
      final lastReconciliation =
          settings['lastReconciliationTimestamp'] as int?;
      if (lastReconciliation == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(lastReconciliation);
    } catch (e) {
      return null;
    }
  }
}
