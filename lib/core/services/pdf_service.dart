import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/ticket_model.dart';
import 'package:intl/intl.dart';
import 'supabase_service.dart';
import 'package:http/http.dart' as http;

class PDFService {
  static Future<void> generateAndPreviewTicketPDF(BuildContext context, TicketModel ticket) async {
    final pdf = pw.Document();
    
    // Charger une police qui supporte le symbole €
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pw.ImageProvider? ticketImage;
    if (ticket.imageUrls.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(SupabaseService.getPublicUrl(ticket.imageUrls.first)));
        if (response.statusCode == 200) {
          ticketImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        debugPrint('Erreur téléchargement image pour PDF: $e');
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('ATTESTATION DE GARANTIE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text('TicketScan', style: pw.TextStyle(fontSize: 18, color: PdfColors.blue)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Magasin: ${ticket.storeName}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date d\'achat: ${DateFormat('dd/MM/yyyy').format(ticket.date)}'),
                      pw.Text('Catégorie: ${ticket.category ?? "Autre"}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('MONTANT TOTAL', style: const pw.TextStyle(fontSize: 12)),
                      pw.Text('${ticket.totalAmount.toStringAsFixed(2)} ${ticket.currency}', 
                          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(color: PdfColors.amber100),
                child: pw.Row(
                  children: [
                    pw.Text('GARANTIE VALIDE JUSQU\'AU : ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(DateFormat('dd/MM/yyyy').format(ticket.warrantyEndDate), 
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text('DÉTAIL DES ARTICLES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.ListView.builder(
                itemCount: ticket.products.length,
                itemBuilder: (context, index) {
                  final p = ticket.products[index];
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('${p['name']} ${p['hasWarranty'] == true ? "(Garanti)" : ""}'),
                        pw.Text('${p['price']} ${ticket.currency}'),
                      ],
                    ),
                  );
                },
              ),
              if (ticketImage != null) ...[
                pw.SizedBox(height: 30),
                pw.Text('PREUVE D\'ACHAT (PHOTO)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Container(
                    height: 350,
                    child: pw.Image(ticketImage, fit: pw.BoxFit.contain),
                  ),
                ),
              ],
              pw.Spacer(),
              pw.Divider(),
              pw.Center(
                child: pw.Text('Document généré par l\'application TicketScan - Gardez vos preuves d\'achat en sécurité.', 
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ),
            ],
          );
        },
      ),
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Aperçu du PDF')),
          body: PdfPreview(
            build: (format) => pdf.save(),
            canDebug: false,
          ),
        ),
      ),
    );
  }
}
