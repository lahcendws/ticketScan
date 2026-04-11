import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'ticket_model.dart';
// import '../../core/services/firebase_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/notification_service.dart';

class TicketProvider extends ChangeNotifier {
  List<TicketModel> _tickets = [];
  bool _isLoading = false;
  String? _error;

  List<TicketModel> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Charger les tickets
  Future<void> loadTickets() async {
    _setLoading(true);
    _clearError();

    try {
      // final query = FirebaseService.getTicketsQuery();
      // final snapshot = await query.get();
      final ticketsData = await SupabaseService.getTickets();
      
      _tickets = ticketsData
          .map((data) => TicketModel.fromMap(data))
          .toList();
      
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement des tickets: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Ajouter un ticket
  Future<void> addTicket(TicketModel ticket) async {
    _setLoading(true);
    _clearError();

    try {
      // await FirebaseService.addTicket(ticket.toMap());
      await SupabaseService.addTicket(ticket.toMap());
      
      // Ajouter à la liste locale
      _tickets.insert(0, ticket);
      
      // Programmer la notification de garantie
      await NotificationService.scheduleWarrantyNotification(
        id: ticket.id.hashCode,
        productName: ticket.products.isNotEmpty ? ticket.products.first : 'Produit',
        storeName: ticket.storeName,
        warrantyEndDate: ticket.warrantyEndDate,
      );
      
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de l\'ajout du ticket: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Mettre à jour un ticket
  Future<void> updateTicket(String ticketId, Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();

    try {
      // await FirebaseService.updateTicket(ticketId, data);
      await SupabaseService.updateTicket(ticketId, data);
      
      // Mettre à jour la liste locale
      final index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
      if (index != -1) {
        final updatedTicket = _tickets[index].copyWith(
          storeName: data['storeName'],
          date: data['date'] != null ? DateTime.parse(data['date']) : null,
          totalAmount: data['totalAmount']?.toDouble(),
          products: data['products'] != null ? List<String>.from(data['products']) : null,
          warrantyEndDate: data['warrantyEndDate'] != null ? DateTime.parse(data['warrantyEndDate']) : null,
        );
        
        _tickets[index] = updatedTicket;
        
        // Reprogrammer la notification de garantie
        await NotificationService.scheduleWarrantyNotification(
          id: updatedTicket.id.hashCode,
          productName: updatedTicket.products.isNotEmpty ? updatedTicket.products.first : 'Produit',
          storeName: updatedTicket.storeName,
          warrantyEndDate: updatedTicket.warrantyEndDate,
        );
        
        notifyListeners();
      }
    } catch (e) {
      _setError('Erreur lors de la mise à jour du ticket: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Supprimer un ticket
  Future<void> deleteTicket(String ticketId) async {
    _setLoading(true);
    _clearError();

    try {
      final ticket = _tickets.firstWhere((t) => t.id == ticketId);
      
      // Supprimer l'image du stockage
      // await FirebaseService.deleteTicketImage(ticket.imageUrl);
      await SupabaseService.deleteTicketImage(ticket.imageUrl);
      
      // Supprimer le document
      // await FirebaseService.deleteTicket(ticketId);
      await SupabaseService.deleteTicket(ticketId);
      
      // Supprimer la notification
      await NotificationService.cancelNotification(ticket.id.hashCode);
      
      // Supprimer de la liste locale
      _tickets.removeWhere((ticket) => ticket.id == ticketId);
      
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la suppression du ticket: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Rechercher des tickets
  Future<List<TicketModel>> searchTickets(String query) async {
    _clearError();

    try {
      // final documents = await FirebaseService.searchTickets(query);
      final documents = await SupabaseService.searchTickets(query);
      return documents
          .map((data) => TicketModel.fromMap(data))
          .toList();
    } catch (e) {
      _setError('Erreur lors de la recherche: $e');
      return [];
    }
  }

  // Obtenir les tickets qui expirent bientôt
  List<TicketModel> getExpiringSoonTickets() {
    return _tickets.where((ticket) => ticket.isWarrantyExpiringSoon()).toList();
  }

  // Obtenir les tickets expirés
  List<TicketModel> getExpiredTickets() {
    return _tickets.where((ticket) => ticket.isWarrantyExpired()).toList();
  }

  // Obtenir les tickets par magasin
  List<TicketModel> getTicketsByStore(String storeName) {
    return _tickets.where((ticket) => 
        ticket.storeName.toLowerCase().contains(storeName.toLowerCase())
    ).toList();
  }

  // Obtenir les tickets par plage de dates
  List<TicketModel> getTicketsByDateRange(DateTime start, DateTime end) {
    return _tickets.where((ticket) => 
        ticket.date.isAfter(start.subtract(const Duration(days: 1))) &&
        ticket.date.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }

  // Obtenir le montant total des tickets
  double getTotalAmount() {
    return _tickets.fold(0.0, (sum, ticket) => sum + ticket.totalAmount);
  }

  // Obtenir le montant total par mois
  Map<String, double> getMonthlyTotals() {
    final Map<String, double> monthlyTotals = {};
    
    for (final ticket in _tickets) {
      final monthKey = '${ticket.date.year}-${ticket.date.month.toString().padLeft(2, '0')}';
      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + ticket.totalAmount;
    }
    
    return monthlyTotals;
  }

  // Obtenir les statistiques
  Map<String, dynamic> getStatistics() {
    final totalTickets = _tickets.length;
    final expiringSoon = getExpiringSoonTickets().length;
    final expired = getExpiredTickets().length;
    final totalAmount = getTotalAmount();
    
    return {
      'totalTickets': totalTickets,
      'expiringSoon': expiringSoon,
      'expired': expired,
      'totalAmount': totalAmount,
      'averageAmount': totalTickets > 0 ? totalAmount / totalTickets : 0.0,
    };
  }

  // Vider les erreurs
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Définir l'état de chargement
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Définir une erreur
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Rafraîchir les données
  Future<void> refresh() async {
    await loadTickets();
  }
}
