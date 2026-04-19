import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static final GoTrueClient _auth = _client.auth;
  static final SupabaseStorageClient _storage = _client.storage;

  static Future<void> initialize() async {}

  static User? get currentUser => _auth.currentUser;
  static Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUpWithEmail(String email, String password) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      // Si Confirm Email est désactivé dans le dashboard, l'utilisateur sera loggé auto
    );
    return response;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    await Future.delayed(const Duration(milliseconds: 100));
  }

  static Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  static Future<List<Map<String, dynamic>>> getTickets({int limit = 20, int offset = 0}) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    return await _client.from('tickets').select().eq('user_id', userId).order('created_at', ascending: false).limit(limit).range(offset, offset + limit - 1);
  }

  static Stream<List<Map<String, dynamic>>> getTicketsStream() {
    return _client.auth.onAuthStateChange.asyncExpand((authState) {
      final userId = authState.session?.user.id;
      if (userId == null) return Stream.value([]);
      return _client.from('tickets').stream(primaryKey: ['id']).eq('user_id', userId).order('created_at', ascending: false);
    });
  }

  static Future<Map<String, dynamic>> addTicket(Map<String, dynamic> ticketData) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    final ticketWithUser = Map<String, dynamic>.from(ticketData);
    ticketWithUser['user_id'] = userId;
    ticketWithUser['created_at'] = DateTime.now().toIso8601String();
    final response = await _client.from('tickets').insert(ticketWithUser).select();
    return response.first;
  }

  static Future<void> updateTicket(String ticketId, Map<String, dynamic> ticketData) async {
    await _client.from('tickets').update(ticketData).eq('id', ticketId);
  }

  static Future<void> deleteTicket(String ticketId) async {
    await _client.from('tickets').delete().eq('id', ticketId);
  }

  static Future<List<Map<String, dynamic>>> searchTickets(String searchTerm) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    return await _client.from('tickets').select().eq('user_id', userId).or('store_name.ilike.%$searchTerm%,category.ilike.%$searchTerm%');
  }

  static Future<String> uploadTicketImage(String filePath, String fileName) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    try {
      final file = File(filePath);
      final path = 'users/$userId/tickets/$fileName';
      await _storage.from('tickets').upload(path, file);
      return path;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteTicketImage(String imagePath) async {
    try {
      await _storage.from('tickets').remove([imagePath]);
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  static String getPublicUrl(String path) {
    if (path.startsWith('http')) return path;
    return _storage.from('tickets').getPublicUrl(path);
  }
}
