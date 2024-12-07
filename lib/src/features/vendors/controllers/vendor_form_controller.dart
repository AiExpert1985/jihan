import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/item_form_controller.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';
import 'package:tablets/src/features/vendors/repository/vendor_repository_provider.dart';

final vendorFormDataProvider =
    StateNotifierProvider<ItemFormData, Map<String, dynamic>>((ref) => ItemFormData({}));

final vendorFormControllerProvider = Provider<ItemFormController>((ref) {
  final repository = ref.read(vendorRepositoryProvider);
  return ItemFormController(repository);
});
