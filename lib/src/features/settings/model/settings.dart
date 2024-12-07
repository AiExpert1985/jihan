import 'package:tablets/src/common/interfaces/base_item.dart';
import 'package:tablets/src/common/values/constants.dart';

enum PaymentType { cash, credit }

enum Currency { dinar, dollar }

class Settings implements BaseItem {
  @override
  String dbRef;
  @override
  String name;

  // uploading
  @override
  List<String> imageUrls;

  // switches
  bool hideTransactionAmountAsText;
  bool hideProductBuyingPrice;
  bool hideMainScreenColumnTotals;
  bool hideCustomerProfit;
  bool hideProductProfit;
  bool hideSalesmanProfit;
  bool hideCompanyUrlBarCode;

  // Sliders
  int printedCustomerInvoices;
  int printedCustomerReceipts;
  int maxDebtDuration;

  // Radio buttons
  String paymentType;
  String currency;

  // text box
  double maxDebtAmount;
  String companyUrl;
  String mainPageGreetingText;

  Settings({
    required this.dbRef,
    required this.name,
    required this.imageUrls,
    required this.hideTransactionAmountAsText,
    required this.hideProductBuyingPrice,
    required this.hideMainScreenColumnTotals,
    required this.hideCustomerProfit,
    required this.hideProductProfit,
    required this.hideSalesmanProfit,
    required this.hideCompanyUrlBarCode,
    required this.maxDebtDuration,
    required this.printedCustomerInvoices,
    required this.printedCustomerReceipts,
    required this.maxDebtAmount,
    required this.companyUrl,
    required this.mainPageGreetingText,
    required this.paymentType,
    required this.currency,
  });

  @override
  String get coverImageUrl =>
      imageUrls.isNotEmpty ? imageUrls[imageUrls.length - 1] : defaultImageUrl;

  @override
  Map<String, dynamic> toMap() {
    return {
      'dbRef': dbRef,
      'name': name,
      'imageUrls': imageUrls,
      'hideTransactionAmountAsText': hideTransactionAmountAsText,
      'hideProductBuyingPrice': hideProductBuyingPrice,
      'hideMainScreenColumnTotals': hideMainScreenColumnTotals,
      'hideCustomerProfit': hideCustomerProfit,
      'hideProductProfit': hideProductProfit,
      'hideSalesmanProfit': hideSalesmanProfit,
      'hideCompanyUrlBarCode': hideCompanyUrlBarCode,
      'maxDebtDuration': maxDebtDuration,
      'printedCustomerInvoices': printedCustomerInvoices,
      'printedCustomerReceipts': printedCustomerReceipts,
      'maxDebtAmount': maxDebtAmount,
      'companyUrl': companyUrl,
      'mainPageGreetingText': mainPageGreetingText,
      'paymentType': paymentType,
      'currency': currency,
    };
  }

  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      dbRef: map['dbRef'] ?? '',
      name: map['name'] ?? '',
      imageUrls: List<String>.from(map['imageUrls']),
      hideTransactionAmountAsText: map['hideTransactionAmountAsText'] ?? false,
      hideProductBuyingPrice: map['hideProductBuyingPrice'] ?? false,
      hideMainScreenColumnTotals: map['hideMainScreenColumnTotals'] ?? false,
      hideCustomerProfit: map['hideCustomerProfit'] ?? false,
      hideProductProfit: map['hideProductProfit'] ?? false,
      hideSalesmanProfit: map['hideSalesmanProfit'] ?? false,
      hideCompanyUrlBarCode: map['hideCompanyUrlBarCode'] ?? false,
      maxDebtDuration: map['maxDebtDuration']?.toInt() ?? 21,
      printedCustomerInvoices: map['printedCustomerInvoices']?.toInt() ?? 1,
      printedCustomerReceipts: map['printedCustomerReceipts']?.toInt() ?? 1,
      maxDebtAmount: map['maxDebtAmount']?.toDouble() ?? 1000000,
      companyUrl: map['companyUrl'] ?? '',
      mainPageGreetingText: map['mainPageGreetingText'] ?? '',
      paymentType: map['paymentType'] ?? PaymentType.credit.name,
      currency: map['currency'] ?? Currency.dinar.name,
    );
  }

  @override
  String toString() {
    return 'Settings for $name';
  }
}
