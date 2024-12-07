import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/classes/item_form_controller.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/widgets/dialog_delete_confirmation.dart';
import 'package:tablets/src/common/widgets/form_frame.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/image_slider.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/features/products/controllers/product_screen_controller.dart';
import 'package:tablets/src/features/products/repository/product_db_cache_provider.dart';
import 'package:tablets/src/features/products/controllers/product_form_controller.dart';
import 'package:tablets/src/common/values/form_dimenssions.dart';
import 'package:tablets/src/features/products/model/product.dart';
import 'package:tablets/src/features/products/view/product_form_fields.dart';
import 'package:tablets/src/features/products/controllers/product_form_data_notifier.dart';

class ProductForm extends ConsumerWidget {
  const ProductForm({this.isEditMode = false, super.key});
  final bool isEditMode; // used by formController to decide whether to save or update in db

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formController = ref.watch(productFormControllerProvider);
    final formDataNotifier = ref.read(productFormDataProvider.notifier);
    final formImagesNotifier = ref.read(imagePickerProvider.notifier);
    final screenController = ref.read(productScreenControllerProvider);
    final dbCache = ref.read(productDbCacheProvider.notifier);
    ref.watch(imagePickerProvider);
    return FormFrame(
      formKey: formController.formKey,
      fields: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ImageSlider(imageUrls: formDataNotifier.data['imageUrls']),
            VerticalGap.l,
            const ProductFormFields(editMode: true),
          ],
        ),
      ),
      buttons: _actionButtons(
          context, formController, formDataNotifier, formImagesNotifier, dbCache, screenController),
      width: productFormWidth,
      height: productFormHeight,
    );
  }

  List<Widget> _actionButtons(
    BuildContext context,
    ItemFormController formController,
    ItemFormData formDataNotifier,
    ImageSliderNotifier formImagesNotifier,
    DbCache transactionDbCache,
    ProductScreenController screenController,
  ) {
    return [
      IconButton(
        onPressed: () {
          _onSavePressed(context, formController, formDataNotifier, formImagesNotifier,
              transactionDbCache, screenController);
        },
        icon: const SaveIcon(),
      ),
      if (isEditMode)
        IconButton(
          onPressed: () {
            _onDeletePressed(context, formDataNotifier, formImagesNotifier, formController,
                transactionDbCache, screenController);
          },
          icon: const DeleteIcon(),
        ),
    ];
  }

  void _onSavePressed(
    BuildContext context,
    ItemFormController formController,
    ItemFormData formDataNotifier,
    ImageSliderNotifier formImagesNotifier,
    DbCache dbCache,
    ProductScreenController screenController,
  ) {
    if (!formController.validateData()) return;
    formController.submitData();
    final formData = formDataNotifier.data;
    final imageUrls = formImagesNotifier.saveChanges();
    final itemData = {...formData, 'imageUrls': imageUrls};
    final product = Product.fromMap({...formData, 'imageUrls': imageUrls});
    formController.saveItemToDb(context, product, isEditMode);
    // update the bdCache (database mirror) so that we don't need to fetch data from db
    if (itemData['initialDate'] is DateTime) {
      // in our form the data type usually is DateTime, but the date type in dbCache should be
      // Timestamp, as to mirror the datatype of firebase
      itemData['initialDate'] = Timestamp.fromDate(formData['initialDate']);
    }
    final operationType = isEditMode ? DbCacheOperationTypes.edit : DbCacheOperationTypes.add;
    dbCache.update(itemData, operationType);
    // redo screenData calculations
    if (context.mounted) {
      screenController.setFeatureScreenData(context);
    }
  }

  Future<void> _onDeletePressed(
    BuildContext context,
    ItemFormData formDataNotifier,
    ImageSliderNotifier formImagesNotifier,
    ItemFormController formController,
    DbCache dbCache,
    ProductScreenController screenController,
  ) async {
    final confirmation = await showDeleteConfirmationDialog(
        context: context, message: formDataNotifier.data['name']);
    final formData = formDataNotifier.data;
    if (confirmation != null) {
      final imageUrls = formImagesNotifier.saveChanges();
      final itemData = {...formData, 'imageUrls': imageUrls};
      final product = Product.fromMap(itemData);
      if (context.mounted) {
        formController.deleteItemFromDb(context, product);
      }
      // update the bdCache (database mirror) so that we don't need to fetch data from db
      const operationType = DbCacheOperationTypes.delete;
      dbCache.update(itemData, operationType);
      // redo screenData calculations
      if (context.mounted) {
        screenController.setFeatureScreenData(context);
      }
    }
  }
}
