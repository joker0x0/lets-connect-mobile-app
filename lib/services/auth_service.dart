import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/fcm_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FCMService _fcmService = FCMService();

  Future<AppUser?> register(String email, String password, String name, String role) async {
    try {
      // 1. Create user in Firebase Auth
      final result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // 2. Create user in Firestore
      AppUser user = AppUser(
        uid: result.user!.uid, 
        email: email, 
        name: name, 
        role: role
      );
      
      await _db.collection('users').doc(user.uid).set(user.toMap());
      
      // 3. Get and store FCM token
      await _storeAndSubscribeFCMToken(user.uid, role);
      
      return user;
    } catch (e) {
      print("Registration error: $e");
      rethrow;
    }
  }

  Future<AppUser?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Get user data
      final user = await getUser(result.user!.uid);
      
      if (user != null) {
        // Store and subscribe FCM token on login
        await _storeAndSubscribeFCMToken(user.uid, user.role);
      }
      
      return user;
    } catch (e) {
      print("Login error: $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      // Unsubscribe from topics before logout
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userDoc = await _db.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          final role = userDoc.data()?['role'] ?? 'citizen';
          await _unsubscribeFromTopics(role);
        }
      }
      
      await _auth.signOut();
    } catch (e) {
      print("Logout error: $e");
      rethrow;
    }
  }

  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists ? AppUser.fromMap(doc.data()!, uid) : null;
    } catch (e) {
      print("Get user error: $e");
      return null;
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // =============== FCM TOKEN MANAGEMENT ===============

  Future<void> _storeAndSubscribeFCMToken(String userId, String role) async {
    try {
      // 1. Get FCM token
      final token = await _fcmService.getToken();
      if (token == null) return;

      // 2. Store token in Firestore
      await _db.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Subscribe to relevant topics
      await _subscribeToTopics(role);
    } catch (e) {
      print("FCM token storage error: $e");
    }
  }

  Future<void> _subscribeToTopics(String role) async {
    try {
      // All users get these topics
      await _fcmService.subscribeToTopic('all_users');
      await _fcmService.subscribeToTopic('announcements');

      // Role-specific topics
      if (role == 'admin' || role == 'government') {
        await _fcmService.subscribeToTopic('admin_notifications');
        await _fcmService.subscribeToTopic('reports');
      } else if (role == 'advertiser') {
        await _fcmService.subscribeToTopic('advertiser_updates');
      }
    } catch (e) {
      print("Topic subscription error: $e");
    }
  }

  Future<void> _unsubscribeFromTopics(String role) async {
    try {
      // Unsubscribe from all possible topics
      await _fcmService.unsubscribeFromTopic('all_users');
      await _fcmService.unsubscribeFromTopic('announcements');
      await _fcmService.unsubscribeFromTopic('admin_notifications');
      await _fcmService.unsubscribeFromTopic('reports');
      await _fcmService.unsubscribeFromTopic('advertiser_updates');
    } catch (e) {
      print("Topic unsubscription error: $e");
    }
  }

  // For token refresh (call this periodically or when token changes)
  Future<void> refreshFCMToken(String userId, String role) async {
    await _storeAndSubscribeFCMToken(userId, role);
  }
}