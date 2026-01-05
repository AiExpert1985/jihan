import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/features/transactions/controllers/invoice_validation_controller.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

class InvoiceValidationResultsScreen extends ConsumerWidget {
  const InvoiceValidationResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mismatches = ref.watch(invoiceValidationResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('نتائج مطابقة مبالغ القوائم'),
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
                'نتائج مطابقة مبالغ القوائم',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            VerticalGap.l,

            // Results
            if (mismatches.isEmpty)
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
                          'لا يوجد خلل في مبالغ القوائم',
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
                    // Table data
                    Expanded(
                      child: ListView.builder(
                        itemCount: mismatches.length,
                        itemBuilder: (context, index) {
                          final mismatch = mismatches[index];
                          return Column(
                            children: [
                              _buildTableRow(mismatch, index + 1),
                              const Divider(thickness: 0.5),
                            ],
                          );
                        },
                      ),
                    ),
                    VerticalGap.l,
                    // Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'إجمالي القوائم المخالفة: ${mismatches.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
          SizedBox(width: 40, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('الاسم', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text('رقم القائمة', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text('المبلغ المسجل', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text('المبلغ الصحيح', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('نوع الخطأ', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildTableRow(InvoiceMismatch mismatch, int rowNumber) {
    final numberFormat = NumberFormat('#,###', 'en_US');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
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
              mismatch.customerName,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              mismatch.invoiceNumber.toString(),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              mismatch.date,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              numberFormat.format(mismatch.actualAmount.round()),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              numberFormat.format(mismatch.correctTotalAmount.round()),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.green),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              mismatch.mismatchTypes,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}
