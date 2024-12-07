import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/item_form_controller.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_repository_provider.dart';

final salesmanFormDataProvider = StateNotifierProvider<ItemFormData, Map<String, dynamic>>((ref) => ItemFormData({}));

final salesmanFormControllerProvider = Provider<ItemFormController>((ref) {
  final repository = ref.read(salesmanRepositoryProvider);
  return ItemFormController(repository);
});
