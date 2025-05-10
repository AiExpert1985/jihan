import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/features/supplier_discount/model/supplier_discount.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/features/transactions/repository/transaction_repository_provider.dart';

class SupplierDiscountService {
  Future<void> applySupplierDiscount(
      BuildContext context, WidgetRef ref, SupplierDiscount discount) async {
    final transactionRepo = ref.read(transactionRepositoryProvider);
    final supplierTransactions = await transactionRepo.fetchItemListAsMaps(
        filterKey: 'nameDbRef', filterValue: discount.supplierDbRef);
    sortMapsByProperty(supplierTransactions, 'date');
    double remainingQuantity = discount.quantity;
    for (var transaction in supplierTransactions) {
      bool isTransactionUpdated = false;
      // because I can't add new items to the list while I am iterating it, I create a list
      // for new items add, and finally append it when finish the loop
      List<Map<String, dynamic>> newItems = [];
      for (var item in transaction['items']) {
        if (item['dbRef'] == discount.productDbRef) {
          isTransactionUpdated = true;
          if (remainingQuantity <= item['soldQuantity']) {
            // create a new item with quantity remained & new Price
            final newItem = deepCopyMap(item);
            newItem['soldQuantity'] = remainingQuantity;
            newItem['sellingPrice'] = discount.newPrice;
            newItem['itemTotalAmount'] = newItem['soldQuantity'] * newItem['sellingPrice'];
            newItems.add(newItem);
            // reduce quantity of original item
            item['soldQuantity'] -= remainingQuantity;
            remainingQuantity = 0;
          } else {
            item['sellingPrice'] = discount.newPrice;
            remainingQuantity -= item['soldQuantity'];
          }
          item['itemTotalAmount'] = item['soldQuantity'] * item['sellingPrice'];
        }
      }
      if (isTransactionUpdated) {
        transaction['items'].addAll(newItems);
        // update transaction related fields
        const String notePartOne = 'في تاريخ';
        const String notePartTwo = 'تم تخفيض سعر المادة';
        final String newNoteLine = // Using final
            '$notePartOne ${formatDate(discount.date)} $notePartTwo ${discount.productName}';

        final dynamic rawExistingNotes = transaction['notes']; // Get the value once
        String? currentNotes; // Explicitly declare as nullable String

        if (rawExistingNotes is String) {
          // Check if it's actually a String
          currentNotes = rawExistingNotes;
        }
        // If rawExistingNotes was null or not a String, currentNotes remains null.
        if (currentNotes != null && currentNotes.isNotEmpty) {
          // .isNotEmpty is idiomatic and safe
          transaction['notes'] = '$currentNotes\n$newNoteLine';
        } else {
          transaction['notes'] = newNoteLine;
        }
        double newSubTotalAmount = 0.0;
        for (var item in transaction['items']) {
          newSubTotalAmount += item['itemTotalAmount'];
        }
        transaction['subTotalAmount'] = newSubTotalAmount;
        transaction['totalAmount'] = transaction['subTotalAmount'] - transaction['discount'];
        if (context.mounted) {
          await transactionRepo.updateItem(Transaction.fromMap(transaction));
        }
      }
      if (remainingQuantity <= 0) break;
    }
    tempPrint('successfully applied');
  }
}

final supplierDiscountServiceProvider = Provider<SupplierDiscountService>((ref) {
  return SupplierDiscountService();
});
