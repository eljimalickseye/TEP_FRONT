import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.role == 'admin';
  bool get isDriver => _user?.role == 'driver';
  bool get isClient => _user?.role == 'client';

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/login', {
        'email': email,
        'password': password,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await ApiService.setToken(data['token']);
        _user = User.fromJson(data['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Erreur de connexion';
      }
    } catch (e) {
      _errorMessage = 'Impossible de contacter le serveur backend.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String name, String email, String password, String passwordConfirmation, String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/register', {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': role,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        await ApiService.setToken(data['token']);
        _user = User.fromJson(data['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Erreur d\'inscription';
      }
    } catch (e) {
      _errorMessage = 'Impossible de contacter le serveur backend.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> tryAutoLogin() async {
    if (ApiService.token == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/me');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _user = User.fromJson(data['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        await ApiService.setToken(null);
      }
    } catch (_) {
      // Keep offline if server is temporarily down, but don't log out yet.
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    if (ApiService.token != null) {
      try {
        await ApiService.post('/logout', {});
      } catch (_) {}
    }
    await ApiService.setToken(null);
    _user = null;
    notifyListeners();
  }
}
