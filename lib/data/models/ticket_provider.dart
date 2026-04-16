import 'package:flutter/material.dart';
import 'ticket_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/notification_service.dart';

class TicketProvider extends ChangeNotifier {
  List<TicketModel> _tickets = [];
  bool _isLoading = false;
  String? _error;

  List<TicketModel> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTickets() async {
    _setLoading(true);
    _clearError();

    try {
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

  Future<void> addTicket(TicketModel ticket) async {
    _setLoading(true);
    _clearError();

    try {
      // 1. Enregistrer dans Supabase et récupérer le résultat (avec le vrai ID)
      final response = await SupabaseService.addTicket(ticket.toMap());
      
      // 2. Créer un nouvel objet ticket avec l'ID réel
      final ticketWithId = TicketModel.fromMap(response);
      
      // 3. Ajouter à la liste locale
      _tickets.insert(0, ticketWithId);
      
      await NotificationService.scheduleWarrantyNotification(
        id: ticketWithId.id.hashCode,
        productName: ticketWithId.products.isNotEmpty 
            ? (ticketWithId.products.first['name']?.toString() ?? 'Produit') 
            : 'Produit',
        storeName: ticketWithId.storeName,
        warrantyEndDate: ticketWithId.warrantyEndDate,
      );
      
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de l\'ajout du ticket: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTicket(String ticketId, Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();

    try {
      await SupabaseService.updateTicket(ticketId, data);
      
      final index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
      if (index != -1) {
        final currentTicket = _tickets[index];
        
        final updatedTicket = currentTicket.copyWith(
          storeName: data['store_name'] ?? currentTicket.storeName,
          date: data['date'] != null ? DateTime.parse(data['date']) : currentTicket.date,
          totalAmount: (data['total_amount'] as num?)?.toDouble() ?? currentTicket.totalAmount,
          products: data['products'] != null 
              ? List<Map<String, dynamic>>.from(data['products']) 
              : currentTicket.products,
          warrantyEndDate: data['warranty_end_date'] != null 
              ? DateTime.parse(data['warranty_end_date']) 
              : currentTicket.warrantyEndDate,
        );
        
        _tickets[index] = updatedTicket;
        
        final productName = updatedTicket.products.isNotEmpty 
            ? (updatedTicket.products.first['name']?.toString() ?? 'Produit')
            : 'Produit';

        await NotificationService.scheduleWarrantyNotification(
          id: updatedTicket.id.hashCode,
          productName: productName,
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

  Future<void> deleteTicket(String ticketId) async {
    _setLoading(true);
    _clearError();

    try {
      final ticket = _tickets.firstWhere((t) => t.id == ticketId);
      for (var url in ticket.imageUrls) {
        await SupabaseService.deleteTicketImage(url);
      }
      await SupabaseService.deleteTicket(ticketId);
      await NotificationService.cancelNotification(ticket.id.hashCode);
      _tickets.removeWhere((ticket) => ticket.id == ticketId);
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la suppression du ticket: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<List<TicketModel>> searchTickets(String query) async {
    _clearError();
    try {
      final documents = await SupabaseService.searchTickets(query);
      return documents.map((data) => TicketModel.fromMap(data)).toList();
    } catch (e) {
      _setError('Erreur lors de la recherche: $e');
      return [];
    }
  }

  List<TicketModel> getExpiringSoonTickets() => _tickets.where((ticket) => ticket.isWarrantyExpiringSoon()).toList();
  List<TicketModel> getExpiredTickets() => _tickets.where((ticket) => ticket.isWarrantyExpired()).toList();

  double getTotalAmount() => _tickets.fold(0.0, (sum, ticket) => sum + ticket.totalAmount);

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  Future<void> refresh() async => await loadTickets();
}
