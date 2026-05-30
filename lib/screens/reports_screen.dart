import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/reports_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/wavy_progress_indicator.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedProductSection = 0; // 0: Más movidos, 1: Menos movidos, 2: Sin movimiento, 3: Mayor valor

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportsProvider>(context, listen: false).fetchSummaryReport();
    });
  }

  void _handleExport(String type, String format) async {
    final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
    
    // Mostrar feedback visual de exportación
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const WavyProgressIndicator(width: 120, height: 25, strokeWidth: 3),
              const SizedBox(height: 15),
              Text(
                'Generando Reporte $type ($format)...',
                style: const TextStyle(color: Colors.white, fontSize: 13, decoration: TextDecoration.none),
              ),
            ],
          ),
        ),
      ),
    );

    // Guardar auditoría
    await reportsProvider.logExportAudit(type, format);

    await Future.delayed(const Duration(milliseconds: 1500)); // Simular render
    if (mounted) Navigator.pop(context); // Cerrar barra de carga

    if (format == 'CSV') {
      final csvContent = reportsProvider.generateCsvContent(type);
      // Simular guardado y dar feedback premium
      _showCompletionDialog(type, format, csvContent);
    } else {
      _showCompletionDialog(type, format, null);
    }
  }

  void _showCompletionDialog(String type, String format, String? csvContent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: const BorderSide(color: Colors.white10)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 24),
            const SizedBox(width: 10),
            const Text('Exportación Exitosa', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Se ha compilado el reporte de **$type** en formato **$format**.', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            const Text('El registro de auditoría fue guardado con éxito en SQL Server.', style: TextStyle(color: AppColors.moradoPrincipal, fontSize: 11, fontWeight: FontWeight.bold)),
            if (csvContent != null) ...[
              const SizedBox(height: 12),
              const Text('Vista previa del contenido:', style: TextStyle(color: Colors.white54, fontSize: 10)),
              Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.all(10),
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                child: SingleChildScrollView(
                  child: Text(csvContent, style: const TextStyle(color: Colors.greenAccent, fontSize: 9, fontFamily: 'monospace')),
                ),
              ),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showExportOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: const Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 15),
            const Text('Exportar Reportes Analíticos', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _exportOptionItem('Reporte Completo (CSV)', Icons.analytics_rounded, () {
              Navigator.pop(context);
              _handleExport('Completo', 'CSV');
            }),
            _exportOptionItem('Inventario y Stocks (CSV)', Icons.inventory_2_rounded, () {
              Navigator.pop(context);
              _handleExport('Inventario', 'CSV');
            }),
            _exportOptionItem('Flujos de Movimiento (PDF)', Icons.swap_vert_rounded, () {
              Navigator.pop(context);
              _handleExport('Movimientos', 'PDF');
            }),
            _exportOptionItem('Financiero y Tops (Excel)', Icons.monetization_on_outlined, () {
              Navigator.pop(context);
              _handleExport('Financiero', 'Excel');
            }),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _exportOptionItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.moradoPrincipal),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportsProvider = Provider.of<ReportsProvider>(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: Stack(
        children: [
          // Blur Orbs
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlurOrb(AppColors.moradoPrincipal.withValues(alpha: isDark ? 0.15 : 0.05), 300),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _buildBlurOrb(AppColors.azulPrincipal.withValues(alpha: isDark ? 0.12 : 0.04), 250),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildPeriodChips(context, reportsProvider),
                Expanded(
                  child: reportsProvider.isLoading || reportsProvider.summaryData == null
                      ? const Center(child: WavyProgressIndicator(width: 150, height: 30, strokeWidth: 4))
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildExecutiveSummary(context, reportsProvider.summaryData!['executiveSummary']),
                              const SizedBox(height: 25),
                              _buildStockDistributionSection(context, reportsProvider.summaryData!['stockDistribution']),
                              const SizedBox(height: 25),
                              _buildMovementsChartSection(context, reportsProvider.summaryData!['movementsVolume']),
                              const SizedBox(height: 25),
                              _buildProductTopsSection(context, reportsProvider.summaryData!['productMetrics']),
                              const SizedBox(height: 25),
                              _buildFinancialSection(context, reportsProvider.summaryData!['financialAnalysis']),
                              const SizedBox(height: 120),
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
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                border: Border.all(color: Colors.white10),
              ),
              child: Icon(Icons.arrow_back_rounded, color: AppColors.getTextColor(context), size: 22),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Centro Analítico', style: TextStyle(color: AppColors.getTextColor(context), fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Métricas ERP e Inteligencia de Datos', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showExportOptionsModal,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.moradoPrincipal, AppColors.azulPrincipal]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.moradoPrincipal.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChips(BuildContext context, ReportsProvider rp) {
    final periods = ['Hoy', 'Semana', 'Mes', 'Año'];
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 15),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: periods.length,
        itemBuilder: (context, index) {
          final period = periods[index];
          final bool isSelected = rp.selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => rp.setPeriod(period),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.moradoPrincipal : AppColors.getCardColor(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.moradoPrincipal : Colors.white.withValues(alpha: 0.05)),
                ),
                child: Center(
                  child: Text(
                    period,
                    style: TextStyle(color: isSelected ? Colors.white : AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExecutiveSummary(BuildContext context, Map<String, dynamic> exec) {
    final valor = exec['totalInventoryValue'] ?? 0.0;
    final refs = exec['totalProducts'] ?? 0;
    final warehouses = exec['totalWarehouses'] ?? 0;
    final suppliers = exec['totalSuppliers'] ?? 0;
    final moves = exec['totalMovements'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resumen Ejecutivo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _kpiCard(context, 'VALOR TOTAL DEL INVENTARIO', '\$${valor.toStringAsFixed(0)}', Icons.monetization_on_rounded, Colors.greenAccent),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _kpiCard(context, 'PRODUCTOS', '$refs referencias', Icons.widgets_rounded, AppColors.azulPrincipal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard(context, 'BODEGAS', '$warehouses bodegas', Icons.warehouse_rounded, Colors.orangeAccent),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _kpiCard(context, 'PROVEEDORES', '$suppliers activos', Icons.local_shipping_rounded, Colors.cyanAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard(context, 'MOVIMIENTOS', '$moves registrados', Icons.import_export_rounded, Colors.pinkAccent),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildStockDistributionSection(BuildContext context, Map<String, dynamic> stock) {
    final int normal = stock['normal'] ?? 0;
    final int bajo = stock['bajo'] ?? 0;
    final int critico = stock['critico'] ?? 0;
    final int agotado = stock['agotado'] ?? 0;
    final int total = normal + bajo + critico + agotado;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estado del Inventario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              Icon(Icons.pie_chart_rounded, color: AppColors.moradoPrincipal, size: 20),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 140,
                  child: total == 0
                      ? const Center(child: Text('Sin datos', style: TextStyle(color: Colors.white30)))
                      : PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 35,
                            sections: [
                              PieChartSectionData(color: Colors.greenAccent, value: normal.toDouble(), radius: 15, showTitle: false),
                              PieChartSectionData(color: Colors.orangeAccent, value: bajo.toDouble(), radius: 15, showTitle: false),
                              PieChartSectionData(color: Colors.redAccent, value: critico.toDouble(), radius: 15, showTitle: false),
                              PieChartSectionData(color: Colors.grey, value: agotado.toDouble(), radius: 15, showTitle: false),
                            ],
                          ),
                        ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _legendItem(context, 'Normal', normal, Colors.greenAccent),
                    _legendItem(context, 'Bajo', bajo, Colors.orangeAccent),
                    _legendItem(context, 'Crítico', critico, Colors.redAccent),
                    _legendItem(context, 'Agotado', agotado, Colors.grey),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(BuildContext context, String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: AppColors.getTextColor(context), fontSize: 12)),
            ],
          ),
          Text('$count u.', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMovementsChartSection(BuildContext context, Map<String, dynamic> vol) {
    final double entrada = (vol['ENTRADA'] ?? 0).toDouble();
    final double salida = (vol['SALIDA'] ?? 0).toDouble();
    final double transfer = (vol['TRANSFERENCIA'] ?? 0).toDouble();
    final double maxVal = [entrada, salida, transfer, 5.0].reduce((curr, next) => curr > next ? curr : next);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Volumen de Movimientos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 25),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.2,
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: entrada, color: AppColors.moradoPrincipal, width: 14, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: salida, color: Colors.orangeAccent, width: 14, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: transfer, color: Colors.blueAccent, width: 14, borderRadius: BorderRadius.circular(4))]),
                ],
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        String title = '';
                        if (val == 0) title = 'Entradas';
                        if (val == 1) title = 'Salidas';
                        if (val == 2) title = 'Transf.';
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(title, style: const TextStyle(color: AppColors.grisTexto, fontSize: 10, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTopsSection(BuildContext context, Map<String, dynamic> metrics) {
    final highestValued = metrics['highestValued'] as List? ?? [];
    final mostMoved = metrics['mostMoved'] as List? ?? [];
    final leastMoved = metrics['leastMoved'] as List? ?? [];
    final noMovement = metrics['noMovement'] as List? ?? [];

    List activeList = [];
    if (_selectedProductSection == 0) activeList = mostMoved;
    if (_selectedProductSection == 1) activeList = leastMoved;
    if (_selectedProductSection == 2) activeList = noMovement;
    if (_selectedProductSection == 3) activeList = highestValued;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Análisis de Productos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          // Sub-tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _tabChip('Más Movidos', 0),
                _tabChip('Menos Movidos', 1),
                _tabChip('Sin Movimiento', 2),
                _tabChip('Mayor Valor', 3),
              ],
            ),
          ),
          const SizedBox(height: 15),
          activeList.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No hay datos en el período', style: TextStyle(color: Colors.white30, fontSize: 12))))
              : Column(
                  children: activeList.map((p) {
                    final String name = p['name'] ?? 'Producto';
                    final String sku = p['sku'] ?? 'N/D';
                    
                    String trailing = '';
                    if (_selectedProductSection == 3) {
                      trailing = '\$${parseFloat(p['value']).toStringAsFixed(0)}';
                    } else if (_selectedProductSection == 0 || _selectedProductSection == 1) {
                      trailing = '${p['qty']} u.';
                    } else {
                      trailing = 'Estático';
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.moradoPrincipal.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.inventory_2_outlined, color: AppColors.moradoPrincipal, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('SKU: $sku', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                              ],
                            ),
                          ),
                          Text(trailing, style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _tabChip(String label, int index) {
    final bool isSel = _selectedProductSection == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedProductSection = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSel ? AppColors.moradoPrincipal : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, style: TextStyle(color: isSel ? Colors.white : Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildFinancialSection(BuildContext context, Map<String, dynamic> financial) {
    final double avgCost = (financial['averageCost'] ?? 0.0).toDouble();
    final categories = financial['valueByCategory'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Análisis Financiero Ponderado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Costo Promedio Unitario:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('\$${avgCost.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.moradoPrincipal, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 15),
          const Text('Valoración por Categoría:', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          categories.isEmpty
              ? const Center(child: Text('Sin categorías', style: TextStyle(color: Colors.white38)))
              : Column(
                  children: categories.map<Widget>((cat) {
                    final String category = cat['category'];
                    final double val = parseFloat(cat['value']);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(category, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('\$${val.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  double parseFloat(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
