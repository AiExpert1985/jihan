import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/classes/item_form_controller.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';
import 'package:tablets/src/common/functions/print_document.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/providers/background_color.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/common/widgets/form_frame.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/values/form_dimenssions.dart';
import 'package:tablets/src/features/transactions/controllers/form_navigator_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_controller.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_controller.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/view/forms/expenditure_form.dart';
import 'package:tablets/src/features/transactions/view/forms/invoice_form.dart';
import 'package:tablets/src/features/transactions/view/forms/receipt_form.dart';
import 'package:tablets/src/features/transactions/view/forms/statement_form.dart';
import 'package:tablets/src/features/transactions/view/transaction_show_form.dart';

class TransactionForm extends ConsumerWidget {
  const TransactionForm(this.isEditMode, this.transactionType, {super.key});
  final bool isEditMode; // used by formController to decide whether to save or update in db
  final String transactionType;
  // used to validate wether customer can buy new invoice (if he didn't exceed limits)

  Widget _getFormWidget(BuildContext context, String transactionType) {
    final titles = {
      TransactionType.customerInvoice.name: S.of(context).transaction_type_customer_invoice,
      TransactionType.vendorInvoice.name: S.of(context).transaction_type_vender_invoice,
      TransactionType.customerReturn.name: S.of(context).transaction_type_customer_return,
      TransactionType.vendorReturn.name: S.of(context).transaction_type_vender_return,
      TransactionType.customerReceipt.name: S.of(context).transaction_type_customer_receipt,
      TransactionType.vendorReceipt.name: S.of(context).transaction_type_vendor_receipt,
      TransactionType.gifts.name: S.of(context).transaction_type_gifts,
      TransactionType.expenditures.name: S.of(context).transaction_type_expenditures,
      TransactionType.damagedItems.name: S.of(context).transaction_type_damaged_items,
    };
    if (transactionType == TransactionType.customerInvoice.name) {
      return InvoiceForm(titles[transactionType]!, transactionType, hideGifts: false);
    }
    if (transactionType == TransactionType.vendorInvoice.name) {
      return InvoiceForm(titles[transactionType]!, transactionType, isVendor: true);
    }
    if (transactionType == TransactionType.customerReturn.name) {
      return InvoiceForm(titles[transactionType]!, transactionType);
    }
    if (transactionType == TransactionType.vendorReturn.name) {
      return InvoiceForm(titles[transactionType]!, transactionType, isVendor: true);
    }
    if (transactionType == TransactionType.customerReceipt.name) {
      return ReceiptForm(titles[transactionType]!);
    }
    if (transactionType == TransactionType.vendorReceipt.name) {
      return ReceiptForm(titles[transactionType]!, isVendor: true);
    }
    if (transactionType == TransactionType.gifts.name) {
      return StatementForm(titles[transactionType]!, transactionType, isGift: true);
    }
    if (transactionType == TransactionType.damagedItems.name) {
      return StatementForm(titles[transactionType]!, transactionType);
    }
    if (transactionType == TransactionType.expenditures.name) {
      return ExpenditureForm(titles[transactionType]!);
    }
    return const Center(child: Text('Error happend while loading transaction form'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formController = ref.read(transactionFormControllerProvider);
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final formImagesNotifier = ref.read(imagePickerProvider.notifier);
    final screenController = ref.read(transactionScreenControllerProvider);
    final dbCache = ref.read(transactionDbCacheProvider.notifier);
    final formNavigation = ref.read(formNavigatorProvider);
    // final transactionTypeTranslated = translateScreenTextToDbText(context, transactionType);
    final backgroundColor = ref.watch(backgroundColorProvider);
    ref.watch(imagePickerProvider);
    ref.watch(transactionFormDataProvider);
    final height = transactionFormDimenssions[transactionType]['height'];
    final width = transactionFormDimenssions[transactionType]['width'];
    return FormFrame(
      backgroundColor: backgroundColor,
      formKey: formController.formKey,
      // formKey: GlobalKey<FormState>(),
      fields: Stack(children: [
        _getFormWidget(context, transactionType),
        Positioned(
          top: 8, // Adjust the top position as needed
          left: 8, // Adjust the left position as needed
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss the dialog
            },
          ),
        ),
      ]),
      buttons: _actionButtons(context, formController, formDataNotifier, formImagesNotifier,
          dbCache, screenController, formNavigation, ref),
      width: width is double ? width : width.toDouble(),
      height: height is double ? height : height.toDouble(),
    );
  }

  List<Widget> _actionButtons(
    BuildContext context,
    ItemFormController formController,
    ItemFormData formDataNotifier,
    ImageSliderNotifier formImagesNotifier,
    DbCache transactionDbCache,
    TransactionScreenController screenController,
    FromNavigator formNavigation,
    WidgetRef ref,
  ) {
    return [
      // IconButton(
      //   onPressed: () {
      //     final formData = formNavigation.first();
      //     _onNavigationPressed(formData, context, ref);
      //   },
      //   icon: const GoFirstIcon(),
      // ),
      // IconButton(
      //   onPressed: () {
      //     final formData = formNavigation.previous();
      //     _onNavigationPressed(formData, context, ref);
      //   },
      //   icon: const GoPreviousIcon(),
      // ),
      // const SizedBox(width: 250),
      // IconButton(
      //   onPressed: () {
      //     _onSavePressed(context, ref, formController, formDataNotifier, formImagesNotifier,
      //         transactionDbCache, screenController);
      //   },
      //   icon: const SaveIcon(),
      // ),
      IconButton(
        onPressed: () {
          TransactionShowForm.deleteTransaction(context, formDataNotifier, formImagesNotifier,
              formController, transactionDbCache, screenController);
        },
        icon: const DeleteIcon(),
      ),
      IconButton(
        onPressed: () {
          // _onSavePressed(context, ref, formController, formDataNotifier, formImagesNotifier,
          //     transactionDbCache, screenController,
          //     keepDialog: true);
          _onPrintPressed(context, ref, formDataNotifier);
        },
        icon: formDataNotifier.getProperty(isPrintedKey) ? const PrintedIcon() : const PrintIcon(),
      ),
      // const SizedBox(width: 250),
      // IconButton(
      //   onPressed: () {
      //     final formData = formNavigation.next();
      //     _onNavigationPressed(formData, context, ref);
      //   },
      //   icon: const GoNextIcon(),
      // ),
      // IconButton(
      //   onPressed: () {
      //     final formData = formNavigation.last();
      //     _onNavigationPressed(formData, context, ref);
      //   },
      //   icon: const GoLastIcon(),
      // ),
    ];
  }

  // void _onSavePressed(
  //     BuildContext context,
  //     WidgetRef ref,
  //     ItemFormController formController,
  //     ItemFormData formDataNotifier,
  //     ImageSliderNotifier formImagesNotifier,
  //     DbCache transactionDbCache,
  //     TransactionScreenController screenController,
  //     {bool keepDialog = false}) {
  //   if (!formController.validateData()) return;
  //   removeEmptyRows(formDataNotifier);
  //   formController.submitData();
  //   final formData = {...formDataNotifier.data};
  //   final imageUrls = formImagesNotifier.saveChanges();
  //   final itemData = {...formData, 'imageUrls': imageUrls};
  //   final transaction = Transaction.fromMap({...formData, 'imageUrls': imageUrls});
  //   formController.saveItemToDb(context, transaction, isEditMode, keepDialogOpen: true);
  //   // update the bdCache (database mirror) so that we don't need to fetch data from db
  //   if (itemData[transactionDateKey] is DateTime) {
  //     // in our form the data type usually is DateTime, but the date type in dbCache should be
  //     // Timestamp, as to mirror the datatype of firebase
  //     itemData[transactionDateKey] = firebase.Timestamp.fromDate(formData[transactionDateKey]);
  //   }
  //   final operationType = isEditMode ? DbCacheOperationTypes.edit : DbCacheOperationTypes.add;
  //   transactionDbCache.update(itemData, operationType);
  //   // redo screenData calculations
  //   if (context.mounted) {
  //     screenController.setFeatureScreenData(context);
  //   }
  //   if (!keepDialog) {
  //     Navigator.of(context).pop();
  //   }

  //   //// open new form when saving
  //   // _showForm(context, ref, transactionType);
  // }

  // /// delete rows where there is not item name
  // void removeEmptyRows(ItemFormData formDataNotifier) {
  //   final items = formDataNotifier.getProperty(itemsKey);
  //   for (var i = 0; i < items.length; i++) {
  //     if (items[i]['name'] == '') {
  //       formDataNotifier.removeSubProperties(itemsKey, i);
  //     }
  //   }
  // }

  void _onPrintPressed(BuildContext context, WidgetRef ref, ItemFormData formDataNotifier) async {
    if (formDataNotifier.data[nameKey] == '') {
      failureUserMessage(context, S.of(context).no_name_print_error);
      return;
    }
    // first we need to save changes done to the form, then print, because if we don't save,
    // then the debt of customer will not accurately calculated
    TransactionShowForm.saveTransaction(context, ref, formDataNotifier.data, true);
    printDocument(context, ref, formDataNotifier.data);
    formDataNotifier.updateProperties({isPrintedKey: true});
  }

  // void _onNavigationPressed(
  //   Map<String, dynamic> formData,
  //   BuildContext context,
  //   WidgetRef ref,
  // ) {
  //   final transaction = Transaction.fromMap(formData);
  //   final transactionType = transaction.transactionType;
  //   _showForm(context, ref, transactionType, transaction: transaction);
  // }

  // void _showForm(
  //   BuildContext context,
  //   WidgetRef ref,
  //   String transactionType, {
  //   Transaction? transaction,
  // }) {
  //   Navigator.of(context).pop();
  //   final imagePickerNotifier = ref.read(imagePickerProvider.notifier);
  //   final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
  //   final textEditingNotifier = ref.read(textFieldsControllerProvider.notifier);
  //   final backgroundColorNofifier = ref.read(backgroundColorProvider.notifier);
  //   final settingsDataNotifier = ref.read(settingsFormDataProvider.notifier);
  //   final dbCache = ref.read(transactionDbCacheProvider.notifier);
  //   backgroundColorNofifier.state = Colors.white;
  //   TransactionShowForm.showForm(
  //     context,
  //     ref,
  //     imagePickerNotifier,
  //     formDataNotifier,
  //     settingsDataNotifier,
  //     textEditingNotifier,
  //     backgroundColorNofifier,
  //     formType: transactionType,
  //     transactionDbCache: dbCache,
  //     transaction: transaction,
  //   );
  // }
}
