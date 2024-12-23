import 'package:tablets/src/common/values/constants.dart';

const double categoryFormWidth = 500;
const double categoryFormHeight = 350;

const double regionFormWidth = 500;
const double regionFormHeight = 350;

const double productFormWidth = 800;
const double productFormHeight = 900;

const double customerInvoiceFormWidth = 800;
const double customerInvoiceFormHeight = 800;

const double salesmanFormWidth = 500;
const double salesmanFormHeight = 500;

const double customerFormWidth = 800;
const double customerFormHeight = 600;

const double vendorFormWidth = 500;
const double vendorFormHeight = 500;

final Map<String, dynamic> transactionFormDimenssions = {
  TransactionType.customerInvoice.name: {'height': 1000, 'width': 900},
  TransactionType.vendorInvoice.name: {'height': 1000, 'width': 800},
  TransactionType.customerReturn.name: {'height': 750, 'width': 800},
  TransactionType.vendorReturn.name: {'height': 750, 'width': 800},
  TransactionType.damagedItems.name: {'height': 650, 'width': 550},
  TransactionType.gifts.name: {'height': 650, 'width': 550},
  TransactionType.customerReceipt.name: {'height': 400, 'width': 800},
  TransactionType.vendorReceipt.name: {'height': 400, 'width': 800},
  TransactionType.expenditures.name: {'height': 500, 'width': 800},
};
