// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:tablets/src/common/interfaces/base_item.dart';
import 'package:tablets/src/common/values/constants.dart'; // Assuming defaultImageUrl is here

class SalesPoint implements BaseItem {
  String salesmanName;
  String salesmanDbRef;
  String customerName;
  String customerDbRef;
  DateTime date; // TODO change it to taskDate
  bool isVisited;
  bool hasTransaction;
  DateTime? visitDate; // <-- Added Property
  DateTime? transactionDate; // <-- Added Property
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
    // Add new nullable properties at the end of the positional list
    this.visitDate, // <-- Added to Constructor
    this.transactionDate, // <-- Added to Constructor
  );

  @override
  String get coverImageUrl => defaultImageUrl; // Make sure defaultImageUrl is defined

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
    DateTime? visitDate, // <-- Added to copyWith parameters
    DateTime? transactionDate, // <-- Added to copyWith parameters
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
      visitDate ?? this.visitDate, // <-- Added assignment
      transactionDate ?? this.transactionDate, // <-- Added assignment
    );
  }

  @override
  Map<String, dynamic> toMap() {
    // Keep existing pattern of adding DateTime object directly
    return <String, dynamic>{
      'salesmanName': salesmanName,
      'salesmanDbRef': salesmanDbRef,
      'customerName': customerName,
      'customerDbRef': customerDbRef,
      'date': date, // Original DateTime object
      'isVisited': isVisited,
      'hasTransaction': hasTransaction,
      'dbRef': dbRef,
      'imageUrls': imageUrls,
      'name': name,
      'x': x,
      'y': y,
      'visitDate': visitDate, // <-- Added DateTime? object
      'transactionDate': transactionDate, // <-- Added DateTime? object
    };
  }

  factory SalesPoint.fromMap(Map<String, dynamic> map) {
    // Follow existing pattern for date conversion (assuming Firestore Timestamp),
    // but handle null for the new nullable fields.
    return SalesPoint(
      map['salesmanName'] as String,
      map['salesmanDbRef'] as String,
      map['customerName'] as String,
      map['customerDbRef'] as String,
      map['date'].toDate(), // Keep original non-nullable assumption
      map['isVisited'] as bool,
      map['hasTransaction'] as bool,
      map['dbRef'] as String,
      List<String>.from((map['imageUrls'])),
      map['name'] as String,
      map['x'] != null ? map['x'] as double : null,
      map['y'] != null ? map['y'] as double : null,
      // Apply same .toDate() logic, checking for null first
      map['visitDate'] == null ? null : (map['visitDate'] as dynamic).toDate(), // <-- Added parsing
      map['transactionDate'] == null
          ? null
          : (map['transactionDate'] as dynamic).toDate(), // <-- Added parsing
    );
  }

  // toJson and fromJson remain unchanged as they rely on toMap/fromMap
  String toJson() => json.encode(toMap());

  factory SalesPoint.fromJson(String source) =>
      SalesPoint.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    // Added new fields to the string representation
    return 'SalesPoint(salesmanName: $salesmanName, salesmanDbRef: $salesmanDbRef, customerName: $customerName, customerDbRef: $customerDbRef, date: $date, isVisited: $isVisited, hasTransaction: $hasTransaction, dbRef: $dbRef, imageUrls: $imageUrls, name: $name, x: $x, y: $y, visitDate: $visitDate, transactionDate: $transactionDate)'; // <-- Added fields here
  }

  @override
  bool operator ==(covariant SalesPoint other) {
    if (identical(this, other)) return true;

    // Added checks for the new fields
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
        other.y == y &&
        other.visitDate == visitDate && // <-- Added check
        other.transactionDate == transactionDate; // <-- Added check
  }

  @override
  int get hashCode {
    // Added hash codes for the new fields
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
        y.hashCode ^
        visitDate.hashCode ^ // <-- Added hash code
        transactionDate.hashCode; // <-- Added hash code
  }
}
