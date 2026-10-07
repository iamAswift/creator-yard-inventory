// lib/features/products/barcode_printing_service.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:barcode/barcode.dart';

class BarcodePrintingService {
  BarcodePrintingService._();

  static Future<void> printA4({
    required String productName,
    required String barcode,
  }) async {
    final cleanBarcode = barcode.trim();

    if (cleanBarcode.isEmpty) {
      throw ArgumentError('Barcode cannot be empty.');
    }

    await Printing.layoutPdf(
      name: 'Barcode - $productName',
      onLayout: (_) => _generateA4Pdf(
        productName: productName,
        barcode: cleanBarcode,
      ),
    );
  }

  static Future<void> printMultipleA4({
    required List<({String productName, String barcode})> items,
  }) async {
    final cleanItems = items
        .map(
          (item) => (
            productName: item.productName.trim(),
            barcode: item.barcode.trim(),
          ),
        )
        .where(
          (item) =>
              item.productName.isNotEmpty &&
              item.barcode.isNotEmpty,
        )
        .toList();

    if (cleanItems.isEmpty) {
      throw ArgumentError('No products with valid barcodes to print.');
    }

    await Printing.layoutPdf(
      name: 'Selected Barcodes',
      onLayout: (_) => _generateMultipleA4Pdf(
        items: cleanItems,
      ),
    );
  }

  static Future<File> exportMultipleA4({
    required List<({String productName, String barcode})> items,
  }) async {
    final cleanItems = items
        .map(
          (item) => (
            productName: item.productName.trim(),
            barcode: item.barcode.trim(),
          ),
        )
        .where(
          (item) =>
              item.productName.isNotEmpty &&
              item.barcode.isNotEmpty,
        )
        .toList();

    if (cleanItems.isEmpty) {
      throw ArgumentError('No products with valid barcodes to export.');
    }

    final bytes = await _generateMultipleA4Pdf(
      items: cleanItems,
    );

    final dir = await getApplicationDocumentsDirectory();

    final file = File(
      '${dir.path}/Selected Barcodes.pdf',
    );

    await file.writeAsBytes(bytes);

    return file;
  }

  static Future<Uint8List> _generateMultipleA4Pdf({
    required List<({String productName, String barcode})> items,
  }) async {
    final pdf = pw.Document();

    const columns = 3;
    const rows = 8;
    const labelsPerPage = columns * rows;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.GridView(
              crossAxisCount: columns,
              childAspectRatio: 1.65,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                for (final item in items)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 5,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.grey500,
                        width: 0.4,
                      ),
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Column(
                      mainAxisAlignment:
                          pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          item.productName,
                          maxLines: 2,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.BarcodeWidget(
                          data: item.barcode,
                          barcode: Barcode.code128(),
                          width: 145,
                          height: 36,
                          drawText: true,
                          textStyle: const pw.TextStyle(
                            fontSize: 5.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ...List.generate(
                  (labelsPerPage -
                          (items.length % labelsPerPage)) %
                      labelsPerPage,
                  (_) => pw.SizedBox(),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<File> exportA4({
    required String productName,
    required String barcode,
  }) async {
    final cleanBarcode = barcode.trim();

    if (cleanBarcode.isEmpty) {
      throw ArgumentError('Barcode cannot be empty.');
    }

    final bytes = await _generateA4Pdf(
      productName: productName,
      barcode: cleanBarcode,
    );

    final dir = await getApplicationDocumentsDirectory();

    final safeName = productName
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

    final file = File(
      '${dir.path}/Barcode - ${safeName.isEmpty ? 'Product' : safeName}.pdf',
    );

    await file.writeAsBytes(bytes);

    return file;
  }

  static Future<Uint8List> _generateA4Pdf({
    required String productName,
    required String barcode,
  }) async {
    final pdf = pw.Document();

    const columns = 3;
    const rows = 8;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.GridView(
              crossAxisCount: columns,
              childAspectRatio: 1.65,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: List.generate(
                columns * rows,
                (_) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 5,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColors.grey500,
                      width: 0.4,
                    ),
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        productName,
                        maxLines: 2,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.BarcodeWidget(
                        data: barcode,
                        barcode: Barcode.code128(),
                        width: 145,
                        height: 36,
                        drawText: true,
                        textStyle: const pw.TextStyle(
                          fontSize: 5.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
