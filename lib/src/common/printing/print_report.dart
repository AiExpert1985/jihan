import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/printing/print_document.dart';
import 'package:flutter/services.dart';

double pageWidth = 580;
List<bool> isWideField = [];
const minStringLengthForLargeField = 20;
const numItemsInFirstPage = 20;
const numItemsInSecondPage = 30;

Future<Document> getReportPdf(
  BuildContext context,
  WidgetRef ref,
  List<List<dynamic>> reportData,
  pw.ImageProvider image,
  String reportTitle,
  List<String> listTitles,
  String? startDate,
  String? endDate,
  String summaryValue,
  String summaryTitle,
) async {
  final pdf = pw.Document();
  final now = DateTime.now();
  final printingDate = DateFormat.yMd('ar').format(now);
  final printingTime = DateFormat.jm('ar').format(now);
  final arabicFont =
      pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf"));
  _setFieldsSizes(reportData, listTitles);

// add first page manually
  pdf.addPage(pw.Page(
    margin: pw.EdgeInsets.zero,
    build: (pw.Context ctx) {
      return _reportPage(
        context,
        arabicFont,
        image,
        reportTitle,
        listTitles,
        reportData
            .sublist(0,
                reportData.length < numItemsInFirstPage ? reportData.length : numItemsInFirstPage)
            .toList(),
        startDate,
        endDate,
        printingDate,
        printingTime,
        summaryValue,
        summaryTitle,
        0,
        includeSummary: reportData.length <= numItemsInFirstPage,
      );
    },
  ));
  // then keep adding pages (until more than thousand items are add, which I don't think they will exceed!)
  for (var i = 0; i < 30; i++) {
    if (reportData.length < (numItemsInFirstPage + (i * numItemsInSecondPage))) {
      // if data length is less than previous max items, it means we are done, so break
      break;
    }

    pdf.addPage(pw.Page(
      margin: pw.EdgeInsets.zero,
      build: (pw.Context ctx) {
        return _reportPage(
          context,
          arabicFont,
          image,
          reportTitle,
          listTitles,
          reportData
              .sublist(
                (numItemsInFirstPage + (i * numItemsInSecondPage)),
                reportData.length < (numItemsInFirstPage + ((i + 1) * numItemsInSecondPage))
                    ? reportData.length
                    : (numItemsInFirstPage + ((i + 1) * numItemsInSecondPage)),
              )
              .toList(),
          startDate,
          endDate,
          printingDate,
          printingTime,
          summaryValue,
          summaryTitle,
          (numItemsInFirstPage + (i * numItemsInSecondPage)),
          includeImage: false,
          includeTitle: false,
          includeSummary: reportData.length < (numItemsInFirstPage + (i * numItemsInSecondPage)),
        );
      },
    ));
  }
  return pdf;
}

void _setFieldsSizes(List<List<dynamic>> reportData, List<String> reportHeaders) {
  // note that we need to reverse the list because pw package works in reversed order
  // so we make sure the intended field takes the large size
  // first we need to clear previous values from other reports
  isWideField = [];
  // first we assume all cells are normal size
  for (var _ in reportHeaders) {
    isWideField.add(false);
  }
  for (List item in reportData) {
    item = item.reversed.toList();
    for (var i = 0; i < item.length; i++) {
      if (item[i] is String && item[i].length > minStringLengthForLargeField) {
        isWideField[i] = true;
      }
    }
  }
  // I don't want to increase the size of notes fields
  // note that we need to reverse the list because pw package works in reversed order
  // so we make sure the intended field takes the large size
  final reversedTitles = reportHeaders.reversed.toList();
  for (var i = 0; i < reversedTitles.length; i++) {
    if (reversedTitles[i].contains('ملاحظات') || reversedTitles[i].contains('notes')) {
      isWideField[i] = false;
    }
  }
}

pw.Widget _reportPage(
  BuildContext context,
  Font arabicFont,
  dynamic image,
  String reportTitle,
  List<String> listTitles,
  List<List<dynamic>> dataList,
  String? startDate,
  String? endDate,
  String printingDate,
  String printingTime,
  String summaryValue,
  String summaryTitle,
  int index, {
  bool includeSummary = true,
  bool includeImage = true,
  bool includeTitle = true,
}) {
  return pw.Column(
    mainAxisAlignment: pw.MainAxisAlignment.start,
    children: [
      if (includeImage) pw.Image(image),
      pw.SizedBox(height: 5),
      if (includeTitle) _buildReportHeader(arabicFont, reportTitle, startDate, endDate),
      pw.SizedBox(height: 5),
      _buildListTitles(arabicFont, listTitles),
      pw.SizedBox(height: 10),
      _buildDataList(arabicFont, dataList, index),
      pw.SizedBox(height: 10),
      if (includeSummary) _buildSummary(arabicFont, summaryValue, summaryTitle),
      pw.Spacer(),
      footerBar(arabicFont, 'وقت الطباعة ', '$printingDate   $printingTime '),
      pw.SizedBox(height: 10),
    ],
  ); // Center
}

pw.Widget _buildSummary(Font arabicFont, String summaryValue, String summaryTitle) {
  return coloredContainer(
    pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        arabicText(arabicFont, summaryValue),
        arabicText(arabicFont, summaryTitle),
      ],
    ),
    bgColor: lightBgColor,
    pageWidth,
    height: 20,
  );
}

pw.Widget _buildReportHeader(
    Font arabicFont, String reportTitle, String? startDate, String? endDate) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
    child: pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            if (startDate != null || endDate != null)
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  children: [
                    if (startDate != null)
                      pw.Row(
                        children: [
                          arabicText(arabicFont, startDate, fontSize: 14),
                          pw.SizedBox(width: 5),
                          arabicText(arabicFont, 'من تاريخ', fontSize: 14),
                        ],
                      ),
                    if (endDate != null)
                      pw.Row(
                        children: [
                          arabicText(arabicFont, endDate, fontSize: 14),
                          pw.SizedBox(width: 5),
                          arabicText(arabicFont, 'الى تاريخ', fontSize: 14),
                        ],
                      ),
                  ],
                ),
              ),
            if (startDate != null || endDate != null) pw.Spacer(),
            arabicText(arabicFont, reportTitle, fontSize: 18),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _buildListTitles(Font arabicFont, List<dynamic> titlesList) {
  titlesList = titlesList.reversed.toList();
  List<pw.Widget> itemsList = [];
  for (int i = 0; i < titlesList.length; i++) {
    itemsList.add(_buildHeaderCell(arabicFont, titlesList[i], i));
  }
  itemsList.add(pw.Container(
      width: 25,
      padding: const pw.EdgeInsets.all(1),
      child: arabicText(arabicFont, 'ت', isTitle: true, textColor: PdfColors.white)));
  pw.Widget titlesContainer = pw.Container(
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: itemsList,
    ),
  );
  return coloredContainer(
    titlesContainer,
    bgColor: darkBgColor,
    pageWidth,
    height: 20,
  );
}

pw.Widget _buildDataList(Font arabicFont, List<List<dynamic>> dataList, int index) {
  List<pw.Widget> itemsList = [];
  for (int i = 0; i < dataList.length; i++) {
    int sequence = index + i + 1;
    itemsList.add(_buildItem(arabicFont, dataList[i], sequence));
  }
  return pw.Container(child: pw.Column(children: itemsList));
}

pw.Widget _buildItem(Font arabicFont, List<dynamic> dataRow, int sequence) {
  List<pw.Widget> item = [];
  dataRow = dataRow.reversed.toList();
  for (int i = 0; i < dataRow.length; i++) {
    item.add(_buildDataCell(arabicFont, dataRow[i], i));
  }
  item.add(pw.Container(
      width: 25,
      padding: const pw.EdgeInsets.all(1),
      child: arabicText(arabicFont, sequence.toString(), isBordered: true)));
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: item,
    ),
  );
}

pw.Widget _buildDataCell(Font arabicFont, dynamic value, int i) {
  String cellText = '';
  if (value is DateTime) {
    cellText = formatDate(value);
  } else if (value is num || value is double || value is int) {
    cellText = doubleToStringWithComma(value);
  } else if (value is String && value.trim().isEmpty) {
    cellText = '-';
  } else if (value is String) {
    cellText = value;
  } else {
    cellText = '-';
  }
  if (isWideField[i]) {
    return pw.Container(
        width: 185,
        padding: const pw.EdgeInsets.all(1),
        child: arabicText(arabicFont, cellText, isBordered: true));
  }
  return pw.Expanded(
      child: pw.Container(
          padding: const pw.EdgeInsets.all(1),
          child: arabicText(arabicFont, cellText, isBordered: true)));
}

pw.Widget _buildHeaderCell(Font arabicFont, String text, int i) {
  if (isWideField[i]) {
    return pw.Container(
      width: 185,
      padding: const pw.EdgeInsets.all(1),
      child: arabicText(arabicFont, text, isTitle: true, textColor: PdfColors.white),
    );
  }
  return pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(1),
      child: arabicText(arabicFont, text, isTitle: true, textColor: PdfColors.white),
    ),
  );
}
