import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tablets/src/common/functions/debug_print.dart';

class ProductListPdfGenerator {
  // Helper to load logo image data
  static Future<Uint8List?> _getLogoData() async {
    try {
      // IMPORTANT: Make sure this path is correct and the asset is in pubspec.yaml
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
    final Uint8List? logoBytes = await _getLogoData(); // Load logo once

    // --- Font Loading ---
    final fontData =
        await rootBundle.load("assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf");
    final arabicFont = pw.Font.ttf(fontData);

    // --- Theme Creation ---
    final theme = pw.ThemeData.withFont(base: arabicFont);

    // Filter out items with zero or less quantity
    final printableProducts = productMaps.where((item) {
      final quantity = item['productQuantity'];
      final name = item['productName'];
      return name is String && name.isNotEmpty && quantity is num && quantity > 0;
    }).toList();

    final pdf = pw.Document();

    // --- Handle Empty List ---
    if (printableProducts.isEmpty) {
      pdf.addPage(pw.Page(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              // Text widget will inherit font from theme
              child: pw.Center(child: pw.Text('لا توجد منتجات للطباعة.')))));
      return pdf.save();
    }

    // --- Variables for Header/Footer (captured by callbacks) ---
    final String printDateTime = DateFormat('yyyy/MM/dd   hh:mm a', 'ar').format(DateTime.now());
    const String defaultTitle = 'تقرير المنتجات'; // Default title if not provided
    final String title = reportTitle ?? defaultTitle;

    // --- Define Page Margins ---
    const double pageSideMargin = 25.0; // Left and Right margins for all pages
    const double pageBottomMargin = 30.0; // Bottom margin for all pages
    const double firstPageTopMargin = 0.0; // Top margin for page 1 (logo at edge)
    const double contentTopMarginForSubsequentPages =
        30.0; // Effective top margin for content on pages 2+

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        // Apply specific margins: top is 0 for first page via header logic
        margin: const pw.EdgeInsets.only(
          top: firstPageTopMargin, // Header on page 1 will start at this position
          left: pageSideMargin,
          right: pageSideMargin,
          bottom: pageBottomMargin,
        ),

        // --- Header: Only on the first page ---
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            // Construct header for the first page
            pw.Widget logoSection;
            if (logoBytes != null) {
              logoSection = pw.Image(
                pw.MemoryImage(logoBytes),
                fit: pw.BoxFit.fitWidth, // Scale image to fit full content width
                // Optional: If the image becomes too tall, you can constrain its height:
                // height: 100.0, // Example: Max height of 100 points
              );
            } else {
              // Placeholder if logo is not found
              logoSection = pw.Container(
                width: double.infinity, // Take full width
                height: 60, // A reasonable height for a placeholder bar
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
              crossAxisAlignment: pw.CrossAxisAlignment.stretch, // Ensures children take full width
              children: [
                logoSection, // Will be at the very top due to page margin top:0
                pw.SizedBox(height: 15),
                pw.Center(
                  child: pw.Text(
                    title,
                    textAlign: pw.TextAlign.center,
                    // Font inherited from theme. Bold removed for compatibility.
                    style: const pw.TextStyle(fontSize: 20),
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Divider(height: 1, thickness: 0.5, color: PdfColors.grey600),
                pw.SizedBox(height: 10), // Space before main content starts on page 1
              ],
            );
          } else {
            // For subsequent pages, create the desired top margin for the content area.
            return pw.SizedBox(height: contentTopMarginForSubsequentPages);
          }
        },

        // --- Footer: Appears on all pages ---
        footer: (pw.Context context) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min, // Important for footer height
            children: [
              pw.Divider(height: 1, thickness: 0.5, color: PdfColors.grey600),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    printDateTime,
                    style:
                        const pw.TextStyle(fontSize: 9, color: PdfColors.grey700), // Font inherited
                  ),
                  pw.Text(
                    'صفحة ${context.pageNumber} من ${context.pagesCount}',
                    style:
                        const pw.TextStyle(fontSize: 9, color: PdfColors.grey700), // Font inherited
                  ),
                ],
              ),
            ],
          );
        },

        // --- Build Function: Main content (table) ---
        build: (pw.Context context) {
          return [
            pw.TableHelper.fromTextArray(
              context: context, // Required for TableHelper
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.7),
              headerAlignment: pw.Alignment.center,
              cellAlignment: pw.Alignment.centerRight,
              // Font inherited. Bold removed for compatibility.
              headerStyle: const pw.TextStyle(fontSize: 12),
              cellStyle: const pw.TextStyle(fontSize: 10),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5), // Product Name column
                1: const pw.FlexColumnWidth(1), // Quantity column
              },
              headers: ['اسم المنتج', 'الكمية'],
              data: printableProducts.map((item) {
                final quantity = item['productQuantity'];
                return [
                  item['productName'] as String,
                  (quantity is int ? quantity : (quantity as num).toInt()).toString()
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
