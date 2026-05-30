import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/product_model.dart';

class InventoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _transactions = [];
  List<ProductModel> _warehouseProducts = [];
  List<Map<String, dynamic>> _transfers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get warehouses => _warehouses;
  List<Map<String, dynamic>> get suppliers => _suppliers;
  List<Map<String, dynamic>> get customers => _customers;
  List<Map<String, dynamic>> get transactions => _transactions;
  List<ProductModel> get warehouseProducts => _warehouseProducts;
  List<Map<String, dynamic>> get transfers => _transfers;
  
  List<Map<String, dynamic>> get entries => _transactions.where((t) => t['type'] == 'ENTRADA').toList();
  List<Map<String, dynamic>> get exits => _transactions.where((t) => t['type'] == 'SALIDA').toList();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Obtiene los almacenes, proveedores y clientes desde SQL Server
  Future<void> fetchConfigData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      
      final wResponse = await _apiService.get('/warehouses', token: token);
      final sResponse = await _apiService.get('/suppliers', token: token);
      final cResponse = await _apiService.get('/customers', token: token);

      if (wResponse != null && wResponse is List) {
        _warehouses = List<Map<String, dynamic>>.from(wResponse);
      }
      if (sResponse != null && sResponse is List) {
        _suppliers = List<Map<String, dynamic>>.from(sResponse);
      }
      if (cResponse != null && cResponse is List) {
        _customers = List<Map<String, dynamic>>.from(cResponse);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('fetchConfigData error: $e');
      notifyListeners();
    }
  }

  /// Obtiene el historial de movimientos de inventario de SQL Server
  Future<void> fetchTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final response = await _apiService.get('/transactions', token: token);

      if (response != null && response is List) {
        _transactions = List<Map<String, dynamic>>.from(response);
      } else {
        _transactions = [];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('fetchTransactions error: $e');
      notifyListeners();
    }
  }

  /// Registra una nueva transacción (Entrada / Salida) y altera el stock de productos
  Future<bool> createTransaction({
    required String type,
    required String warehouseId,
    String? supplierId,
    String? customerId,
    required String observations,
    required List<Map<String, dynamic>> items,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final user = await _authService.getSavedUser();
      
      final payload = {
        'type': type,
        'warehouseId': warehouseId,
        'supplierId': supplierId,
        'customerId': customerId,
        'observations': observations,
        'userId': user?.id ?? '1',
        'items': items.map((i) => {
          'productId': i['productId'].toString(),
          'quantity': i['quantity'],
          'unitPrice': i['price']
        }).toList()
      };

      final response = await _apiService.post('/transactions', payload, token: token);

      if (response != null) {
        // Recargar transacciones para tener el listado al día
        await fetchTransactions();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('createTransaction error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Crea un nuevo proveedor
  Future<bool> addSupplier(String name, String contactInfo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final payload = {
        'name': name,
        'contactInfo': contactInfo,
      };

      final response = await _apiService.post('/suppliers', payload, token: token);

      if (response != null) {
        await fetchConfigData();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('addSupplier error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Actualiza un proveedor existente
  Future<bool> updateSupplier(String id, String name, String contactInfo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final payload = {
        'name': name,
        'contactInfo': contactInfo,
      };

      final response = await _apiService.put('/suppliers/$id', payload, token: token);

      if (response != null) {
        await fetchConfigData();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('updateSupplier error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Elimina un proveedor
  Future<bool> deleteSupplier(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final response = await _apiService.delete('/suppliers/$id', token: token);

      if (response != null) {
        await fetchConfigData();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('deleteSupplier error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Crea un nuevo almacén
  Future<bool> addWarehouse(String name, String location) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final payload = {
        'name': name,
        'location': location,
      };

      final response = await _apiService.post('/warehouses', payload, token: token);

      if (response != null) {
        await fetchConfigData();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('addWarehouse error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Actualiza un almacén existente
  Future<bool> updateWarehouse(String id, String name, String location) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final payload = {
        'name': name,
        'location': location,
      };

      final response = await _apiService.put('/warehouses/$id', payload, token: token);

      if (response != null) {
        await fetchConfigData();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('updateWarehouse error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Elimina un almacén
  Future<bool> deleteWarehouse(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final response = await _apiService.delete('/warehouses/$id', token: token);

      if (response != null) {
        await fetchConfigData();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('deleteWarehouse error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Obtiene el inventario detallado de productos con su stock correspondiente en un almacén específico
  Future<void> fetchWarehouseInventory(String warehouseId) async {
    _isLoading = true;
    _errorMessage = null;
    _warehouseProducts = [];
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final response = await _apiService.get('/warehouses/$warehouseId/inventory', token: token);

      if (response != null && response is List) {
        _warehouseProducts = response.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        _warehouseProducts = [];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('fetchWarehouseInventory error: $e');
      _warehouseProducts = [];
      notifyListeners();
    }
  }

  /// Obtiene el historial de transferencias entre almacenes
  Future<void> fetchTransfers() async {
    _isLoading = true;
    _errorMessage = null;
    _transfers = [];
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final response = await _apiService.get('/transfers', token: token);

      if (response != null && response is List) {
        _transfers = List<Map<String, dynamic>>.from(response);
      } else {
        _transfers = [];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('fetchTransfers error: $e');
      _transfers = [];
      notifyListeners();
    }
  }

  /// Registra una nueva transferencia entre almacenes
  Future<bool> createTransfer({
    required String fromWarehouseId,
    required String toWarehouseId,
    required String observations,
    required List<Map<String, dynamic>> items,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final payload = {
        'fromWarehouseId': fromWarehouseId,
        'toWarehouseId': toWarehouseId,
        'observations': observations,
        'items': items,
        'userId': userId,
      };

      final response = await _apiService.post('/transfers', payload, token: token);

      if (response != null) {
        await fetchTransfers();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('createTransfer error: $e');
      notifyListeners();
      return false;
    }
  }
}

