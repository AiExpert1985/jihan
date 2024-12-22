import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/classes/item_form_controller.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/printing/print_document.dart';
import 'package:tablets/src/common/functions/transaction_type_drowdop_list.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/providers/background_color.dart';
// import 'package:tablets/src/common/providers/background_color.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/providers/text_editing_controllers_provider.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/common/widgets/custome_appbar_for_back_return.dart';
import 'package:tablets/src/common/widgets/dialog_delete_confirmation.dart';
import 'package:tablets/src/common/widgets/form_frame.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/values/form_dimenssions.dart';
import 'package:tablets/src/common/widgets/form_title.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/controllers/customer_debt_info_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_navigator_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_controller.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_controller.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/view/forms/expenditure_form.dart';
import 'package:tablets/src/features/transactions/view/forms/invoice_form.dart';
import 'package:tablets/src/features/transactions/view/forms/receipt_form.dart';
import 'package:tablets/src/features/transactions/view/forms/statement_form.dart';
import 'package:tablets/src/features/transactions/view/transaction_show_form.dart';
import 'package:tablets/src/routers/go_router_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firebase;

class TransactionForm extends ConsumerWidget {
  const TransactionForm(this.isEditMode, this.transactionType, {super.key});
  final bool isEditMode; // used by formController to decide whether to save or update in db
  final String transactionType;
  // used to validate wether customer can buy new invoice (if he didn't exceed limits)

  Widget _getFormWidget(BuildContext context, String transactionType, WidgetRef ref) {
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
      final backgroundColor = ref.read(backgroundColorProvider);
      return InvoiceForm(
        titles[transactionType]!,
        transactionType,
        hideGifts: false,
        backgroundColor: backgroundColor,
      );
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
    formNavigation.initialize(transactionType, formDataNotifier.getProperty(dbRefKey));
    // final transactionTypeTranslated = translateScreenTextToDbText(context, transactionType);
    // final backgroundColor = ref.watch(backgroundColorProvider);
    ref.watch(imagePickerProvider);
    ref.watch(transactionFormDataProvider);
    ref.watch(textFieldsControllerProvider);
    final height = transactionFormDimenssions[transactionType]['height'];
    final width = transactionFormDimenssions[transactionType]['width'];

    return Scaffold(
      appBar: buildArabicAppBar(context, () async {
        // back to transactions screen
        onLeavingTransaction(context, ref, formImagesNotifier);
        Navigator.pop(context);
        context.goNamed(AppRoute.transactions.name);
      }, () async {
        // back to home screen
        onLeavingTransaction(context, ref, formImagesNotifier);
        Navigator.pop(context);
        context.goNamed(AppRoute.home.name);
      }),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const NavigationButtons(),
          FormFrame(
            title: buildFormTitle(translateDbTextToScreenText(context, transactionType)),
            // backgroundColor: backgroundColor,
            // formKey: formController.formKey,
            // formKey: GlobalKey<FormState>(),
            fields: _getFormWidget(context, transactionType, ref),
            buttons: _actionButtons(context, formController, formDataNotifier, formImagesNotifier,
                dbCache, screenController, formNavigation, ref),
            width: width is double ? width : width.toDouble(),
            height: height is double ? height : height.toDouble(),
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
          onNavigationPressed(formDataNotifier, context, ref, formImagesNotifier, formNavigation,
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
            onNavigationPressed(formDataNotifier, context, ref, formImagesNotifier, formNavigation,
                targetTransactionData: formData);
          },
          icon: const EditIcon(),
        ),
      // only show delete button if we are in editing mode
      if (!formNavigation.isReadOnly)
        IconButton(
          onPressed: () {
            formNavigation.isReadOnly = true;
            deleteTransaction(context, ref, formDataNotifier, formImagesNotifier, formController,
                transactionDbCache, screenController,
                formNavigation: formNavigation);
          },
          icon: const DeleteIcon(),
        ),
      IconButton(
        onPressed: () {
          _onPrintPressed(context, ref, formDataNotifier);
          // if not printed due to empty name, don't continue
          if (!formDataNotifier.getProperty(isPrintedKey)) return;
          formNavigation.isReadOnly = true;
          // TODO navigation to self  is added only to layout rebuild because formNavigation is not stateNotifier
          // TODO later I might change formNavigation to StateNotifier and watch it in this widget
          final formData = formDataNotifier.data;
          onNavigationPressed(formDataNotifier, context, ref, formImagesNotifier, formNavigation,
              targetTransactionData: formData);
        },
        icon: const PrintIcon(),
      ),
    ];
  }

  void _onPrintPressed(BuildContext context, WidgetRef ref, ItemFormData formDataNotifier) async {
    if (formDataNotifier.data[nameKey] == '') {
      failureUserMessage(context, S.of(context).no_name_print_error);
      return;
    }

    // first we need to save changes done to the form, then print, because if we don't save,
    // then the debt of customer will not accurately calculated
    // also, as a policy, I want always to save before print, because I want to ensure always the transaction in
    // database matches the printed transaction.
    saveTransaction(context, ref, formDataNotifier.data, true);
    printForm(context, ref, formDataNotifier.data);
    formDataNotifier.updateProperties({isPrintedKey: true});
  }

  static void onNavigationPressed(ItemFormData formDataNotifier, BuildContext context,
      WidgetRef ref, ImageSliderNotifier formImagesNotifier, FromNavigator formNavigation,
      {Map<String, dynamic>? targetTransactionData,
      bool isNewTransaction = false,
      bool isDeleting = false}) {
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
      onLeavingTransaction(context, ref, formImagesNotifier);
    }
    Navigator.of(context).pop();
    // now load the target transaction into the form, whether it is navigated or new transaction
    // note that navigatorFormData shouldn't be null if isNewTransaction is false
    if (isNewTransaction) {
      final backgroundColorNofifier = ref.read(backgroundColorProvider.notifier);
      backgroundColorNofifier.state = normalColor!;
      TransactionShowForm.showForm(
        context,
        ref,
        imagePickerNotifier,
        formDataNotifier,
        settingsDataNotifier,
        textEditingNotifier,
        formType: formType,
        transactionDbCache: transactionDbCache,
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
      );
    }
  }

  /// this function is called when navigating away from current transaction
  /// or when leaving the form page
  /// unless the transaction has no name, we save (update) it.
  static Future<void> onLeavingTransaction(
      BuildContext context, WidgetRef ref, ImageSliderNotifier formImagesNotifier) async {
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final formData = formDataNotifier.data;
    final name = formData[nameKey];
    final type = formData[transactionTypeKey];
    // if form doesn't contain name, delete it
    if (name.isEmpty) {
      final formController = ref.read(transactionFormControllerProvider);
      final transactionDbCache = ref.read(transactionDbCacheProvider.notifier);
      final screenController = ref.read(transactionScreenControllerProvider);
      deleteTransaction(context, ref, formDataNotifier, formImagesNotifier, formController,
          transactionDbCache, screenController,
          dialogOn: false);
      return;
    }
    // if invoice doesn't contain items, delete it
    final isItemedTransaction =
        type.contains('Invoice') || type.contains('gift') || type.contains('Return');
    if (isItemedTransaction &&
        formData.containsKey(itemsKey) &&
        formData[itemsKey] is List &&
        formData[itemsKey].length == 1 &&
        formData[itemsKey][0]['code'] == null &&
        formData[itemsKey][0]['name'].isEmpty) {
      failureUserMessage(
          context, '${S.of(context).no_item_were_added_to_invoice} ${formData[numberKey]}');
    }
    // save (or update) transaction
    formImagesNotifier.close();
    final dbCache = ref.read(transactionDbCacheProvider.notifier);
    final transDbRef = formDataNotifier.data[dbRefKey];
    if (dbCache.getItemByDbRef(transDbRef).isNotEmpty && context.mounted) {
      saveTransaction(context, ref, formDataNotifier.data, true);
    }
    // clear customer debt info
    final customerDebInfo = ref.read(customerDebtNotifierProvider.notifier);
    customerDebInfo.reset();
  }

  /// when delete transaction, we stay in the form but navigate to previous transaction
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
          message:
              '${translateDbTextToScreenText(context, formDataNotifier.data[transTypeKey])}  ${formDataNotifier.data[numberKey]}');
      if (confirmation == null) return false;
    }

    final formData = formDataNotifier.data;

    final imageUrls = formImagesNotifier.saveChanges();
    final itemData = {...formData, 'imageUrls': imageUrls};
    final transaction = Transaction.fromMap(itemData);
    if (context.mounted) {
      formController.deleteItemFromDb(context, transaction, keepDialogOpen: true);
    }
    // update the bdCache (database mirror) so that we don't need to fetch data from db
    const operationType = DbCacheOperationTypes.delete;
    transactionDbCache.update(itemData, operationType);
    // redo screenData calculations
    if (context.mounted) {
      screenController.setFeatureScreenData(context);
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

  static void saveTransaction(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> formData,
    bool isEditing,
  ) {
    final formController = ref.read(transactionFormControllerProvider);
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final formImagesNotifier = ref.read(imagePickerProvider.notifier);
    final screenController = ref.read(transactionScreenControllerProvider);
    final dbCache = ref.read(transactionDbCacheProvider.notifier);
    // if (isEditing) {
    //   if (!formController.validateData()) return;
    //   formController.submitData();
    // }
    Map<String, dynamic> formData = {...formDataNotifier.data};
    // we need to remove empty rows (rows without item name, which is usally last one)
    formData = removeEmptyRows(formData);
    final imageUrls = formImagesNotifier.saveChanges();
    final itemData = {...formData, 'imageUrls': imageUrls};
    final transaction = Transaction.fromMap({...formData, 'imageUrls': imageUrls});
    formController.saveItemToDb(context, transaction, isEditing, keepDialogOpen: true);
    // update the bdCache (database mirror) so that we don't need to fetch data from db
    if (itemData[transactionDateKey] is DateTime) {
      // in our form the data type usually is DateTime, but the date type in dbCache should be
      // Timestamp, as to mirror the datatype of firebase
      itemData[transactionDateKey] = firebase.Timestamp.fromDate(formData[transactionDateKey]);
    }
    final operationType = isEditing ? DbCacheOperationTypes.edit : DbCacheOperationTypes.add;
    dbCache.update(itemData, operationType);
    // redo screenData calculations
    if (context.mounted) {
      screenController.setFeatureScreenData(context);
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
    bool showDebtInfo = transactionType == TransactionType.customerInvoice.name;
    return Container(
      width: 300,
      padding: const EdgeInsets.only(left: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PrintStatus(),
          if (showDebtInfo)
            Column(
              children: [
                VerticalGap.l,
                ReviewRow(S.of(context).last_receipt_date, customerDebtInfo.lastReceiptDate),
                VerticalGap.l,
                ReviewRow(S.of(context).total_debt, customerDebtInfo.totalDebt),
                VerticalGap.l,
                ReviewRow(S.of(context).due_debt_amount, customerDebtInfo.dueDebt, isWarning: true),
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
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final isPrinted = formDataNotifier.data[isPrintedKey];
    final printStatus = isPrinted ? S.of(context).printed : S.of(context).not_printed;

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

class ReviewRow extends ConsumerWidget {
  const ReviewRow(this.title, this.content, {this.isWarning = false, super.key});
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
                style:
                    const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )),
        Container(
            width: 130,
            decoration: BoxDecoration(
                color: Colors.white, border: Border.all(width: 0.5)), // Rounded corners,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Center(
              child: Text(
                content,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  TransactionForm.onNavigationPressed(
                      formDataNotifier, context, ref, formImagesNotifier, formNavigation,
                      targetTransactionData: formData);
                },
                icon: const GoFirstIcon(),
              ),
              IconButton(
                onPressed: () {
                  final formData = formNavigation.previous();
                  formNavigation.isReadOnly = true;
                  TransactionForm.onNavigationPressed(
                      formDataNotifier, context, ref, formImagesNotifier, formNavigation,
                      targetTransactionData: formData);
                },
                icon: const GoPreviousIcon(),
              ),
              IconButton(
                onPressed: () {
                  formNavigation.isReadOnly = true;
                  final formData = formNavigation.next();

                  TransactionForm.onNavigationPressed(
                      formDataNotifier, context, ref, formImagesNotifier, formNavigation,
                      targetTransactionData: formData);
                },
                icon: const GoNextIcon(),
              ),
              IconButton(
                onPressed: () {
                  final formData = formNavigation.last();
                  formNavigation.isReadOnly = true;
                  TransactionForm.onNavigationPressed(
                      formDataNotifier, context, ref, formImagesNotifier, formNavigation,
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
    final formNavigation = ref.read(formNavigatorProvider);
    return SizedBox(
      width: 250,
      child: TextFormField(
        textAlign: TextAlign.center,
        decoration: formFieldDecoration(label: S.of(context).transaction_number),
        onFieldSubmitted: (value) {
          try {
            formNavigator.goTo(context, int.tryParse(value.trim()));
            // TODO navigation to self  is added only to layout rebuild because formNavigation is not stateNotifier
            // TODO later I might change formNavigation to StateNotifier and watch it in this widget
            TransactionForm.onNavigationPressed(
                formDataNotifier, context, ref, formImagesNotifier, formNavigation,
                targetTransactionData:
                    formNavigation.navigatorTransactions[formNavigation.currentIndex]);
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
          decoration: formFieldDecoration(label: S.of(context).transaction_type),
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
          decoration: formFieldDecoration(label: S.of(context).transaction_type),
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
