import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';

/// Model for invoice validation mismatch
class InvoiceMismatch {
  final String customerName;
  final int invoiceNumber;
  final String date;
  final double correctTotalAmount;
  final double actualAmount;
  final String mismatchTypes;

  InvoiceMismatch({
    required this.customerName,
    required this.invoiceNumber,
    required this.date,
    required this.correctTotalAmount,
    required this.actualAmount,
    required this.mismatchTypes,
  });
}

/// Provider for invoice validation results
final invoiceValidationResultsProvider =
    StateProvider<List<InvoiceMismatch>>((ref) => []);

/// Validates all customer invoices and returns list of mismatches
Future<List<InvoiceMismatch>> validateCustomerInvoices(WidgetRef ref) async {
  final transactionDbCache = ref.read(transactionDbCacheProvider.notifier);
  final allTransactions = transactionDbCache.data;

  // Filter only customer invoices
  final customerInvoices = allTransactions.where(
      (t) => t['transactionType'] == TransactionType.customerInvoice.name);

  List<InvoiceMismatch> mismatches = [];
  final dateFormat = DateFormat('dd-MM-yyyy');

  for (var invoice in customerInvoices) {
    // Skip if items is null or empty
    final items = invoice['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) {
      continue;
    }

    List<String> errors = [];
    double correctItemsSum = 0;
    double storedItemsSum = 0;

    // Stage 1: Item validation - check ALL items
    for (var item in items) {
      final sellingPrice = (item['sellingPrice'] ?? 0).toDouble();
      final soldQuantity = (item['soldQuantity'] ?? 0).toDouble();
      final itemTotalAmount = (item['itemTotalAmount'] ?? 0).toDouble();

      final calculatedAmount = sellingPrice * soldQuantity;
      correctItemsSum += calculatedAmount;
      storedItemsSum += itemTotalAmount;

      // Check if calculated matches stored
      if ((calculatedAmount - itemTotalAmount).abs() > 0.01) {
        // Using 0.01 threshold for floating point comparison
        if (!errors.contains("خطأ على مستوى المواد")) {
          errors.add("خطأ على مستوى المواد");
        }
      }
    }

    // Stage 2: Subtotal validation
    final subTotalAmount = (invoice['subTotalAmount'] ?? 0).toDouble();
    if ((storedItemsSum - subTotalAmount).abs() > 0.01) {
      errors.add("خطأ على مستوى مجموع المواد");
    }

    // Stage 3: Total validation
    final discount = (invoice['discount'] ?? 0).toDouble();
    final totalAmount = (invoice['totalAmount'] ?? 0).toDouble();
    final correctTotal = correctItemsSum - discount;

    if ((correctTotal - totalAmount).abs() > 0.01) {
      errors.add("خطأ على مستوى مجموع القائمة");
    }

    // Only add to mismatches if total amount error exists
    if (errors.contains("خطأ على مستوى مجموع القائمة")) {
      final date = invoice['date'];
      final dateString = date is DateTime
          ? dateFormat.format(date)
          : dateFormat.format(date.toDate());

      mismatches.add(InvoiceMismatch(
        customerName: invoice['name'] ?? '',
        invoiceNumber: (invoice['number'] ?? 0).round(),
        date: dateString,
        correctTotalAmount: correctTotal,
        actualAmount: totalAmount,
        mismatchTypes: errors.join(", "),
      ));
    }
  }

  // Sort by invoice number (ascending)
  mismatches.sort((a, b) => a.invoiceNumber.compareTo(b.invoiceNumber));

  return mismatches;
}
