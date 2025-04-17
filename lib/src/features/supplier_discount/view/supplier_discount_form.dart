import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/form_dimenssions.dart';
import 'package:tablets/src/common/widgets/custome_appbar_for_back_return.dart';
import 'package:tablets/src/common/widgets/form_frame.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/form_title.dart';
import 'package:tablets/src/features/supplier_discount/controllers/supplier_discount_form_controller.dart';
import 'package:tablets/src/features/supplier_discount/model/supplier_discount.dart';
import 'package:tablets/src/features/supplier_discount/repository/supplier_discount_repository_provider.dart';
import 'package:tablets/src/features/supplier_discount/services/apply_discount.dart';
import 'package:tablets/src/features/supplier_discount/view/supplier_discount_form_fields.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/repository/transaction_repository_provider.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

class SupplierDiscountForm extends ConsumerWidget {
  const SupplierDiscountForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: buildArabicAppBar(context, () async {
        Navigator.pop(context);
      }, () async {
        // back to home screen
        Navigator.pop(context);
        context.goNamed(AppRoute.home.name);
      }),
      body: FormFrame(
        title: buildFormTitle(S.of(context).region),
        fields: Container(
          padding: const EdgeInsets.all(0),
          width: 800,
          height: 400,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SupplierDiscountFormFields(),
            ],
          ),
        ),
        buttons: [
          IconButton(
            onPressed: () => _onSavePress(context, ref),
            icon: const SaveIcon(),
          ),
          IconButton(
            onPressed: () => _onDeletePressed(context, ref),
            icon: const DeleteIcon(),
          ),
        ],
        width: regionFormWidth,
        height: regionFormHeight,
      ),
    );
  }

  void _onSavePress(BuildContext context, WidgetRef ref) async {
    final discountRep = ref.read(supplierDiscountRepositoryProvider);
    final formDataNotifier = ref.read(supplierDiscountFormDataProvider.notifier);
    final supplierDiscountService = ref.read(supplierDiscountServiceProvider);
    addRequiredProperties(ref);
    bool isValid = userEnteredAllData(formDataNotifier.data);
    if (!isValid) {
      failureUserMessage(context, 'يجب ملئ جميع الحقول');
      return;
    }
    final discount = SupplierDiscount.fromMap(formDataNotifier.data);
    discountRep.addItem(discount);
    formDataNotifier.reset();
    await supplierDiscountService.applySupplierDiscount(context, ref, discount);
    // update transaction dbCache
    final transactionDbCache = ref.read(transactionDbCacheProvider.notifier);
    final transactionData = await ref.read(transactionRepositoryProvider).fetchItemListAsMaps();
    transactionDbCache.set(transactionData);
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  void _onDeletePressed(BuildContext context, WidgetRef ref) {
    ref.read(supplierDiscountFormDataProvider.notifier).reset();
    Navigator.pop(context);
  }

  void addRequiredProperties(WidgetRef ref) {
    // these properties required for BaseItem, but not needed to be entered by user
    final formDataNotifier = ref.read(supplierDiscountFormDataProvider.notifier);
    formDataNotifier.updateProperties({
      'dbRef': generateRandomString(len: 8),
      'name': generateRandomString(len: 10),
    });
  }

  bool userEnteredAllData(Map<dynamic, dynamic> map) {
    final requiredKeys = [
      'dbRef',
      'name',
      'supplierDbRef',
      'supplierName',
      'productDbRef',
      'productName',
      'date',
      'discountAmount',
      'newPrice',
      'quantity'
    ];
    for (String keyToCheck in requiredKeys) {
      if (!map.containsKey(keyToCheck)) {
        return false;
      }
    }
    return true;
  }
}
