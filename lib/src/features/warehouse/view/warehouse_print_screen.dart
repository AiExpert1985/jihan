import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/widgets/custome_appbar_for_back_return.dart';
import 'package:tablets/src/features/warehouse/model/warehouse_queue_item.dart';
import 'package:tablets/src/features/warehouse/services/warehouse_service.dart';
import 'package:tablets/src/routers/go_router_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class WarehousePrintScreen extends ConsumerWidget {
  const WarehousePrintScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warehouseService = ref.read(warehouseServiceProvider);

    return Scaffold(
      appBar: buildArabicAppBar(
        context,
        () => context.goNamed(AppRoute.home.name),
        () => context.goNamed(AppRoute.home.name),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blueGrey,
            width: double.infinity,
            child: const Text(
              'طباعة المجهز',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: StreamBuilder<List<WarehouseQueueItem>>(
              stream: warehouseService.getPendingInvoices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('حدث خطأ: ${snapshot.error}'),
                  );
                }

                final invoices = snapshot.data ?? [];

                if (invoices.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد فواتير للطباعة',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    return InvoiceCard(invoice: invoice);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class InvoiceCard extends ConsumerWidget {
  const InvoiceCard({required this.invoice, super.key});

  final WarehouseQueueItem invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warehouseService = ref.read(warehouseServiceProvider);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'رقم الفاتورة: ${invoice.invoiceNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اسم الزبون: ${invoice.clientName}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'التاريخ: ${dateFormat.format(invoice.createdAt)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'عدد المواد: ${invoice.itemCount}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'المجموع: ${invoice.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await _printInvoice(context, ref, invoice, warehouseService);
              },
              icon: const Icon(Icons.print),
              label: const Text('طباعة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printInvoice(
    BuildContext context,
    WidgetRef ref,
    WarehouseQueueItem invoice,
    WarehouseService warehouseService,
  ) async {
    try {
      final pdfFile = await warehouseService.downloadPdf(invoice.pdfPath);

      if (pdfFile == null) {
        if (context.mounted) {
          failureUserMessage(context, 'فشل تحميل ملف PDF');
        }
        return;
      }

      final pdfBytes = await pdfFile.readAsBytes();

      // Print first copy
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );

      // Print second copy
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );

      await warehouseService.markAsPrinted(invoice.invoiceId);

      if (context.mounted) {
        successUserMessage(context, 'تمت الطباعة بنجاح');
      }
    } catch (e) {
      if (context.mounted) {
        failureUserMessage(context, 'فشلت الطباعة: $e');
      }
    }
  }
}
