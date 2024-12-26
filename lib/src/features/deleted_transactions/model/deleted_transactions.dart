import 'package:cloud_firestore/cloud_firestore.dart' as cloud;
import 'package:tablets/src/features/transactions/model/transaction.dart';

class DeletedTransaction extends Transaction {
  DateTime? deleteDateTime; // New property to store the deletion date and time

  DeletedTransaction({
    required super.dbRef,
    required super.name,
    required super.imageUrls,
    required super.number,
    super.nameDbRef,
    required super.date,
    required super.currency,
    super.notes,
    required super.transactionType,
    super.paymentType,
    super.salesman,
    super.items,
    super.discount,
    super.totalAsText,
    super.totalWeight,
    super.subTotalAmount,
    required super.totalAmount,
    super.salesmanDbRef,
    super.sellingPriceType,
    required super.transactionTotalProfit,
    super.itemsTotalProfit,
    super.salesmanTransactionComssion,
    required super.isPrinted,
    this.deleteDateTime, // Initialize the new property
  });

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap(); // Get the map from the parent class
    map['deleteDateTime'] = deleteDateTime; // Add the new property to the map
    return map;
  }

  factory DeletedTransaction.fromMap(Map<String, dynamic> map) {
    return DeletedTransaction(
      dbRef: map['dbRef'],
      name: map['name'],
      imageUrls: List<String>.from(map['imageUrls']),
      number: map['number'] is int ? map['number'] : map['number']?.toInt(),
      nameDbRef: map['nameDbRef'],
      date: map['date'] is cloud.Timestamp ? map['date'].toDate() : map['date'],
      currency: map['currency'],
      notes: map['notes'],
      transactionType: map['transactionType'],
      paymentType: map['paymentType'],
      salesman: map['salesman'],
      items: (map['items'] as List<dynamic>?)?.map((item) => item as Map<String, dynamic>).toList(),
      discount: map['discount'] is double ? map['discount'] : map['discount']?.toDouble(),
      totalAsText: map['totalAsText'],
      totalWeight:
          map['totalWeight'] is double ? map['totalWeight'] : map['totalWeight']?.toDouble(),
      totalAmount:
          map['totalAmount'] is double ? map['totalAmount'] : map['totalAmount']?.toDouble(),
      subTotalAmount: map['subTotalAmount'] is double
          ? map['subTotalAmount']
          : map['subTotalAmount']?.toDouble(),
      salesmanDbRef: map['salesmanDbRef'],
      sellingPriceType: map['sellingPriceType'],
      transactionTotalProfit: map['transactionTotalProfit'] is double
          ? map['transactionTotalProfit']
          : map['transactionTotalProfit']?.toDouble(),
      itemsTotalProfit: map['itemsTotalProfit'] is double
          ? map['itemsTotalProfit']
          : map['itemsTotalProfit']?.toDouble(),
      salesmanTransactionComssion: map['salesmanTransactionComssion'] is double
          ? map['salesmanTransactionComssion']
          : map['salesmanTransactionComssion']?.toDouble(),
      isPrinted: map['isPrinted'] ?? false,
      deleteDateTime: map['deleteDateTime'] is cloud.Timestamp
          ? map['deleteDateTime'].toDate()
          : map['deleteDateTime'], // Handle the new property
    );
  }

  @override
  String toString() {
    return '${super.toString()}, DeletedTransaction(deleteDateTime: $deleteDateTime)';
  }
}
