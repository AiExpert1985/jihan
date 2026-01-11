// Model for missing transaction data to be displayed in results screen
class MissingTransaction {
  final String customerName;
  final int transactionNumber;
  final String transactionType;
  final String date;
  final double totalAmount;

  MissingTransaction({
    required this.customerName,
    required this.transactionNumber,
    required this.transactionType,
    required this.date,
    required this.totalAmount,
  });
}
