import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_repository.dart';

final accountsRepositoryProvider = Provider<DbRepository>((ref) => DbRepository('accounts'));

final accountsStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final accountsRepo = ref.watch(accountsRepositoryProvider);
  return accountsRepo.watchItemListAsMaps();
});
