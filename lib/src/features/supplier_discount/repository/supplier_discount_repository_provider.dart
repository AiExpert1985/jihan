import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_repository.dart';

final supplierDiscountRepositoryProvider =
    Provider<DbRepository>((ref) => DbRepository('supplier_discount'));

final supplierDiscountStreamProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final supplierDiscountRepository = ref.watch(supplierDiscountRepositoryProvider);
  return supplierDiscountRepository.watchItemListAsMaps();
});
