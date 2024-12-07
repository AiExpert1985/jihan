import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/item_form_controller.dart';
import 'package:tablets/src/features/transactions/repository/transaction_repository_provider.dart';

final transactionFormControllerProvider = Provider<ItemFormController>((ref) {
  final repository = ref.read(transactionRepositoryProvider);
  return ItemFormController(repository);
});
