import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/printing/print_document.dart';
import 'package:flutter/services.dart';

Future<Document> getDamagedItemsPdf(BuildContext context, WidgetRef ref,
    Map<String, dynamic> transactionData, pw.ImageProvider image) async {
  final pdf = pw.Document();
  final type = translateDbTextToScreenText(context, transactionData['transactionType']);
  final number = transactionData['number'].round().toString();
  final items = transactionData['items'] as List;
  final date = formatDate(transactionData['date']);
  final totalAmount = doubleToStringWithComma(transactionData['totalAmount']);
  final currency = translateDbTextToScreenText(context, transactionData['currency']);
  final now = DateTime.now();
  final printingDate = DateFormat.yMd('ar').format(now);
  final printingTime = DateFormat.jm('ar').format(now);
  final notes = transactionData['notes'];

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
          type,
          number,
          date,
          items,
          currency,
          notes,
          printingDate,
          printingTime,
          0,
          items.length,
          totalAmount,
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
            type,
            number,
            date,
            items,
            currency,
            notes,
            printingDate,
            printingTime,
            0,
            25,
            totalAmount,
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
            type,
            number,
            date,
            items,
            currency,
            notes,
            printingDate,
            printingTime,
            25,
            items.length,
            totalAmount,
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
            type,
            number,
            date,
            items,
            currency,
            notes,
            printingDate,
            printingTime,
            0,
            25,
            totalAmount,
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
            type,
            number,
            date,
            items,
            currency,
            notes,
            printingDate,
            printingTime,
            25,
            50,
            totalAmount,
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
            type,
            number,
            date,
            items,
            currency,
            notes,
            printingDate,
            printingTime,
            50,
            items.length,
            totalAmount,
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
            type,
            number,
            date,
            items,
            currency,
            notes,
            printingDate,
            printingTime,
            0,
            25,
            totalAmount,
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
            type,
            number,
            date,
            items,
            currency,
            notes,
            printingDate,
            printingTime,
            25,
            50,
            totalAmount,
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
            type,
            number,
            date,
            items,
            currency,
            notes,
            printingDate,
            printingTime,
            50,
            75,
            totalAmount,
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
            type,
            number,
            date,
            items,
            currency,
            notes,
            printingDate,
            printingTime,
            75,
            items.length,
            totalAmount,
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
    String type,
    String number,
    String date,
    List<dynamic> items,
    String currency,
    String notes,
    String printingDate,
    String printingTime,
    int startItem,
    int endItem,
    String totalAmount,
    {bool addTotals = true,
    bool includeImage = false,
    int startSequence = 1}) {
  return pw.Column(
    mainAxisAlignment: pw.MainAxisAlignment.start,
    children: [
      if (includeImage) pw.Image(image),
      pw.SizedBox(height: 5),
      arabicText(arabicFont, type, fontSize: 16),
      _buildFirstRow(context, arabicFont, number, date),
      pw.SizedBox(height: 10),
      _itemTitles(arabicFont),
      pw.SizedBox(height: 2),
      _buildItems(
          arabicFont, items.sublist(startItem, items.length < endItem ? items.length : endItem),
          startingSequence: startSequence),
      pw.SizedBox(height: 8),
      if (addTotals) _totals(arabicFont, currency, notes, totalAmount),
      pw.Spacer(),
      footerBar(arabicFont, 'وقت الطباعة', '$printingDate   $printingTime '),
      pw.SizedBox(height: 10),
    ],
  ); // Center
}

pw.Widget _buildFirstRow(BuildContext context, Font arabicFont, String number, String date) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
    children: [
      pw.SizedBox(width: 5), // margin
      labedContainer(date, 'تاريخ القائمة', arabicFont, width: 80),
      labedContainer(number, 'رقم القائمة', arabicFont, width: 60),
      pw.SizedBox(width: 5), // margin
    ],
  );
}

pw.Widget _itemTitles(Font arabicFont) {
  final childWidget = pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
    children: [
      arabicText(arabicFont, 'المجموع', width: 94, isTitle: true, textColor: PdfColors.white),
      arabicText(arabicFont, 'السعر', width: 85, isTitle: true, textColor: PdfColors.white),
      arabicText(arabicFont, 'العدد', width: 85, isTitle: true, textColor: PdfColors.white),
      arabicText(arabicFont, 'اسم المادة', width: 220, isTitle: true, textColor: PdfColors.white),
      arabicText(arabicFont, 'ت', width: 55, isTitle: true, textColor: PdfColors.white),
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
      doubleToStringWithComma(item['sellingPrice']),
      doubleToStringWithComma(item['itemTotalAmount']),
    ));
  }
  return pw.Column(children: itemWidgets);
}

pw.Widget _itemsRow(
    Font arabicFont, String sequence, String name, String quantity, String price, String total) {
  return pw.Container(
    height: 20,
    width: 554,
    padding: const pw.EdgeInsets.all(1),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        arabicText(arabicFont, total, width: 94, isBordered: true, fontSize: 9),
        arabicText(arabicFont, price, width: 85, isBordered: true, fontSize: 9),
        arabicText(arabicFont, quantity, width: 85, isBordered: true, fontSize: 9),
        arabicText(arabicFont, name, width: 220, isBordered: true, fontSize: 9),
        arabicText(arabicFont, sequence, width: 55, isBordered: true, fontSize: 9),
      ],
    ),
  );
}

pw.Widget _totals(Font arabicFont, String currency, String notes, String totalAmount) {
  return pw.Container(
    width: 558, // Set a fixed width for the container
    height: 120,
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      _invoiceAmountColumn(arabicFont, currency, totalAmount),
      _weightColumn(
        arabicFont,
        notes,
      ),
    ]),
  );
}

pw.Widget _weightColumn(
  Font arabicFont,
  String notes,
) {
  return pw.Column(
    mainAxisAlignment: pw.MainAxisAlignment.start,
    children: [
      labedContainer(notes, 'الملاحظات', arabicFont, width: 250, height: 40),
    ],
  );
}

pw.Widget _invoiceAmountColumn(Font arabicFont, String currency, String totalAmount) {
  return pw.Column(
    mainAxisAlignment: pw.MainAxisAlignment.center,
    children: [
      pw.SizedBox(height: 4),
      _totalsItem(arabicFont, 'المبلغ الكلي', totalAmount, darkBgColor, textColor: PdfColors.white),
      pw.SizedBox(height: 3),
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
