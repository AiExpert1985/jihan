import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/classes/item_form_controller.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/values/form_dimenssions.dart';
import 'package:tablets/src/common/widgets/form_frame.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/image_slider.dart';
import 'package:tablets/src/common/widgets/dialog_delete_confirmation.dart';
import 'package:tablets/src/features/categories/controllers/category_form_controller.dart';
import 'package:tablets/src/features/categories/controllers/category_screen_controller.dart';
import 'package:tablets/src/features/categories/model/category.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/features/categories/repository/category_db_cache_provider.dart';
import 'package:tablets/src/features/categories/view/category_form_fields.dart';

class CategoryForm extends ConsumerWidget {
  const CategoryForm({this.isEditMode = false, super.key});
  final bool isEditMode; // used by formController to decide whether to save or update in db

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formController = ref.watch(categoryFormControllerProvider);
    final formDataNotifier = ref.read(categoryFormDataProvider.notifier);
    final formImagesNotifier = ref.read(imagePickerProvider.notifier);
    final screenController = ref.read(categoryScreenControllerProvider);
    final dbCache = ref.read(categoryDbCacheProvider.notifier);
    ref.watch(imagePickerProvider);
    return FormFrame(
      formKey: formController.formKey,
      fields: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ImageSlider(imageUrls: formDataNotifier.data['imageUrls']),
          VerticalGap.l,
          const CategoryFormFields(),
        ],
      ),
      buttons: [
        IconButton(
          onPressed: () => _onSavePress(context, formDataNotifier, formImagesNotifier,
              formController, dbCache, screenController),
          icon: const SaveIcon(),
        ),
        if (isEditMode)
          IconButton(
            onPressed: () => _onDeletePressed(context, formDataNotifier, formImagesNotifier,
                formController, dbCache, screenController),
            icon: const DeleteIcon(),
          ),
      ],
      width: categoryFormWidth,
      height: categoryFormHeight,
    );
  }

  void _onSavePress(
    BuildContext context,
    ItemFormData formDataNotifier,
    ImageSliderNotifier formImagesNotifier,
    ItemFormController formController,
    DbCache dbCache,
    CategoryScreenController screenController,
  ) {
    if (!formController.validateData()) return;
    formController.submitData();
    final formData = formDataNotifier.data;
    final imageUrls = formImagesNotifier.saveChanges();
    final itemData = {...formData, 'imageUrls': imageUrls};
    final category = ProductCategory.fromMap(itemData);
    formController.saveItemToDb(context, category, isEditMode);
    // update the bdCache (database mirror) so that we don't need to fetch data from db
    final operationType = isEditMode ? DbCacheOperationTypes.edit : DbCacheOperationTypes.add;
    dbCache.update(itemData, operationType);
    // redo screenData calculations
    if (context.mounted) {
      screenController.setFeatureScreenData(context);
    }
  }

  void _onDeletePressed(
    BuildContext context,
    ItemFormData formDataNotifier,
    ImageSliderNotifier formImagesNotifier,
    ItemFormController formController,
    DbCache dbCache,
    CategoryScreenController screenController,
  ) async {
    final confiramtion = await showDeleteConfirmationDialog(
        context: context, message: formDataNotifier.data['name']);
    if (confiramtion != null) {
      final formData = formDataNotifier.data;
      final imageUrls = formImagesNotifier.saveChanges();
      final itemData = {...formData, 'imageUrls': imageUrls};
      final category = ProductCategory.fromMap(itemData);
      if (context.mounted) {
        formController.deleteItemFromDb(context, category);
      }
      // update the dbCache (database mirror) so that we don't need to fetch data from db
      const operationType = DbCacheOperationTypes.delete;
      dbCache.update(itemData, operationType);
      // redo screenData calculations
      if (context.mounted) {
        screenController.setFeatureScreenData(context);
      }
    }
  }
}
