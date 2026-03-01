import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

/// Finds transactions that share the same dbRef (duplicates).
/// Returns a flat list of all transactions involved in duplication,
/// sorted so duplicates with the same dbRef are grouped together.
List<Map<String, dynamic>> findDuplicateTransactions(
    List<Map<String, dynamic>> transactions) {
  // Group by dbRef
  final Map<String, List<Map<String, dynamic>>> grouped = {};
  for (final t in transactions) {
    final dbRef = t[dbRefKey]?.toString() ?? '';
    if (dbRef.isEmpty) continue;
    grouped.putIfAbsent(dbRef, () => []).add(t);
  }
  // Collect only groups with more than one entry
  final List<Map<String, dynamic>> duplicates = [];
  for (final entry in grouped.entries) {
    if (entry.value.length > 1) {
      duplicates.addAll(entry.value);
    }
  }
  return duplicates;
}

class DuplicateTransactionsScreen extends ConsumerWidget {
  const DuplicateTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionDbCacheProvider);
    final duplicates = findDuplicateTransactions(transactions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التعاملات المكررة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed(AppRoute.home.name),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: duplicates.isEmpty ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: duplicates.isEmpty ? Colors.green : Colors.red),
              ),
              child: Text(
                duplicates.isEmpty
                    ? 'لا توجد تعاملات مكررة'
                    : 'عدد التعاملات المكررة: ${duplicates.length}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: duplicates.isEmpty ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (duplicates.isEmpty)
              const Expanded(
                child: Center(
                  child: Icon(Icons.check_circle, size: 64, color: Colors.green),
                ),
              )
            else ...[
              VerticalGap.l,
              _buildTableHeader(),
              const Divider(thickness: 2),
              Expanded(
                child: ListView.separated(
                  itemCount: duplicates.length,
                  separatorBuilder: (_, __) => const Divider(thickness: 0.5),
                  itemBuilder: (context, index) {
                    return _buildTableRow(context, duplicates[index], index + 1);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: Colors.grey[200],
      child: const Row(
        children: [
          SizedBox(
              width: 40,
              child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('dbRef',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child: Text('نوع القائمة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child: Text('الاسم',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)),
          Expanded(
              flex: 1,
              child: Text('الرقم',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child: Text('المندوب',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildTableRow(
      BuildContext context, Map<String, dynamic> transaction, int rowNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(rowNumber.toString(),
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              transaction[dbRefKey]?.toString() ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              translateDbTextToScreenText(
                  context, transaction[transTypeKey]?.toString() ?? ''),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              transaction[nameKey]?.toString() ?? '',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              transaction[numberKey]?.toString() ?? '',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              transaction[salesmanKey]?.toString() ?? '',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
