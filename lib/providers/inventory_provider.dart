import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/offline_db_service.dart';
import '../services/notification_service.dart';
import '../models/product_model.dart';

class InventoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  bool _lastTransactionOffline = false;
  bool get lastTransactionOffline => _lastTransactionOffline;

  bool _lastTransferOffline = false;
  bool get lastTransferOffline => _lastTransferOffline;

  InventoryProvider() {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (!results.contains(ConnectivityResult.none)) {
        syncOfflineTransactions();
      }
    });
  }

  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _transactions = [];
  List<ProductModel> _warehouseProducts = [];
  List<Map<String, dynamic>> _transfers = [];
  String? _logoUrl;
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get warehouses => _warehouses;
  List<Map<String, dynamic>> get suppliers => _suppliers;
  List<Map<String, dynamic>> get customers => _customers;
  List<Map<String, dynamic>> get transactions => _transactions;
  List<ProductModel> get warehouseProducts => _warehouseProducts;
  List<Map<String, dynamic>> get transfers => _transfers;
  String? get logoUrl => _logoUrl;
  
  List<Map<String, dynamic>> get entries => _transactions.where((t) => t['type'] == 'ENTRADA').toList();
  List<Map<String, dynamic>> get exits => _transactions.where((t) => t['type'] == 'SALIDA').toList();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Obtiene el logo actual de la empresa desde SQL Server
  Future<void> fetchLogo() async {
    try {
      final token = await _authService.getToken();
      final response = await _apiService.get('/logo', token: token);
      if (response != null && response['logoUrl'] != null) {
        _logoUrl = response['logoUrl'];
      } else {
        _logoUrl = null;
      }
      notifyListeners();
    } catch (e) {
      print('fetchLogo error: $e');
    }
  }

  /// Sube y actualiza el logo de la empresa
  Future<bool> uploadLogo(String base64Image) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final response = await _apiService.post('/logo', {'base64Image': base64Image}, token: token);
      if (response != null && response['success'] == true) {
        _logoUrl = response['logoUrl'];
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

  /// Obtiene los almacenes, proveedores y clientes desde SQL Server
  Future<void> fetchConfigData({bool force = false}) async {
    if (!force && _warehouses.isNotEmpty && _suppliers.isNotEmpty && _customers.isNotEmpty) {
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      try {
        final token = await _authService.getToken();
        await fetchLogo();
        
        final wResponse = await _apiService.get('/warehouses', token: token);
        final sResponse = await _apiService.get('/suppliers', token: token);
        final cResponse = await _apiService.get('/customers', token: token);

        bool changed = false;
        if (wResponse != null && wResponse is List) {
          _warehouses = List<Map<String, dynamic>>.from(wResponse);
          changed = true;
        }
        if (sResponse != null && sResponse is List) {
          _suppliers = List<Map<String, dynamic>>.from(sResponse);
          changed = true;
        }
        if (cResponse != null && cResponse is List) {
          _customers = List<Map<String, dynamic>>.from(cResponse);
          changed = true;
        }
        if (changed) {
          notifyListeners();
        }
      } catch (e) {
        print('fetchConfigData background error: $e');
      }
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      
      // Intentar cargar el logo también
      await fetchLogo();
      
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
  Future<void> fetchTransactions({bool force = false}) async {
    if (!force && _transactions.isNotEmpty) {
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      try {
        final token = await _authService.getToken();
        final response = await _apiService.get('/transactions', token: token);
        if (response != null && response is List) {
          _transactions = List<Map<String, dynamic>>.from(response);
          notifyListeners();
        }
      } catch (e) {
        print('fetchTransactions background error: $e');
      }
      return;
    }

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
    String? reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOffline = connectivityResult.contains(ConnectivityResult.none);

      final payload = {
        'type': type,
        'warehouseId': warehouseId,
        'supplierId': supplierId,
        'customerId': customerId,
        'observations': observations,
        'userId': '1',
        'reason': reason ?? 'Venta',
        'items': items.map((i) => {
          'productId': i['productId'].toString(),
          'quantity': i['quantity'],
          'unitPrice': i['price']
        }).toList()
      };

      if (isOffline) {
        await OfflineDbService.insertOfflineTransaction('TRANSACTION', payload);
        _lastTransactionOffline = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _lastTransactionOffline = false;
      final token = await _authService.getToken();
      final user = await _authService.getSavedUser();
      payload['userId'] = user?.id ?? '1';

      final response = await _apiService.post('/transactions', payload, token: token);

      if (response != null) {
        // En caso de SALIDA, chequear si cruza el stock mínimo localmente para notificar
        for (var i in items) {
          if (type == 'SALIDA') {
            final int? currentStock = i['currentStock'] as int?;
            final int? minStock = i['minStock'] as int?;
            final int quantity = i['quantity'] as int;
            final String name = i['name'] as String? ?? 'Producto';
            final int prodId = int.tryParse(i['productId'].toString()) ?? 0;
            if (currentStock != null && minStock != null) {
              final newStock = currentStock - quantity;
              if (newStock < minStock) {
                await NotificationService.showLowStockNotification(
                  id: prodId,
                  name: name,
                  stock: newStock,
                  minStock: minStock,
                );
              }
            }
          }
        }

        // Recargar transacciones para tener el listado al día
        await fetchTransactions(force: true);
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
        await fetchConfigData(force: true);
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
        await fetchConfigData(force: true);
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
        await fetchConfigData(force: true);
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

  /// Crea un nuevo cliente
  Future<bool> addCustomer(String name, String taxId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final payload = {
        'name': name,
        'taxId': taxId,
      };

      final response = await _apiService.post('/customers', payload, token: token);

      if (response != null) {
        await fetchConfigData(force: true);
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('addCustomer error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Actualiza un cliente existente
  Future<bool> updateCustomer(String id, String name, String taxId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final payload = {
        'name': name,
        'taxId': taxId,
      };

      final response = await _apiService.put('/customers/$id', payload, token: token);

      if (response != null) {
        await fetchConfigData(force: true);
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('updateCustomer error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Elimina un cliente
  Future<bool> deleteCustomer(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final response = await _apiService.delete('/customers/$id', token: token);

      if (response != null) {
        await fetchConfigData(force: true);
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('deleteCustomer error: $e');
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
        await fetchConfigData(force: true);
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
        await fetchConfigData(force: true);
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
        await fetchConfigData(force: true);
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
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOffline = connectivityResult.contains(ConnectivityResult.none);

      final payload = {
        'fromWarehouseId': fromWarehouseId,
        'toWarehouseId': toWarehouseId,
        'observations': observations,
        'items': items,
        'userId': userId,
      };

      if (isOffline) {
        await OfflineDbService.insertOfflineTransaction('TRANSFER', payload);
        _lastTransferOffline = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _lastTransferOffline = false;
      final token = await _authService.getToken();
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

  /// Sincroniza las transacciones guardadas localmente cuando vuelve la conexión
  Future<void> syncOfflineTransactions() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return;

    final pending = await OfflineDbService.getPendingTransactions();
    if (pending.isEmpty) return;

    final token = await _authService.getToken();

    for (var tx in pending) {
      final id = tx['id'] as int;
      final type = tx['type'] as String;
      final payload = Map<String, dynamic>.from(jsonDecode(tx['payload'] as String));

      try {
        if (type == 'TRANSACTION') {
          final response = await _apiService.post('/transactions', payload, token: token);
          if (response != null) {
            await OfflineDbService.deleteTransaction(id);
            const androidDetails = AndroidNotificationDetails(
              'sync_channel',
              'Sincronización',
              channelDescription: 'Notifica la sincronización exitosa offline',
              importance: Importance.max,
              priority: Priority.high,
              color: Color(0xFF4CAF50),
            );
            final details = const NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
            final flutterNotifications = FlutterLocalNotificationsPlugin();
            await flutterNotifications.show(
              id,
              '🔄 Sincronización Exitosa',
              'Una transacción guardada offline (${payload['type']}) fue enviada con éxito al servidor.',
              details,
            );
          }
        } else if (type == 'TRANSFER') {
          final response = await _apiService.post('/transfers', payload, token: token);
          if (response != null) {
            await OfflineDbService.deleteTransaction(id);
            const androidDetails = AndroidNotificationDetails(
              'sync_channel',
              'Sincronización',
              channelDescription: 'Notifica la sincronización exitosa offline',
              importance: Importance.max,
              priority: Priority.high,
              color: Color(0xFF4CAF50),
            );
            final details = const NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
            final flutterNotifications = FlutterLocalNotificationsPlugin();
            await flutterNotifications.show(
              id,
              '🔄 Transferencia Sincronizada',
              'Una transferencia offline entre almacenes se sincronizó correctamente.',
              details,
            );
          }
        }
      } catch (e) {
        print('Error syncing offline transaction $id: $e');
        break;
      }
    }

    await fetchTransactions();
    await fetchTransfers();
    notifyListeners();
  }
}

