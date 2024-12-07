// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tablets/src/common/interfaces/base_item.dart';
import 'package:tablets/src/common/values/constants.dart' as constants;

class Customer implements BaseItem {
  @override
  String dbRef;
  @override
  String name;
  @override
  List<String> imageUrls;
  String salesman;
  String salesmanDbRef;
  String region;
  String regionDbRef;
  double? x; // gps longitude
  double? y; // gps latitude
  DateTime initialDate;
  double initialCredit; // initial debt on customer
  String? address;
  String sellingPriceType; // wholesale or retail
  double creditLimit; // maximum allowed credit
  double paymentDurationLimit; // maximum days to close a transaction (pay its amount)
  String? phone;

  Customer({
    required this.dbRef,
    required this.name,
    required this.imageUrls,
    required this.salesman,
    required this.salesmanDbRef,
    required this.region,
    required this.regionDbRef,
    this.x,
    this.y,
    required this.initialDate,
    required this.initialCredit,
    this.address,
    required this.sellingPriceType,
    required this.creditLimit,
    required this.paymentDurationLimit,
    this.phone,
  });

  @override
  String get coverImageUrl =>
      imageUrls.isNotEmpty ? imageUrls[imageUrls.length - 1] : constants.defaultImageUrl;

  @override
  Map<String, dynamic> toMap() {
    return {
      'dbRef': dbRef,
      'name': name,
      'imageUrls': imageUrls,
      'salesman': salesman,
      'salesmanDbRef': salesmanDbRef,
      'region': region,
      'regionDbRef': regionDbRef,
      'x': x,
      'y': y,
      'initialDate': initialDate,
      'initialCredit': initialCredit,
      'address': address,
      'sellingPriceType': sellingPriceType,
      'creditLimit': creditLimit,
      'paymentDurationLimit': paymentDurationLimit,
      'phone': phone,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      dbRef: map['dbRef'] ?? '',
      name: map['name'] ?? '',
      imageUrls: List<String>.from(map['imageUrls']),
      salesman: map['salesman'] ?? '',
      salesmanDbRef: map['salesmanDbRef'] ?? '',
      region: map['region'] ?? '',
      regionDbRef: map['regionDbRef'] ?? '',
      x: map['x']?.toDouble(),
      y: map['y']?.toDouble(),
      initialDate:
          map['initialDate'] is Timestamp ? map['initialDate'].toDate() : map['initialDate'],
      initialCredit: map['initialCredit']?.toDouble() ?? 0.0,
      address: map['address'],
      sellingPriceType: map['sellingPriceType'] ?? '',
      phone: map['phone'] ?? '',
      creditLimit: map['creditLimit']?.toDouble() ?? 0.0,
      paymentDurationLimit: map['paymentDurationLimit']?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'Customer(dbRef: $dbRef, name: $name, phone: $phone)';
  }
}
