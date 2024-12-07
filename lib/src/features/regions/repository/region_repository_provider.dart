import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_repository.dart';

final regionRepositoryProvider = Provider<DbRepository>((ref) {
  return DbRepository('regions');
});

// final regionStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
//   final regionsRepository = ref.watch(regionRepositoryProvider);
//   return regionsRepository.watchItemListAsMaps();
// });
