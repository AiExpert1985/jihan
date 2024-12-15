import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/classes/item_form_controller.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/values/form_dimenssions.dart';
import 'package:tablets/src/common/widgets/custome_appbar_for_back_return.dart';
import 'package:tablets/src/common/widgets/form_frame.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/form_title.dart';
import 'package:tablets/src/common/widgets/image_slider.dart';
import 'package:tablets/src/common/widgets/dialog_delete_confirmation.dart';
import 'package:tablets/src/features/regions/controllers/region_form_controller.dart';
import 'package:tablets/src/features/regions/controllers/region_screen_controller.dart';
import 'package:tablets/src/features/regions/model/region.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/features/regions/repository/region_db_cache_provider.dart';
import 'package:tablets/src/features/regions/view/region_form_fields.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

class RegionForm extends ConsumerWidget {
  const RegionForm({this.isEditMode = false, super.key});
  final bool isEditMode; // used by formController to decide whether to save or update in db

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formController = ref.watch(regionFormControllerProvider);
    final formDataNotifier = ref.read(regionFormDataProvider.notifier);
    final formImagesNotifier = ref.read(imagePickerProvider.notifier);
    final screenController = ref.read(regionScreenControllerProvider);
    final dbCache = ref.read(regionDbCacheProvider.notifier);
    ref.watch(imagePickerProvider);
    return Scaffold(
      appBar: buildArabicAppBar(context, () async {
        // back to customers screen
        Navigator.pop(context);
      }, () async {
        // back to home screen
        Navigator.pop(context);
        context.goNamed(AppRoute.home.name);
      }),
      // body: const Text('hi')
      body: FormFrame(
        title: buildFormTitle(S.of(context).region),
        fields: Container(
          padding: const EdgeInsets.all(0),
          width: 800,
          height: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ImageSlider(imageUrls: formDataNotifier.data['imageUrls']),
              VerticalGap.l,
              const RegionFormFields(),
            ],
          ),
        ),
        buttons: [
          IconButton(
            onPressed: () =>
                _onSavePress(context, formDataNotifier, formImagesNotifier, formController, dbCache, screenController),
            icon: const SaveIcon(),
          ),
          if (isEditMode)
            IconButton(
              onPressed: () => _onDeletePressed(
                  context, formDataNotifier, formImagesNotifier, formController, dbCache, screenController),
              icon: const DeleteIcon(),
            ),
        ],
        width: regionFormWidth,
        height: regionFormHeight,
      ),
    );
  }

  void _onSavePress(
    BuildContext context,
    ItemFormData formDataNotifier,
    ImageSliderNotifier formImagesNotifier,
    ItemFormController formController,
    DbCache dbCache,
    RegionScreenController screenController,
  ) {
    // if (!formController.validateData()) return;
    // formController.submitData();
    final formData = formDataNotifier.data;
    final imageUrls = formImagesNotifier.saveChanges();
    final itemData = {...formData, 'imageUrls': imageUrls};
    final region = Region.fromMap(itemData);
    formController.saveItemToDb(context, region, isEditMode);
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
    RegionScreenController screenController,
  ) async {
    final confiramtion = await showDeleteConfirmationDialog(context: context, message: formDataNotifier.data['name']);
    if (confiramtion != null) {
      final formData = formDataNotifier.data;
      final imageUrls = formImagesNotifier.saveChanges();
      final itemData = {...formData, 'imageUrls': imageUrls};
      final region = Region.fromMap(itemData);
      if (context.mounted) {
        formController.deleteItemFromDb(context, region);
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
