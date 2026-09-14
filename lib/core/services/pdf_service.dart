import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/ticket_model.dart';
import 'package:intl/intl.dart';
import 'supabase_service.dart';
import 'package:http/http.dart' as http;
import 'app_localizations.dart';

class PDFService {
  static Future<void> generateAndPreviewTicketPDF(
    BuildContext context,
    TicketModel ticket,
  ) async {
    final pdf = pw.Document();
    final localizations = AppLocalizations.of(context);
    String tr(String key, String fallback) =>
        localizations?.get(key) ?? fallback;

    // Charger une police qui supporte le symbole €
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pw.ImageProvider? ticketImage;
    if (ticket.imageUrls.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse(SupabaseService.getPublicUrl(ticket.imageUrls.first)),
        );
        if (response.statusCode == 200) {
          ticketImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        debugPrint('Erreur téléchargement image pour PDF: $e');
      }
    }

    const navy = PdfColor.fromInt(0xFF102A56);
    const blue = PdfColor.fromInt(0xFF147DFF);
    const paleBlue = PdfColor.fromInt(0xFFEAF3FF);
    const paleGold = PdfColor.fromInt(0xFFFFF7DF);
    const muted = PdfColor.fromInt(0xFF5A7194);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 34, 36, 38),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 16),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: paleBlue, width: 1.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TicketScan',
                    style: pw.TextStyle(
                      color: blue,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    tr('pdf_warranty_certificate', 'ATTESTATION DE GARANTIE'),
                    style: pw.TextStyle(
                      color: navy,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              pw.Text(
                '01',
                style: pw.TextStyle(
                  color: muted,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: paleBlue, width: 1)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  tr(
                    'pdf_footer',
                    'Document généré par l\'application TicketScan - Gardez vos preuves d\'achat en sécurité.',
                  ),
                  style: const pw.TextStyle(fontSize: 8, color: muted),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'TicketScan',
                style: pw.TextStyle(
                  color: blue,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 22),
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: paleBlue,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        ticket.storeName,
                        style: pw.TextStyle(
                          color: navy,
                          fontSize: 19,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        '${tr('pdf_purchase_date', 'Date d\'achat')}: ${DateFormat('dd/MM/yyyy').format(ticket.date)}',
                        style: const pw.TextStyle(color: muted, fontSize: 10),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '${tr('pdf_category', 'Catégorie')}: ${ticket.category ?? "Autre"}',
                        style: const pw.TextStyle(color: muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 18),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      tr('pdf_total_amount', 'MONTANT TOTAL'),
                      style: const pw.TextStyle(color: muted, fontSize: 9),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${ticket.totalAmount.toStringAsFixed(2)} ${ticket.currency}',
                      style: pw.TextStyle(
                        color: blue,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: pw.BoxDecoration(
              color: paleGold,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.amber300, width: 0.8),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 7,
                  height: 30,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber700,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        tr(
                          'pdf_warranty_valid_until',
                          'GARANTIE VALIDE JUSQU\'AU :',
                        ),
                        style: pw.TextStyle(
                          color: navy,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        DateFormat('dd/MM/yyyy').format(ticket.warrantyEndDate),
                        style: pw.TextStyle(
                          color: PdfColors.amber900,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Icon(
                  pw.IconData(0xe8e8),
                  color: PdfColors.amber800,
                  size: 20,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 26),
          pw.Text(
            tr('pdf_items_detail', 'DÉTAIL DES ARTICLES'),
            style: pw.TextStyle(
              color: navy,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: paleBlue, width: 1),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: List.generate(ticket.products.length, (index) {
                final product = ticket.products[index];
                final isLast = index == ticket.products.length - 1;
                final name = product['name']?.toString() ?? '';
                final price = product['price']?.toString() ?? '0.00';
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    color: index.isEven ? PdfColors.white : paleBlue,
                    border: isLast
                        ? null
                        : const pw.Border(
                            bottom: pw.BorderSide(color: paleBlue, width: 0.7),
                          ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '$name ${product['hasWarranty'] == true ? "(${tr('pdf_warrantied', 'Garanti')})" : ""}',
                          style: pw.TextStyle(
                            color: navy,
                            fontSize: 10,
                            fontWeight: product['hasWarranty'] == true
                                ? pw.FontWeight.bold
                                : pw.FontWeight.normal,
                          ),
                        ),
                      ),
                      pw.Text(
                        '$price ${ticket.currency}',
                        style: pw.TextStyle(
                          color: navy,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          if (ticketImage != null) ...[
            pw.SizedBox(height: 26),
            pw.Text(
              tr('pdf_purchase_proof', 'PREUVE D\'ACHAT (PHOTO)'),
              style: pw.TextStyle(
                color: navy,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              height: 300,
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: paleBlue, width: 1),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Image(ticketImage, fit: pw.BoxFit.contain),
            ),
          ],
        ],
      ),
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(tr('pdf_preview', 'Aperçu du PDF'))),
          body: PdfPreview(build: (format) => pdf.save(), canDebug: false),
        ),
      ),
    );
  }
}
