import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email, display name, and password
  Future<UserCredential?> signUp({
    required String email,
    required String displayName,
    required String password,
  }) async {
    try {
      // Check if display name is already taken
      bool isDisplayNameTaken = await _isDisplayNameTaken(displayName);
      if (isDisplayNameTaken) {
        throw Exception('Display name is already taken');
      }

      // Create user with email and password
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name in Firebase Auth profile (using correct method)
      try {
        await result.user?.updateProfile(displayName: displayName);
        await result.user?.reload();
      } catch (e) {
        print('Note: Display name update may not appear in Auth console immediately');
      }

      // Store user data in Firestore (this is our source of truth)
      await _firestore.collection('users').doc(result.user?.uid).set({
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with email and password
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Check if display name is already taken
  Future<bool> _isDisplayNameTaken(String displayName) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('displayName', isEqualTo: displayName)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }
}

