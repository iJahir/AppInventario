import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../utils/app_colors.dart';
import '../utils/routes.dart';
import '../widgets/wavy_progress_indicator.dart';

class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'Todos'; // Todos, Hoy, Semana, Mes
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchTransfers();
      Provider.of<InventoryProvider>(context, listen: false).fetchConfigData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _applyDateFilter(DateTime date) {
    final now = DateTime.now();
    if (_activeFilter == 'Hoy') {
      return date.year == now.year && date.month == now.month && date.day == now.day;
    } else if (_activeFilter == 'Semana') {
      final weekAgo = now.subtract(const Duration(days: 7));
      return date.isAfter(weekAgo);
    } else if (_activeFilter == 'Mes') {
      final monthAgo = now.subtract(const Duration(days: 30));
      return date.isAfter(monthAgo);
    }
    return true; // Todos
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Filtrar transferencias
    final filteredTransfers = inventoryProvider.transfers.where((t) {
      // 1. Filtro buscador
      final query = _searchQuery.toLowerCase();
      final origin = (t['originWarehouseName'] ?? '').toString().toLowerCase();
      final dest = (t['destinationWarehouseName'] ?? '').toString().toLowerCase();
      final note = (t['observations'] ?? '').toString().toLowerCase();
      final user = (t['userName'] ?? '').toString().toLowerCase();
      
      final matchesSearch = origin.contains(query) || 
                            dest.contains(query) || 
                            note.contains(query) ||
                            user.contains(query);

      // 2. Filtro fecha
      final DateTime dt = t['transactionDate'] != null 
          ? DateTime.parse(t['transactionDate'].toString()) 
          : DateTime.now();
      
      final matchesDate = _applyDateFilter(dt);

      return matchesSearch && matchesDate;
    }).toList();

    // Paginación
    final int totalTransfersCount = filteredTransfers.length;
    final int totalPages = (totalTransfersCount / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    }
    final paginatedTransfers = filteredTransfers.isEmpty ? <Map<String, dynamic>>[] : filteredTransfers.sublist(
      (_currentPage - 1) * _itemsPerPage,
      ((_currentPage * _itemsPerPage) > totalTransfersCount) ? totalTransfersCount : (_currentPage * _itemsPerPage)
    );

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: Stack(
        children: [
          // Blur Orbs Premium
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlurOrb(AppColors.azulPrincipal.withValues(alpha: isDark ? 0.15 : 0.04), 300),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _buildBlurOrb(AppColors.moradoPrincipal.withValues(alpha: isDark ? 0.12 : 0.03), 250),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildSearchBar(context),
                _buildFilterChips(context),
                const SizedBox(height: 10),
                Expanded(
                  child: inventoryProvider.isLoading && inventoryProvider.transfers.isEmpty
                      ? const Center(child: WavyProgressIndicator(width: 150, height: 30, strokeWidth: 4))
                      : Column(
                          children: [
                            Expanded(
                              child: filteredTransfers.isEmpty
                                  ? _buildEmptyState(context)
                                  : ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      itemCount: paginatedTransfers.length,
                                      itemBuilder: (context, index) {
                                        final transfer = paginatedTransfers[index];
                                        return _buildTransferCard(context, transfer);
                                      },
                                    ),
                            ),
                            if (totalPages > 1)
                              _buildPaginationControls(context, totalPages),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addTransfer),
        backgroundColor: AppColors.moradoPrincipal,
        icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
        label: const Text('Nueva Transferencia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBlurOrb(Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.settings),
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
                  'Transferencias',
                  style: TextStyle(color: AppColors.getTextColor(context), fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Control de movimientos entre bodegas',
                  style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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
            Icon(Icons.search_rounded, color: AppColors.getSubtextColor(context), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: AppColors.getTextColor(context), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar origen, destino, nota...',
                  hintStyle: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.6), fontSize: 13),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _currentPage = 1;
                  });
                },
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _currentPage = 1;
                  });
                },
                child: Icon(Icons.close, color: AppColors.getSubtextColor(context), size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final filters = ['Todos', 'Hoy', 'Semana', 'Mes'];
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final bool isSelected = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeFilter = filter;
                  _currentPage = 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.moradoPrincipal 
                      : AppColors.getCardColor(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? AppColors.moradoPrincipal 
                        : Colors.white.withValues(alpha: 0.05)
                  ),
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.getTextColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransferCard(BuildContext context, Map<String, dynamic> tx) {
    final origin = tx['originWarehouseName'] ?? 'Origen';
    final dest = tx['destinationWarehouseName'] ?? 'Destino';
    final observations = tx['observations'] ?? '';
    final user = tx['userName'] ?? 'Admin';
    final itemsList = tx['items'] as List? ?? [];
    
    // Suma de unidades transferidas en total
    final totalQty = itemsList.fold<int>(0, (sum, item) => sum + (item['quantity'] as int? ?? 0));

    final DateTime dt = tx['transactionDate'] != null 
        ? DateTime.parse(tx['transactionDate'].toString()) 
        : DateTime.now();
    final dateStr = "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.moradoPrincipal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'TRANSFERENCIA',
                  style: TextStyle(color: AppColors.moradoPrincipal, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.5), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORIGEN',
                      style: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      origin,
                      style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward_rounded, color: AppColors.moradoPrincipal.withValues(alpha: 0.7), size: 16),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DESTINO',
                      style: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dest,
                      style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (observations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              observations,
              style: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.8), fontSize: 11, fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, color: AppColors.getSubtextColor(context).withValues(alpha: 0.5), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    user,
                    style: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.7), fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$totalQty unidades (${itemsList.length} ref.)',
                  style: TextStyle(color: AppColors.getTextColor(context), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(BuildContext context, int totalPages) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _currentPage > 1 ? AppColors.moradoPrincipal : AppColors.getCardColor(context).withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 25),
          Text(
            '$_currentPage / $totalPages',
            style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 25),
          GestureDetector(
            onTap: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _currentPage < totalPages ? AppColors.moradoPrincipal : AppColors.getCardColor(context).withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz_rounded, color: AppColors.getSubtextColor(context).withValues(alpha: 0.3), size: 55),
            const SizedBox(height: 15),
            Text(
              'No hay transferencias',
              style: TextStyle(color: AppColors.getTextColor(context), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'No se encontraron transferencias con los filtros aplicados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
