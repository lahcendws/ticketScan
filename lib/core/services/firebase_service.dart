// Service Firebase (commenté pour migration vers Supabase)
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'dart:io';

// class FirebaseService {
//   static final FirebaseAuth _auth = FirebaseAuth.instance;
//   static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   static final FirebaseStorage _storage = FirebaseStorage.instance;

//   // Initialisation
//   static Future<void> initialize() async {
//     // Firebase est déjà initialisé dans main.dart
//   }

//   // Authentification
//   static User? get currentUser => _auth.currentUser;
//   static Stream<User?> get authStateChanges => _auth.authStateChanges();

//   static Future<UserCredential> signInWithEmail(String email, String password) async {
//     return await _auth.signInWithEmailAndPassword(email: email, password: password);
//   }

//   static Future<UserCredential> signUpWithEmail(String email, String password) async {
//     return await _auth.createUserWithEmailAndPassword(email: email, password: password);
//   }

//   static Future<void> signOut() async {
//     await _auth.signOut();
//   }

//   static Future<void> resetPassword(String email) async {
//     await _auth.sendPasswordResetEmail(email: email);
//   }

//   // Firestore
//   static CollectionReference getTicketsCollection() {
//     final userId = currentUser?.uid;
//     if (userId == null) throw Exception('User not authenticated');
//     return _firestore.collection('users').doc(userId).collection('tickets');
//   }

//   // Nouveau : Stream pour écouter les tickets en temps réel
//   static Stream<QuerySnapshot> getTicketsStream() {
//     return getTicketsCollection()
//         .orderBy('createdAt', descending: true)
//         .snapshots();
//   }

//   static Future<DocumentReference> addTicket(Map<String, dynamic> ticketData) async {
//     return await getTicketsCollection().add(ticketData);
//   }

//   static Future<void> updateTicket(String ticketId, Map<String, dynamic> ticketData) async {
//     await getTicketsCollection().doc(ticketId).update(ticketData);
//   }

//   static Future<void> deleteTicket(String ticketId) async {
//     await getTicketsCollection().doc(ticketId).delete();
//   }

//   static Query getTicketsQuery({int limit = 20, DocumentSnapshot? startAfter}) {
//     Query query = getTicketsCollection().orderBy('createdAt', descending: true).limit(limit);
//     if (startAfter != null) {
//       query = query.startAfterDocument(startAfter);
//     }
//     return query;
//   }

//   static Future<List<DocumentSnapshot>> searchTickets(String searchTerm) async {
//     final tickets = await getTicketsCollection().get();
//     final results = tickets.docs.where((doc) {
//       final data = doc.data() as Map<String, dynamic>;
//       final storeName = data['storeName']?.toString().toLowerCase() ?? '';
//       final products = List<String>.from(data['products'] ?? []);
//       final extractedText = List<String>.from(data['extractedText'] ?? []);
      
//       return storeName.contains(searchTerm.toLowerCase()) ||
//              products.any((product) => product.toLowerCase().contains(searchTerm.toLowerCase())) ||
//              extractedText.any((text) => text.toLowerCase().contains(searchTerm.toLowerCase()));
//     }).toList();
    
//     return results;
//   }

//   // Storage
//   static Future<String> uploadTicketImage(String filePath, String fileName) async {
//     final userId = currentUser?.uid;
//     if (userId == null) throw Exception('User not authenticated');
    
//     try {
//       final file = File(filePath);
//       if (!await file.exists()) {
//         throw Exception('Le fichier local n\'existe pas');
//       }

//       final ref = _storage.ref().child('users/$userId/tickets/$fileName');
//       final metadata = SettableMetadata(contentType: 'image/jpeg');
//       final uploadTask = await ref.putFile(file, metadata);

//       if (uploadTask.state == TaskState.success) {
//         return await ref.getDownloadURL();
//       } else {
//         throw Exception('L\'upload a échoué');
//       }
//     } catch (e) {
//       print('Erreur upload Firebase Storage: $e');
//       rethrow;
//     }
//   }

//   static Future<void> deleteTicketImage(String imageUrl) async {
//     try {
//       final ref = _storage.refFromURL(imageUrl);
//       await ref.delete();
//     } catch (e) {
//       print('Error deleting image: $e');
//     }
//   }

//   // Notifications de garantie
//   static Future<void> scheduleWarrantyNotifications() async {
//   }

//   static Stream<QuerySnapshot> getExpiringWarranties() {
//     final now = Timestamp.now();
//     final thirtyDaysLater = Timestamp.fromDate(
//       DateTime.now().add(const Duration(days: 30))
//     );
    
//     return getTicketsCollection()
//         .where('warrantyEndDate', isGreaterThan: now)
//         .where('warrantyEndDate', isLessThan: thirtyDaysLater)
//         .snapshots();
//   }
// }
