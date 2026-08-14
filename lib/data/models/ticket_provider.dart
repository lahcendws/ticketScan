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
      final ticketsData = await SupabaseService.getAllTickets();
      _tickets = ticketsData.map((data) => TicketModel.fromMap(data)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addTicket(TicketModel ticket) async {
    _setLoading(true);
    _clearError();
    try {
      final response = await SupabaseService.addTicket(ticket.toMap());
      final ticketWithId = TicketModel.fromMap(response);
      _tickets.insert(0, ticketWithId);
      
      await _scheduleWarrantyReminder(ticketWithId);
      
      notifyListeners();
    } catch (e) {
      _setError('Erreur: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // MÉTHODE RESTAURÉE
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
          products: data['products'] != null ? List<Map<String, dynamic>>.from(data['products']) : currentTicket.products,
          warrantyEndDate: data['warranty_end_date'] != null ? DateTime.parse(data['warranty_end_date']) : currentTicket.warrantyEndDate,
        );
        _tickets[index] = updatedTicket;
        notifyListeners();

        // La garantie a pu changer : on reprogramme le rappel
        if (data['warranty_end_date'] != null) {
          await _rescheduleWarrantyReminder(updatedTicket);
        }
      }
    } catch (e) {
      _setError('Erreur lors de la mise à jour: $e');
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
      // Annule le rappel planifié pour ce ticket
      await NotificationService.cancelWarrantyNotification(ticketId);
      _tickets.removeWhere((t) => t.id == ticketId);
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la suppression: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _scheduleWarrantyReminder(TicketModel ticket) async {
    final ticketId = ticket.id;
    if (ticketId == null) return;
    await NotificationService.scheduleWarrantyNotification(
      id: NotificationService.notificationIdForTicket(ticketId),
      productName: ticket.products.isNotEmpty ? (ticket.products.first['name']?.toString() ?? 'Produit') : 'Produit',
      storeName: ticket.storeName,
      warrantyEndDate: ticket.warrantyEndDate,
    );
  }

  Future<void> _rescheduleWarrantyReminder(TicketModel ticket) async {
    final ticketId = ticket.id;
    if (ticketId == null) return;
    await NotificationService.cancelWarrantyNotification(ticketId);
    await _scheduleWarrantyReminder(ticket);
  }

  void _clearError() { _error = null; notifyListeners(); }
  void _setLoading(bool loading) { _isLoading = loading; notifyListeners(); }
  void _setError(String error) { _error = error; notifyListeners(); }
}
