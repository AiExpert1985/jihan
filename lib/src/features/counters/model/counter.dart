// Counter model for maintaining sequential transaction numbers
// Each transaction type has its own counter document in Firestore
class Counter {
  final String transactionType; // e.g., 'customerInvoice', 'vendorInvoice'
  final int nextNumber; // The next available number for this transaction type

  Counter({
    required this.transactionType,
    required this.nextNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'transactionType': transactionType,
      'nextNumber': nextNumber,
    };
  }

  factory Counter.fromMap(Map<String, dynamic> map) {
    return Counter(
      transactionType: map['transactionType'] ?? '',
      nextNumber: map['nextNumber'] is int ? map['nextNumber'] : map['nextNumber']?.toInt() ?? 1,
    );
  }
}
