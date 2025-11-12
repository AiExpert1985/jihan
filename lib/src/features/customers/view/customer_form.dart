import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:tablets/src/features/customers/controllers/customer_form_controller.dart';
import 'package:tablets/src/features/customers/controllers/customer_screen_controller.dart';
import 'package:tablets/src/features/customers/model/customer.dart';
import 'package:tablets/src/features/customers/repository/customer_db_cache_provider.dart';
import 'package:tablets/src/features/customers/view/customer_form_fields.dart';
import 'package:tablets/src/features/customers/controllers/customer_form_data_notifier.dart';
import 'package:tablets/src/routers/go_router_provider.dart';
import 'package:tablets/src/common/providers/user_info_provider.dart';
import 'package:tablets/src/features/authentication/model/user_account.dart';

class CustomerForm extends ConsumerWidget {
  const CustomerForm({this.isEditMode = false, super.key});
  final bool isEditMode; // used by formController to decide whether to update or save in db

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfo = ref.watch(userInfoProvider);
    final isAccountant = userInfo?.privilage == UserPrivilage.accountant.name;
    final formController = ref.watch(customerFormControllerProvider);
    final formDataNotifier = ref.read(customerFormDataProvider.notifier);
    final formImagesNotifier = ref.read(imagePickerProvider.notifier);
    final screenController = ref.read(customerScreenControllerProvider);
    final dbCache = ref.read(customerDbCacheProvider.notifier);
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
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FormFrame(
            title: buildFormTitle(S.of(context).customer),
            fields: Container(
              padding: const EdgeInsets.all(0),
              width: 800,
              height: 550,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ImageSlider(imageUrls: formDataNotifier.data['imageUrls']),
                  VerticalGap.l,
                  const CustomerFormFields(),
                ],
              ),
            ),
            buttons: [
              IconButton(
                onPressed: () => _onSavePress(context, formDataNotifier, formImagesNotifier,
                    formController, dbCache, screenController),
                icon: const SaveIcon(),
              ),
              if (isEditMode && !isAccountant)
                IconButton(
                  onPressed: () => _onDeletePressed(context, formDataNotifier, formImagesNotifier,
                      formController, dbCache, screenController),
                  icon: const DeleteIcon(),
                ),
            ],
            width: customerFormWidth,
            height: customerFormHeight,
          ),
        ],
      ),
    );
  }

  void _onSavePress(
    BuildContext context,
    ItemFormData formDataNotifier,
    ImageSliderNotifier formImagesNotifier,
    ItemFormController formController,
    DbCache dbCache,
    CustomerScreenController screenController,
  ) {
    // if (!formController.validateData()) return;
    // formController.submitData();
    final formData = formDataNotifier.data;
    final imageUrls = formImagesNotifier.saveChanges();
    final itemData = {...formData, 'imageUrls': imageUrls};
    final customer = Customer.fromMap(itemData);
    formController.saveItemToDb(context, customer, isEditMode);
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

  void _onDeletePressed(
    BuildContext context,
    ItemFormData formDataNotifier,
    ImageSliderNotifier formImagesNotifier,
    ItemFormController formController,
    DbCache dbCache,
    CustomerScreenController screenController,
  ) async {
    final confiramtion = await showDeleteConfirmationDialog(
        context: context,
        messagePart1: S.of(context).alert_before_delete,
        messagePart2: formDataNotifier.data['name']);
    if (confiramtion != null) {
      final formData = formDataNotifier.data;
      final imageUrls = formImagesNotifier.saveChanges();
      final itemData = {...formData, 'imageUrls': imageUrls};
      final customer = Customer.fromMap(itemData);
      if (context.mounted) {
        formController.deleteItemFromDb(context, customer);
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
