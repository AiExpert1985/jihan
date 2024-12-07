import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/features/customers/model/customer.dart';
import 'package:tablets/src/features/customers/repository/customer_repository_provider.dart';
import 'package:tablets/src/features/products/model/product.dart';
import 'package:tablets/src/features/products/repository/product_repository_provider.dart';

void importCustomerExcel(WidgetRef ref) async {
  final repository = ref.read(customerRepositoryProvider);

  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result != null) {
      String? filePath = result.files.single.path;
      if (filePath != null) {
        var file = File(filePath);
        var bytes = await file.readAsBytes();
        var excel = Excel.decodeBytes(bytes);
        for (var table in excel.tables.keys) {
          final rows = excel.tables[table]!.rows;
          for (var i = 0; i < rows.length; i++) {
            final row = rows[i];
            if (i == 0) continue;
            final customerData = {
              'name': row[0]!.value.toString(),
              'sellingPriceType': row[1]!.value!.toString(),
              'regionDbRef': 'sgdfgdfg',
              'region': 'غير معرف',
              'salesman': 'غير معرف',
              'salesmanDbRef': 'hjfdracd',
              'paymentDurationLimit': 21,
              'dbRef': generateRandomString(len: 8),
              'initialDate': DateTime.now(),
              'creditLimit': 1000000,
              'imageUrls': [defaultImageUrl],
            };
            final customer = Customer.fromMap(customerData);
            repository.addItem(customer);
          }
        }
        // Process the Excel data
      } else {
        errorPrint('File path is null.');
      }
    }
  } catch (e) {
    errorPrint('Error while importing excel - $e');
  }
}

void importProductExcel(WidgetRef ref) async {
  final repository = ref.read(productRepositoryProvider);
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result != null) {
      String? filePath = result.files.single.path;
      if (filePath != null) {
        var file = File(filePath);
        var bytes = await file.readAsBytes();
        var excel = Excel.decodeBytes(bytes);
        for (var table in excel.tables.keys) {
          final rows = excel.tables[table]!.rows;
          for (var i = 0; i < rows.length; i++) {
            final row = rows[i];
            if (i == 0) continue;
            final productData = {
              'code': (row[0]!.value as IntCellValue).value.toInt(), //TODO
              'name': row[1]!.value.toString(),
              'buyingPrice': (row[2]!.value as IntCellValue).value.toDouble(), //TODO
              'sellRetailPrice': (row[3]!.value as IntCellValue).value.toDouble(), //TODO
              'sellWholePrice': (row[4]!.value as IntCellValue).value.toDouble(), //TODO
              'dbRef': generateRandomString(len: 8),
              'imageUrls': [defaultImageUrl],
              'alertWhenExceeds': 1000,
              'altertWhenLessThan': 10,
              'category': 'غير معرف',
              'categoryDbRef': 'kfdsrsgh',
              'initialQuantity': 0,
              'numItemsInsidePackage': 0,
              'packageType': 'كارتون',
              'packageWeight': 0,
              'salesmanCommission': 70,
              'initialDate': DateTime.now(),
            };
            final product = Product.fromMap(productData);
            repository.addItem(product);
          }
        }
        // Process the Excel data
      } else {
        errorPrint('File path is null.');
      }
    }
  } catch (e) {
    errorPrint('Error while importing excel - $e');
  }
}
