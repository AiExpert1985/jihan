// this function is used only to check whether the sum of items equals the total price
// I used it after the error found in one function

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/features/transactions/repository/transaction_repository_provider.dart';

void checkTransactionsTotals(WidgetRef ref) async {
  tempPrint('check transaction total started');
  final transactionRepo = ref.read(transactionRepositoryProvider);
  final transactions = await transactionRepo.fetchItemListAsMaps(
      filterKey: "transactionType", filterValue: TransactionType.customerInvoice.name);
  tempPrint('number of customerInvoices = ${transactions.length}');
  double mismatcheCount = 0;
  for (var trans in transactions) {
    double sum = 0;
    for (var item in trans['items']) {
      sum += item['itemTotalAmount'];
    }
    if (sum != trans['subTotalAmount']) {
      mismatcheCount += 1;
      tempPrint('$mismatcheCount: ${trans['name']}: ${formatDate(trans['date'].toDate())}');
    }
  }
  tempPrint('check transaction total finished');
  tempPrint('Number of mismatches = $mismatcheCount');
}
