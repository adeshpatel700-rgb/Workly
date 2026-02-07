import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get userStream => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Admin: Sign Up
  Future<void> signUpAdmin(String email, String password) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Create admin record
    await _firestore.collection('users').doc(cred.user!.uid).set({
      'email': email,
      'role': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Admin: Sign In
  Future<void> signInAdmin(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    // Check if role is admin?
    // For simplicity we assume email login is always admin or we check extra doc
  }

  // User: Join Workplace (Anonymous Auth)
  Future<void> joinWorkplace(String name, String workplaceId) async {
    // 1. Sign In Anonymously
    UserCredential cred;
    try {
      cred = await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        throw 'Enable "Anonymous" sign-in provider in Firebase Console > Authentication > Sign-in method.';
      }
      rethrow;
    }
    
    // 2. Check if Workplace Exists
    final workplaceRef = _firestore.collection('workplaces').doc(workplaceId);
    final workplaceDoc = await workplaceRef.get();
    
    if (!workplaceDoc.exists) {
      // Clean up the anonymous user we just created? Ideally yes, but tricky.
      // For now just throw.
      await _auth.signOut(); // Invalid attempt, sign out to avoid phantom user state
      throw 'Workplace ID "$workplaceId" not found.';
    }

    // 3. Store user info
    await _firestore.collection('users').doc(cred.user!.uid).set({
      'name': name,
      'role': 'user',
      'joinedAt': FieldValue.serverTimestamp(),
      'workplaceId': workplaceId,
    });

    // 4. Add to workplace members
    await workplaceRef.update({
      'members': FieldValue.arrayUnion([cred.user!.uid])
    });

    // 5. Persist locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('workplaceId', workplaceId);
    await prefs.setString('userName', name);
  }



  Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<String?> getUserRole() async {
    if (currentUser == null) return null;
    final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
    return doc.data()?['role'] as String?;
  }
}
