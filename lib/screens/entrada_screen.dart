import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/product_provider.dart';
import '../utils/routes.dart';
import '../utils/app_colors.dart';
import '../widgets/transaction_detail_sheet.dart';

class EntradaScreen extends StatefulWidget {
  const EntradaScreen({super.key});

  @override
  State<EntradaScreen> createState() => _EntradaScreenState();
}

class _EntradaScreenState extends State<EntradaScreen> {
  final int _selectedIndex = 2;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _sortOption = 'Recientes';
  int _currentPage = 1;
  static const int _itemsPerPage = 5;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlurOrb(AppColors.moradoPrincipal.withOpacity(isDark ? 0.15 : 0.05), 300),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _buildBlurOrb(AppColors.azulPrincipal.withOpacity(isDark ? 0.1 : 0.05), 250),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildMiniDashboard(context),
                        const SizedBox(height: 25),
                        _buildActionButton(context),
                        const SizedBox(height: 20),
                        _buildSearchBar(context),
                        const SizedBox(height: 25),
                        _buildSectionTitle('Entradas recientes', context),
                        const SizedBox(height: 15),
                        _buildEntradasList(context),
                        const SizedBox(height: 20),
                        _buildFooterSummary(context),
                        _buildEntradasBreakdown(context),
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
      bottomNavigationBar: _buildSnakeNavBar(context),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildCircleIconButton(context, Icons.arrow_back_rounded, onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.dashboard)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Entradas', style: TextStyle(color: AppColors.getTextColor(context), fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Registra y gestiona los ingresos', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 13)),
              ],
            ),
          ),
          _buildCircleIconButton(
            context, 
            isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round, 
            iconColor: isDark ? Colors.amberAccent : Colors.orangeAccent,
            onTap: () => themeProvider.toggleTheme(),
          ),
          const SizedBox(width: 10),
          _buildCircleIconButton(
            context, 
            Icons.bar_chart_rounded, 
            iconColor: AppColors.moradoPrincipal,
            onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton(BuildContext context, IconData icon, {VoidCallback? onTap, Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context), 
          shape: BoxShape.circle, 
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.getTextColor(context), size: 22),
      ),
    );
  }

  List<double> _calculateWeeklyStats(List<Map<String, dynamic>> entries) {
    List<double> dayTotals = List.filled(7, 0.0);
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday; 
    DateTime startOfWeek = now.subtract(Duration(days: currentWeekday - 1));
    startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    for (var entry in entries) {
      DateTime dt = DateTime.tryParse(entry['transactionDate'].toString()) ?? DateTime.now();
      if (dt.isAfter(startOfWeek) || dt.isAtSameMomentAs(startOfWeek)) {
        int dayIndex = dt.weekday - 1;
        double amount = (entry['totalAmount'] as num?)?.toDouble() ?? 0.0;
        dayTotals[dayIndex] += amount; // We can use total amount or count. Let's use count for activity or total amount. Let's use count.
        // Or wait, let's use count of entries as bars
        dayTotals[dayIndex] += 1;
      }
    }

    double maxVal = dayTotals.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return List.filled(7, 0.1);

    return dayTotals.map((val) => (val / maxVal).clamp(0.1, 1.0)).toList();
  }

  Widget _buildMiniDashboard(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final stats = _calculateWeeklyStats(inventoryProvider.entries);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Resumen Semanal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Icon(Icons.trending_up_rounded, color: Colors.greenAccent, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(stats[0], 'L'),
                _buildBar(stats[1], 'M'),
                _buildBar(stats[2], 'M'),
                _buildBar(stats[3], 'J'),
                _buildBar(stats[4], 'V'),
                _buildBar(stats[5], 'S'),
                _buildBar(stats[6], 'D'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat('Total', '${Provider.of<InventoryProvider>(context).entries.length}', Colors.blueAccent),
              _miniStat('Valor', '\$${Provider.of<InventoryProvider>(context).entries.fold(0.0, (sum, e) => sum + ((e['totalAmount'] as num?)?.toDouble() ?? 0.0)).toStringAsFixed(0)}', AppColors.moradoPrincipal),
              _miniStat('Prov.', '${Provider.of<InventoryProvider>(context).suppliers.length}', Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double heightFactor, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 8,
          height: 60 * heightFactor,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.moradoPrincipal, AppColors.azulPrincipal.withOpacity(0.5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.grisTexto, fontSize: 10)),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: TextStyle(color: AppColors.grisTexto, fontSize: 10)),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.addEntry),
      child: Container(
        width: double.infinity, height: 55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.moradoPrincipal, Color(0xFF6A11CB)]),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: AppColors.moradoPrincipal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.white),
              SizedBox(width: 8),
              Text('Nueva entrada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50, padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: AppColors.getCardColor(context), 
              borderRadius: BorderRadius.circular(15), 
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.getSubtextColor(context), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                        _currentPage = 1;
                      });
                    },
                    style: TextStyle(color: AppColors.getTextColor(context), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar entradas...',
                      hintStyle: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        PopupMenuButton<String>(
          onSelected: (val) {
            setState(() {
              _sortOption = val;
              _currentPage = 1;
            });
          },
          color: AppColors.getCardColor(context),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Recientes', child: Text('Recientes', style: TextStyle(color: Colors.white))),
            const PopupMenuItem(value: 'Antiguas', child: Text('Más Antiguas', style: TextStyle(color: Colors.white))),
            const PopupMenuItem(value: 'Mayor Monto', child: Text('Mayor Monto', style: TextStyle(color: Colors.white))),
            const PopupMenuItem(value: 'Menor Monto', child: Text('Menor Monto', style: TextStyle(color: Colors.white))),
          ],
          child: Container(
            height: 50, width: 50,
            decoration: BoxDecoration(
              color: AppColors.getCardColor(context), 
              borderRadius: BorderRadius.circular(15), 
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Icon(Icons.tune_rounded, color: AppColors.getSubtextColor(context), size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: AppColors.getTextColor(context), fontSize: 18, fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.allEntries),
          child: const Text('Ver todas', style: TextStyle(color: AppColors.moradoPrincipal, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildEntradasList(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);

    if (inventoryProvider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.moradoPrincipal));
    }

    var filteredEntries = List<Map<String, dynamic>>.from(inventoryProvider.entries);
    if (_searchQuery.isNotEmpty) {
      filteredEntries = filteredEntries.where((tx) {
        final pNames = (tx['items'] as List?)?.map((i) => i['productName']).join(', ').toLowerCase() ?? '';
        final prov = (tx['supplierName']?.toString().toLowerCase() ?? '');
        return pNames.contains(_searchQuery) || prov.contains(_searchQuery);
      }).toList();
    }

    // Sort entries based on _sortOption
    filteredEntries.sort((a, b) {
      if (_sortOption == 'Mayor Monto' || _sortOption == 'Menor Monto') {
        final amtA = (a['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final amtB = (b['totalAmount'] as num?)?.toDouble() ?? 0.0;
        return _sortOption == 'Mayor Monto' ? amtB.compareTo(amtA) : amtA.compareTo(amtB);
      } else {
        final dateA = DateTime.tryParse(a['transactionDate']?.toString() ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['transactionDate']?.toString() ?? '') ?? DateTime.now();
        return _sortOption == 'Antiguas' ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      }
    });

    if (filteredEntries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text('No hay entradas registradas.', style: TextStyle(color: Colors.white54)),
      );
    }

    final int totalItems = filteredEntries.length;
    final int totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    }

    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage) > totalItems ? totalItems : (startIndex + _itemsPerPage);

    final paginatedEntries = filteredEntries.sublist(startIndex, endIndex);

    return Column(
      children: [
        // Rango de items
        Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mostrando ${startIndex + 1}-$endIndex de $totalItems entradas',
                style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12),
              ),
              Text(
                'Pág. $_currentPage de $totalPages',
                style: const TextStyle(color: AppColors.moradoPrincipal, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // Items de entradas
        ...paginatedEntries.map((tx) {
          final pNames = (tx['items'] as List?)?.map((i) => i['productName']).join(', ') ?? 'Varios';
          final prov = tx['supplierName'] ?? 'General';
          final val = '\$${((tx['totalAmount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}';
          
          final DateTime dt = tx['transactionDate'] != null 
              ? DateTime.parse(tx['transactionDate'].toString()) 
              : DateTime.now();
          final dateStr = "${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

          return GestureDetector(
            onTap: () => _showTransactionDetails(context, tx, true),
            child: _entradaItem(context, pNames, prov, dateStr, 'Completada', val, Colors.greenAccent),
          );
        }).toList(),

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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _currentPage > 1 ? AppColors.getCardColor(context) : AppColors.getCardColor(context).withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: _currentPage > 1 ? AppColors.getTextColor(context) : AppColors.getSubtextColor(context).withOpacity(0.3),
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
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.moradoPrincipal : AppColors.getCardColor(context),
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? AppColors.moradoPrincipal : Colors.white.withOpacity(0.05)),
                      boxShadow: isSelected ? [BoxShadow(color: AppColors.moradoPrincipal.withOpacity(0.3), blurRadius: 8)] : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$pageNum',
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.getTextColor(context),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _currentPage < totalPages ? AppColors.getCardColor(context) : AppColors.getCardColor(context).withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: _currentPage < totalPages ? AppColors.getTextColor(context) : AppColors.getSubtextColor(context).withOpacity(0.3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _entradaItem(BuildContext context, String name, String prov, String date, String status, String value, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context), 
        borderRadius: BorderRadius.circular(22), 
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.download_rounded, color: statusColor, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                Text(prov, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11)),
                Text(date, style: TextStyle(color: AppColors.getSubtextColor(context).withOpacity(0.5), fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(status, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(width: 5),
          const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildFooterSummary(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final count = inventoryProvider.entries.length;
    final total = inventoryProvider.entries.fold(0.0, (sum, e) => sum + ((e['totalAmount'] as num?)?.toDouble() ?? 0.0));

    return GestureDetector(
      onTap: () => _showAnalyticsSummary(context, true),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context), 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_graph_rounded, color: AppColors.moradoPrincipal, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total registrado', style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('$count entradas', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12)),
                ],
              ),
            ),
            Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.moradoPrincipal, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildEntradasBreakdown(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final transactions = inventoryProvider.entries;
    final totalAmount = transactions.fold(0.0, (sum, e) => sum + ((e['totalAmount'] as num?)?.toDouble() ?? 0.0));
    final count = transactions.length;
    final avgAmount = count > 0 ? totalAmount / count : 0.0;

    if (transactions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen Analítico Rápido',
            style: TextStyle(color: AppColors.getTextColor(context), fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _miniStatBox(context, 'Movimientos', '$count regs', Colors.greenAccent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStatBox(context, 'Promedio Operado', '\$${avgAmount.toStringAsFixed(2)}', AppColors.moradoPrincipal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStatBox(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getBackgroundColor(context).withOpacity(0.4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSnakeNavBar(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double itemWidth = (width - 40) / 5;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 75,
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context).withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            left: (_selectedIndex * itemWidth) + (itemWidth / 2) - 28,
            top: 10,
            child: Container(
              width: 56, height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.moradoPrincipal.withOpacity(0.5), width: 1.5),
                boxShadow: [BoxShadow(color: AppColors.moradoPrincipal.withOpacity(0.15), blurRadius: 10, spreadRadius: 1)],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            left: (_selectedIndex * itemWidth) + (itemWidth / 2) - 2.5,
            bottom: 8,
            child: Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.moradoPrincipal, shape: BoxShape.circle)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navBtn(context, 0, Icons.home_rounded, 'Inicio'),
              _navBtn(context, 1, Icons.inventory_2_rounded, 'Producto'),
              _navBtn(context, 2, Icons.download_rounded, 'Entrada'),
              _navBtn(context, 3, Icons.upload_rounded, 'Salidas'),
              _navBtn(context, 4, Icons.settings_rounded, 'Ajustes'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navBtn(BuildContext context, int i, IconData ico, String lab) {
    bool act = _selectedIndex == i;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (i == 0) Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          else if (i == 1) Navigator.pushReplacementNamed(context, AppRoutes.products);
          else if (i == 3) Navigator.pushReplacementNamed(context, AppRoutes.exits);
          else if (i == 4) Navigator.pushReplacementNamed(context, AppRoutes.settings);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ico, color: act ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.moradoPrincipal) : AppColors.getSubtextColor(context), size: 24),
            const SizedBox(height: 4),
            Text(lab, style: TextStyle(color: act ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.moradoPrincipal) : AppColors.getSubtextColor(context), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, Map<String, dynamic> tx, bool isEntrada) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return TransactionDetailSheet(tx: tx, isEntrada: isEntrada);
      },
    );
  }

  void _showAnalyticsSummary(BuildContext context, bool isEntrada) {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final transactions = isEntrada ? inventoryProvider.entries : inventoryProvider.exits;
    final totalAmount = transactions.fold(0.0, (sum, e) => sum + ((e['totalAmount'] as num?)?.toDouble() ?? 0.0));
    final count = transactions.length;
    final avgAmount = count > 0 ? totalAmount / count : 0.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.getCardColor(context).withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEntrada ? 'Análisis de Entradas' : 'Análisis de Salidas',
                      style: TextStyle(color: AppColors.getTextColor(context), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.analytics_rounded, color: AppColors.moradoPrincipal),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white10),
                const SizedBox(height: 15),
                
                Row(
                  children: [
                    Expanded(
                      child: _analyticKpiBox(
                        context, 
                        'Total Registrado', 
                        '\$${totalAmount.toStringAsFixed(0)}', 
                        isEntrada ? Colors.greenAccent : Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _analyticKpiBox(
                        context, 
                        'Movimientos', 
                        '$count registros', 
                        AppColors.azulPrincipal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _analyticKpiBox(
                        context, 
                        'Promedio', 
                        '\$${avgAmount.toStringAsFixed(0)}', 
                        AppColors.moradoPrincipal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                Text(
                  'Volumen Operacional Semanal',
                  style: TextStyle(color: AppColors.getTextColor(context), fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                
                _weeklyFlowVisualization(context, transactions, isEntrada),
                const SizedBox(height: 25),
                
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.reports);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.moradoPrincipal, AppColors.azulPrincipal]),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.moradoPrincipal.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Ver Centro Analítico Completo',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _analyticKpiBox(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.02 : 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 9)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _weeklyFlowVisualization(BuildContext context, List<Map<String, dynamic>> txs, bool isEntrada) {
    final stats = _calculateWeeklyStats(txs);
    final days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isDark ? 0.01 : 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final double h = stats[index];
          return Column(
            children: [
              Text('${(h * 10).toStringAsFixed(0)}', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 8)),
              const SizedBox(height: 4),
              Container(
                width: 12,
                height: 80 * h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isEntrada 
                      ? [AppColors.moradoPrincipal, Colors.greenAccent]
                      : [Colors.orangeAccent, Colors.redAccent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Text(days[index], style: TextStyle(color: AppColors.getTextColor(context), fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          );
        }),
      ),
    );
  }
}

