import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  /// Intenta iniciar sesión contra el backend de la base de datos remota
  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response != null && response['user'] != null) {
        final user = UserModel.fromJson(response['user']);
        
        // Guardar token y datos del usuario si el backend los provee
        final prefs = await SharedPreferences.getInstance();
        if (response['token'] != null) {
          await prefs.setString('token', response['token']);
        }
        await prefs.setString('user_id', user.id ?? '');
        await prefs.setString('user_name', user.name);
        await prefs.setString('user_email', user.email);
        
        return user;
      }
      return null;
    } catch (e) {
      print('AuthService Login Error: $e');
      rethrow;
    }
  }

  /// Registrar un nuevo usuario en la base de datos
  Future<UserModel?> register(String name, String email, String password) async {
    try {
      final response = await _apiService.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response != null && response['user'] != null) {
        return UserModel.fromJson(response['user']);
      }
      return null;
    } catch (e) {
      print('AuthService Register Error: $e');
      rethrow;
    }
  }

  /// Elimina la sesión localmente
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }

  /// Obtiene el token guardado para solicitudes autenticadas
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Obtiene los datos del usuario local si ya está autenticado
  Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('user_id');
    final name = prefs.getString('user_name');
    final email = prefs.getString('user_email');

    if (id != null && name != null && email != null) {
      return UserModel(id: id, name: name, email: email);
    }
    return null;
  }

  /// Actualiza la contraseña del usuario en el servidor
  Future<bool> updatePassword(String userId, String currentPassword, String newPassword) async {
    try {
      final token = await getToken();
      await _apiService.post(
        '/auth/update-password',
        {
          'userId': userId,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        token: token,
      );
      return true;
    } catch (e) {
      print('AuthService updatePassword Error: $e');
      rethrow;
    }
  }
}
