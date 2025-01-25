import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/item_form_controller.dart';
import 'package:tablets/src/features/pending_transactions/repository/pending_transaction_repository_provider.dart';

final pendingTransactionFormControllerProvider = Provider<ItemFormController>((ref) {
  final repository = ref.read(pendingTransactionRepositoryProvider);
  return ItemFormController(repository);
});
