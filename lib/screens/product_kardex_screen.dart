import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import '../models/product_model.dart';
import '../models/kardex_model.dart';
import '../utils/app_colors.dart';

class ProductKardexScreen extends StatefulWidget {
  const ProductKardexScreen({super.key});

  @override
  State<ProductKardexScreen> createState() => _ProductKardexScreenState();
}

class _ProductKardexScreenState extends State<ProductKardexScreen> {
  String _activeFilter = 'Mes'; // 'Hoy' | 'Semana' | 'Mes' | 'Rango'
  DateTimeRange? _selectedDateRange;
  List<KardexModel> _allMovements = [];
  List<KardexModel> _filteredMovements = [];
  bool _initialized = false;
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _allMovements = args['kardex'] as List<KardexModel>;
      _currentPage = 1;
      _applyFilter();
      _initialized = true;
    }
  }

  void _applyFilter() {
    final now = DateTime.now();
    DateTime startLimit = now.subtract(const Duration(days: 30)); // default Month

    if (_activeFilter == 'Hoy') {
      startLimit = DateTime(now.year, now.month, now.day);
    } else if (_activeFilter == 'Semana') {
      startLimit = now.subtract(const Duration(days: 7));
    } else if (_activeFilter == 'Mes') {
      startLimit = now.subtract(const Duration(days: 30));
    }

    setState(() {
      _currentPage = 1;
      if (_activeFilter == 'Rango' && _selectedDateRange != null) {
        _filteredMovements = _allMovements.where((m) {
          return m.date.isAfter(_selectedDateRange!.start.subtract(const Duration(seconds: 1))) &&
              m.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
        }).toList();
      } else {
        _filteredMovements = _allMovements.where((m) => m.date.isAfter(startLimit)).toList();
      }
    });
  }

  Future<void> _selectCustomRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(nowYear() - 5),
      lastDate: DateTime(nowYear() + 1),
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.moradoPrincipal,
              onPrimary: Colors.white,
              surface: AppColors.getCardColor(context),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _activeFilter = 'Rango';
      });
      _applyFilter();
    }
  }

  int nowYear() => DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final product = args['product'] as ProductModel;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Cálculo de estadísticas basadas en la lista filtrada
    int totalEntradas = 0;
    int totalSalidas = 0;
    for (var m in _filteredMovements) {
      if (m.type == 'ENTRADA') {
        totalEntradas += m.quantity;
      } else if (m.type == 'SALIDA') {
        totalSalidas += m.quantity;
      }
    }
    final int currentStock = product.stock;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: Stack(
        children: [
          // Blur Orbs Premium
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlurOrb(AppColors.moradoPrincipal.withValues(alpha: isDark ? 0.12 : 0.04), 300),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _buildBlurOrb(AppColors.azulPrincipal.withValues(alpha: isDark ? 0.1 : 0.03), 250),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, product.name),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterChips(context),
                        const SizedBox(height: 20),
                        
                        _buildKardexChart(context),
                        const SizedBox(height: 20),

                        _buildStatsRow(context, totalEntradas, totalSalidas, currentStock),
                        const SizedBox(height: 25),

                        Text(
                          'Detalle del Libro de Kardex',
                          style: TextStyle(
                            color: AppColors.getTextColor(context),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildKardexTable(context),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String productName) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Icon(Icons.arrow_back_rounded, color: AppColors.getTextColor(context), size: 22),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Libro de Control Físico',
                  style: TextStyle(
                    color: AppColors.getSubtextColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Kardex: $productName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.getTextColor(context),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final filters = ['Hoy', 'Semana', 'Mes'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          ...filters.map((f) {
            final active = _activeFilter == f;
            return GestureDetector(
              onTap: () {
                setState(() => _activeFilter = f);
                _applyFilter();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(colors: [AppColors.moradoPrincipal, Color(0xFF6A11CB)])
                      : null,
                  color: active ? null : AppColors.getCardColor(context),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: active ? Colors.transparent : Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.getSubtextColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: _selectCustomRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: _activeFilter == 'Rango'
                    ? const LinearGradient(colors: [AppColors.moradoPrincipal, Color(0xFF6A11CB)])
                    : null,
                color: _activeFilter == 'Rango' ? null : AppColors.getCardColor(context),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _activeFilter == 'Rango' ? Colors.transparent : Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: _activeFilter == 'Rango' ? Colors.white : AppColors.getSubtextColor(context),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _activeFilter == 'Rango' && _selectedDateRange != null
                        ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}'
                        : 'Personalizado',
                    style: TextStyle(
                      color: _activeFilter == 'Rango' ? Colors.white : AppColors.getSubtextColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildKardexChart(BuildContext context) {
    if (_filteredMovements.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart_rounded, color: AppColors.getSubtextColor(context).withValues(alpha: 0.3), size: 40),
              const SizedBox(height: 10),
              Text(
                'Datos insuficientes para graficar en este rango',
                style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Convertir movimientos ordenados a puntos de gráfico
    final List<FlSpot> spots = [];
    double minStockValue = 9999.0;
    double maxStockValue = 0.0;
    
    for (int i = 0; i < _filteredMovements.length; i++) {
      final stockVal = _filteredMovements[i].runningStock.toDouble();
      spots.add(FlSpot(i.toDouble(), stockVal));
      if (stockVal < minStockValue) minStockValue = stockVal;
      if (stockVal > maxStockValue) maxStockValue = stockVal;
    }

    // Si solo hay un punto, duplicarlo para dibujar una línea estable
    if (spots.length == 1) {
      spots.add(FlSpot(1.0, spots[0].y));
    }

    final double verticalPadding = (maxStockValue - minStockValue) * 0.15;
    final double minY = (minStockValue - verticalPadding).clamp(0, double.infinity);
    final double maxY = maxStockValue + (verticalPadding == 0 ? 5.0 : verticalPadding);

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(10, 25, 20, 10),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1),
          ),
          titlesData: const FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: getLeftTitlesWidget,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: const LinearGradient(colors: [AppColors.moradoPrincipal, AppColors.azulPrincipal]),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: spots.length <= 15,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.moradoPrincipal,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.moradoPrincipal.withValues(alpha: 0.2),
                    AppColors.azulPrincipal.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget getLeftTitlesWidget(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      child: Text(
        value.toInt().toString(),
        style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, int entradas, int salidas, int actual) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'ENTRADAS',
            '+$entradas u.',
            Colors.greenAccent,
            Icons.add_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            context,
            'SALIDAS',
            '-$salidas u.',
            Colors.redAccent,
            Icons.remove_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            context,
            'STOCK ACTUAL',
            '$actual u.',
            AppColors.azulPrincipal,
            Icons.warehouse_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, 
    String label, 
    String value, 
    Color color, 
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.getSubtextColor(context).withValues(alpha: 0.6),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.getTextColor(context),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKardexTable(BuildContext context) {
    if (_filteredMovements.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, color: AppColors.getSubtextColor(context).withValues(alpha: 0.3), size: 40),
            const SizedBox(height: 10),
            Text(
              'No hay transacciones en el periodo seleccionado',
              style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Para la tabla ilustramos de forma descendente (del más nuevo al más viejo)
    final listForTable = List<KardexModel>.from(_filteredMovements.reversed);
    final int totalItems = listForTable.length;
    final int totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    }

    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage) > totalItems ? totalItems : (startIndex + _itemsPerPage);

    final paginatedMovements = listForTable.sublist(startIndex, endIndex);

    return Column(
      children: [
        // Rango de items
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mostrando ${startIndex + 1}-$endIndex de $totalItems movimientos',
                style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11),
              ),
              Text(
                'Pág. $_currentPage de $totalPages',
                style: const TextStyle(color: AppColors.moradoPrincipal, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // Listado de movimientos
        Container(
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: paginatedMovements.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, index) {
              final m = paginatedMovements[index];
              final isEntrada = m.type == 'ENTRADA';

              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tipo Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isEntrada ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (isEntrada ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isEntrada ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                color: isEntrada ? Colors.greenAccent : Colors.redAccent,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                m.type,
                                style: TextStyle(
                                  color: isEntrada ? Colors.greenAccent : Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Stock Resultante (Balance)
                        Row(
                          children: [
                            Text(
                              'Stock: ',
                              style: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.5), fontSize: 11),
                            ),
                            Text(
                              '${m.runningStock} u.',
                              style: TextStyle(
                                color: AppColors.getTextColor(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Cantidad y Precio
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cantidad: ${isEntrada ? "+" : "-"}${m.quantity} u.',
                          style: TextStyle(
                            color: AppColors.getTextColor(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'P.U.: \$${m.unitPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppColors.getSubtextColor(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),

                    // Badge Lote PEPS (solo si tiene lotId)
                    if (m.lotId != null) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6A11CB).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF6A11CB).withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.layers_rounded, color: Color(0xFFB39DDB), size: 10),
                                const SizedBox(width: 4),
                                Text(
                                  'Lote #${m.lotId}',
                                  style: const TextStyle(
                                    color: Color(0xFFB39DDB),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Observaciones
                    if (m.observations.isNotEmpty) ...[
                      Text(
                        'Obs: ${m.observations}',
                        style: TextStyle(
                          color: AppColors.getSubtextColor(context).withValues(alpha: 0.7),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Usuario y fecha
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Por: ${m.userName}',
                          style: TextStyle(
                            color: AppColors.getSubtextColor(context).withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${m.date.day}/${m.date.month}/${m.date.year} ${m.date.hour.toString().padLeft(2, '0')}:${m.date.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: AppColors.getSubtextColor(context).withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),


        // Controles de Paginación
        if (totalPages > 1) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón Anterior
              GestureDetector(
                onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _currentPage > 1 ? AppColors.getCardColor(context) : AppColors.getCardColor(context).withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: _currentPage > 1 ? AppColors.getTextColor(context) : AppColors.getSubtextColor(context).withValues(alpha: 0.3),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 15),

              // Números de Página
              ...List.generate(totalPages, (index) {
                final pageNum = index + 1;
                final bool isSelected = pageNum == _currentPage;

                if (totalPages > 5 && (pageNum - _currentPage).abs() > 1 && pageNum != 1 && pageNum != totalPages) {
                  if (pageNum == 2 || pageNum == totalPages - 1) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text('...', style: TextStyle(color: Colors.white30)),
                    );
                  }
                  return const SizedBox.shrink();
                }

                return GestureDetector(
                  onTap: () => setState(() => _currentPage = pageNum),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.moradoPrincipal : AppColors.getCardColor(context),
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? AppColors.moradoPrincipal : Colors.white.withValues(alpha: 0.05)),
                      boxShadow: isSelected ? [BoxShadow(color: AppColors.moradoPrincipal.withValues(alpha: 0.3), blurRadius: 8)] : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$pageNum',
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.getTextColor(context),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(width: 15),
              // Botón Siguiente
              GestureDetector(
                onTap: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _currentPage < totalPages ? AppColors.getCardColor(context) : AppColors.getCardColor(context).withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: _currentPage < totalPages ? AppColors.getTextColor(context) : AppColors.getSubtextColor(context).withValues(alpha: 0.3),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
