import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/kardex_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Obtiene todos los productos desde la base de datos remota
  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final response = await _apiService.get('/products', token: token);

      if (response != null && response is List) {
        _products = response.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        _products = [];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('fetchProducts error: $e');
      notifyListeners();
    }
  }

  /// Añade un nuevo producto a la base de datos remota
  Future<bool> addProduct(ProductModel product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final response = await _apiService.post(
        '/products',
        product.toJson(),
        token: token,
      );

      if (response != null) {
        final newProduct = ProductModel.fromJson(response);
        _products.add(newProduct);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('addProduct error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Actualiza un producto existente
  Future<bool> updateProduct(ProductModel product) async {
    if (product.id == null) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final response = await _apiService.put(
        '/products/${product.id}',
        product.toJson(),
        token: token,
      );

      if (response != null) {
        final updatedProduct = ProductModel.fromJson(response);
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = updatedProduct;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Elimina un producto por su ID de la base de datos remota
  Future<bool> deleteProduct(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      await _apiService.delete('/products/$id', token: token);
      
      _products.removeWhere((p) => p.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Obtiene el historial de movimientos de Kardex para un producto específico
  Future<List<KardexModel>> fetchProductKardex(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final response = await _apiService.get('/products/$productId/kardex', token: token);

      List<KardexModel> movements = [];
      if (response != null && response is List) {
        movements = response.map((json) => KardexModel.fromJson(json)).toList();
      }
      
      _isLoading = false;
      notifyListeners();
      return movements;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('fetchProductKardex error: $e');
      notifyListeners();
      return [];
    }
  }
}
