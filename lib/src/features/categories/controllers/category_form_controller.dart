import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/item_form_controller.dart';
import 'package:tablets/src/features/categories/repository/category_repository_provider.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';

final categoryFormDataProvider =
    StateNotifierProvider<ItemFormData, Map<String, dynamic>>((ref) => ItemFormData({}));

final categoryFormControllerProvider = Provider<ItemFormController>((ref) {
  final repository = ref.read(categoryRepositoryProvider);
  return ItemFormController(repository);
});
