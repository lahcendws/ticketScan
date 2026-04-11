import 'package:intl/intl.dart';

class AppDateUtils {
  static const String frenchDateFormat = 'dd/MM/yyyy';
  static const String frenchDateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String frenchDateLongFormat = 'dd MMMM yyyy';
  static const String frenchDateTimeLongFormat = 'dd MMMM yyyy à HH:mm';

  // Formater une date en format français
  static String formatDate(DateTime date, {bool longFormat = false}) {
    final format = longFormat ? frenchDateLongFormat : frenchDateFormat;
    return DateFormat(format, 'fr_FR').format(date);
  }

  // Formater une date et heure en format français
  static String formatDateTime(DateTime dateTime, {bool longFormat = false}) {
    final format = longFormat ? frenchDateTimeLongFormat : frenchDateTimeFormat;
    return DateFormat(format, 'fr_FR').format(dateTime);
  }

  // Parser une date depuis une chaîne
  static DateTime? parseDate(String dateString) {
    try {
      // Essayer différents formats
      final formats = [
        frenchDateFormat,
        'yyyy-MM-dd',
        'dd-MM-yyyy',
        'dd/MM/yyyy',
        'MM/dd/yyyy',
        'yyyy/MM/dd',
      ];

      for (final format in formats) {
        try {
          return DateFormat(format).parseStrict(dateString);
        } catch (e) {
          continue;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Calculer la différence entre deux dates en jours
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  // Vérifier si une date est aujourd'hui
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // Vérifier si une date est hier
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }

  // Vérifier si une date est cette semaine
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    return date.isAfter(weekStart.subtract(const Duration(days: 1))) && 
           date.isBefore(weekEnd.add(const Duration(days: 1)));
  }

  // Vérifier si une date est ce mois
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  // Obtenir une description lisible de la différence de temps
  static String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Hier';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays} jours';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return weeks == 1 ? 'Il y a 1 semaine' : 'Il y a $weeks semaines';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return months == 1 ? 'Il y a 1 mois' : 'Il y a $months mois';
      } else {
        final years = (difference.inDays / 365).floor();
        return years == 1 ? 'Il y a 1 an' : 'Il y a $years ans';
      }
    } else if (difference.inHours > 0) {
      return difference.inHours == 1 ? 'Il y a 1 heure' : 'Il y a ${difference.inHours} heures';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1 ? 'Il y a 1 minute' : 'Il y a ${difference.inMinutes} minutes';
    } else {
      return 'À l\'instant';
    }
  }

  // Ajouter des années à une date
  static DateTime addYears(DateTime date, int years) {
    return DateTime(date.year + years, date.month, date.day);
  }

  // Obtenir le début de la journée
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Obtenir la fin de la journée
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  // Obtenir le début de la semaine
  static DateTime startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // Obtenir la fin de la semaine
  static DateTime endOfWeek(DateTime date) {
    return startOfWeek(date).add(const Duration(days: 6));
  }

  // Obtenir le début du mois
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Obtenir la fin du mois
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  // Vérifier si une date est dans le futur
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  // Vérifier si une date est dans le passé
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  // Obtenir une date formatée pour les notifications
  static String formatDateForNotification(DateTime date) {
    if (isToday(date)) {
      return "Aujourd'hui";
    } else if (isTomorrow(date)) {
      return 'Demain';
    } else if (isThisWeek(date)) {
      return DateFormat('EEEE', 'fr_FR').format(date);
    } else {
      return formatDate(date, longFormat: true);
    }
  }

  // Vérifier si une date est demain
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && 
           date.month == tomorrow.month && 
           date.day == tomorrow.day;
  }

  // Calculer l'âge d'un ticket en jours
  static int getTicketAgeInDays(DateTime ticketDate) {
    return daysBetween(ticketDate, DateTime.now());
  }

  // Formater la durée de garantie restante
  static String formatWarrantyRemaining(DateTime warrantyEndDate) {
    final now = DateTime.now();
    final remainingDays = daysBetween(now, warrantyEndDate);

    if (remainingDays < 0) {
      return 'Expirée';
    } else if (remainingDays == 0) {
      return 'Expire aujourd\'hui';
    } else if (remainingDays == 1) {
      return '1 jour restant';
    } else if (remainingDays < 30) {
      return '$remainingDays jours restants';
    } else if (remainingDays < 365) {
      final months = (remainingDays / 30).floor();
      return months == 1 ? '1 mois restant' : '$months mois restants';
    } else {
      final years = (remainingDays / 365).floor();
      return years == 1 ? '1 an restant' : '$years ans restants';
    }
  }
}
