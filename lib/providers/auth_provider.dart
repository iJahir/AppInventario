import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  /// Inicializa la autenticación intentando recuperar una sesión previa
  Future<void> initAuth() async {
    _user = await _authService.getSavedUser();
    notifyListeners();
  }

  /// Inicia sesión con la API de la base de datos remota
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.login(email, password);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Registra un nuevo usuario
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newUser = await _authService.register(name, email, password);
      _isLoading = false;
      if (newUser != null) {
        // Iniciar sesión automáticamente después de registrar
        return await login(email, password);
      }
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Cierra la sesión activa
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  /// Actualiza la contraseña en el servidor
  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    if (_user?.id == null) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.updatePassword(_user!.id!, currentPassword, newPassword);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Actualiza el perfil del usuario activo (nombre y foto de perfil en base64)
  Future<bool> updateProfile(String name, String? base64Image) async {
    if (_user?.id == null) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _authService.updateProfile(_user!.id!, name, base64Image);
      _isLoading = false;
      if (updatedUser != null) {
        _user = updatedUser;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
