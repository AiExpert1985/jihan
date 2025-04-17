import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tablets/src/common/interfaces/base_item.dart'; // Import if using Firestore Timestamp

class SupplierDiscount implements BaseItem {
  SupplierDiscount({
    required this.dbRef,
    required this.name,
    required this.supplierDbRef,
    required this.supplierName,
    required this.productDbRef,
    required this.productName,
    required this.date,
    required this.discountAmount,
    required this.newPrice,
    required this.quantity,
  });

  @override
  String dbRef;
  @override
  String name; // only used for compatibility with BaseItem
  String supplierDbRef;
  String supplierName;
  String productDbRef;
  String productName;
  DateTime date;
  double quantity;
  double discountAmount;
  double newPrice;

  /// Converts this SupplierDiscount instance into a Map.
  /// Suitable for storing in Firestore or converting to JSON.
  @override
  Map<String, dynamic> toMap() {
    return {
      'dbRef': dbRef,
      'name': name,
      'supplierDbRef': supplierDbRef,
      'supplierName': supplierName,
      'productDbRef': productDbRef,
      'productName': productName,
      // Store DateTime as ISO 8601 string for better compatibility
      // Alternatively, use Timestamp.fromDate(date) if using Firestore directly
      'date': date.toIso8601String(),
      'quantity': quantity,
      'discountAmount': discountAmount,
      'newPrice': newPrice,
    };
  }

  /// Creates a SupplierDiscount instance from a Map (e.g., from Firestore).
  factory SupplierDiscount.fromMap(Map<String, dynamic> map) {
    // Handle potential Firestore Timestamp or ISO String for date
    dynamic dateData = map['date'];
    DateTime parsedDate;
    if (dateData is Timestamp) {
      // If data is from Firestore and stored as Timestamp
      parsedDate = dateData.toDate();
    } else if (dateData is String) {
      // If data was stored as ISO 8601 string
      parsedDate = DateTime.parse(dateData);
    } else {
      parsedDate = DateTime.now(); // Example default
    }

    return SupplierDiscount(
      dbRef: map['dbRef'] as String? ?? '',
      name: map['name'] as String? ?? '',
      supplierDbRef: map['supplierDbRef'] as String? ?? '',
      supplierName: map['supplierName'] as String? ?? '',
      productDbRef: map['productDbRef'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      date: parsedDate,
      // Use 'num' casting for flexibility if data source sends int or double
      quantity: (map['quantity'] as num? ?? 0).toDouble(),
      discountAmount: (map['discountAmount'] as num? ?? 0).toDouble(),
      newPrice: (map['newPrice'] as num? ?? 0).toDouble(),
    );
  }

  @override
  String get coverImageUrl => '';

  @override
  List<String> get imageUrls => [];
}
