import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../utils/app_colors.dart';
import '../utils/routes.dart';

class SalidaScreen extends StatefulWidget {
  const SalidaScreen({super.key});

  @override
  State<SalidaScreen> createState() => _SalidaScreenState();
}

class _SalidaScreenState extends State<SalidaScreen> {
  final int _selectedIndex = 3;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
            child: _buildBlurOrb(AppColors.azulPrincipal.withValues(alpha: isDark ? 0.15 : 0.05), 300),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _buildBlurOrb(const Color(0xFFFFAB40).withValues(alpha: isDark ? 0.1 : 0.05), 250),
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
                        _buildSectionTitle(context, 'Salidas recientes'),
                        const SizedBox(height: 15),
                        _buildSalidasList(context),
                        const SizedBox(height: 20),
                        _buildFooterSummary(context),
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
                Text('Salidas', style: TextStyle(color: AppColors.getTextColor(context), fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Gestiona y controla las salidas', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 13)),
              ],
            ),
          ),
          _buildCircleIconButton(context, Icons.bar_chart_rounded, iconColor: const Color(0xFFFFAB40)),
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
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.getTextColor(context), size: 22),
      ),
    );
  }

  List<double> _calculateWeeklyStats(List<Map<String, dynamic>> exits) {
    List<double> dayTotals = List.filled(7, 0.0);
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday; 
    DateTime startOfWeek = now.subtract(Duration(days: currentWeekday - 1));
    startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    for (var exitTx in exits) {
      DateTime dt = DateTime.tryParse(exitTx['transactionDate'].toString()) ?? DateTime.now();
      if (dt.isAfter(startOfWeek) || dt.isAtSameMomentAs(startOfWeek)) {
        int dayIndex = dt.weekday - 1;
        dayTotals[dayIndex] += 1; // Count of exits
      }
    }

    double maxVal = dayTotals.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return List.filled(7, 0.1);

    return dayTotals.map((val) => (val / maxVal).clamp(0.1, 1.0)).toList();
  }

  Widget _buildMiniDashboard(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final stats = _calculateWeeklyStats(inventoryProvider.exits);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Flujo de Salidas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Icon(Icons.trending_down_rounded, color: Colors.orangeAccent, size: 20),
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
              _miniStat('Total', '${Provider.of<InventoryProvider>(context).exits.length}', Colors.orangeAccent),
              _miniStat('Valor', '\$${Provider.of<InventoryProvider>(context).exits.fold(0.0, (sum, e) => sum + ((e['totalAmount'] as num?)?.toDouble() ?? 0.0)).toStringAsFixed(0)}', AppColors.moradoPrincipal),
              _miniStat('Clientes', '${Provider.of<InventoryProvider>(context).customers.length}', Colors.greenAccent),
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
            gradient: const LinearGradient(
              colors: [Color(0xFFFFAB40), Color(0xFFFF8A00)],
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
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: AppColors.grisTexto, fontSize: 10)),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.addExit),
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFAB40), Color(0xFFFF8A00)]),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: const Color(0xFFFFAB40).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.white),
              SizedBox(width: 8),
              Text('Nueva salida', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: AppColors.getCardColor(context), 
              borderRadius: BorderRadius.circular(15), 
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                      });
                    },
                    style: TextStyle(color: AppColors.getTextColor(context), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar salidas...',
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
        Container(
          height: 50, width: 50,
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context), 
            borderRadius: BorderRadius.circular(15), 
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Icon(Icons.tune_rounded, color: AppColors.getSubtextColor(context), size: 20),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: AppColors.getTextColor(context), fontSize: 18, fontWeight: FontWeight.bold)),
        const Text('Ver todas', style: TextStyle(color: AppColors.moradoPrincipal, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSalidasList(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);

    if (inventoryProvider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.moradoPrincipal));
    }

    var filteredExits = inventoryProvider.exits;
    if (_searchQuery.isNotEmpty) {
      filteredExits = filteredExits.where((tx) {
        final pNames = (tx['items'] as List?)?.map((i) => i['productName']).join(', ').toLowerCase() ?? '';
        final client = (tx['customerName']?.toString().toLowerCase() ?? '');
        return pNames.contains(_searchQuery) || client.contains(_searchQuery);
      }).toList();
    }

    if (filteredExits.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text('No hay salidas registradas.', style: TextStyle(color: Colors.white54)),
      );
    }

    return Column(
      children: filteredExits.map((tx) {
        final pNames = (tx['items'] as List?)?.map((i) => i['productName']).join(', ') ?? 'Varios';
        final client = tx['customerName'] ?? 'General';
        final val = '\$${((tx['totalAmount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}';
        
        final DateTime dt = tx['transactionDate'] != null 
            ? DateTime.parse(tx['transactionDate'].toString()) 
            : DateTime.now();
        final dateStr = "${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

        return _salidaItem(context, pNames, client, dateStr, 'Completada', val, Colors.greenAccent);
      }).toList(),
    );
  }

  Widget _salidaItem(BuildContext context, String name, String client, String date, String status, String value, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context), 
        borderRadius: BorderRadius.circular(22), 
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFFFAB40).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.upload_rounded, color: Color(0xFFFFAB40), size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                Text(client, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11)),
                Text(date, style: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.6), fontSize: 10)),
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
          Icon(Icons.chevron_right_rounded, color: AppColors.getSubtextColor(context).withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _buildFooterSummary(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final count = inventoryProvider.exits.length;
    final total = inventoryProvider.exits.fold(0.0, (sum, e) => sum + ((e['totalAmount'] as num?)?.toDouble() ?? 0.0));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                Text('$count salidas', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12)),
              ],
            ),
          ),
          Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.moradoPrincipal, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 5),
          Icon(Icons.chevron_right_rounded, color: AppColors.getSubtextColor(context).withValues(alpha: 0.3)),
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
        color: AppColors.getCardColor(context).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1), blurRadius: 20, offset: const Offset(0, 10))],
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
                border: Border.all(color: AppColors.moradoPrincipal.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [BoxShadow(color: AppColors.moradoPrincipal.withValues(alpha: 0.15), blurRadius: 10, spreadRadius: 1)],
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
          else if (i == 2) Navigator.pushReplacementNamed(context, AppRoutes.entries);
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
}
