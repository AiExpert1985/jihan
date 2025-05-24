import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tablets/src/common/functions/debug_print.dart';

class ProductListPdfGenerator {
  static Future<Uint8List?> _getLogoData() async {
    try {
      final data = await rootBundle.load('assets/images/invoice_logo.png');
      return data.buffer.asUint8List();
    } catch (e) {
      errorPrint("Logo image 'assets/images/your_company_logo.png' not loaded: $e");
      errorPrint("Ensure the path is correct and 'assets/images/' is listed in pubspec.yaml.");
      return null;
    }
  }

  static Future<Uint8List> generatePdf(List<Map<String, dynamic>> productMaps,
      {String? reportTitle}) async {
    final Uint8List? logoBytes = await _getLogoData();

    final fontData =
        await rootBundle.load("assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf");
    final arabicFont = pw.Font.ttf(fontData);
    final theme = pw.ThemeData.withFont(base: arabicFont);

    final printableProducts = productMaps.where((item) {
      final quantity = item['productQuantity'];
      final name = item['productName'];
      return name is String && name.isNotEmpty && quantity is num;
    }).toList();

    final pdf = pw.Document();

    if (printableProducts.isEmpty) {
      pdf.addPage(pw.Page(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Center(child: pw.Text('لا توجد منتجات للطباعة.')))));
      return pdf.save();
    }

    final String printDateTime = DateFormat('yyyy/MM/dd   hh:mm a', 'ar').format(DateTime.now());
    const String defaultTitle = 'تقرير المنتجات';
    final String title = reportTitle ?? defaultTitle;

    const double pageSideMargin = 25.0;
    const double pageBottomMargin = 30.0;
    const double firstPageTopMargin = 0.0;
    const double contentTopMarginForSubsequentPages = 30.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.only(
          top: firstPageTopMargin,
          left: pageSideMargin,
          right: pageSideMargin,
          bottom: pageBottomMargin,
        ),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            pw.Widget logoSection;
            if (logoBytes != null) {
              logoSection = pw.Image(
                pw.MemoryImage(logoBytes),
                fit: pw.BoxFit.fitWidth,
                // height: 100.0,
              );
            } else {
              logoSection = pw.Container(
                width: double.infinity,
                height: 60,
                color: PdfColors.grey200,
                child: pw.Center(
                  child: pw.Text(
                    'الشعار غير متوفر',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                ),
              );
            }
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                logoSection,
                pw.SizedBox(height: 15),
                pw.Center(
                  child: pw.Text(
                    title,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 20),
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Divider(height: 1, thickness: 0.5, color: PdfColors.grey600),
                pw.SizedBox(height: 10),
              ],
            );
          } else {
            return pw.SizedBox(height: contentTopMarginForSubsequentPages);
          }
        },
        footer: (pw.Context context) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Divider(height: 1, thickness: 0.5, color: PdfColors.grey600),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    printDateTime,
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    'صفحة ${context.pageNumber} من ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.TableHelper.fromTextArray(
              context: context,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.7),
              headerAlignment: pw.Alignment.center,
              cellAlignment: pw.Alignment.center,
              headerStyle: const pw.TextStyle(fontSize: 12),
              cellStyle: const pw.TextStyle(fontSize: 10),
              // --- ADJUSTED COLUMN WIDTHS FOR FLIPPED ORDER ---
              columnWidths: {
                0: const pw.FlexColumnWidth(1), // Quantity column (was index 2)
                1: const pw.FlexColumnWidth(2.5), // Product Name column (was index 1)
                2: const pw.FlexColumnWidth(0.5), // Sequence number column (was index 0)
              },
              // --- UPDATED HEADERS FOR FLIPPED ORDER ---
              // Rightmost is 'الكمية', leftmost is 'م'
              headers: ['الكمية', 'اسم المنتج', 'تسلسل'],
              // --- UPDATED DATA MAPPING FOR FLIPPED ORDER ---
              data: printableProducts.asMap().entries.map((entry) {
                final int index = entry.key;
                final Map<String, dynamic> item = entry.value;
                final quantity = item['productQuantity'];
                final sequenceNumber = (index + 1).toString();

                // Order: Quantity, Product Name, Sequence Number
                return [
                  (quantity is int ? quantity : (quantity as num).toInt()).toString(),
                  item['productName'] as String,
                  sequenceNumber,
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
