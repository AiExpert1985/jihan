import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/file_system_path.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/features/customers/controllers/customer_screen_controller.dart';
import 'package:tablets/src/features/customers/repository/customer_db_cache_provider.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_db_cache_provider.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

const darkBgColor = PdfColor(0.2, 0.2, 0.5);
const lightBgColor = PdfColor(0.85, 0.85, 0.99);
const bordersColor = PdfColors.grey;
const labelsColor = PdfColors.red;

Future<void> _printPDf(Document pdf) async {
  try {
    for (int i = 0; i < 2; i++) {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => await pdf.save(),
      );
    }
  } catch (e) {
    debugLog('Printing failed - ($e)');
  }
}

Future<void> printDocument(
    BuildContext context, WidgetRef ref, Map<String, dynamic> transactionData) async {
  try {
    // now we only print customer invoices
    if (transactionData['transactionType'] != TransactionType.customerInvoice.name) {
      errorPrint('not customer invoice, because currently we only print customer invoices');
      return;
    }
    final filePath = gePdfpath('test_file');
    if (context.mounted) {
      final pdf = await getCustomerInvoicePdf(context, ref, transactionData);
      _printPDf(pdf);
      if (filePath == null) return;

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
    }
  } catch (e) {
    debugLog('Pdf creation failed - ($e)');
  }
}

Future<pw.ImageProvider> loadImage(String path) async {
  final ByteData bytes = await rootBundle.load(path);
  final Uint8List list = bytes.buffer.asUint8List();
  return pw.MemoryImage(list);
}

Future<Document> getCustomerInvoicePdf(
    BuildContext context, WidgetRef ref, Map<String, dynamic> transactionData) async {
  final pdf = pw.Document();
  final customerDbCache = ref.read(customerDbCacheProvider.notifier);
  final customerData = customerDbCache.getItemByDbRef(transactionData['nameDbRef']);
  final salesmanDbCache = ref.read(salesmanDbCacheProvider.notifier);
  final salesmanData = salesmanDbCache.getItemByDbRef(transactionData['salesmanDbRef']);
  final type = translateDbTextToScreenText(context, transactionData['transactionType']);
  final number = transactionData['number'].toString();
  final customerName = transactionData['name'];
  final customerPhone = customerData['phone'] ?? '';
  final customerRegion = customerData['region'] ?? '';
  final salesmanName = salesmanData['name'] ?? '';
  final salesmanPhone = salesmanData['phone'] ?? '';
  final items = transactionData['items'] as List;
  final paymentType = translateDbTextToScreenText(context, transactionData['paymentType']);
  final date = formatDate(transactionData['date']);
  final subtotalAmount = doubleToStringWithComma(transactionData['subTotalAmount']);
  final discount = doubleToStringWithComma(transactionData['discount']);
  final currency = translateDbTextToScreenText(context, transactionData['currency']);
  final now = DateTime.now();
  final printingDate = DateFormat.yMd('ar').format(now);
  final printingTime = DateFormat.jm('ar').format(now);
  final notes = transactionData['notes'];
  final totalNumOfItems = doubleToStringWithComma(calculateTotalNumOfItems(items));
  final itemsWeigt = doubleToStringWithComma(transactionData['totalWeight']);
  final customerScreenController = ref.read(customerScreenControllerProvider);
  final customerScreenData = customerScreenController.getItemScreenData(context, customerData);
  final debtAfter = doubleToStringWithComma(customerScreenData['totalDebt']);
  final debtBefore =
      doubleToStringWithComma(customerScreenData['totalDebt'] - transactionData['totalAmount']);
  final arabicFont =
      pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf"));
  final image = await loadImage('assets/images/invoice_logo.PNG');
  if (items.length <= 20) {
    pdf.addPage(pw.Page(
      margin: pw.EdgeInsets.zero,
      build: (pw.Context ctx) {
        return invoicePage(
          context,
          arabicFont,
          image,
          customerName,
          customerPhone,
          customerRegion,
          paymentType,
          salesmanName,
          salesmanPhone,
          type,
          number,
          date,
          items,
          subtotalAmount,
          discount,
          debtBefore,
          debtAfter,
          currency,
          notes,
          totalNumOfItems,
          itemsWeigt,
          printingDate,
          printingTime,
          0,
          items.length,
          includeImage: true,
        );
      },
    ));
  } else if (items.length <= 50) {
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) {
          return invoicePage(
            context,
            arabicFont,
            image,
            customerName,
            customerPhone,
            customerRegion,
            paymentType,
            salesmanName,
            salesmanPhone,
            type,
            number,
            date,
            items,
            subtotalAmount,
            discount,
            debtBefore,
            debtAfter,
            currency,
            notes,
            totalNumOfItems,
            itemsWeigt,
            printingDate,
            printingTime,
            0,
            25,
            addTotals: false,
            includeImage: true,
          );
        },
      ),
    );
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) {
          return invoicePage(
            context,
            arabicFont,
            image,
            customerName,
            customerPhone,
            customerRegion,
            paymentType,
            salesmanName,
            salesmanPhone,
            type,
            number,
            date,
            items,
            subtotalAmount,
            discount,
            debtBefore,
            debtAfter,
            currency,
            notes,
            totalNumOfItems,
            itemsWeigt,
            printingDate,
            printingTime,
            25,
            items.length,
            startSequence: 26,
          );
        },
      ),
    );
  } else if (items.length <= 75) {
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) {
          return invoicePage(
            context,
            arabicFont,
            image,
            customerName,
            customerPhone,
            customerRegion,
            paymentType,
            salesmanName,
            salesmanPhone,
            type,
            number,
            date,
            items,
            subtotalAmount,
            discount,
            debtBefore,
            debtAfter,
            currency,
            notes,
            totalNumOfItems,
            itemsWeigt,
            printingDate,
            printingTime,
            0,
            25,
            addTotals: false,
            includeImage: true,
          );
        },
      ),
    );
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) {
          return invoicePage(
            context,
            arabicFont,
            image,
            customerName,
            customerPhone,
            customerRegion,
            paymentType,
            salesmanName,
            salesmanPhone,
            type,
            number,
            date,
            items,
            subtotalAmount,
            discount,
            debtBefore,
            debtAfter,
            currency,
            notes,
            totalNumOfItems,
            itemsWeigt,
            printingDate,
            printingTime,
            25,
            50,
            addTotals: false,
            startSequence: 26,
          );
        },
      ),
    );
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) {
          return invoicePage(
            context,
            arabicFont,
            image,
            customerName,
            customerPhone,
            customerRegion,
            paymentType,
            salesmanName,
            salesmanPhone,
            type,
            number,
            date,
            items,
            subtotalAmount,
            discount,
            debtBefore,
            debtAfter,
            currency,
            notes,
            totalNumOfItems,
            itemsWeigt,
            printingDate,
            printingTime,
            50,
            items.length,
            startSequence: 51,
          );
        },
      ),
    );
  } else {
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) {
          return invoicePage(
            context,
            arabicFont,
            image,
            customerName,
            customerPhone,
            customerRegion,
            paymentType,
            salesmanName,
            salesmanPhone,
            type,
            number,
            date,
            items,
            subtotalAmount,
            discount,
            debtBefore,
            debtAfter,
            currency,
            notes,
            totalNumOfItems,
            itemsWeigt,
            printingDate,
            printingTime,
            0,
            25,
            addTotals: false,
            includeImage: true,
          );
        },
      ),
    );
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) {
          return invoicePage(
            context,
            arabicFont,
            image,
            customerName,
            customerPhone,
            customerRegion,
            paymentType,
            salesmanName,
            salesmanPhone,
            type,
            number,
            date,
            items,
            subtotalAmount,
            discount,
            debtBefore,
            debtAfter,
            currency,
            notes,
            totalNumOfItems,
            itemsWeigt,
            printingDate,
            printingTime,
            25,
            50,
            addTotals: false,
            startSequence: 26,
          );
        },
      ),
    );
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) {
          return invoicePage(
            context,
            arabicFont,
            image,
            customerName,
            customerPhone,
            customerRegion,
            paymentType,
            salesmanName,
            salesmanPhone,
            type,
            number,
            date,
            items,
            subtotalAmount,
            discount,
            debtBefore,
            debtAfter,
            currency,
            notes,
            totalNumOfItems,
            itemsWeigt,
            printingDate,
            printingTime,
            50,
            75,
            startSequence: 51,
          );
        },
      ),
    );
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) {
          return invoicePage(
            context,
            arabicFont,
            image,
            customerName,
            customerPhone,
            customerRegion,
            paymentType,
            salesmanName,
            salesmanPhone,
            type,
            number,
            date,
            items,
            subtotalAmount,
            discount,
            debtBefore,
            debtAfter,
            currency,
            notes,
            totalNumOfItems,
            itemsWeigt,
            printingDate,
            printingTime,
            75,
            items.length,
            addTotals: true,
            startSequence: 76,
          );
        },
      ),
    );
  }
  return pdf;
}

pw.Widget invoicePage(
    BuildContext context,
    Font arabicFont,
    dynamic image,
    String customerName,
    String customerPhone,
    String customerRegion,
    String paymentType,
    String salesmanName,
    String salesmanPhone,
    String type,
    String number,
    String date,
    List<dynamic> items,
    String subtotalAmount,
    String discount,
    String debtBefore,
    String debtAfter,
    String currency,
    String notes,
    String totalNumOfItems,
    String itemsWeigt,
    String printingDate,
    String printingTime,
    int startItem,
    int endItem,
    {bool addTotals = true,
    bool includeImage = false,
    int startSequence = 1}) {
  return pw.Column(
    mainAxisAlignment: pw.MainAxisAlignment.start,
    children: [
      if (includeImage) pw.Image(image),
      _buildFirstRow(context, arabicFont, customerName, customerPhone, customerRegion, paymentType),
      pw.SizedBox(height: 8),
      _buildSecondRow(context, arabicFont, salesmanName, salesmanPhone, type, number, date),
      pw.SizedBox(height: 10),
      _itemTitles(arabicFont),
      pw.SizedBox(height: 2),
      _buildItems(
          arabicFont, items.sublist(startItem, items.length < endItem ? items.length : endItem),
          startingSequence: startSequence),
      pw.SizedBox(height: 8),
      if (addTotals)
        _totals(arabicFont, subtotalAmount, discount, debtBefore, debtAfter, currency, notes,
            totalNumOfItems, itemsWeigt),
      pw.Spacer(),
      _signituresRow(arabicFont),
      pw.SizedBox(height: 5),
      footerBar(arabicFont, 'الشركة غير مسؤولة عن انتهاء الصلاحية بعد استلام البضاعة',
          'وقت الطباعة     $printingDate   $printingTime '),
      pw.SizedBox(height: 10),
    ],
  ); // Center
}

num calculateTotalNumOfItems(List<dynamic> items) {
  num numItems = 0;
  for (int i = 0; i < items.length; i++) {
    numItems += items[i]['soldQuantity'].toInt() + items[i]['giftQuantity'].toInt();
  }
  return numItems;
}

pw.Widget _buildFirstRow(BuildContext context, Font arabicFont, String customerName,
    String customerPhone, String customerRegion, String paymentType) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
    children: [
      pw.SizedBox(width: 5), // margin
      _labedContainer(paymentType, 'الدفع', arabicFont, width: 80),
      _labedContainer(customerRegion, 'العنوان', arabicFont, width: 158),
      _labedContainer(customerPhone, 'رقم الزبون', arabicFont, width: 90),
      _labedContainer(customerName, 'اسم الزبون', arabicFont),
      pw.SizedBox(width: 5), // margin
    ],
  );
}

pw.Widget _buildSecondRow(BuildContext context, Font arabicFont, String salesmanName,
    String salesmanPhone, String type, String number, String date) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
    children: [
      pw.SizedBox(width: 5), // margin
      _labedContainer(date, 'تاريخ القائمة', arabicFont, width: 80),
      _labedContainer(number, 'رقم القائمة', arabicFont, width: 60),
      _labedContainer(type, 'نوع القائمة', arabicFont, width: 80),
      _labedContainer(salesmanPhone, 'رقم المندوب', arabicFont, width: 90),
      _labedContainer(salesmanName, 'المندوب', arabicFont),
      pw.SizedBox(width: 5), // margin
    ],
  );
}

pw.Widget _itemTitles(Font arabicFont) {
  final childWidget = pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
    children: [
      _arabicText(arabicFont, 'المجموع', width: 70, isTitle: true, textColor: PdfColors.white),
      _arabicText(arabicFont, 'السعر', width: 70, isTitle: true, textColor: PdfColors.white),
      _arabicText(arabicFont, 'الهدية', width: 70, isTitle: true, textColor: PdfColors.red),
      _arabicText(arabicFont, 'العدد', width: 70, isTitle: true, textColor: PdfColors.white),
      _arabicText(arabicFont, 'اسم المادة', width: 200, isTitle: true, textColor: PdfColors.white),
      _arabicText(arabicFont, 'ت', width: 40, isTitle: true, textColor: PdfColors.white),
    ],
  );
  // return pw.Stack(children: [
  return _coloredContainer(childWidget, bgColor: darkBgColor, 554, height: 20);
}

pw.Widget _buildItems(Font arabicFont, List<dynamic> items, {int startingSequence = 1}) {
  List<pw.Widget> itemWidgets = [];
  for (int i = 0; i < items.length; i++) {
    final item = items[i];
    // don't add empty rows
    if (item['name'] == '') continue;
    itemWidgets.add(_itemsRow(
      arabicFont,
      (startingSequence + i).toString(),
      item['name'],
      doubleToStringWithComma(item['soldQuantity']),
      doubleToStringWithComma(item['giftQuantity']),
      doubleToStringWithComma(item['sellingPrice']),
      doubleToStringWithComma(item['itemTotalAmount']),
    ));
  }
  return pw.Column(children: itemWidgets);
}

pw.Widget _itemsRow(Font arabicFont, String sequence, String name, String quantity, String gift,
    String price, String total) {
  return pw.Container(
    height: 20,
    width: 554,
    padding: const pw.EdgeInsets.all(1),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _arabicText(arabicFont, total, width: 70, isBordered: true, fontSize: 9),
        _arabicText(arabicFont, price, width: 70, isBordered: true, fontSize: 9),
        _arabicText(arabicFont, gift,
            width: 70, isBordered: true, textColor: PdfColors.red, fontSize: 9),
        _arabicText(arabicFont, quantity, width: 70, isBordered: true, fontSize: 9),
        _arabicText(arabicFont, name, width: 200, isBordered: true, fontSize: 9),
        _arabicText(arabicFont, sequence, width: 40, isBordered: true, fontSize: 9),
      ],
    ),
  );
}

// pw.Widget _itemsRow2(Font arabicFont) {
//   return pw.Container(
//     width: 554,
//     padding: const pw.EdgeInsets.all(2),
//     child: pw.Row(
//       mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
//       children: [
//         _arabicText(arabicFont, '25,000', width: 70, isBordered: true),
//         _arabicText(arabicFont, '5,000', width: 70, isBordered: true),
//         _arabicText(arabicFont, '1',
//             width: 70, isBordered: true, borderColor: PdfColors.red, textColor: PdfColors.red),
//         _arabicText(arabicFont, '5', width: 70, isBordered: true),
//         _arabicText(arabicFont, 'رز جيهان', width: 200, isBordered: true),
//         _arabicText(arabicFont, '2', width: 40, isBordered: true),
//       ],
//     ),
//   );
// }

// pw.Widget _itemsRow3(Font arabicFont) {
//   return pw.Container(
//     width: 554,
//     padding: const pw.EdgeInsets.all(2),
//     child: pw.Row(
//       mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
//       children: [
//         _arabicText(arabicFont, '12,000', width: 70, isBordered: true),
//         _arabicText(arabicFont, '4,000', width: 70, isBordered: true),
//         _arabicText(arabicFont, '1',
//             width: 70, isBordered: true, borderColor: PdfColors.red, textColor: PdfColors.red),
//         _arabicText(arabicFont, '3', width: 70, isBordered: true),
//         _arabicText(arabicFont, 'حليب الطازج', width: 200, isBordered: true),
//         _arabicText(arabicFont, '3', width: 40, isBordered: true),
//       ],
//     ),
//   );
// }

pw.Widget _totals(Font arabicFont, String totalAmount, String discount, String debtBefore,
    String debtAfter, String currency, String notes, String itemsNumber, String itemsWeigt) {
  return pw.Container(
    width: 558, // Set a fixed width for the container
    height: 120,
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      invoiceAmountColumn(arabicFont, totalAmount, discount, debtBefore, debtAfter, currency),
      weightColumn(arabicFont, notes, itemsNumber, itemsWeigt),
    ]),
  );
}

pw.Widget invoiceAmountColumn(Font arabicFont, String totalAmount, String discount,
    String debtBefore, String debtAfter, String currency) {
  return pw.Column(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      totalsItem(arabicFont, 'مبلغ القائمة', totalAmount, lightBgColor),
      totalsItem(arabicFont, 'الخصم', discount, lightBgColor),
      totalsItem(arabicFont, 'الطلب السابق', debtBefore, lightBgColor),
      totalsItem(arabicFont, 'المجموع الكلي', debtAfter, darkBgColor, textColor: PdfColors.white),
      _arabicText(arabicFont, currency),
    ],
  );
}

pw.Widget weightColumn(Font arabicFont, String notes, String itemsNumber, String itemsWeigt) {
  return pw.Column(
    mainAxisAlignment: pw.MainAxisAlignment.start,
    children: [
      _labedContainer(notes, 'الملاحظات', arabicFont, width: 250, height: 40),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _labedContainer(itemsNumber, 'عدد الكراتين', arabicFont, width: 120),
          pw.SizedBox(width: 10),
          _labedContainer(itemsWeigt, 'الوزن', arabicFont, width: 120),
        ],
      ),
    ],
  );
}

pw.Widget _signituresRow(Font arabicFont) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
    children: [
      _arabicText(arabicFont, 'المستلم'),
      _arabicText(arabicFont, 'السائق'),
      _arabicText(arabicFont, 'المجهز'),
    ],
  );
}

pw.Widget footerBar(
  Font arabicFont,
  String text1,
  String text2,
) {
  final childWidget = pw.Row(
    children: [
      pw.SizedBox(width: 14),
      _arabicText(arabicFont, text2, fontSize: 8, textColor: PdfColors.white),
      pw.Spacer(),
      _arabicText(arabicFont, text1, fontSize: 8, textColor: PdfColors.white),
      pw.SizedBox(width: 14),
    ],
  );
  return _coloredContainer(childWidget, 555, height: 22, bgColor: darkBgColor);
}

pw.Widget _coloredContainer(pw.Widget childWidget, double width,
    {bool isDecorated = true,
    PdfColor bgColor = PdfColors.white,
    PdfColor borderColor = PdfColors.grey300,
    double height = 22}) {
  return pw.Container(
    width: width,
    height: height, // Increased height to provide more space for the label
    decoration: isDecorated
        ? pw.BoxDecoration(
            borderRadius: const pw.BorderRadius.all(Radius.circular(4)), // Rounded corners
            border: pw.Border.all(color: borderColor), // Border color
            color: bgColor,
          )
        : null,
    padding: const pw.EdgeInsets.only(bottom: 0, left: 0), // Set padding to 0 to avoid extra space
    child: childWidget,
  );
}

pw.Widget _labedContainer(String text, String label, Font arabicFont,
    {PdfColor bgColor = PdfColors.white,
    PdfColor borderColor = PdfColors.grey,
    double width = 170,
    double height = 22}) {
  final childWidget = _arabicText(arabicFont, text);
  // return pw.Stack(children: [
  return pw.Stack(children: [
    pw.Container(
      padding: const pw.EdgeInsets.only(top: 17),
      child: _coloredContainer(childWidget, width,
          height: height, bgColor: bgColor, borderColor: borderColor),
    ),
    pw.Positioned(
      top: 3, // Adjusted position to move the label down
      right: 5, // Position at the right
      child: _arabicText(arabicFont, label,
          textColor: PdfColors.red, fontSize: 7, bgColor: PdfColors.white),
    ),
  ]);
}

pw.Widget totalsItem(Font arabicFont, String text1, String text2, PdfColor bgColor,
    {double width = 180, PdfColor textColor = PdfColors.black}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      borderRadius: const pw.BorderRadius.all(Radius.circular(4)), // Rounded corners
      border: pw.Border.all(color: PdfColors.grey), // Border color
      color: bgColor,
    ),
    width: width,
    padding: const pw.EdgeInsets.symmetric(horizontal: 10),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        _arabicText(arabicFont, text2, width: 60, textColor: textColor),
        pw.Spacer(),
        _arabicText(arabicFont, text1, width: 88, textColor: textColor),
      ],
    ),
  );
}

pw.Widget _arabicText(
  Font arabicFont,
  String text, {
  PdfColor? textColor,
  double? width,
  bool isTitle = false,
  double fontSize = 10,
  PdfColor? bgColor,
  PdfColor? borderColor,
  bool isBordered = false,
}) {
  return pw.Container(
    width: width,
    decoration: isBordered
        ? pw.BoxDecoration(
            borderRadius: const pw.BorderRadius.all(Radius.circular(1)), // Rounded corners
            border: pw.Border.all(color: borderColor ?? PdfColors.grey600), // Border color
          )
        : null,
    color: bgColor,
    padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 0),
    child: pw.Text(
      text,
      textAlign: pw.TextAlign.center,
      textDirection: pw.TextDirection.rtl,
      style: pw.TextStyle(
        font: arabicFont,
        fontSize: fontSize,
        color: textColor,
      ),
    ),
  );
}
