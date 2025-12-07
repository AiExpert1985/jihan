import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_repository.dart';

/// Repository provider for customer_screen_data collection
final customerScreenCacheRepositoryProvider = Provider<DbRepository>((ref) {
  return DbRepository('customer_screen_data');
});

/// Repository provider for product_screen_data collection
final productScreenCacheRepositoryProvider = Provider<DbRepository>((ref) {
  return DbRepository('product_screen_data');
});

/// Repository provider for salesman_screen_data collection
final salesmanScreenCacheRepositoryProvider = Provider<DbRepository>((ref) {
  return DbRepository('salesman_screen_data');
});
