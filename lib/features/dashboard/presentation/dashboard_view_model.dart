import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/data/auth_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final AuthService _authService;
  StreamSubscription<DocumentSnapshot>? _subscription;

  String? _workplaceId;
  String? _userRole;
  bool _isLoading = true;
  String? _error;
  bool _shouldCreateUserDoc = false;

  DashboardViewModel(this._authService) {
    _init();
  }

  String? get workplaceId => _workplaceId;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Load from cache first for immediate display
      final prefs = await SharedPreferences.getInstance();
      _workplaceId = prefs.getString('workplaceId');
      
      // Listen to Firestore updates
      _subscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        _handleUserSnapshot(snapshot, user, prefs);
      }, onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      });

    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _handleUserSnapshot(
    DocumentSnapshot snapshot,
    User user,
    SharedPreferences prefs,
  ) async {
    _isLoading = false;
    _error = null;

    if (!snapshot.exists) {
      // User doc doesn't exist, create it
      if (!_shouldCreateUserDoc) {
        _shouldCreateUserDoc = true;
        await _createUserDocument(user);
      }
      // After creation, snapshot listener will fire again
      notifyListeners();
      return;
    }

    final data = snapshot.data() as Map<String, dynamic>? ?? {};

    // Workplace ID Parsing
    final wpIdRaw = data['workplaceId'];
    final String? serverWpId = wpIdRaw is String
        ? wpIdRaw
        : (wpIdRaw is List && wpIdRaw.isNotEmpty ? wpIdRaw[0] : null);

    // Role Parsing
    final roleRaw = data['role'];
    final String? serverRole = roleRaw is String
        ? roleRaw
        : (roleRaw is List && roleRaw.isNotEmpty ? roleRaw[0] : null);

    // Sync state
    if (serverWpId != _workplaceId || serverRole != _userRole) {
      _workplaceId = serverWpId;
      _userRole = serverRole;
      
      // Update cache
      if (_workplaceId != null) {
        await prefs.setString('workplaceId', _workplaceId!);
      }
      
      notifyListeners();
    } else {
      // Just notify if loading state changed
      notifyListeners(); 
    }
  }

  Future<void> _createUserDocument(User user) async {
    try {
      debugPrint("Creating user document for ${user.uid}");
      final role = user.isAnonymous ? 'user' : 'admin';
      
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email ?? '',
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Update local state temporarily until stream fires
      _userRole = role; 
    } catch (e) {
      debugPrint("Error creating user doc: $e");
    }
  }
  
  Future<void> signOut() async {
    _subscription?.cancel();
    await _authService.signOut();
  }
}
