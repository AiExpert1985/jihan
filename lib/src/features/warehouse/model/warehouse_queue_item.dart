import 'package:cloud_firestore/cloud_firestore.dart';

class WarehouseQueueItem {
  final String invoiceId;
  final String invoiceNumber;
  final String clientName;
  final int itemCount;
  final double totalPrice;
  final DateTime createdAt;
  final String status;
  final String pdfPath;
  final DateTime? printedAt;
  final DateTime sentAt;

  WarehouseQueueItem({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.clientName,
    required this.itemCount,
    required this.totalPrice,
    required this.createdAt,
    required this.status,
    required this.pdfPath,
    this.printedAt,
    required this.sentAt,
  });

  factory WarehouseQueueItem.fromMap(Map<String, dynamic> map) {
    return WarehouseQueueItem(
      invoiceId: map['invoiceId'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      clientName: map['clientName'] ?? '',
      itemCount: map['itemCount'] ?? 0,
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      pdfPath: map['pdfPath'] ?? '',
      printedAt: map['printedAt'] != null ? (map['printedAt'] as Timestamp).toDate() : null,
      sentAt: (map['sentAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'clientName': clientName,
      'itemCount': itemCount,
      'totalPrice': totalPrice,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'pdfPath': pdfPath,
      'printedAt': printedAt != null ? Timestamp.fromDate(printedAt!) : null,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }
}
