// Model for missing transaction data to be displayed in results screen
class MissingTransaction {
  final String customerName;
  final int transactionNumber;
  final String transactionType;
  final String date;
  final double totalAmount;
  final String backupDate; // Formatted date from backup filename (DD/MM/YYYY)
  final Map<String, dynamic> fullTransactionData; // Complete transaction data from backup

  MissingTransaction({
    required this.customerName,
    required this.transactionNumber,
    required this.transactionType,
    required this.date,
    required this.totalAmount,
    required this.backupDate,
    required this.fullTransactionData,
  });
}

// Model for file processing result
class FileProcessingResult {
  final String filename; // Full filename: "tablets_backup_20260110.zip"
  final int missingCount; // Number of missing transactions found, or 0 if corrupted
  final bool isCorrupted;

  FileProcessingResult({
    required this.filename,
    required this.missingCount,
    required this.isCorrupted,
  });
}
