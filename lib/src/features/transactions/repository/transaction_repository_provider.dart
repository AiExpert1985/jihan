import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_repository.dart';

final transactionRepositoryProvider = Provider<DbRepository>((ref) => DbRepository('transactions'));

// final transactionStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
//   final transactionRepository = ref.watch(transactionRepositoryProvider);
//   return transactionRepository.watchItemListAsMaps();
// });
