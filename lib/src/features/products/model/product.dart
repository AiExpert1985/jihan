import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tablets/src/common/interfaces/base_item.dart';

class Product implements BaseItem {
  @override
  String dbRef;
  @override
  String name;
  @override
  List<String> imageUrls;
  int code;
  double buyingPrice;
  double sellRetailPrice;
  double sellWholePrice;
  String packageType;
  double packageWeight;
  int numItemsInsidePackage;
  int alertWhenExceeds;
  int altertWhenLessThan;
  double salesmanCommission;
  String category;
  String categoryDbRef;
  int initialQuantity;
  DateTime initialDate;
  String? notes;
  bool? isHiddenInSpecialReports;

  Product({
    required this.dbRef,
    required this.code,
    required this.name,
    required this.buyingPrice,
    required this.sellRetailPrice,
    required this.sellWholePrice,
    required this.packageType,
    required this.packageWeight,
    required this.numItemsInsidePackage,
    required this.alertWhenExceeds,
    required this.altertWhenLessThan,
    required this.salesmanCommission,
    required this.imageUrls,
    required this.category,
    required this.categoryDbRef,
    required this.initialQuantity,
    required this.initialDate,
    this.isHiddenInSpecialReports, //TODO make it required later
    this.notes,
  });

  @override
  String get coverImageUrl => imageUrls[imageUrls.length - 1];

  @override
  Map<String, dynamic> toMap() {
    return {
      'dbRef': dbRef,
      'code': code,
      'name': name,
      'buyingPrice': buyingPrice,
      'sellRetailPrice': sellRetailPrice,
      'sellWholePrice': sellWholePrice,
      'packageType': packageType,
      'packageWeight': packageWeight,
      'numItemsInsidePackage': numItemsInsidePackage,
      'alertWhenExceeds': alertWhenExceeds,
      'altertWhenLessThan': altertWhenLessThan,
      'salesmanCommission': salesmanCommission,
      'imageUrls': imageUrls,
      'category': category,
      'categoryDbRef': categoryDbRef,
      'initialQuantity': initialQuantity,
      'initialDate': initialDate,
      'notes': notes,
      'isHiddenInSpecialReports': isHiddenInSpecialReports,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      dbRef: map['dbRef'] ?? '',
      code: map['code']?.toInt() ?? 0,
      name: map['name'] ?? '',
      buyingPrice: map['buyingPrice']?.toDouble() ?? 0.0,
      sellRetailPrice: map['sellRetailPrice']?.toDouble() ?? 0.0,
      sellWholePrice: map['sellWholePrice']?.toDouble() ?? 0.0,
      packageType: map['packageType'] ?? '',
      packageWeight: map['packageWeight']?.toDouble() ?? 0.0,
      numItemsInsidePackage: map['numItemsInsidePackage']?.toInt() ?? 0,
      alertWhenExceeds: map['alertWhenExceeds']?.toInt() ?? 0,
      altertWhenLessThan: map['altertWhenLessThan']?.toInt() ?? 0,
      salesmanCommission: map['salesmanCommission']?.toDouble() ?? 0.0,
      imageUrls: List<String>.from(map['imageUrls']),
      category: map['category'] ?? '',
      categoryDbRef: map['categoryDbRef'] ?? '',
      initialQuantity: map['initialQuantity']?.toInt() ?? 0,
      initialDate:
          map['initialDate'] is Timestamp ? map['initialDate'].toDate() : map['initialDate'],
      notes: map['notes'] ?? '',
      isHiddenInSpecialReports: map['isHiddenInSpecialReports'] ?? false,
    );
  }

  @override
  String toString() {
    return 'Product(dbRef: $dbRef, code: $code, name: $name, sellRetailPrice: $sellRetailPrice, sellWholePrice: $sellWholePrice, packageType: $packageType, packageWeight: $packageWeight, numItemsInsidePackage: $numItemsInsidePackage, alertWhenExceeds: $alertWhenExceeds, altertWhenLessThan: $altertWhenLessThan, salesmanCommission: $salesmanCommission, imageUrls: $imageUrls, category: $category, initialQuantity: $initialQuantity)';
  }
}
