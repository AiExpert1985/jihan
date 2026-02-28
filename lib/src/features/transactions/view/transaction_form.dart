import 'package:cloud_firestore/cloud_firestore.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/classes/item_form_controller.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/transaction_type_drowdop_list.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/printing/print_document.dart';
import 'package:tablets/src/common/providers/background_color.dart';
// import 'package:tablets/src/common/providers/background_color.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/providers/screen_cache_update_service.dart';
import 'package:tablets/src/common/providers/text_editing_controllers_provider.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/custome_appbar_for_back_return.dart';
import 'package:tablets/src/common/widgets/dialog_delete_confirmation.dart';
import 'package:tablets/src/common/widgets/form_frame.dart';
import 'package:tablets/src/common/widgets/form_title.dart';
import 'package:tablets/src/common/widgets/spinner_icon_button.dart';
import 'package:tablets/src/features/counters/repository/counter_repository_provider.dart';
import 'package:tablets/src/features/deleted_transactions/model/deleted_transactions.dart';
import 'package:tablets/src/features/deleted_transactions/repository/deleted_transaction_db_cache_provider.dart';
import 'package:tablets/src/features/deleted_transactions/repository/deleted_transaction_repository_provider.dart';
import 'package:tablets/src/features/print_log/print_log_service.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/controllers/customer_debt_info_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_navigator_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_controller.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_controller.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/view/forms/expenditure_form.dart';
import 'package:tablets/src/features/transactions/view/forms/invoice_form.dart';
import 'package:tablets/src/features/transactions/view/forms/receipt_form.dart';
import 'package:tablets/src/features/transactions/view/forms/statement_form.dart';
import 'package:tablets/src/features/transactions/view/transaction_show_form.dart';
import 'package:tablets/src/features/warehouse/services/warehouse_service.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

final Map<String, dynamic> transactionFormDimenssions = {
  TransactionType.customerInvoice.name: {'height': 1100, 'width': 900},
  TransactionType.vendorInvoice.name: {'height': 1000, 'width': 800},
  TransactionType.customerReturn.name: {'height': 750, 'width': 800},
  TransactionType.vendorReturn.name: {'height': 750, 'width': 800},
  TransactionType.damagedItems.name: {'height': 650, 'width': 550},
  TransactionType.gifts.name: {'height': 650, 'width': 550},
  TransactionType.customerReceipt.name: {'height': 400, 'width': 800},
  TransactionType.vendorReceipt.name: {'height': 400, 'width': 800},
  TransactionType.expenditures.name: {'height': 500, 'width': 800},
};

class TransactionForm extends ConsumerWidget {
  const TransactionForm(this.isEditMode, this.transactionType, {super.key});
  final bool
      isEditMode; // used by formController to decide whether to save or update in db
  final String transactionType;
  // used to validate wether customer can buy new invoice (if he didn't exceed limits)

  Map<String, double>? _getFormDimenssions(String transactionType) {
    final dimenssions = {
      TransactionType.customerInvoice.name: {'height': 1200.0, 'width': 1100.0},
      TransactionType.vendorInvoice.name: {'height': 1000.0, 'width': 1000.0},
      TransactionType.customerReturn.name: {'height': 1000.0, 'width': 1000.0},
      TransactionType.vendorReturn.name: {'height': 900.0, 'width': 1000.0},
      TransactionType.damagedItems.name: {'height': 900.0, 'width': 750.0},
      TransactionType.gifts.name: {'height': 900.0, 'width': 750.0},
      TransactionType.customerReceipt.name: {'height': 700.0, 'width': 800.0},
      TransactionType.vendorReceipt.name: {'height': 700.0, 'width': 800.0},
      TransactionType.expenditures.name: {'height': 700.0, 'width': 800.0},
    };
    return dimenssions[transactionType];
  }

  Widget _getFormWidget(
      BuildContext context, String transactionType, WidgetRef ref) {
    final titles = {
      TransactionType.customerInvoice.name:
          S.of(context).transaction_type_customer_invoice,
      TransactionType.vendorInvoice.name:
          S.of(context).transaction_type_vender_invoice,
      TransactionType.customerReturn.name:
          S.of(context).transaction_type_customer_return,
      TransactionType.vendorReturn.name:
          S.of(context).transaction_type_vender_return,
      TransactionType.customerReceipt.name:
          S.of(context).transaction_type_customer_receipt,
      TransactionType.vendorReceipt.name:
          S.of(context).transaction_type_vendor_receipt,
      TransactionType.gifts.name: S.of(context).transaction_type_gifts,
      TransactionType.expenditures.name:
          S.of(context).transaction_type_expenditures,
      TransactionType.damagedItems.name:
          S.of(context).transaction_type_damaged_items,
    };
    if (transactionType == TransactionType.customerInvoice.name) {
      final backgroundColor = ref.read(backgroundColorProvider);
      return InvoiceForm(
        titles[transactionType]!,
        transactionType,
        hideGifts: false,
        backgroundColor: backgroundColor,
      );
    }
    if (transactionType == TransactionType.vendorInvoice.name) {
      return InvoiceForm(titles[transactionType]!, transactionType,
          isVendor: true);
    }
    if (transactionType == TransactionType.customerReturn.name) {
      return InvoiceForm(titles[transactionType]!, transactionType);
    }
    if (transactionType == TransactionType.vendorReturn.name) {
      return InvoiceForm(titles[transactionType]!, transactionType,
          isVendor: true);
    }
    if (transactionType == TransactionType.customerReceipt.name) {
      return ReceiptForm(titles[transactionType]!);
    }
    if (transactionType == TransactionType.vendorReceipt.name) {
      return ReceiptForm(titles[transactionType]!, isVendor: true);
    }
    if (transactionType == TransactionType.gifts.name) {
      return StatementForm(titles[transactionType]!, transactionType,
          isGift: true);
    }
    if (transactionType == TransactionType.damagedItems.name) {
      return StatementForm(titles[transactionType]!, transactionType);
    }
    if (transactionType == TransactionType.expenditures.name) {
      return ExpenditureForm(titles[transactionType]!);
    }
    return const Center(
        child: Text('Error happend while loading transaction form'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formController = ref.read(transactionFormControllerProvider);
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final formImagesNotifier = ref.read(imagePickerProvider.notifier);
    final screenController = ref.read(transactionScreenControllerProvider);
    final dbCache = ref.read(transactionDbCacheProvider.notifier);
    final formNavigation = ref.read(formNavigatorProvider);
    formNavigation.initialize(
        transactionType, formDataNotifier.getProperty(dbRefKey));
    // final transactionTypeTranslated = translateScreenTextToDbText(context, transactionType);
    // final backgroundColor = ref.watch(backgroundColorProvider);
    ref.watch(imagePickerProvider);
    ref.watch(transactionFormDataProvider);
    ref.watch(textFieldsControllerProvider);
    final formDimenssions = _getFormDimenssions(transactionType);
    final height = formDimenssions?['height'] ?? 1000;
    final width = formDimenssions?['width'] ?? 1000;

    return Scaffold(
      appBar: buildArabicAppBar(context, () async {
        // back to transactions screen
        if (!await onLeavingTransaction(context, ref, formImagesNotifier)) {
          return;
        }
        if (!context.mounted) return;
        Navigator.pop(context);
        // context.goNamed(AppRoute.transactions.name);
      }, () async {
        // back to home screen
        await onLeavingTransaction(context, ref, formImagesNotifier);
        if (!context.mounted) return;
        Navigator.pop(context);
        context.goNamed(AppRoute.home.name);
      }),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const NavigationButtons(),
          FormFrame(
            title: buildFormTitle(
                translateDbTextToScreenText(context, transactionType)),
            // backgroundColor: backgroundColor,
            // formKey: formController.formKey,
            // formKey: GlobalKey<FormState>(),
            fields: _getFormWidget(context, transactionType, ref),
            buttons: _actionButtons(
                context,
                formController,
                formDataNotifier,
                formImagesNotifier,
                dbCache,
                screenController,
                formNavigation,
                ref),
            width: width,
            height: height,
          ),
          // customer debt info only show for customer transactions

          CustomerDebtReview(transactionType)
        ],
      ),
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
      IconButton(
        onPressed: () {
          formNavigation.isReadOnly = false;
          onNavigationPressed(formDataNotifier, context, ref,
              formImagesNotifier, formNavigation,
              isNewTransaction: true);
        },
        icon: const NewIemIcon(),
      ),
      if (formNavigation.isReadOnly)
        IconButton(
          onPressed: () {
            formNavigation.isReadOnly = false;
            // TODO navigation to self  is added only to layout rebuild because formNavigation is not stateNotifier
            // TODO later I might change formNavigation to StateNotifier and watch it in this widget
            final formData = formDataNotifier.data;
            onNavigationPressed(formDataNotifier, context, ref,
                formImagesNotifier, formNavigation,
                targetTransactionData: formData);
          },
          icon: const EditIcon(),
        ),
      // only show delete button if we are in editing mode
      if (!formNavigation.isReadOnly)
        IconButton(
          onPressed: () {
            formNavigation.isReadOnly = true;
            deleteTransaction(
                context,
                ref,
                formDataNotifier,
                formImagesNotifier,
                formController,
                transactionDbCache,
                screenController,
                formNavigation: formNavigation);
          },
          icon: const DeleteIcon(),
        ),
      SpinnerIconButton(
        onPressed: () async {
          await _onPrintPressed(context, ref, formDataNotifier);
          // if not printed due to empty name, don't continue
          if (!formDataNotifier.getProperty(isPrintedKey)) return;
          formNavigation.isReadOnly = true;
          // TODO navigation to self  is added only to layout rebuild because formNavigation is not stateNotifier
          // TODO later I might change formNavigation to StateNotifier and watch it in this widget
          final formData = formDataNotifier.data;
          if (context.mounted) {
            onNavigationPressed(formDataNotifier, context, ref,
                formImagesNotifier, formNavigation,
                targetTransactionData: formData);
          }
        },
        icon: const PrintIcon(),
      ),
      // Print 2 button - hidden for now, may be re-enabled later
      const Visibility(
          visible: false,
          child: IconButton(
            onPressed: null,
            icon: PrintIconB(),
          )),
      if (transactionType == TransactionType.customerInvoice.name)
        SpinnerIconButton(
            onPressed: () async {
              await _onSendToWarehousePressed(
                  context, ref, formDataNotifier, formImagesNotifier);
              formNavigation.isReadOnly = true;
              final formData = formDataNotifier.data;
              if (context.mounted) {
                onNavigationPressed(formDataNotifier, context, ref,
                    formImagesNotifier, formNavigation,
                    targetTransactionData: formData);
              }
            },
            icon: const SendIcon()),
    ];
  }

  Future<void> _onPrintPressed(
      BuildContext context, WidgetRef ref, ItemFormData formDataNotifier,
      {bool isLogoB = false}) async {
    if (formDataNotifier.data[nameKey] == '') {
      failureUserMessage(context, S.of(context).no_name_print_error);
      return;
    }

    // first we need to save changes done to the form, then print, because if we don't save,
    // then the debt of customer will not accurately calculated
    // also, as a policy, I want always to save before print, because I want to ensure always the transaction in
    // database matches the printed transaction.
    // isPrinted must be set BEFORE saveTransaction to avoid race condition with subsequent saves
    formDataNotifier.updateProperties({isPrintedKey: true});
    // Save is non-blocking: writes to Firebase local cache instantly, syncs to server in background
    await saveTransaction(context, ref, formDataNotifier.data, true);
    if (!context.mounted) return;
    await printForm(context, ref, formDataNotifier.data, isLogoB: isLogoB);
    ref.read(printLogServiceProvider).logPrint(
        {...formDataNotifier.data, 'imageUrls': ref.read(imagePickerProvider)},
        'local');
  }

  Future<void> _onSendToWarehousePressed(
      BuildContext context,
      WidgetRef ref,
      ItemFormData formDataNotifier,
      ImageSliderNotifier formImagesNotifier) async {
    // Save/delete current transaction before warehouse operation (similar to navigation)
    if (!await onLeavingTransaction(context, ref, formImagesNotifier)) return;

    // Check if transaction still has name after cleanup
    if (formDataNotifier.data[nameKey] == '' && context.mounted) {
      failureUserMessage(context, S.of(context).no_name_print_error);
      return;
    }

    const imagePath = 'assets/images/invoice_logo.PNG';
    final image = await loadImage(imagePath);
    if (!context.mounted) return;
    final pdf = await getPdfFile(context, ref, formDataNotifier.data, image);
    if (!context.mounted) return;

    ref.read(printLogServiceProvider).logPrint(
        {...formDataNotifier.data, 'imageUrls': ref.read(imagePickerProvider)},
        'warehouse');
    final warehouseService = ref.read(warehouseServiceProvider);
    if (context.mounted) {
      await warehouseService.sendToWarehouse(
          context, ref, formDataNotifier.data, pdf);
    }
  }

  static Future<void> onNavigationPressed(
      ItemFormData formDataNotifier,
      BuildContext context,
      WidgetRef ref,
      ImageSliderNotifier formImagesNotifier,
      FromNavigator formNavigation,
      {Map<String, dynamic>? targetTransactionData,
      bool isNewTransaction = false,
      bool isDeleting = false}) async {
    final settingsDataNotifier = ref.read(settingsFormDataProvider.notifier);
    final textEditingNotifier = ref.read(textFieldsControllerProvider.notifier);
    final imagePickerNotifier = ref.read(imagePickerProvider.notifier);

    final transactionDbCache = ref.read(transactionDbCacheProvider.notifier);

    final formType = formDataNotifier.getProperty(transactionTypeKey);
    // if we are navigating or creating new transaction, we save previous one, but if we are comming from
    // delete button inside the form, then we don't save
    if (!isDeleting) {
      // as we are leaving the current transaction, we should make sure to delete the transaction if it has no name
      // or to save (update) it if it does have name.
      if (!await onLeavingTransaction(context, ref, formImagesNotifier)) {
        return;
      }
    }
    // Don't pop here - let showForm handle navigation using pushReplacement
    // Navigator.of(context).pop();
    // now load the target transaction into the form, whether it is navigated or new transaction
    // note that navigatorFormData shouldn't be null if isNewTransaction is false
    if (!context.mounted) return;

    if (isNewTransaction) {
      TransactionShowForm.showForm(
        context,
        ref,
        imagePickerNotifier,
        formDataNotifier,
        settingsDataNotifier,
        textEditingNotifier,
        formType: formType,
        transactionDbCache: transactionDbCache,
        useReplacement: true,
      );
    } else {
      if (targetTransactionData == null) {
        errorPrint('Navigating to a null transaction');
        return;
      }
      final imageUrls = formImagesNotifier.saveChanges();
      final itemData = {...targetTransactionData, 'imageUrls': imageUrls};
      final transaction = Transaction.fromMap(itemData);
      TransactionShowForm.showForm(
        context,
        ref,
        imagePickerNotifier,
        formDataNotifier,
        settingsDataNotifier,
        textEditingNotifier,
        transaction: transaction,
        formType: formType,
        useReplacement: true,
      );
    }
    final backgroundColorNofifier = ref.read(backgroundColorProvider.notifier);
    backgroundColorNofifier.state = normalColor!;
  }

  /// this function is called when navigating away from current transaction
  /// or when leaving the form page
  /// unless the transaction has no name, we save (update) it.
  /// Returns true if operation (save or delete) was successful, false otherwise.
  static Future<bool> onLeavingTransaction(BuildContext context, WidgetRef ref,
      ImageSliderNotifier formImagesNotifier) async {
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final formData = formDataNotifier.data;
    final name = formData[nameKey];
    final type = formData[transactionTypeKey];
    // if form doesn't contain name, delete it
    if (name.isEmpty) {
      final formController = ref.read(transactionFormControllerProvider);
      final transactionDbCache = ref.read(transactionDbCacheProvider.notifier);
      final screenController = ref.read(transactionScreenControllerProvider);

      // Decrement counter in background - not critical for transaction flow
      // ignore: unawaited_futures
      _decrementCounterIfLastTransaction(ref, formData);

      if (!context.mounted) return false;
      return await deleteTransaction(
          context,
          ref,
          formDataNotifier,
          formImagesNotifier,
          formController,
          transactionDbCache,
          screenController,
          dialogOn: false);
    }
    // if invoice doesn't contain items, delete it
    final isItemedTransaction = type.contains('Invoice') ||
        type.contains('gift') ||
        type.contains('Return');
    if (isItemedTransaction &&
        formData.containsKey(itemsKey) &&
        formData[itemsKey] is List &&
        formData[itemsKey].length == 1 &&
        formData[itemsKey][0]['code'] == null &&
        formData[itemsKey][0]['name'].isEmpty) {
      failureUserMessage(context,
          '${S.of(context).no_item_were_added_to_invoice} ${formData[numberKey]}');
    }
    // save (or update) transaction
    formImagesNotifier.close();
    final dbCache = ref.read(transactionDbCacheProvider.notifier);
    final transDbRef = formDataNotifier.data[dbRefKey];
    // Determine if this is an existing transaction (edit) or new transaction (add)
    final isExisting = dbCache.getItemByDbRef(transDbRef).isNotEmpty;

    if (!context.mounted) return false;

    final success =
        await saveTransaction(context, ref, formDataNotifier.data, isExisting);
    if (!success) return false;

    // clear customer debt info
    final customerDebInfo = ref.read(customerDebtNotifierProvider.notifier);
    customerDebInfo.reset();
    return true;
  }

  /// when delete transaction, we stay in the form but navigate to previous transaction
  /// Returns true if delete was successful, false otherwise
  static Future<bool> deleteTransaction(
      BuildContext context,
      WidgetRef ref,
      ItemFormData formDataNotifier,
      ImageSliderNotifier formImagesNotifier,
      ItemFormController formController,
      DbCache transactionDbCache,
      TransactionScreenController screenController,
      {bool dialogOn = true,
      FromNavigator? formNavigation}) async {
    if (dialogOn) {
      final confirmation = await showDeleteConfirmationDialog(
          context: context,
          messagePart1: S.of(context).alert_before_delete,
          messagePart2:
              '${translateDbTextToScreenText(context, formDataNotifier.data[transTypeKey])}  ${formDataNotifier.data[numberKey]}');
      if (confirmation == null) return false;
    }

    final formData = formDataNotifier.data;

    final imageUrls = formImagesNotifier.saveChanges();
    final itemData = {...formData, 'imageUrls': imageUrls};
    final transaction = Transaction.fromMap(itemData);

    if (!context.mounted) return false;

    // Fire-and-forget Firebase delete - writes go to Firebase local cache instantly,
    // then sync to server in background via Firebase persistence
    // ignore: unawaited_futures
    formController
        .deleteItemFromDb(context, transaction, keepDialogOpen: true)
        .catchError((e) {
      errorPrint('Background delete failed: $e');
      return false;
    });

    if (!context.mounted) return true;

    // Update local cache immediately (Firebase local cache already has the delete)
    if (dialogOn && itemData['name'].isNotEmpty) {
      // if dialog is on, it means this is real transaction deletion (i.e. user pressed delete button)
      // not automatic delete for empty transaction (when no name entered and we leave the form)
      addToDeletedTransactionsDb(ref, itemData);
    }

    // update the bdCache (database mirror) so that we don't need to fetch data from db
    const operationType = DbCacheOperationTypes.delete;
    transactionDbCache.update(itemData, operationType);
    // redo screenData calculations for transaction screen
    if (context.mounted) {
      screenController.setFeatureScreenData(context);
    }

    // PRE-CALCULATE affected entities synchronously while context is still valid
    // This must happen BEFORE navigation which will invalidate context
    final cacheUpdateService = ref.read(screenCacheUpdateServiceProvider);
    PreCalculatedCacheData? preCalculatedData;
    if (context.mounted) {
      preCalculatedData = cacheUpdateService.calculateAffectedEntities(
        context,
        itemData, // deleted transaction as old
        null, // no new transaction
        TransactionOperation.delete,
      );
    }

    // Save pre-calculated data to Firebase asynchronously (no context needed)
    if (preCalculatedData != null) {
      _savePreCalculatedDataAsync(cacheUpdateService, preCalculatedData);
    }

    // move point to previous transaction
    if (formNavigation != null && context.mounted) {
      final targetTransactionData = formNavigation.previous();
      onNavigationPressed(
        formDataNotifier,
        context,
        ref,
        formImagesNotifier,
        formNavigation,
        targetTransactionData: targetTransactionData,
        isDeleting: true,
      );
    }
    return true;
  }

  static void addToDeletedTransactionsDb(
      WidgetRef ref, Map<String, dynamic> itemData) {
    itemData = removeEmptyRows(itemData);
    final deletionItemData = {...itemData, 'deleteDateTime': DateTime.now()};
    final deletedTransaction = DeletedTransaction.fromMap(deletionItemData);
    final deletedTransactionRepository =
        ref.read(deletedTransactionRepositoryProvider);
    deletedTransactionRepository.addItem(deletedTransaction);
    final deletedTransactionsDbCache =
        ref.read(deletedTransactionDbCacheProvider.notifier);
    // update the bdCache (database mirror) so that we don't need to fetch data from db
    if (deletionItemData[transactionDateKey] is DateTime) {
      // in our form the data type usually is DateTime, but the date type in dbCache should be
      // Timestamp, as to mirror the datatype of firebase
      deletionItemData[transactionDateKey] =
          firebase.Timestamp.fromDate(deletionItemData[transactionDateKey]);
    }
    // update the bdCache (database mirror) so that we don't need to fetch data from db
    if (deletionItemData['deleteDateTime'] is DateTime) {
      // in our form the data type usually is DateTime, but the date type in dbCache should be
      // Timestamp, as to mirror the datatype of firebase
      deletionItemData['deleteDateTime'] =
          firebase.Timestamp.fromDate(deletionItemData['deleteDateTime']);
    }
    deletedTransactionsDbCache.update(
        deletionItemData, DbCacheOperationTypes.add);
  }

  /// Saves transaction to Firebase, then updates local cache only if save succeeded.
  /// Returns true if save was successful, false otherwise.
  static Future<bool> saveTransaction(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> formData,
    bool isEditing,
  ) async {
    final formController = ref.read(transactionFormControllerProvider);

    final formImagesNotifier = ref.read(imagePickerProvider.notifier);
    final screenController = ref.read(transactionScreenControllerProvider);
    final dbCache = ref.read(transactionDbCacheProvider.notifier);

    // Capture old transaction before editing (for cache update)
    Map<String, dynamic>? oldTransaction;
    Map<String, dynamic> formDataCopy = {...formData};
    if (isEditing) {
      oldTransaction = dbCache.getItemByDbRef(formDataCopy[dbRefKey]);
    }

    // we need to remove empty rows (rows without item name, which is usally last one)
    formDataCopy = removeEmptyRows(formDataCopy);
    final imageUrls = formImagesNotifier.saveChanges();
    final itemData = {...formDataCopy, 'imageUrls': imageUrls};
    final transaction =
        Transaction.fromMap({...formDataCopy, 'imageUrls': imageUrls});

    // Fire-and-forget Firebase save - writes go to Firebase local cache instantly,
    // then sync to server in background via Firebase persistence
    // ignore: unawaited_futures
    formController
        .saveItemToDb(context, transaction, isEditing, keepDialogOpen: true)
        .catchError((e) {
      errorPrint('Background save failed: $e');
      return false;
    });

    if (!context.mounted) return true;

    // Update local cache immediately (Firebase local cache already has the write)
    // update the bdCache (database mirror) so that we don't need to fetch data from db
    if (itemData[transactionDateKey] is DateTime) {
      // in our form the data type usually is DateTime, but the date type in dbCache should be
      // Timestamp, as to mirror the datatype of firebase
      itemData[transactionDateKey] =
          firebase.Timestamp.fromDate(formDataCopy[transactionDateKey]);
    }
    final operationType =
        isEditing ? DbCacheOperationTypes.edit : DbCacheOperationTypes.add;
    dbCache.update(itemData, operationType);
    // redo screenData calculations for transaction screen
    if (context.mounted) {
      screenController.setFeatureScreenData(context);
    }

    // Update counter in background - not critical for transaction save
    // ignore: unawaited_futures
    _updateCounterIfNeeded(ref, formDataCopy);

    // PRE-CALCULATE affected entities synchronously while context is still valid
    final cacheUpdateService = ref.read(screenCacheUpdateServiceProvider);
    if (context.mounted) {
      final preCalculatedData = cacheUpdateService.calculateAffectedEntities(
        context,
        oldTransaction,
        itemData,
        isEditing ? TransactionOperation.edit : TransactionOperation.add,
      );
      // Save pre-calculated data to Firebase asynchronously (no context needed)
      _savePreCalculatedDataAsync(cacheUpdateService, preCalculatedData);
    }
    return true;
  }

  /// Save pre-calculated data to Firebase asynchronously (no context needed)
  /// Retries up to 3 times with increasing delays to handle transient network issues
  static void _savePreCalculatedDataAsync(
    ScreenCacheUpdateService cacheUpdateService,
    PreCalculatedCacheData preCalculatedData,
  ) {
    // Run asynchronously without blocking the UI
    Future.delayed(Duration.zero, () async {
      const retryDelays = [
        Duration.zero,
        Duration(seconds: 3),
        Duration(seconds: 5),
        Duration(seconds: 10)
      ];
      for (int attempt = 0; attempt < retryDelays.length; attempt++) {
        try {
          if (attempt > 0) {
            await Future.delayed(retryDelays[attempt]);
          }
          await cacheUpdateService.savePreCalculatedData(preCalculatedData);
          return; // success, no need to retry
        } catch (e) {
          errorPrint('Attempt ${attempt + 1} failed saving cache data: $e');
        }
      }
    });
  }

  static Future<void> _updateCounterIfNeeded(
      WidgetRef ref, Map<String, dynamic> formData) async {
    final transactionType = formData[transactionTypeKey];
    var transactionNumber = formData[numberKey];

    if (transactionNumber is double) {
      transactionNumber = transactionNumber.toInt();
    }

    if (transactionType != null &&
        transactionNumber != null &&
        transactionNumber is int) {
      final counterRepository = ref.read(counterRepositoryProvider);
      await counterRepository.ensureCounterAtLeast(
          transactionType, transactionNumber);
    }
  }

  static Future<void> _decrementCounterIfLastTransaction(
      WidgetRef ref, Map<String, dynamic> formData) async {
    final transactionType = formData[transactionTypeKey];
    var transactionNumber = formData[numberKey];

    if (transactionNumber is double) {
      transactionNumber = transactionNumber.toInt();
    }

    if (transactionType != null && transactionNumber != null) {
      final counterRepository = ref.read(counterRepositoryProvider);
      final currentCounter =
          await counterRepository.getCurrentNumber(transactionType);

      // If this transaction number is the last one (currentCounter - 1), decrement
      if (transactionNumber == currentCounter - 1) {
        await counterRepository.decrementCounter(transactionType);
      }
    }
  }

  /// delete rows where there is not item name
  static Map<String, dynamic> removeEmptyRows(Map<String, dynamic> formData) {
    List<Map<String, dynamic>> items = [];
    for (var i = 0; i < formData[itemsKey].length; i++) {
      final item = formData[itemsKey][i];
      // only add items with non empty name field
      if (item[nameKey] != '') {
        Map<String, dynamic> newItem = {};
        item.forEach((key, value) => newItem[key] = value);
        items.add(newItem);
      }
    }
    return {...formData, itemsKey: items};
  }
}

class CustomerDebtReview extends ConsumerWidget {
  const CustomerDebtReview(this.transactionType, {super.key});
  final String transactionType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerDebtInfo = ref.read(customerDebtNotifierProvider);
    ref.watch(customerDebtNotifierProvider);
    // show debt review for customer invoices & receipts
    bool showDebtInfo =
        transactionType == TransactionType.customerInvoice.name ||
            transactionType == TransactionType.customerReceipt.name;
    return Container(
      width: 300,
      padding: const EdgeInsets.only(left: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PrintStatus(),
          if (transactionType == TransactionType.customerInvoice.name)
            const WarehouseStatus(),
          if (showDebtInfo)
            Column(
              children: [
                VerticalGap.l,
                ReviewRow(S.of(context).last_receipt_date,
                    customerDebtInfo.lastReceiptDate),
                VerticalGap.l,
                ReviewRow(S.of(context).total_debt, customerDebtInfo.totalDebt),
                VerticalGap.l,
                ReviewRow(
                    S.of(context).due_debt_amount, customerDebtInfo.dueDebt,
                    isWarning: true),
              ],
            )
        ],
      ),
    );
  }
}

class PrintStatus extends ConsumerWidget {
  const PrintStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider to rebuild when form data changes
    ref.watch(transactionFormDataProvider);
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final bool isPrinted = formDataNotifier.data[isPrintedKey] ?? false;
    final printStatus =
        isPrinted ? S.of(context).printed : S.of(context).not_printed;

    return Row(
      children: [
        Container(
            width: 280,
            decoration: BoxDecoration(
                color: isPrinted ? Colors.blueGrey : Colors.yellow,
                border: Border.all(width: 0.5)), // R
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Center(
              child: Text(
                translateDbTextToScreenText(context, printStatus),
                style: TextStyle(
                    color: isPrinted ? Colors.white : Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            )),
      ],
    );
  }
}

class WarehouseStatus extends ConsumerWidget {
  const WarehouseStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final invoiceId = formDataNotifier.data[dbRefKey];
    final warehouseService = ref.read(warehouseServiceProvider);

    return FutureBuilder(
      future: warehouseService.getQueueItem(invoiceId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final queueItem = snapshot.data!;
        final isPrinted = queueItem.status == 'printed';
        final statusText =
            isPrinted ? 'تم الطباعة في المجهز' : 'في انتظار طباعة المجهز';
        final color = isPrinted ? Colors.green : Colors.orange;

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Container(
                width: 280,
                decoration:
                    BoxDecoration(color: color, border: Border.all(width: 0.5)),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Center(
                  child: Text(
                    statusText,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReviewRow extends ConsumerWidget {
  const ReviewRow(this.title, this.content,
      {this.isWarning = false, super.key});
  final String title;
  final String content;
  final bool isWarning;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Container(
            width: 150,
            decoration: BoxDecoration(
                color: isWarning ? Colors.red : Colors.blueGrey,
                border: Border.all(width: 0.5)), // R
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            )),
        Container(
            width: 130,
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(width: 0.5)), // Rounded corners,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Center(
              child: Text(
                content,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )),
      ],
    );
  }
}

class NavigationButtons extends ConsumerWidget {
  const NavigationButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final formImagesNotifier = ref.read(imagePickerProvider.notifier);
    final formNavigation = ref.read(formNavigatorProvider);
    return Container(
      width: 300,
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // const PrintedSearch(),
          // VerticalGap.l,
          // NavigationTypeSelection(formDataNotifier.getProperty(transactionTypeKey)),
          // VerticalGap.l,
          const NavigationSearch(),
          VerticalGap.l,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () {
                  final formData = formNavigation.first();
                  formNavigation.isReadOnly = true;
                  TransactionForm.onNavigationPressed(formDataNotifier, context,
                      ref, formImagesNotifier, formNavigation,
                      targetTransactionData: formData);
                },
                icon: const GoFirstIcon(),
              ),
              IconButton(
                onPressed: () {
                  final formData = formNavigation.previous();
                  formNavigation.isReadOnly = true;
                  TransactionForm.onNavigationPressed(formDataNotifier, context,
                      ref, formImagesNotifier, formNavigation,
                      targetTransactionData: formData);
                },
                icon: const GoPreviousIcon(),
              ),
              IconButton(
                onPressed: () {
                  formNavigation.isReadOnly = true;
                  final formData = formNavigation.next();

                  TransactionForm.onNavigationPressed(formDataNotifier, context,
                      ref, formImagesNotifier, formNavigation,
                      targetTransactionData: formData);
                },
                icon: const GoNextIcon(),
              ),
              IconButton(
                onPressed: () {
                  final formData = formNavigation.last();
                  formNavigation.isReadOnly = true;
                  TransactionForm.onNavigationPressed(formDataNotifier, context,
                      ref, formImagesNotifier, formNavigation,
                      targetTransactionData: formData);
                },
                icon: const GoLastIcon(),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class NavigationSearch extends ConsumerWidget {
  const NavigationSearch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formNavigator = ref.read(formNavigatorProvider);
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final formImagesNotifier = ref.read(imagePickerProvider.notifier);
    return SizedBox(
      width: 250,
      child: TextFormField(
        textAlign: TextAlign.center,
        decoration:
            formFieldDecoration(label: S.of(context).transaction_number),
        onFieldSubmitted: (value) {
          try {
            formNavigator.goTo(context, int.tryParse(value.trim()));
            formNavigator.isReadOnly = true;
            // TODO navigation to self  is added only to layout rebuild because formNavigation is not stateNotifier
            // TODO later I might change formNavigation to StateNotifier and watch it in this widget
            TransactionForm.onNavigationPressed(formDataNotifier, context, ref,
                formImagesNotifier, formNavigator,
                targetTransactionData: formNavigator
                    .navigatorTransactions[formNavigator.currentIndex]);
          } catch (e) {
            return;
          }
        },
      ),
    );
  }
}

class NavigationTypeSelection extends ConsumerWidget {
  const NavigationTypeSelection(this.transactionType, {super.key});
  final String transactionType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesList = getTransactionTypeDropList(context);
    return SizedBox(
      width: 250,
      child: FormBuilderDropdown(
          initialValue: translateDbTextToScreenText(context, transactionType),
          decoration:
              formFieldDecoration(label: S.of(context).transaction_type),
          onChanged: (value) {},
          name: 'transactionTypeSearch',
          items: typesList
              .sublist(0, typesList.length - 1)
              .map((item) => DropdownMenuItem(
                    alignment: AlignmentDirectional.center,
                    value: item,
                    child: Text(item),
                  ))
              .toList()),
    );
  }
}

class PrintedSearch extends ConsumerWidget {
  const PrintedSearch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 250,
      child: FormBuilderDropdown(
          initialValue: S.of(context).show_all,
          decoration:
              formFieldDecoration(label: S.of(context).transaction_type),
          onChanged: (value) {},
          name: 'printedSearch',
          items: [S.of(context).show_printed_only, S.of(context).show_all]
              .map((item) => DropdownMenuItem(
                    alignment: AlignmentDirectional.center,
                    value: item,
                    child: Text(item),
                  ))
              .toList()),
    );
  }
}
