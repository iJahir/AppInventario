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
  Future<void> fetchProducts({bool force = false}) async {
    if (!force && _products.isNotEmpty) {
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      try {
        final token = await _authService.getToken();
        final response = await _apiService.get('/products', token: token);
        if (response != null && response is List) {
          _products = response.map((json) => ProductModel.fromJson(json)).toList();
          notifyListeners();
        }
      } catch (e) {
        print('fetchProducts background error: $e');
      }
      return;
    }

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

  /// Obtiene el detalle de consumo por lotes PEPS de una transacción de SALIDA registrada
  Future<List<Map<String, dynamic>>> fetchTransactionFifoDetail(String transactionId) async {
    try {
      final token = await _authService.getToken();
      final response = await _apiService.get('/transactions/$transactionId/fifo-detail', token: token);
      if (response != null && response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('fetchTransactionFifoDetail error: $e');
      return [];
    }
  }

  /// Calcula en tiempo real qué lotes PEPS se consumirán para una salida (vista previa)
  Future<Map<String, dynamic>?> fetchPepsPreview(String productId, int qty, String warehouseId) async {
    try {
      final token = await _authService.getToken();
      final response = await _apiService.get(
        '/products/$productId/lots/preview-peps?qty=$qty&warehouseId=$warehouseId',
        token: token,
      );
      if (response != null && response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return null;
    } catch (e) {
      print('fetchPepsPreview error: $e');
      return null;
    }
  }

  /// Obtiene todos los lotes PEPS de un producto
  /// [status]: 'active' | 'depleted' | null (todos)
  Future<List<Map<String, dynamic>>> fetchProductLots(String productId, {String? status}) async {
    try {
      final token = await _authService.getToken();
      final endpoint = status != null
          ? '/products/$productId/lots?status=$status'
          : '/products/$productId/lots';
      final response = await _apiService.get(endpoint, token: token);
      if (response != null && response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('fetchProductLots error: $e');
      return [];
    }
  }
}
