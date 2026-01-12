import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/show_transaction_dialog.dart';
import 'package:tablets/src/features/transactions/controllers/missing_transactions_detector.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

class MissingTransactionsResultsScreen extends ConsumerWidget {
  const MissingTransactionsResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missingTransactions = ref.watch(missingTransactionsProvider);
    final fileStats = ref.watch(fileProcessingStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('القوائم المفقودة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed(AppRoute.settings.name),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'القوائم المفقودة',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            VerticalGap.l,

            // Check if all files are corrupted
            if (fileStats.isNotEmpty &&
                fileStats.every((stat) => stat.isCorrupted))
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        VerticalGap.l,
                        Text(
                          'جميع الملفات غير صالحة',
                          style: TextStyle(fontSize: 20, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            // Results: no missing transactions
            else if (missingTransactions.isEmpty)
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 64, color: Colors.green),
                        VerticalGap.l,
                        Text(
                          'لا توجد قوائم مفقودة',
                          style: TextStyle(fontSize: 20, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    // Table header
                    _buildTableHeader(),
                    const Divider(thickness: 2),

                    // Table data - scrollable (60% of space)
                    Expanded(
                      flex: 6,
                      child: ListView.builder(
                        itemCount: missingTransactions.length,
                        itemBuilder: (context, index) {
                          final missing = missingTransactions[index];
                          return Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  final transactionData = Map<String, dynamic>.from(missing.fullTransactionData);
                                  // Convert date from String (DD-MM-YYYY) to DateTime
                                  if (transactionData['date'] is String) {
                                    final dateStr = transactionData['date'] as String;
                                    final parts = dateStr.split('-');
                                    transactionData['date'] = DateTime(
                                      int.parse(parts[2]), // year
                                      int.parse(parts[1]), // month
                                      int.parse(parts[0]), // day
                                    );
                                  }
                                  final transaction = Transaction.fromMap(transactionData);
                                  showReadOnlyTransaction(context, transaction);
                                },
                                child: _buildTableRow(context, ref, missing, index + 1),
                              ),
                              const Divider(thickness: 0.5),
                            ],
                          );
                        },
                      ),
                    ),

                    VerticalGap.l,

                    // Summary - scrollable (40% of space)
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'عدد القوائم المفقودة: ${missingTransactions.length}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (fileStats
                                .where((stat) =>
                                    stat.missingCount > 0 || stat.isCorrupted)
                                .isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'تفاصيل الملفات:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView(
                                  children: fileStats
                                      .where((stat) =>
                                          stat.missingCount > 0 ||
                                          stat.isCorrupted)
                                      .map((stat) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 2),
                                            child: Text(
                                              stat.isCorrupted
                                                  ? '- ${extractAndFormatBackupDate(stat.filename)}: ملف تالف'
                                                  : '- ${extractAndFormatBackupDate(stat.filename)}: ${stat.missingCount} قوائم مفقودة',
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
              width: 50,
              child:
                  Text('استرجاع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          SizedBox(
              width: 40,
              child:
                  Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('اسم الزبون',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)),
          Expanded(
              flex: 1,
              child: Text('رقم القائمة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child: Text('نوع القائمة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)),
          Expanded(
              flex: 1,
              child: Text('التاريخ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)),
          Expanded(
              flex: 1,
              child: Text('المبلغ الإجمالي',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)),
          Expanded(
              flex: 1,
              child: Text('اخر نسخة ظهر فيها',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildTableRow(
      BuildContext context, WidgetRef ref, dynamic missing, int rowNumber) {
    final numberFormat = NumberFormat('#,###', 'en_US');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: IconButton(
              icon: const Icon(Icons.restore, size: 20),
              onPressed: () => restoreMissingTransaction(context, ref, missing),
              tooltip: 'استرجاع القائمة',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              rowNumber.toString(),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              missing.customerName,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              missing.transactionNumber.toString(),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              translateDbTextToScreenText(context, missing.transactionType),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              missing.date,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              numberFormat.format(missing.totalAmount.round()),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              missing.backupDate,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
