import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  AppUser? _user;

  AppUser? get user => _user;

  void setUser(AppUser user) {
    _user = user;
    notifyListeners();
  }

  Future<void> loadUser(String uid) async {
    _user = await _authService.getUser(uid);
    notifyListeners();
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
}
