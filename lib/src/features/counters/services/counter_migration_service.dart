import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/features/counters/repository/counter_repository_provider.dart';
import 'package:tablets/src/features/transactions/repository/transaction_repository_provider.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/features/transactions/view/transaction_show_form.dart';

// Service to migrate existing transaction data to use Firestore counters
class CounterMigrationService {
  // Initialize all transaction counters based on existing data
  Future<void> initializeAllCounters(BuildContext context, WidgetRef ref) async {
    tempPrint('Starting counter initialization...');

    final transactionTypes = [
      TransactionType.customerInvoice.name,
      TransactionType.vendorInvoice.name,
      TransactionType.customerReceipt.name,
      TransactionType.vendorReceipt.name,
      TransactionType.customerReturn.name,
      TransactionType.vendorReturn.name,
      TransactionType.expenditures.name,
      TransactionType.gifts.name,
      TransactionType.damagedItems.name,
    ];

    final errors = <String>[];

    for (final transactionType in transactionTypes) {
      try {
        await initializeCounterForType(context, transactionType, ref);
      } catch (e) {
        errorPrint('Failed to initialize counter for $transactionType: $e');
        errors.add('$transactionType: $e');
      }
    }

    if (errors.isNotEmpty) {
      throw Exception('Failed to initialize some counters: ${errors.join(", ")}');
    }

    tempPrint('Counter initialization completed!');
  }

  // Initialize counter for a specific transaction type
  // Always recalculates and overwrites existing counter based on highest transaction number
  Future<void> initializeCounterForType(BuildContext context, String transactionType, WidgetRef ref) async {
    final counterRepository = ref.read(counterRepositoryProvider);

    // Get current counter value before recalculation
    final currentCounter = await counterRepository.getCurrentNumber(transactionType);
    tempPrint('=== Recalculating counter for $transactionType ===');
    tempPrint('Current counter value: $currentCounter');

    // Get all transactions data
    final transactionRepository = ref.read(transactionRepositoryProvider);
    final transactions = await transactionRepository.fetchItemListAsMaps();

    if (!context.mounted) return;

    // Get highest numbers for debugging
    final maxTransactionNumber = TransactionShowForm.getHighestTransactionNumber(
        context, transactions, transactionType);
    final maxDeletedNumber = TransactionShowForm.getHighestDeletedTransactionNumber(
        ref, transactionType);

    tempPrint('Highest active transaction number: $maxTransactionNumber');
    tempPrint('Highest deleted transaction number: $maxDeletedNumber');

    // Calculate next number (includes both regular and deleted transactions)
    final nextNumber = TransactionShowForm.getNextTransactionNumberFromLocalData(
        context, transactions, transactionType, ref);

    tempPrint('Calculated next number: $nextNumber');

    // Always overwrite the counter with the recalculated value
    await counterRepository.initializeCounter(transactionType, nextNumber);

    tempPrint('Counter updated from $currentCounter to $nextNumber');
    tempPrint('=== End recalculation for $transactionType ===\n');
  }
}

final counterMigrationServiceProvider = Provider<CounterMigrationService>((ref) {
  return CounterMigrationService();
});
