// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:tablets/src/common/interfaces/base_item.dart';
import 'package:tablets/src/common/values/constants.dart';

class SalesPoint implements BaseItem {
  String salesmanName;
  String salesmanDbRef;
  String customerName;
  String customerDbRef;
  DateTime date;
  bool isVisited;
  bool hasTransaction;
  @override
  String dbRef;
  @override
  List<String> imageUrls;
  @override
  String name;
  double? x;
  double? y;

  SalesPoint(
    this.salesmanName,
    this.salesmanDbRef,
    this.customerName,
    this.customerDbRef,
    this.date,
    this.isVisited,
    this.hasTransaction,
    this.dbRef,
    this.imageUrls,
    this.name,
    this.x,
    this.y,
  );

  @override
  String get coverImageUrl => defaultImageUrl;

  SalesPoint copyWith({
    String? salesmanName,
    String? salesmanDbRef,
    String? customerName,
    String? customerDbRef,
    DateTime? date,
    bool? isVisited,
    bool? hasTransaction,
    String? dbRef,
    List<String>? imageUrls,
    String? name,
    double? x,
    double? y,
  }) {
    return SalesPoint(
      salesmanName ?? this.salesmanName,
      salesmanDbRef ?? this.salesmanDbRef,
      customerName ?? this.customerName,
      customerDbRef ?? this.customerDbRef,
      date ?? this.date,
      isVisited ?? this.isVisited,
      hasTransaction ?? this.hasTransaction,
      dbRef ?? this.dbRef,
      imageUrls ?? this.imageUrls,
      name ?? this.name,
      x ?? this.x,
      y ?? this.y,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'salesmanName': salesmanName,
      'salesmanDbRef': salesmanDbRef,
      'customerName': customerName,
      'customerDbRef': customerDbRef,
      'date': date,
      'isVisited': isVisited,
      'hasTransaction': hasTransaction,
      'dbRef': dbRef,
      'imageUrls': imageUrls,
      'name': name,
      'x': x,
      'y': y,
    };
  }

  factory SalesPoint.fromMap(Map<String, dynamic> map) {
    return SalesPoint(
      map['salesmanName'] as String,
      map['salesmanDbRef'] as String,
      map['customerName'] as String,
      map['customerDbRef'] as String,
      map['date'].toDate(),
      map['isVisited'] as bool,
      map['hasTransaction'] as bool,
      map['dbRef'] as String,
      List<String>.from((map['imageUrls'])),
      map['name'] as String,
      map['x'] != null ? map['x'] as double : null,
      map['y'] != null ? map['y'] as double : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory SalesPoint.fromJson(String source) =>
      SalesPoint.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'SalesPoint(salesmanName: $salesmanName, salesmanDbRef: $salesmanDbRef, customerName: $customerName, customerDbRef: $customerDbRef, date: $date, isVisited: $isVisited, hasTransaction: $hasTransaction, dbRef: $dbRef, imageUrls: $imageUrls, name: $name, x: $x, y: $y)';
  }

  @override
  bool operator ==(covariant SalesPoint other) {
    if (identical(this, other)) return true;

    return other.salesmanName == salesmanName &&
        other.salesmanDbRef == salesmanDbRef &&
        other.customerName == customerName &&
        other.customerDbRef == customerDbRef &&
        other.date == date &&
        other.isVisited == isVisited &&
        other.hasTransaction == hasTransaction &&
        other.dbRef == dbRef &&
        listEquals(other.imageUrls, imageUrls) &&
        other.name == name &&
        other.x == x &&
        other.y == y;
  }

  @override
  int get hashCode {
    return salesmanName.hashCode ^
        salesmanDbRef.hashCode ^
        customerName.hashCode ^
        customerDbRef.hashCode ^
        date.hashCode ^
        isVisited.hashCode ^
        hasTransaction.hashCode ^
        dbRef.hashCode ^
        imageUrls.hashCode ^
        name.hashCode ^
        x.hashCode ^
        y.hashCode;
  }
}
