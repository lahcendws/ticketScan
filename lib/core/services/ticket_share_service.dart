import 'dart:io';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/ticket_model.dart';
import '../../core/services/supabase_service.dart';

class TicketShareService {
  static String buildMessage(TicketModel ticket, {String locale = 'fr_FR'}) {
    try {
      final dateFormat = DateFormat('dd/MM/yyyy');
      final buffer = StringBuffer()
        ..writeln('TicketScan')
        ..writeln()
        ..writeln('${_label('Magasin', 'Store', locale)} : ${ticket.storeName}')
        ..writeln(
          '${_label('Date d\'achat', 'Purchase date', locale)} : ${ticket.date != null ? dateFormat.format(ticket.date) : ''}',
        )
        ..writeln(
          '${_label('Montant total', 'Total amount', locale)} : '
          '${ticket.totalAmount != null ? ticket.totalAmount.toStringAsFixed(2) : '0.00'} ${ticket.currency ?? ''}',
        )
        ..writeln(
          '${_label('Fin de garantie', 'Warranty end date', locale)} : '
          '${ticket.warrantyEndDate != null ? dateFormat.format(ticket.warrantyEndDate) : ''}',
        );

      if (ticket.products.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln(_label('Articles', 'Products', locale));
        for (final product in ticket.products) {
          final name = product['name']?.toString() ?? '';
          final price = product['price']?.toString() ?? '0.00';
          buffer.writeln('- $name : $price ${ticket.currency ?? ''}');
        }
      }

      return buffer.toString().trim();
    } catch (e) {
      // Fallback to a simple message if building fails
      return 'TicketScan\n${ticket.storeName}\n${ticket.date != null ? ticket.date.toString() : ''}';
    }
  }

  static Future<void> shareTicket(
    TicketModel ticket, {
    String locale = 'fr_FR',
    Rect? sharePositionOrigin,
  }) {
    try {
      final message = buildMessage(ticket, locale: locale);
      return Share.share(
        message,
        subject: 'TicketScan - ${ticket.storeName}',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      // Log and rethrow
      print('Error sharing ticket: $e');
      rethrow;
    }
  }

  static Future<void> shareTicketImage(
    TicketModel ticket,
    int imageIndex,
    Rect sharePositionOrigin,
  ) async {
    if (ticket.imageUrls.isEmpty || imageIndex >= ticket.imageUrls.length) {
      throw Exception('No image available at index $imageIndex');
    }

    final imagePath = ticket.imageUrls[imageIndex];
    File? file;

    try {
      // Download the image from Supabase storage
      final bytes = await SupabaseService.storage
          .from('tickets')
          .download(imagePath);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final String extension = imagePath.split('.').last;
      final String idPart = ticket.id ?? 'unknown';
      file = File(
        '${tempDir.path}/ticket_${idPart}_image_$imageIndex.$extension',
      );
      await file!.writeAsBytes(bytes);

      // Verify file was written correctly
      if (!await file!.exists()) {
        throw Exception('Failed to create image file');
      }
      final fileSize = await file!.length();
      if (fileSize == 0) {
        throw Exception('Image file is empty');
      }
      // Log for debugging (only in debug mode)
      // ignore: avoid_print
      print('Sharing image: ${file!.path}, size: $fileSize bytes');

      // Share the image file
      await Share.shareXFiles(
        [XFile(file!.path)],
        text: 'TicketScan - ${ticket.storeName}',
        sharePositionOrigin: sharePositionOrigin,
      );
    } finally {
      // Clean up temporary file
      try {
        if (file != null && await file!.exists()) {
          await file!.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }
    }
  }

  static String _label(String french, String english, String locale) {
    return locale.startsWith('en') ? english : french;
  }
}
