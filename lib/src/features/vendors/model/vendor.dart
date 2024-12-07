import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tablets/src/common/interfaces/base_item.dart';
import 'package:tablets/src/common/values/constants.dart' as constants;

class Vendor implements BaseItem {
  @override
  String dbRef;
  @override
  String name;
  @override
  List<String> imageUrls;
  String? phone;
  DateTime initialDate;
  double initialAmount;

  Vendor({
    required this.dbRef,
    required this.name,
    required this.imageUrls,
    this.phone,
    required this.initialAmount,
    required this.initialDate,
  });

  @override
  String get coverImageUrl => imageUrls.isNotEmpty ? imageUrls[imageUrls.length - 1] : constants.defaultImageUrl;

  @override
  Map<String, dynamic> toMap() {
    return {
      'dbRef': dbRef,
      'name': name,
      'imageUrls': imageUrls,
      'phone': phone,
      'initialAmount': initialAmount,
      'initialDate': initialDate
    };
  }

  factory Vendor.fromMap(Map<String, dynamic> map) {
    return Vendor(
      dbRef: map['dbRef'] ?? '',
      name: map['name'] ?? '',
      imageUrls: List<String>.from(map['imageUrls']),
      phone: map['phone'] ?? '',
      initialDate: map['initialDate'] is Timestamp ? map['initialDate'].toDate() : map['initialDate'],
      initialAmount: map['initialAmount'],
    );
  }

  @override
  String toString() => 'ProductCategory(dbRef: $dbRef, name: $name, imageUrls: $imageUrls)';
}
