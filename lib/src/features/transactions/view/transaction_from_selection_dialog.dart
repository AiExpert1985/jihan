import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/widgets/custome_appbar_for_back_return.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/view/transaction_show_form.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/providers/text_editing_controllers_provider.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

class TransactionGroupSelection extends ConsumerWidget {
  const TransactionGroupSelection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> names = [
      S.of(context).customer,
      S.of(context).vendor,
      S.of(context).internal_transaction,
    ];

    final List<String> formTypes = [
      "customer",
      "vendor",
      "internal",
    ];

    return Scaffold(
      appBar: buildArabicAppBar(context, () {
        // back to transactions
        Navigator.of(context).pop();
      }, () {
        context.goNamed(AppRoute.home.name);
      }),
      body: Center(
        child: Container(
          width: 300,
          height: 900,
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1, // Number of columns
              childAspectRatio: 1.7, // Aspect ratio of each card
            ),
            itemCount: names.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TransactionTypeSelection(formTypes[index])),
                  );
                },
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 40, // Reduced height for the card
                    child: Center(
                      child: Text(
                        names[index], // Use the corresponding name
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class TransactionTypeSelection extends ConsumerWidget {
  const TransactionTypeSelection(this.groupName, {super.key});
  final String groupName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = {
      'customer': {
        'names': [
          S.of(context).transaction_type_customer_invoice,
          S.of(context).transaction_type_customer_receipt,
          S.of(context).transaction_type_customer_return,
          S.of(context).transaction_type_gifts,
        ],
        'formTypes': [
          TransactionType.customerInvoice.name,
          TransactionType.customerReceipt.name,
          TransactionType.customerReturn.name,
          TransactionType.gifts.name,
        ]
      },
      'vendor': {
        'names': [
          S.of(context).transaction_type_vender_invoice,
          S.of(context).transaction_type_vendor_receipt,
          S.of(context).transaction_type_vender_return,
        ],
        'formTypes': [
          TransactionType.vendorInvoice.name,
          TransactionType.vendorReceipt.name,
          TransactionType.vendorReturn.name,
        ]
      },
      'internal': {
        'names': [
          S.of(context).transaction_type_expenditures,
          S.of(context).transaction_type_damaged_items,
        ],
        'formTypes': [
          TransactionType.expenditures.name,
          TransactionType.damagedItems.name,
        ]
      },
    };
    // Define the form types and corresponding names
    final List<String> names = group[groupName]!['names']!;

    final List<String> formTypes = group[groupName]!['formTypes']!;

    final textEditingNotifier = ref.read(textFieldsControllerProvider.notifier);
    final imagePickerNotifier = ref.read(imagePickerProvider.notifier);
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final settingsDataNotifier = ref.read(settingsFormDataProvider.notifier);
    final transactionDbCache = ref.read(transactionDbCacheProvider.notifier);

    return Scaffold(
      appBar: buildArabicAppBar(context, () {
        // we pop twice to return to transaction
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }, () {
        context.goNamed(AppRoute.home.name);
      }),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(5),
          width: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1, // Number of columns
              childAspectRatio: 1.5, // Aspect ratio of each card
            ),
            itemCount: names.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () async {
                  if (context.mounted) {
                    TransactionShowForm.showForm(
                      context,
                      ref,
                      imagePickerNotifier,
                      formDataNotifier,
                      settingsDataNotifier,
                      textEditingNotifier,
                      formType: formTypes[index],
                      transactionDbCache: transactionDbCache,
                    );
                  }
                },
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 40, // Reduced height for the card
                    child: Center(
                      child: Text(
                        names[index], // Use the corresponding name
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
