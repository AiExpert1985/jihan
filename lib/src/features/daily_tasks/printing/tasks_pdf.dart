import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tablets/src/features/daily_tasks/model/point.dart';
// Import your SalesPoint model

class SalesPointPdfGenerator {
  static Future<Uint8List> generatePdf(List<SalesPoint> salesPoints) async {
    if (salesPoints.isEmpty) {
      // ... (empty list handling remains the same)
      final emptyDoc = pw.Document();
      // Load font even for empty message if it could be Arabic
      final fontData =
          await rootBundle.load("assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf");
      final arabicFont = pw.Font.ttf(fontData);
      emptyDoc.addPage(pw.Page(
          theme: pw.ThemeData.withFont(base: arabicFont),
          build: (context) => pw.Directionality(
              // Add Directionality even here
              textDirection: pw.TextDirection.rtl,
              child:
                  pw.Center(child: pw.Text('لا توجد بيانات مبيعات متاحة.')) // Example Arabic text
              )));
      return emptyDoc.save();
    }

    // Load the Arabic Font (same as before)
    final fontData =
        await rootBundle.load("assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf");
    final arabicFont = pw.Font.ttf(fontData);
    final theme = pw.ThemeData.withFont(base: arabicFont);

    final String salesmanName = salesPoints.first.salesmanName;
    // Format date - consider locale if needed 'ar'
    final String reportDate = DateFormat.yMMMd('ar')
        .format(salesPoints.first.date); // Using 'ar' locale for Arabic date format

    // --- Translate Labels --- (Recommended)
    const String reportDateLabel = 'تاريخ التقرير:';
    const String totalPointsLabel = 'إجمالي نقاط العملاء:';
    const String visitedNoTxLabel = 'زيارة فقط:';
    const String visitedWithTxLabel = 'زيارة مع تعامل:';
    const String notVisitedWithTxLabel = 'لم يتم زيارتها:';
    // ------------------------

    // Calculate Summary Stats (same as before)
    final int totalCount = salesPoints.length;
    final int visitedNoTransactionCount =
        salesPoints.where((p) => p.isVisited && !p.hasTransaction).length;
    final int visitedWithTransactionCount = salesPoints.where((p) => p.hasTransaction).length;
    final int notVisistedCount =
        totalCount - visitedNoTransactionCount - visitedWithTransactionCount;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme, // Apply the theme for the font
        build: (pw.Context context) {
          // Wrap the entire page content with Directionality for RTL
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl, // <--- Key change: Set RTL direction
            child: pw.Column(
              // CrossAxisAlignment.start often works visually better even in RTL
              // as it aligns to the start edge (right edge in RTL). Test if needed.
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 1. Header
                pw.Center(
                  // Keep title centered
                  child: pw.Text(salesmanName),
                ),
                pw.SizedBox(height: 5),
                // Date - Directionality handles RTL. Use translated label.
                pw.Text(
                  '$reportDateLabel $reportDate',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),

                // 2. Body - Grid
                pw.Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  // Wrap direction is influenced by Directionality
                  children: salesPoints.map((point) {
                    PdfColor boxColor;
                    if (point.hasTransaction) {
                      boxColor = PdfColors.green100;
                    } else if (point.isVisited) {
                      boxColor = PdfColors.yellow100;
                    } else {
                      boxColor = PdfColors.red100;
                    }

                    return pw.Container(
                      width: 80,
                      height: 60,
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(
                        color: boxColor,
                        border: pw.Border.all(color: PdfColors.grey, width: 0.5),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          point.customerName, // Should render correctly RTL
                          textAlign: pw.TextAlign.center, // Keep text centered
                          // textDirection inherited from Directionality
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                pw.Spacer(), // Pushes the summary to the bottom

                // 3. Footer - Summary
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.SizedBox(height: 5),
                // Use translated labels
                pw.Text('$totalPointsLabel $totalCount'),
                pw.Text('$visitedNoTxLabel $visitedNoTransactionCount'),
                pw.Text('$visitedWithTxLabel $visitedWithTransactionCount'),
                pw.Text('$notVisitedWithTxLabel $notVisistedCount'),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
