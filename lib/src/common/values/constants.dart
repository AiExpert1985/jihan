const String defaultImageUrl =
    'https://firebasestorage.googleapis.com/v0/b/tablets-519a0.appspot.com/o/default%2Fdefault_image.PNG?alt=media&token=d142f689-e42f-46ca-bb4b-8ea68a714ba4';

enum FieldDataType { num, text, datetime }

enum TransactionType {
  expenditures,
  gifts,
  customerReceipt,
  vendorReceipt,
  vendorReturn,
  customerReturn,
  vendorInvoice,
  customerInvoice,
  damagedItems,
  initialCredit // not a real transaction but is used in some reports related to customer
}

enum SellPriceType {
  retail,
  wholesale,
}

enum InvoiceStatus {
  open,
  closed,
  due,
}
