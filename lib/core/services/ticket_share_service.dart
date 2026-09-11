import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/ticket_model.dart';

class TicketShareService {
  static String buildMessage(TicketModel ticket, {String locale = 'fr_FR'}) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final buffer = StringBuffer()
      ..writeln('TicketScan')
      ..writeln()
      ..writeln('${_label('Magasin', 'Store', locale)} : ${ticket.storeName}')
      ..writeln(
        '${_label('Date d\'achat', 'Purchase date', locale)} : ${dateFormat.format(ticket.date)}',
      )
      ..writeln(
        '${_label('Montant total', 'Total amount', locale)} : '
        '${ticket.totalAmount.toStringAsFixed(2)} ${ticket.currency}',
      )
      ..writeln(
        '${_label('Fin de garantie', 'Warranty end date', locale)} : '
        '${dateFormat.format(ticket.warrantyEndDate)}',
      );

    if (ticket.products.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(_label('Articles', 'Products', locale));
      for (final product in ticket.products) {
        final name = product['name']?.toString() ?? '';
        final price = product['price']?.toString() ?? '0.00';
        buffer.writeln('- $name : $price ${ticket.currency}');
      }
    }

    return buffer.toString().trim();
  }

  static Future<void> shareTicket(
    TicketModel ticket, {
    String locale = 'fr_FR',
  }) {
    final message = buildMessage(ticket, locale: locale);
    return Share.share(message, subject: 'TicketScan - ${ticket.storeName}');
  }

  static String _label(String french, String english, String locale) {
    return locale.startsWith('en') ? english : french;
  }
}
