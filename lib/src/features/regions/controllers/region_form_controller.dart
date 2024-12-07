import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/item_form_controller.dart';
import 'package:tablets/src/features/regions/repository/region_repository_provider.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';

final regionFormDataProvider = StateNotifierProvider<ItemFormData, Map<String, dynamic>>((ref) => ItemFormData({}));

final regionFormControllerProvider = Provider<ItemFormController>((ref) {
  final repository = ref.read(regionRepositoryProvider);
  return ItemFormController(repository);
});
