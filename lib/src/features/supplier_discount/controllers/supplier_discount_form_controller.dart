import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';

final supplierDiscountFormDataProvider =
    StateNotifierProvider<ItemFormData, Map<String, dynamic>>((ref) => ItemFormData({}));

// final supplierDiscountFormControllerProvider = Provider<ItemFormController>((ref) {
//   final repository = ref.read(supplierDiscountRepositoryProvider);
//   return ItemFormController(repository);
// });
