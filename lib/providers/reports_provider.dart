import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ReportsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _summaryData;
  bool _isLoading = false;
  String? _errorMessage;

  String _selectedPeriod = 'Mes'; // 'Hoy', 'Semana', 'Mes', 'Año', 'Personalizado'
  DateTimeRange? _customRange;

  Map<String, dynamic>? get summaryData => _summaryData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedPeriod => _selectedPeriod;
  DateTimeRange? get customRange => _customRange;

  void setPeriod(String period, {DateTimeRange? range}) {
    _selectedPeriod = period;
    if (period == 'Personalizado' && range != null) {
      _customRange = range;
    } else {
      _customRange = null;
    }
    notifyListeners();
    fetchSummaryReport();
  }

  /// Calcula el rango de fechas de acuerdo al periodo seleccionado
  Map<String, String> _getDateRangeParams() {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    if (_selectedPeriod == 'Hoy') {
      start = DateTime(now.year, now.month, now.day);
    } else if (_selectedPeriod == 'Semana') {
      start = now.subtract(const Duration(days: 7));
    } else if (_selectedPeriod == 'Año') {
      start = DateTime(now.year, 1, 1);
    } else if (_selectedPeriod == 'Personalizado' && _customRange != null) {
      start = _customRange!.start;
      end = _customRange!.end;
    } else {
      // Por defecto: 'Mes'
      start = now.subtract(const Duration(days: 30));
    }

    return {
      'startDate': start.toIso8601String(),
      'endDate': end.toIso8601String(),
    };
  }

  /// Consume el endpoint analítico GET /api/reports/summary
  Future<void> fetchSummaryReport() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final dateParams = _getDateRangeParams();
      
      final query = '?startDate=${dateParams['startDate']}&endDate=${dateParams['endDate']}';
      final response = await _apiService.get('/reports/summary$query', token: token);

      if (response != null && response is Map<String, dynamic>) {
        _summaryData = response;
      } else {
        _summaryData = null;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('fetchSummaryReport error: $e');
      _summaryData = null;
      notifyListeners();
    }
  }

  /// Registra la auditoría de exportación en POST /api/reports/audit
  Future<bool> logExportAudit(String reportType, String format) async {
    try {
      final token = await _authService.getToken();
      final payload = {
        'userId': 1, // Por defecto Admin en esta versión
        'reportType': reportType,
        'exportFormat': format
      };
      
      final response = await _apiService.post('/reports/audit', payload, token: token);
      return response != null;
    } catch (e) {
      print('logExportAudit error: $e');
      return false;
    }
  }

  /// Genera contenido en formato CSV
  String generateCsvContent(String reportType) {
    if (_summaryData == null) return 'No hay datos disponibles';
    final StringBuffer buffer = StringBuffer();

    if (reportType == 'Inventario' || reportType == 'Completo') {
      buffer.writeln('REPORTES DE INVENTARIO - ERP');
      buffer.writeln('Generado el:,${DateTime.now().toIso8601String()}');
      buffer.writeln('Periodo:,$_selectedPeriod');
      buffer.writeln();
      buffer.writeln('Resumen Ejecutivo');
      final exec = _summaryData!['executiveSummary'];
      buffer.writeln('Valor Total Inventario:,\$${exec['totalInventoryValue']}');
      buffer.writeln('Total Productos:,${exec['totalProducts']}');
      buffer.writeln('Total Almacenes:,${exec['totalWarehouses']}');
      buffer.writeln('Total Proveedores:,${exec['totalSuppliers']}');
      buffer.writeln();
      buffer.writeln('Distribución de Stock');
      final stock = _summaryData!['stockDistribution'];
      buffer.writeln('Normal:,${stock['normal']}');
      buffer.writeln('Bajo:,${stock['bajo']}');
      buffer.writeln('Critico:,${stock['critico']}');
      buffer.writeln('Agotado:,${stock['agotado']}');
      buffer.writeln();
    }

    if (reportType == 'Movimientos' || reportType == 'Completo') {
      buffer.writeln('REPORTES DE MOVIMIENTOS');
      buffer.writeln('Tipo de Movimiento,Volumen del Período');
      final vol = _summaryData!['movementsVolume'];
      buffer.writeln('Entradas,${vol['ENTRADA'] ?? 0}');
      buffer.writeln('Salidas,${vol['SALIDA'] ?? 0}');
      buffer.writeln('Transferencias,${vol['TRANSFERENCIA'] ?? 0}');
      buffer.writeln();
    }

    if (reportType == 'Productos' || reportType == 'Completo') {
      buffer.writeln('REPORTES DE PRODUCTOS - TOP 5 VALORACIÓN');
      buffer.writeln('Nombre,SKU,Valor Total');
      final tops = _summaryData!['productMetrics']?['highestValued'] as List? ?? [];
      for (var p in tops) {
        buffer.writeln('"${p['name']}",${p['sku']},\$${p['value']}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
