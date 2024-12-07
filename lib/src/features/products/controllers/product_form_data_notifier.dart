import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';

final productFormDataProvider =
    StateNotifierProvider<ItemFormData, Map<String, dynamic>>((ref) => ItemFormData({}));
