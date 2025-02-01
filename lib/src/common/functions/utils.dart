import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tablets/src/common/functions/debug_print.dart' as debug;
import 'package:image/image.dart' as img;
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/features/settings/model/settings.dart';
import 'package:tablets/src/common/values/constants.dart';

String translateDbTextToScreenText(BuildContext context, String dbText) {
  final Map<String, String> lookup = {
    TransactionType.expenditures.name: S.of(context).transaction_type_expenditures,
    TransactionType.gifts.name: S.of(context).transaction_type_gifts,
    TransactionType.vendorReceipt.name: S.of(context).transaction_type_vendor_receipt,
    TransactionType.vendorReturn.name: S.of(context).transaction_type_vender_return,
    TransactionType.vendorInvoice.name: S.of(context).transaction_type_vender_invoice,
    TransactionType.customerReceipt.name: S.of(context).transaction_type_customer_receipt,
    TransactionType.customerReturn.name: S.of(context).transaction_type_customer_return,
    TransactionType.customerInvoice.name: S.of(context).transaction_type_customer_invoice,
    TransactionType.damagedItems.name: S.of(context).transaction_type_damaged_items,
    TransactionType.initialCredit.name: S.of(context).transaction_type_initial_credit,
    Currency.dinar.name: S.of(context).transaction_payment_Dinar,
    Currency.dollar.name: S.of(context).transaction_payment_Dollar,
    PaymentType.credit.name: S.of(context).transaction_payment_credit,
    PaymentType.cash.name: S.of(context).transaction_payment_cash,
    SellPriceType.retail.name: S.of(context).selling_price_type_retail,
    SellPriceType.wholesale.name: S.of(context).selling_price_type_whole,
    InvoiceStatus.closed.name: S.of(context).invoice_status_closed,
    InvoiceStatus.open.name: S.of(context).invoice_status_open,
    InvoiceStatus.due.name: S.of(context).invoice_status_due,
    'true': S.of(context).yes,
    'false': S.of(context).no,
  };
  return lookup[dbText] ?? dbText;
}

String translateScreenTextToDbText(BuildContext context, String screenText) {
  final Map<String, String> lookup = {
    S.of(context).transaction_type_expenditures: TransactionType.expenditures.name,
    S.of(context).transaction_type_gifts: TransactionType.gifts.name,
    S.of(context).transaction_type_customer_receipt: TransactionType.customerReceipt.name,
    S.of(context).transaction_type_vendor_receipt: TransactionType.vendorReceipt.name,
    S.of(context).transaction_type_vender_return: TransactionType.vendorReturn.name,
    S.of(context).transaction_type_customer_return: TransactionType.customerReturn.name,
    S.of(context).transaction_type_vender_invoice: TransactionType.vendorInvoice.name,
    S.of(context).transaction_type_customer_invoice: TransactionType.customerInvoice.name,
    S.of(context).transaction_type_damaged_items: TransactionType.damagedItems.name,
    S.of(context).transaction_type_initial_credit: TransactionType.initialCredit.name,
    S.of(context).transaction_payment_Dinar: Currency.dinar.name,
    S.of(context).transaction_payment_Dollar: Currency.dollar.name,
    S.of(context).transaction_payment_credit: PaymentType.credit.name,
    S.of(context).transaction_payment_cash: PaymentType.cash.name,
    S.of(context).selling_price_type_retail: SellPriceType.retail.name,
    S.of(context).selling_price_type_whole: SellPriceType.wholesale.name,
    S.of(context).invoice_status_closed: InvoiceStatus.closed.name,
    S.of(context).invoice_status_open: InvoiceStatus.open.name,
    S.of(context).invoice_status_due: InvoiceStatus.due.name,
    S.of(context).yes: 'true',
    S.of(context).no: 'false',
  };

  return lookup[screenText] ?? screenText;
}

String generateRandomString({int len = 5}) {
  var r = Random();
  return String.fromCharCodes(List.generate(len, (index) => r.nextInt(33) + 89)).toString();
}

/// compare two Lists of string
/// find items in the first list that don't exists in second list
List<String> twoListsDifferences(List<String> list1, List<String> list2) =>
    list1.where((item) => !list2.toSet().contains(item)).toList();

// Default result image size is 50 k byte (reduce speed and the cost of firebase)
// compression depends on image size, the larget image the more compression
// if image size is small, it will not be compressed
Uint8List? compressImage(Uint8List? image, {int targetImageSizeInBytes = 5120}) {
  final quality = (image!.length / targetImageSizeInBytes).round();
  if (quality > 0) {
    image = img.encodeJpg(img.decodeImage(image)!, quality: quality);
  }
  return image;
}

InputDecoration formFieldDecoration({String? label, bool hideBorders = false}) {
  return InputDecoration(
    // floatingLabelAlignment: FloatingLabelAlignment.center,
    label: label == null
        ? null
        : Text(
            label,
            // textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
    alignLabelWithHint: true,
    contentPadding: const EdgeInsets.all(12),
    isDense: true, // Add this line to remove the default padding
    border: hideBorders
        ? InputBorder.none
        : const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
  );
}

List<Map<String, dynamic>> convertAsyncValueListToList(
    AsyncValue<List<Map<String, dynamic>>> asyncProductList) {
  return asyncProductList.when(
      data: (products) => products,
      error: (e, st) {
        debug.errorPrint(e, stackTrace: st);
        return [];
      },
      loading: () {
        debug.errorPrint('product list is loading');
        return [];
      });
}

/// if the number ends with .0 (example 55.0), it will remove .0 and convert to String
String numberToText(dynamic value) {
  // Check if the value is an integer
  if (value == value.toInt()) {
    return value.toInt().toString(); // Convert to int and return as string
  }
  return value.toString(); // Return as string if not an integer
}

String formatDate(DateTime date) => DateFormat('dd-MM-yyyy', 'en_US').format(date);
String formatDateTime(DateTime date) => DateFormat('yyyy/MM/dd hh:mm a').format(date);

// used to create thousand comma separators for numbers displayed in the UI
// it can be used with or without decimal places using numDecimalPlaces optional parameter
String doubleToStringWithComma(dynamic value,
    {int? numDecimalPlaces, bool isAbsoluteValue = false}) {
  if (value == null) {
    return '';
  }
  String valueString;
  if (value is double || value is num) {
    value = value.round();
  }
  if (isAbsoluteValue && (value is double || value is num || value is int)) {
    value = value.abs();
  }
  if (numDecimalPlaces != null) {
    valueString = value.toStringAsFixed(numDecimalPlaces); // Keeping 2 decimal places
  } else {
    valueString = value.toString();
  }
  // Split the string into whole and decimal parts
  List<String> parts = valueString.split('.');
  String wholePart = parts[0];
  String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';
  // Add commas to the whole part
  String formattedWholePart = wholePart.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match match) => '${match[1]},');
  // Combine the whole part and the decimal part
  return formattedWholePart + decimalPart;
}

String doubleToIntString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is double) return value.toInt().toString();
  return value.toString();
}

// order a list of lists based on date, from latest to oldest
List<List<dynamic>> sortListOfListsByDate(List<List<dynamic>> list, int dateIndex,
    {bool isAscending = false}) {
  list.sort((a, b) {
    final dateA = a[dateIndex] is Timestamp
        ? a[dateIndex].toDate()
        : a[dateIndex]; // Assuming dateKey is the key for the date
    final dateB = b[dateIndex] is Timestamp ? b[dateIndex].toDate() : b[dateIndex];
    if (isAscending) {
      return dateA.compareTo(dateB);
    }
    return dateB.compareTo(dateA); // Descending order
  });
  return list;
}

// order a list of lists based on a number, from biggest to smallest
List<List<dynamic>> sortListOfListsByNumber(List<List<dynamic>> list, int numberIndex) {
  list.sort((a, b) {
    final itemA = a[numberIndex];
    final itemB = b[numberIndex];
    return itemB.compareTo(itemA); // Descending order
  });
  return list;
}

void sortMapsByProperty(List<Map<String, dynamic>> list, String propertyName,
    {isAscending = false}) {
  if (list.isEmpty || !list[0].containsKey(propertyName)) return;
  list.sort((a, b) {
    dynamic itemA = a[propertyName] ?? '';
    dynamic itemB = b[propertyName] ?? '';
    if (a[propertyName] is DateTime ||
        a[propertyName] is Timestamp ||
        b[propertyName] is DateTime ||
        b[propertyName] is Timestamp) {
      itemA = a[propertyName] is! DateTime ? a[propertyName].toDate() : a[propertyName];
      itemB = b[propertyName] is! DateTime ? b[propertyName].toDate() : b[propertyName];
    }
    if (isAscending) {
      return itemA.compareTo(itemB);
    }
    return itemB.compareTo(itemA);
  });
}

// return a copy of the original list after removing one or more specific indices from the list
List<List<dynamic>> removeIndicesFromInnerLists(
    List<List<dynamic>> data, List<int> indicesToRemove) {
  List<List<dynamic>> result = [];
  indicesToRemove.sort((a, b) => b.compareTo(a));
  for (var innerList in data) {
    List<dynamic> newInnerList = List.from(innerList);
    for (int index in indicesToRemove) {
      if (index >= 0 && index < newInnerList.length) {
        newInnerList.removeAt(index);
      }
    }
    result.add(newInnerList);
  }
  return result;
}

// return a copy of the original list after removing last x number of indices from the list
List<List<dynamic>> trimLastXIndicesFromInnerLists(List<List<dynamic>> data, int x) {
  List<List<dynamic>> result = [];
  for (var innerList in data) {
    List<dynamic> newInnerList = List.from(innerList);
    if (x > 0) {
      if (x < newInnerList.length) {
        newInnerList = newInnerList.sublist(0, newInnerList.length - x);
      }
    }
    result.add(newInnerList);
  }
  return result;
}

///returns the sum of a list of lists for a specific index
double sumAtIndex(List<List<dynamic>> listOfLists, int index) {
  double sum = 0;
  for (var sublist in listOfLists) {
    if (index < sublist.length) {
      if (sublist[index] != null) {
        sum += sublist[index];
      }
    }
  }
  return sum;
}

/// returns a new copy of the list, where Maps are duplicated x number of times
/// I used it to create huge size copies of lists for performace testing purpose
List<Map<String, dynamic>> duplicateDbCache(List<Map<String, dynamic>> data, int times) {
  List<Map<String, dynamic>> duplicatedList = [];
  for (var map in data) {
    for (int i = 0; i < times; i++) {
      // change dbRef to make every item unique
      final newDbRef = generateRandomString(len: 8);
      duplicatedList.add(Map<String, dynamic>.from({...map, 'dbRef': newDbRef}));
    }
  }
  return duplicatedList;
}

/// convert the date type of a date key in a  whole List<Map<String, dynamic>>
/// from type Timestamp to DateTime
List<Map<String, dynamic>> formatDateForJson(List<Map<String, dynamic>> data, String keyName) {
  List<Map<String, dynamic>> modifiedList = deepCopyDbCache(data);
  for (var i = 0; i < data.length; i++) {
    if (data[i].containsKey(keyName) && data[i][keyName] is Timestamp) {
      modifiedList[i][keyName] = formatDate(data[i][keyName].toDate());
    }
  }
  return modifiedList;
}

/// create completely new copy of dbCache or any List<Map<String, dynamic>>
List<Map<String, dynamic>> deepCopyDbCache(List<Map<String, dynamic>> original) {
  return original.map((map) => Map<String, dynamic>.from(map)).toList();
}

// I did below map creation to solve issue I faced with List<dynamic> is not accepted as List<Map<String, dynamic>>
List<Map<String, dynamic>> convertListofDyanmicToListofMaps(List<dynamic> list) {
  List<Map<String, dynamic>> newList = [];
  for (var item in list) {
    Map<String, dynamic> typeAdjustedItem = {};
    item.forEach((key, value) {
      typeAdjustedItem[key] = value;
    });
    newList.add(typeAdjustedItem);
  }

  return newList;
}
