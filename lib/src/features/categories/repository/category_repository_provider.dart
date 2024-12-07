import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_repository.dart';

final categoryRepositoryProvider = Provider<DbRepository>((ref) {
  return DbRepository('categories');
});

// final categoryStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
//   final categoriesRepository = ref.watch(categoryRepositoryProvider);
//   return categoriesRepository.watchItemListAsMaps();
// });
