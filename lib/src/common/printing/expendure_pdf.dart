import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/printing/print_document.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_controller.dart';

Future<Document> getExpenditurePdf(BuildContext context, WidgetRef ref,
    Map<String, dynamic> transactionData, pw.ImageProvider image) async {
  final pdf = pw.Document();
  final type = translateDbTextToScreenText(context, transactionData['transactionType']);
  final number = transactionData['number'].round().toString();
  final name = transactionData['name'];
  final date = formatDate(transactionData['date']);
  final subtotalAmount = doubleToStringWithComma(transactionData['subTotalAmount']);
  final totalAmount = doubleToStringWithComma(transactionData[transactionTotalAmountKey]);
  final currency = translateDbTextToScreenText(context, transactionData['currency']);
  final now = DateTime.now();
  final printingDate = DateFormat.yMd('ar').format(now);
  final printingTime = DateFormat.jm('ar').format(now);
  final notes = transactionData['notes'];
  final arabicFont =
      pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf"));

  pdf.addPage(pw.Page(
    margin: pw.EdgeInsets.zero,
    orientation: PageOrientation.landscape,
    build: (pw.Context ctx) {
      return _receiptPage(
        context,
        arabicFont,
        image,
        name,
        type,
        number,
        date,
        subtotalAmount,
        totalAmount,
        currency,
        notes,
        printingTime,
        printingDate,
        includeImage: true,
      );
    },
  ));

  return pdf;
}

pw.Widget _receiptPage(
  BuildContext context,
  Font arabicFont,
  dynamic image,
  String customerName,
  String type,
  String number,
  String date,
  String subtotalAmount,
  String totalAmount,
  String currency,
  String notes,
  String printingDate,
  String printingTime, {
  bool includeImage = true,
}) {
  return pw.Row(children: [
    for (var i = 0; i < 2; i++) ...[
      pw.SizedBox(width: 15),
      pw.Container(
        width: 400,
        height: 600,
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            pw.Image(image),
            pw.SizedBox(height: 15),
            pw.Center(child: arabicText(arabicFont, type, fontSize: 20)),
            pw.SizedBox(height: 15),
            separateLabelContainer(arabicFont, customerName, 'نوع الدفع', 330),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                separateLabelContainer(arabicFont, date, 'تاريخ الوصل', 130),
                pw.SizedBox(width: 5),
                separateLabelContainer(arabicFont, number, 'رقم الوصل', 130),
              ],
            ),
            pw.SizedBox(height: 20),
            _invoiceAmountColumn(arabicFont, subtotalAmount, totalAmount, currency),
            pw.SizedBox(height: 30),
            labedContainer(notes, 'الملاحظات', arabicFont, width: 400, height: 70),
            pw.Spacer(),
            footerBar(arabicFont, 'وقت الطباعة', '$printingDate   $printingTime '),
            pw.SizedBox(height: 8),
          ],
        ),
      ),
    ]
  ])

      // ]

      ; // Center
}

pw.Widget _invoiceAmountColumn(
    Font arabicFont, String subTotalAmount, String totalAmount, String currency) {
  return pw.Column(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      _totalsItem(arabicFont, 'المبلغ ', totalAmount, darkBgColor, textColor: PdfColors.white),
      pw.SizedBox(height: 10),
      separateLabelContainer(arabicFont, currency, 'العملة', 80),
    ],
  );
}

pw.Widget _totalsItem(Font arabicFont, String text1, String text2, PdfColor bgColor,
    {double width = 540, PdfColor textColor = PdfColors.black}) {
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
