import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../utils/app_colors.dart';

class ProductLotsScreen extends StatefulWidget {
  const ProductLotsScreen({super.key});

  @override
  State<ProductLotsScreen> createState() => _ProductLotsScreenState();
}

class _ProductLotsScreenState extends State<ProductLotsScreen> {
  String _activeFilter = 'Todos'; // 'Todos' | 'Activos' | 'Agotados'
  List<Map<String, dynamic>> _allLots = [];
  List<Map<String, dynamic>> _filteredLots = [];
  bool _isLoading = true;
  bool _isInit = false;
  late ProductModel _product;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _product = ModalRoute.of(context)!.settings.arguments as ProductModel;
      _loadLots();
      _isInit = true;
    }
  }

  Future<void> _loadLots() async {
    setState(() => _isLoading = true);
    final lots = await Provider.of<ProductProvider>(context, listen: false)
        .fetchProductLots(_product.id ?? '');
    if (mounted) {
      setState(() {
        _allLots = lots;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_activeFilter == 'Activos') {
      _filteredLots = _allLots
          .where((l) => (l['availableQuantity'] as num? ?? 0) > 0)
          .toList();
    } else if (_activeFilter == 'Agotados') {
      _filteredLots = _allLots
          .where((l) => (l['availableQuantity'] as num? ?? 0) == 0)
          .toList();
    } else {
      _filteredLots = List.from(_allLots);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final int totalActive = _allLots
        .where((l) => (l['availableQuantity'] as num? ?? 0) > 0)
        .length;
    final int totalDepleted = _allLots.length - totalActive;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _blurOrb(AppColors.moradoPrincipal.withValues(alpha: isDark ? 0.12 : 0.04), 280),
          ),
          Positioned(
            bottom: 80,
            left: -60,
            child: _blurOrb(AppColors.azulPrincipal.withValues(alpha: isDark ? 0.1 : 0.03), 240),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildStatsBanner(context, totalActive, totalDepleted),
                _buildFilterTabs(context),
                const SizedBox(height: 4),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.moradoPrincipal,
                            strokeWidth: 2,
                          ),
                        )
                      : _filteredLots.isEmpty
                          ? _buildEmptyState(context)
                          : RefreshIndicator(
                              onRefresh: _loadLots,
                              color: AppColors.moradoPrincipal,
                              child: ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                itemCount: _filteredLots.length,
                                itemBuilder: (context, i) =>
                                    _buildLotCard(context, _filteredLots[i], i + 1, isDark),
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

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: AppColors.getTextColor(context), size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lotes PEPS',
                  style: TextStyle(
                    color: AppColors.getSubtextColor(context),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  _product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.getTextColor(context),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _loadLots,
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Icon(Icons.refresh_rounded,
                  color: AppColors.azulPrincipal, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats Banner ─────────────────────────────────────────────────────────
  Widget _buildStatsBanner(BuildContext context, int active, int depleted) {
    final int totalUnits = _allLots.fold(
        0, (s, l) => s + ((l['initialQuantity'] as num?)?.toInt() ?? 0));
    final int availUnits = _allLots.fold(
        0, (s, l) => s + ((l['availableQuantity'] as num?)?.toInt() ?? 0));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.moradoPrincipal.withValues(alpha: 0.15),
            AppColors.azulPrincipal.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.moradoPrincipal.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _bannerStat('Lotes totales', '${_allLots.length}', AppColors.moradoPrincipal),
          _vDivider(),
          _bannerStat('Activos', '$active', Colors.greenAccent),
          _vDivider(),
          _bannerStat('Agotados', '$depleted', Colors.redAccent),
          _vDivider(),
          _bannerStat('Disponible', '$availUnits / $totalUnits u.', AppColors.azulPrincipal),
        ],
      ),
    );
  }

  Widget _bannerStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: AppColors.getSubtextColor(context),
                fontSize: 9,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _vDivider() => Container(width: 1, height: 28, color: Colors.white12);

  // ─── Filter Tabs ───────────────────────────────────────────────────────────
  Widget _buildFilterTabs(BuildContext context) {
    final filters = ['Todos', 'Activos', 'Agotados'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: filters.map((f) {
          final bool active = _activeFilter == f;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _activeFilter = f;
                _applyFilter();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(
                          colors: [AppColors.moradoPrincipal, AppColors.azulPrincipal])
                      : null,
                  color: active ? null : AppColors.getCardColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active
                        ? Colors.transparent
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.moradoPrincipal.withValues(alpha: 0.25),
                            blurRadius: 10,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    f,
                    style: TextStyle(
                      color: active
                          ? Colors.white
                          : AppColors.getSubtextColor(context),
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Lot Card ──────────────────────────────────────────────────────────────
  Widget _buildLotCard(
      BuildContext context, Map<String, dynamic> lot, int displayIndex, bool isDark) {
    final int initial = (lot['initialQuantity'] as num?)?.toInt() ?? 0;
    final int available = (lot['availableQuantity'] as num?)?.toInt() ?? 0;
    final double unitCost = (lot['unitCost'] as num?)?.toDouble() ?? 0.0;
    final bool isActive = available > 0;
    final String lotId = lot['id']?.toString() ?? '?';
    final String warehouse = lot['warehouseName'] ?? 'Almacén';

    final entryDateRaw = lot['entryDate'];
    String entryDateStr = 'N/A';
    if (entryDateRaw != null) {
      try {
        final d = DateTime.parse(entryDateRaw.toString()).toLocal();
        entryDateStr =
            '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      } catch (_) {}
    }

    final double consumed = (initial - available).toDouble();
    final double progress = initial > 0 ? available / initial : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isActive ? Colors.greenAccent : Colors.redAccent)
              .withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // — Encabezado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [
                        Colors.greenAccent.withValues(alpha: isDark ? 0.08 : 0.04),
                        Colors.transparent,
                      ]
                    : [
                        Colors.redAccent.withValues(alpha: isDark ? 0.06 : 0.03),
                        Colors.transparent,
                      ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.moradoPrincipal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Lote #$lotId',
                        style: const TextStyle(
                          color: AppColors.moradoPrincipal,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.warehouse_rounded,
                        color: AppColors.getSubtextColor(context), size: 13),
                    const SizedBox(width: 4),
                    Text(
                      warehouse,
                      style: TextStyle(
                          color: AppColors.getSubtextColor(context),
                          fontSize: 11),
                    ),
                  ],
                ),
                // Badge estado
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isActive ? Colors.greenAccent : Colors.redAccent)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isActive ? Colors.greenAccent : Colors.redAccent)
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    isActive ? 'Activo' : 'Agotado',
                    style: TextStyle(
                      color:
                          isActive ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // — Cuerpo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row de métricas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _metricBox(context, 'Fecha entrada', entryDateStr,
                        Icons.calendar_today_rounded),
                    _metricBox(context, 'Costo unitario',
                        '\$${unitCost.toStringAsFixed(2)}',
                        Icons.attach_money_rounded),
                    _metricBox(context, 'Consumido',
                        '${consumed.toInt()} u.', Icons.trending_down_rounded),
                    _metricBox(context, 'Disponible', '$available u.',
                        Icons.inventory_2_rounded,
                        valueColor: isActive
                            ? Colors.greenAccent
                            : AppColors.getSubtextColor(context)),
                  ],
                ),

                const SizedBox(height: 14),

                // Barra de progreso de disponibilidad
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Disponibilidad del lote',
                                style: TextStyle(
                                  color: AppColors.getSubtextColor(context),
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                '$available / $initial u. (${(progress * 100).toStringAsFixed(0)}%)',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isActive ? Colors.greenAccent : Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Valoración del lote
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.azulPrincipal.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.azulPrincipal.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Valoración disponible (PEPS)',
                        style: TextStyle(
                            color: AppColors.getSubtextColor(context),
                            fontSize: 11),
                      ),
                      Text(
                        '\$${(available * unitCost).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.azulPrincipal,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBox(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.getSubtextColor(context), size: 11),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                    color: AppColors.getSubtextColor(context), fontSize: 9)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.getTextColor(context),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ─── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_outlined,
                color: AppColors.getSubtextColor(context).withValues(alpha: 0.3),
                size: 60),
            const SizedBox(height: 16),
            Text(
              _activeFilter == 'Todos'
                  ? 'No hay lotes registrados para este producto'
                  : 'No hay lotes ${_activeFilter.toLowerCase()} para este producto',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.getSubtextColor(context), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Blur Orb ─────────────────────────────────────────────────────────────
  Widget _blurOrb(Color color, double size) {
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
}
