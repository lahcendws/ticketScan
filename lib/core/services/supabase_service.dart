import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static final GoTrueClient _auth = _client.auth;
  static final SupabaseStorageClient _storage = _client.storage;

  // Initialisation
  static Future<void> initialize() async {
    // Supabase est déjà initialisé dans main.dart
  }

  // Authentification
  static User? get currentUser => _auth.currentUser;
  static Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUpWithEmail(String email, String password) async {
    final response = await _auth.signUp(email: email, password: password);
    
    // Si l'inscription réussit, essayer de se connecter automatiquement
    if (response.user != null && response.user!.emailConfirmedAt != null) {
      await _auth.signInWithPassword(email: email, password: password);
    }
    
    return response;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    // Forcer la mise à jour de l'état
    await Future.delayed(const Duration(milliseconds: 100));
  }

  static Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  // Base de données (remplace Firestore)
  static Future<List<Map<String, dynamic>>> getTickets({int limit = 20, int offset = 0}) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    return await _client
        .from('tickets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit)
        .range(offset, offset + limit - 1);
  }

  // Stream pour écouter les tickets en temps réel
  static Stream<List<Map<String, dynamic>>> getTicketsStream() {
    return _client.auth.onAuthStateChange.asyncExpand((authState) {
      final userId = authState.session?.user.id;
      if (userId == null) {
        // Retourner un stream vide si pas d'utilisateur
        return Stream.value([]);
      }
      
      return _client
          .from('tickets')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false);
    });
  }

  static Future<Map<String, dynamic>> addTicket(Map<String, dynamic> ticketData) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    final ticketWithUser = Map<String, dynamic>.from(ticketData);
    ticketWithUser['user_id'] = userId;
    ticketWithUser['created_at'] = DateTime.now().toIso8601String();
    
    final response = await _client
        .from('tickets')
        .insert(ticketWithUser)
        .select();
    return response.first;
  }

  static Future<void> updateTicket(String ticketId, Map<String, dynamic> ticketData) async {
    await _client
        .from('tickets')
        .update(ticketData)
        .eq('id', ticketId);
  }

  static Future<void> deleteTicket(String ticketId) async {
    await _client
        .from('tickets')
        .delete()
        .eq('id', ticketId);
  }

  static Future<List<Map<String, dynamic>>> searchTickets(String searchTerm) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    return await _client
        .from('tickets')
        .select()
        .eq('user_id', userId)
        .or('store_name.ilike.%$searchTerm%,products.cs.{\\"$searchTerm\\"},extracted_text.cs.{\\"$searchTerm\\"}');
  }

  // Storage
  static Future<String> uploadTicketImage(String filePath, String fileName) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Le fichier local n\'existe pas');
      }

      final path = 'users/$userId/tickets/$fileName';
      final storageResponse = await _storage
          .from('tickets')
          .upload(
            path,
            file,
          );

      if (storageResponse.isEmpty) {
        throw Exception('L\'upload a échoué');
      }

      final publicUrl = _storage
          .from('tickets')
          .getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('Erreur upload Supabase Storage: $e');
      rethrow;
    }
  }

  static Future<void> deleteTicketImage(String imageUrl) async {
    try {
      // Extraire le chemin de l'URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final pathIndex = pathSegments.indexOf('tickets');
      if (pathIndex != -1 && pathIndex < pathSegments.length - 1) {
        final path = pathSegments.sublist(pathIndex).join('/');
        await _storage
            .from('tickets')
            .remove([path]);
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  // Notifications de garantie
  static Future<void> scheduleWarrantyNotifications() async {
    // Implémenter avec les fonctions Supabase Edge Functions si nécessaire
  }

  static Future<List<Map<String, dynamic>>> getExpiringWarranties() async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    final now = DateTime.now().toIso8601String();
    final thirtyDaysLater = DateTime.now()
        .add(const Duration(days: 30))
        .toIso8601String();
    
    return await _client
        .from('tickets')
        .select()
        .eq('user_id', userId)
        .gt('warranty_end_date', now)
        .lt('warranty_end_date', thirtyDaysLater);
  }
}
