import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/features/deleted_transactions/controllers/deleted_transaction_screen_controller.dart';
import 'package:tablets/src/features/warehouse/model/warehouse_queue_item.dart';

class WarehouseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String collectionName = 'warehouse_print_queue';

  Future<void> sendToWarehouse(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> transactionData,
    pw.Document pdf,
  ) async {
    try {
      final invoiceId = transactionData[dbRefKey];
      final invoiceNumber = transactionData[numberKey].toString();
      final clientName = transactionData[nameKey] ?? '';
      final items = transactionData[itemsKey] as List? ?? [];
      final itemCount = items.where((item) => item[nameKey] != '').length;
      final totalPrice = (transactionData[totalAmountKey] ?? 0).toDouble();

      final pdfPath = 'warehouse_invoices/$invoiceId.pdf';
      final pdfBytes = await pdf.save();

      final docRef = _firestore.collection(collectionName).doc(invoiceId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final oldPdfPath = docSnapshot.data()?['pdfPath'];
        if (oldPdfPath != null) {
          try {
            await _storage.ref(oldPdfPath).delete();
          } catch (e) {
            debugPrint('Failed to delete old PDF: $e');
          }
        }
      }

      await _storage.ref(pdfPath).putData(pdfBytes);

      final queueItem = WarehouseQueueItem(
        invoiceId: invoiceId,
        invoiceNumber: invoiceNumber,
        clientName: clientName,
        itemCount: itemCount,
        totalPrice: totalPrice,
        createdAt: transactionData[transactionDateKey] is DateTime
            ? transactionData[transactionDateKey]
            : (transactionData[transactionDateKey] as Timestamp).toDate(),
        status: 'pending',
        pdfPath: pdfPath,
        printedAt: null,
        sentAt: DateTime.now(),
      );

      await docRef.set(queueItem.toMap());

      if (context.mounted) {
        successUserMessage(context, 'تم الارسال الى المجهز');
      }
    } catch (e) {
      debugPrint('Failed to send to warehouse: $e');
      if (context.mounted) {
        failureUserMessage(context, 'فشل الارسال الى المجهز');
      }
    }
  }

  Stream<List<WarehouseQueueItem>> getPendingInvoices() {
    return _firestore
        .collection(collectionName)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => WarehouseQueueItem.fromMap(doc.data()))
          .toList();

      // Sort in the app instead of Firestore (no index needed)
      items.sort((a, b) => b.sentAt.compareTo(a.sentAt));

      return items;
    });
  }

  Future<void> markAsPrinted(String invoiceId) async {
    try {
      final docRef = _firestore.collection(collectionName).doc(invoiceId);
      await docRef.update({
        'status': 'printed',
        'printedAt': Timestamp.fromDate(DateTime.now()),
      });

      final docSnapshot = await docRef.get();
      final pdfPath = docSnapshot.data()?['pdfPath'];
      if (pdfPath != null) {
        try {
          await _storage.ref(pdfPath).delete();
        } catch (e) {
          debugPrint('Failed to delete PDF after printing: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to mark as printed: $e');
      rethrow;
    }
  }

  Future<File?> downloadPdf(String pdfPath) async {
    try {
      final ref = _storage.ref(pdfPath);
      final bytes = await ref.getData();
      if (bytes == null) return null;

      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/temp_invoice.pdf');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      debugPrint('Failed to download PDF: $e');
      return null;
    }
  }

  Future<WarehouseQueueItem?> getQueueItem(String invoiceId) async {
    try {
      final doc =
          await _firestore.collection(collectionName).doc(invoiceId).get();
      if (!doc.exists) return null;
      return WarehouseQueueItem.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Failed to get queue item: $e');
      return null;
    }
  }
}

final warehouseServiceProvider = Provider<WarehouseService>((ref) {
  return WarehouseService();
});
