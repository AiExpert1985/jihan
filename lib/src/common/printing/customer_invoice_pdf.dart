import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/printing/print_document.dart';
import 'package:tablets/src/features/customers/controllers/customer_screen_controller.dart';
import 'package:tablets/src/features/customers/repository/customer_db_cache_provider.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_db_cache_provider.dart';
import 'package:flutter/services.dart';

Future<Document> getCustomerInvoicePdf(BuildContext context, WidgetRef ref,
    Map<String, dynamic> transactionData, pw.ImageProvider image) async {
  final pdf = pw.Document();
  final customerDbCache = ref.read(customerDbCacheProvider.notifier);
  final customerData = customerDbCache.getItemByDbRef(transactionData['nameDbRef']);
  final salesmanDbCache = ref.read(salesmanDbCacheProvider.notifier);
  final salesmanData = salesmanDbCache.getItemByDbRef(transactionData['salesmanDbRef']);
  final type = translateDbTextToScreenText(context, transactionData['transactionType']);
  final number = transactionData['number'].round().toString();
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
  final notes = transactionData['notes'] ?? '';
  final totalNumOfItems = doubleToStringWithComma(_calculateTotalNumOfItems(items));
  final itemsWeigt = doubleToStringWithComma(transactionData['totalWeight']);
  final customerScreenController = ref.read(customerScreenControllerProvider);
  final customerScreenData = customerScreenController.getItemScreenData(context, customerData);
  final debtAfter = doubleToStringWithComma(customerScreenData['totalDebt']);
  final debtBefore =
      doubleToStringWithComma(customerScreenData['totalDebt'] - transactionData['totalAmount']);
  final arabicFont =
      pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf"));

  if (items.length <= 20) {
    pdf.addPage(pw.Page(
      margin: pw.EdgeInsets.zero,
      build: (pw.Context ctx) {
        return _invoicePage(
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
          return _invoicePage(
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
          return _invoicePage(
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
          return _invoicePage(
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
          return _invoicePage(
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
          return _invoicePage(
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
          return _invoicePage(
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
          return _invoicePage(
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
          return _invoicePage(
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
          return _invoicePage(
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

pw.Widget _invoicePage(
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

num _calculateTotalNumOfItems(List<dynamic> items) {
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
      labedContainer(paymentType, 'الدفع', arabicFont, width: 80),
      labedContainer(customerRegion, 'العنوان', arabicFont, width: 158),
      labedContainer(customerPhone, 'رقم الزبون', arabicFont, width: 90),
      labedContainer(customerName, 'اسم الزبون', arabicFont),
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
      labedContainer(date, 'تاريخ القائمة', arabicFont, width: 80),
      labedContainer(number, 'رقم القائمة', arabicFont, width: 60),
      labedContainer(type, 'نوع القائمة', arabicFont, width: 80),
      labedContainer(salesmanPhone, 'رقم المندوب', arabicFont, width: 90),
      labedContainer(salesmanName, 'المندوب', arabicFont),
      pw.SizedBox(width: 5), // margin
    ],
  );
}

pw.Widget _itemTitles(Font arabicFont) {
  final childWidget = pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
    children: [
      arabicText(arabicFont, 'المجموع', width: 70, isTitle: true, textColor: PdfColors.white),
      arabicText(arabicFont, 'السعر', width: 70, isTitle: true, textColor: PdfColors.white),
      arabicText(arabicFont, 'الهدية', width: 70, isTitle: true, textColor: PdfColors.red),
      arabicText(arabicFont, 'العدد', width: 70, isTitle: true, textColor: PdfColors.white),
      arabicText(arabicFont, 'اسم المادة', width: 200, isTitle: true, textColor: PdfColors.white),
      arabicText(arabicFont, 'ت', width: 40, isTitle: true, textColor: PdfColors.white),
    ],
  );
  // return pw.Stack(children: [
  return coloredContainer(childWidget, bgColor: darkBgColor, 554, height: 20);
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
        arabicText(arabicFont, total, width: 70, isBordered: true, fontSize: 9),
        arabicText(arabicFont, price, width: 70, isBordered: true, fontSize: 9),
        arabicText(arabicFont, gift,
            width: 70, isBordered: true, textColor: PdfColors.red, fontSize: 9),
        arabicText(arabicFont, quantity, width: 70, isBordered: true, fontSize: 9),
        arabicText(arabicFont, name, width: 200, isBordered: true, fontSize: 9),
        arabicText(arabicFont, sequence, width: 40, isBordered: true, fontSize: 9),
      ],
    ),
  );
}

pw.Widget _totals(Font arabicFont, String totalAmount, String discount, String debtBefore,
    String debtAfter, String currency, String notes, String itemsNumber, String itemsWeigt) {
  return pw.Container(
    width: 558, // Set a fixed width for the container
    height: 120,
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      _invoiceAmountColumn(arabicFont, totalAmount, discount, debtBefore, debtAfter, currency),
      _weightColumn(arabicFont, notes, itemsNumber, itemsWeigt),
    ]),
  );
}

pw.Widget _weightColumn(Font arabicFont, String notes, String itemsNumber, String itemsWeigt) {
  return pw.Column(
    mainAxisAlignment: pw.MainAxisAlignment.start,
    children: [
      labedContainer(notes, 'الملاحظات', arabicFont, width: 250, height: 40),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          labedContainer(itemsNumber, 'عدد الكراتين', arabicFont, width: 120),
          pw.SizedBox(width: 10),
          labedContainer(itemsWeigt, 'الوزن', arabicFont, width: 120),
        ],
      ),
    ],
  );
}

pw.Widget _signituresRow(Font arabicFont) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
    children: [
      arabicText(arabicFont, 'المستلم'),
      arabicText(arabicFont, 'السائق'),
      arabicText(arabicFont, 'المجهز'),
    ],
  );
}

pw.Widget _invoiceAmountColumn(Font arabicFont, String totalAmount, String discount,
    String debtBefore, String debtAfter, String currency) {
  return pw.Column(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      _totalsItem(arabicFont, 'مبلغ القائمة', totalAmount, darkBgColor, textColor: PdfColors.white),
      _totalsItem(arabicFont, 'الخصم', discount, lightBgColor),
      _totalsItem(arabicFont, 'الدين السابق', debtBefore, lightBgColor),
      _totalsItem(arabicFont, 'الدين الحالي', debtAfter, darkBgColor, textColor: PdfColors.white),
      arabicText(arabicFont, currency),
    ],
  );
}

pw.Widget _totalsItem(Font arabicFont, String text1, String text2, PdfColor bgColor,
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
        arabicText(arabicFont, text2, width: 60, textColor: textColor),
        pw.Spacer(),
        arabicText(arabicFont, text1, width: 88, textColor: textColor),
      ],
    ),
  );
}
