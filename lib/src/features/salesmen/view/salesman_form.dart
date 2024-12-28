import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/classes/item_form_controller.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/widgets/custome_appbar_for_back_return.dart';
import 'package:tablets/src/common/widgets/form_frame.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/form_title.dart';
import 'package:tablets/src/common/widgets/image_slider.dart';
import 'package:tablets/src/common/widgets/dialog_delete_confirmation.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/values/form_dimenssions.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_form_controller.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_screen_controller.dart';
import 'package:tablets/src/features/salesmen/model/salesman.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_db_cache_provider.dart';
import 'package:tablets/src/features/salesmen/view/salesman_form_fields.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

class SalesmanForm extends ConsumerWidget {
  const SalesmanForm({this.isEditMode = false, super.key});
  final bool isEditMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formController = ref.watch(salesmanFormControllerProvider);
    final formDataNotifier = ref.read(salesmanFormDataProvider.notifier);
    final formImagesNotifier = ref.read(imagePickerProvider.notifier);
    final screenController = ref.read(salesmanScreenControllerProvider);
    final dbCache = ref.read(salesmanDbCacheProvider.notifier);
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
        title: buildFormTitle(S.of(context).salesmen),
        fields: Container(
          padding: const EdgeInsets.all(0),
          width: 800,
          height: 550,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ImageSlider(imageUrls: formDataNotifier.data['imageUrls']),
              VerticalGap.l,
              const SalesmanFormFields(),
            ],
          ),
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
        width: salesmanFormWidth,
        height: salesmanFormHeight,
      ),
    );
  }

  void _onSavePress(
    BuildContext context,
    ItemFormData formDataNotifier,
    ImageSliderNotifier formImagesNotifier,
    ItemFormController formController,
    DbCache dbCache,
    SalesmanScreenController screenController,
  ) {
    // if (!formController.validateData()) return;
    // formController.submitData();
    final formData = formDataNotifier.data;
    final imageUrls = formImagesNotifier.saveChanges();
    final itemData = {...formData, 'imageUrls': imageUrls};
    final salesman = Salesman.fromMap(itemData);
    formController.saveItemToDb(context, salesman, isEditMode);
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
    SalesmanScreenController screenController,
  ) async {
    final confiramtion = await showDeleteConfirmationDialog(
        context: context,
        messagePart1: S.of(context).alert_before_delete,
        messagePart2: formDataNotifier.data['name']);
    if (confiramtion != null) {
      final formData = formDataNotifier.data;
      final imageUrls = formImagesNotifier.saveChanges();
      final itemData = {...formData, 'imageUrls': imageUrls};
      final salesman = Salesman.fromMap(itemData);
      if (context.mounted) {
        formController.deleteItemFromDb(context, salesman);
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
