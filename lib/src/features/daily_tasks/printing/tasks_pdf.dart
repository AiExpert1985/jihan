import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tablets/src/features/daily_tasks/model/point.dart'; // Import your SalesPoint model

class SalesPointPdfGenerator {
  static Future<Uint8List> generatePdf(List<SalesPoint> salesPoints) async {
    // --- Empty List Handling (No change needed) ---
    if (salesPoints.isEmpty) {
      final emptyDoc = pw.Document();
      final fontData =
          await rootBundle.load("assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf");
      final arabicFont = pw.Font.ttf(fontData);
      emptyDoc.addPage(pw.Page(
          theme: pw.ThemeData.withFont(base: arabicFont),
          build: (context) => pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Center(child: pw.Text('لا توجد بيانات مبيعات متاحة.')))));
      return emptyDoc.save();
    }

    // --- Font Loading and Theme (No change needed) ---
    final fontData =
        await rootBundle.load("assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf");
    final arabicFont = pw.Font.ttf(fontData);
    final theme = pw.ThemeData.withFont(base: arabicFont);

    // --- Data Preparation (No change needed) ---
    final String salesmanName = salesPoints.first.salesmanName;
    final String reportDate =
        DateFormat.yMMMd('ar').format(salesPoints.first.date); // Using 'ar' locale

    // --- Translated Labels (No change needed) ---
    const String reportDateLabel = 'تاريخ التقرير:';
    const String totalPointsLabel = 'إجمالي نقاط العملاء:';
    const String visitedNoTxLabel = 'زيارة فقط:';
    const String visitedWithTxLabel = 'زيارة مع تعامل:';
    const String notVisitedWithTxLabel = 'لم يتم زيارتها:'; // Corrected variable name

    // --- Summary Stats Calculation (No change needed, fixed typo in var name) ---
    final int totalCount = salesPoints.length;
    final int visitedNoTransactionCount =
        salesPoints.where((p) => p.isVisited && !p.hasTransaction).length;
    final int visitedWithTransactionCount = salesPoints.where((p) => p.hasTransaction).length;
    // Corrected variable name usage below
    final int notVisitedCount = // Renamed from notVisistedCount for consistency
        totalCount - visitedNoTransactionCount - visitedWithTransactionCount;

    // --- PDF Document Creation ---
    final pdf = pw.Document();

    // --- Use MultiPage instead of Page ---
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme, // Apply the theme
        textDirection: pw.TextDirection.rtl, // Set RTL direction for the whole MultiPage
        margin: const pw.EdgeInsets.all(30), // Add some default margin

        // --- Header Builder (Repeats on each page) ---
        header: (pw.Context context) {
          // Only build header if it's not the first page to avoid duplication IF
          // you also add it in the main build. Or just keep it simple like this:
          return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Center(
              child: pw.Text(salesmanName),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              '$reportDateLabel $reportDate',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 15), // Space before main content
            pw.Divider(),
            pw.SizedBox(height: 5),
          ]);
        },

        // --- Footer Builder (Example: Page Numbers) ---
        footer: (pw.Context context) {
          return pw.Container(
              alignment:
                  pw.Alignment.centerRight, // Align page number to right (adjust as needed for RTL)
              child: pw.Text(
                  'صفحة ${context.pageNumber} من ${context.pagesCount}', // Arabic "Page X of Y"
                  style: const pw.TextStyle(fontSize: 10)));
        },

// --- Build Function (Content flows across pages) ---
        build: (pw.Context context) {
          // Returns a LIST of widgets. MultiPage will arrange them across pages.

          // Define the time formatter once (using 'ar' locale for Arabic AM/PM)
          final DateFormat timeFormatter = DateFormat.jm('ar');

          return [
            // 1. Body - Grid
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: salesPoints.map((point) {
                // Start mapping salesPoints
                PdfColor boxColor;
                // ... (color logic remains the same) ...
                if (point.hasTransaction) {
                  boxColor = PdfColors.green100;
                } else if (point.isVisited) {
                  boxColor = PdfColors.yellow100;
                } else {
                  boxColor = PdfColors.red100;
                }

                // Get formatted times, handling nulls
                String visitTimeStr =
                    point.visitDate != null ? timeFormatter.format(point.visitDate!) : '';
                String transactionTimeStr = point.transactionDate != null
                    ? timeFormatter.format(point.transactionDate!)
                    : '';

                // --- Conditional Logic for Times Row ---
                pw.Widget timesRowWidget; // Placeholder for the row widget
                bool hasVisit = visitTimeStr.isNotEmpty;
                bool hasTransaction = transactionTimeStr.isNotEmpty;

                if (hasVisit && hasTransaction) {
                  // CASE 1: Both Visit and Transaction Times -> Push Apart
                  timesRowWidget = pw.Row(
                    children: [
                      pw.Text(visitTimeStr, style: const pw.TextStyle(fontSize: 7)),
                      pw.Spacer(),
                      pw.Text(transactionTimeStr, style: const pw.TextStyle(fontSize: 7)),
                    ],
                  );
                } else if (hasVisit && !hasTransaction) {
                  // CASE 2: ONLY Visit Time -> Center Align
                  timesRowWidget = pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center, // Center the content
                    children: [
                      pw.Text(visitTimeStr, style: const pw.TextStyle(fontSize: 7)),
                    ],
                  );
                } else if (!hasVisit && hasTransaction) {
                  // CASE 3: ONLY Transaction Time -> Default Align (Start/Right in RTL)
                  timesRowWidget = pw.Row(
                    // Default mainAxisAlignment is start
                    children: [
                      pw.Text(transactionTimeStr, style: const pw.TextStyle(fontSize: 7)),
                    ],
                  );
                } else {
                  // CASE 4: No times -> Render an empty container
                  timesRowWidget = pw.Container(); // Or pw.SizedBox.shrink()
                }
                // --- End Conditional Logic ---

                return pw.Container(
                  // ... (container settings: width, height, padding, decoration remain the same) ...
                  width: 85,
                  height: 65,
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    color: boxColor,
                    border: pw.Border.all(color: PdfColors.grey, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Customer Name (at the top)
                      pw.Text(
                        point.customerName,
                        textAlign: pw.TextAlign.center,
                        maxLines: 2, // Allow up to two lines for the name
                        overflow: pw.TextOverflow.clip, // Add '...' if text exceeds maxLines
                        style: const pw.TextStyle(
                            fontSize: 9), // Or use your customerNameFontSize constant
                      ),

                      // Spacer to push the times row to the bottom
                      pw.Spacer(),

                      // The conditionally constructed times row widget
                      timesRowWidget,
                    ],
                  ),
                );
              }).toList(), // End mapping salesPoints
            ), // End Wrap

            // --- Remaining summary section (no changes needed here) ---
            pw.SizedBox(height: 20),
            pw.Divider(),
            // ... (rest of the summary Text widgets) ...
            pw.SizedBox(height: 10),
            pw.Text('$totalPointsLabel $totalCount'),
            pw.SizedBox(height: 5),
            pw.Text('$visitedNoTxLabel $visitedNoTransactionCount'),
            pw.SizedBox(height: 5),
            pw.Text('$visitedWithTxLabel $visitedWithTransactionCount'),
            pw.SizedBox(height: 5),
            pw.Text('$notVisitedWithTxLabel $notVisitedCount'),
          ];
        }, // End build function
      ),
    );

    return pdf.save();
  }
}
