import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/printing/print_document.dart';
import 'package:flutter/services.dart';

double pageWidth = 580;
List<bool> isWideField = [];
const minStringLengthForLargeField = 20;
const numItemsInFirstPage = 20;
const numItemsInSecondPage = 30;
const double headerFontSize = 14;
const double wideFieldWidth = 185;

Future<pw.Document> getReportPdf(
  BuildContext context,
  WidgetRef ref,
  List<List<dynamic>> reportData,
  pw.ImageProvider image,
  String reportTitle,
  List<String> listTitles,
  String? startDate,
  String? endDate,
  List<String> summaryList,
  List<String> filter1Values, // value selected in filter 1
  List<String> filter2Values, // value selected in filter 2
  List<String> filter3Values, // value selected in filter 3
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
        summaryList,
        0,
        filter1Values,
        filter2Values,
        filter3Values,
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
          summaryList,
          (numItemsInFirstPage + (i * numItemsInSecondPage)),
          filter1Values,
          filter2Values,
          filter3Values,
          includeImage: false,
          includeTitle: false,
          includeSummary:
              reportData.length < (numItemsInFirstPage + ((i + 1) * numItemsInSecondPage)),
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
  pw.Font arabicFont,
  dynamic image,
  String reportTitle,
  List<String> listTitles,
  List<List<dynamic>> dataList,
  String? startDate,
  String? endDate,
  String printingDate,
  String printingTime,
  List<String> summaryList,
  int index,
  List<String> filter1Values,
  List<String> filter2Values,
  List<String> filter3Values, {
  bool includeSummary = true,
  bool includeImage = true,
  bool includeTitle = true,
}) {
  return pw.Column(
    mainAxisAlignment: pw.MainAxisAlignment.start,
    children: [
      if (includeImage) pw.Image(image),
      pw.SizedBox(height: 5),
      if (includeTitle)
        _buildReportHeader(arabicFont, reportTitle, startDate, endDate, filter1Values,
            filter2Values, filter3Values),
      pw.SizedBox(height: 5),
      _buildListTitles(arabicFont, listTitles),
      pw.SizedBox(height: 10),
      _buildDataList(arabicFont, dataList, index),
      pw.SizedBox(height: 10),
      if (includeSummary) _buildSummary(arabicFont, summaryList),
      pw.Spacer(),
      footerBar(arabicFont, 'وقت الطباعة ', '$printingDate   $printingTime '),
      pw.SizedBox(height: 10),
    ],
  ); // Center
}

pw.Widget _buildSummary(pw.Font arabicFont, List<String> summaryList) {
  // pw.Row in arabic needs to reverse data
  final printedSummaryList = summaryList.reversed.toList();
  List<pw.Widget> summaryWidgets = [];
  for (var i = 0; i < printedSummaryList.length; i++) {
    if (isWideField[i]) {
      summaryWidgets.add(pw.Container(
          width: wideFieldWidth, child: arabicText(arabicFont, printedSummaryList[i])));
    } else {
      summaryWidgets.add(
          pw.Expanded(child: pw.Container(child: arabicText(arabicFont, printedSummaryList[i]))));
    }
  }
  // place holder for sequence, since we work in reverse order, we put it at last to appear at beginning
  summaryWidgets.add(pw.Container(width: 25));
  return coloredContainer(
    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: summaryWidgets),
    bgColor: lightBgColor,
    pageWidth,
    height: 20,
  );
}

pw.Widget _buildReportHeader(
  pw.Font arabicFont,
  String reportTitle,
  String? startDate,
  String? endDate,
  List<String> filter1Values,
  List<String> filter2Values,
  List<String> filter3Values,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
    child: pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        arabicText(arabicFont, reportTitle, fontSize: headerFontSize),
        if (filter1Values.isNotEmpty)
          _buildFilteredValueRow(arabicFont, filter1Values, fontSize: headerFontSize),
        if (filter2Values.isNotEmpty)
          _buildFilteredValueRow(arabicFont, filter2Values, fontSize: headerFontSize),
        if (filter3Values.isNotEmpty)
          _buildFilteredValueRow(arabicFont, filter3Values, fontSize: headerFontSize),
        if (startDate != null || endDate != null)
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                if (endDate != null)
                  pw.Row(
                    children: [
                      arabicText(arabicFont, endDate, fontSize: headerFontSize),
                      pw.SizedBox(width: 5),
                      arabicText(arabicFont, 'الى ', fontSize: headerFontSize),
                    ],
                  ),
                pw.SizedBox(width: 10),
                if (startDate != null)
                  pw.Row(
                    children: [
                      arabicText(arabicFont, startDate, fontSize: headerFontSize),
                      pw.SizedBox(width: 5),
                      arabicText(arabicFont, 'من ', fontSize: headerFontSize),
                    ],
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

pw.Widget _buildFilteredValueRow(pw.Font arabicFont, List<String> values, {double fontSize = 14}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.center,
    children: values.map((text) {
      return arabicText(arabicFont, text, fontSize: fontSize);
    }).toList(),
  );
}

pw.Widget _buildListTitles(pw.Font arabicFont, List<dynamic> titlesList) {
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

pw.Widget _buildDataList(pw.Font arabicFont, List<List<dynamic>> dataList, int index) {
  List<pw.Widget> itemsList = [];
  for (int i = 0; i < dataList.length; i++) {
    int sequence = index + i + 1;
    itemsList.add(_buildItem(arabicFont, dataList[i], sequence));
  }
  return pw.Container(child: pw.Column(children: itemsList));
}

pw.Widget _buildItem(pw.Font arabicFont, List<dynamic> dataRow, int sequence) {
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

pw.Widget _buildDataCell(pw.Font arabicFont, dynamic value, int i) {
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
        width: wideFieldWidth,
        padding: const pw.EdgeInsets.all(1),
        child: arabicText(arabicFont, cellText, isBordered: true));
  }
  return pw.Expanded(
      child: pw.Container(
          padding: const pw.EdgeInsets.all(1),
          child: arabicText(arabicFont, cellText, isBordered: true)));
}

pw.Widget _buildHeaderCell(pw.Font arabicFont, String text, int i) {
  if (isWideField[i]) {
    return pw.Container(
      width: wideFieldWidth,
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
