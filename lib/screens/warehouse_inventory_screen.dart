import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/inventory_provider.dart';
import '../utils/app_colors.dart';
import '../utils/routes.dart';
import '../widgets/wavy_progress_indicator.dart';

class WarehouseInventoryScreen extends StatefulWidget {
  const WarehouseInventoryScreen({super.key});

  @override
  State<WarehouseInventoryScreen> createState() => _WarehouseInventoryScreenState();
}

class _WarehouseInventoryScreenState extends State<WarehouseInventoryScreen> {
  String? _selectedWarehouseId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    await inventoryProvider.fetchConfigData();
    
    if (inventoryProvider.warehouses.isNotEmpty && mounted) {
      setState(() {
        _selectedWarehouseId = inventoryProvider.warehouses.first['id'].toString();
        _currentPage = 1;
      });
      inventoryProvider.fetchWarehouseInventory(_selectedWarehouseId!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Almacén activo seleccionado
    final warehouseList = inventoryProvider.warehouses;
    
    // Filtrar inventario por buscador
    final filteredInventory = inventoryProvider.warehouseProducts.where((p) {
      final name = p.name.toLowerCase();
      final sku = (p.sku ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || sku.contains(q);
    }).toList();

    // Paginación
    final int totalProductsCount = filteredInventory.length;
    final int totalPages = (totalProductsCount / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    }
    final paginatedInventory = filteredInventory.isEmpty ? <ProductModel>[] : filteredInventory.sublist(
      (_currentPage - 1) * _itemsPerPage,
      ((_currentPage * _itemsPerPage) > totalProductsCount) ? totalProductsCount : (_currentPage * _itemsPerPage)
    );

    // Calcular KPIs financieras y operativas del almacén seleccionado
    int totalProducts = 0;
    double totalInventoryValue = 0.0;
    int lowStockCount = 0;
    int outOfStockCount = 0;

    for (var p in inventoryProvider.warehouseProducts) {
      if (p.stock > 0) {
        totalProducts++;
        totalInventoryValue += (p.stock * (p.purchasePrice ?? p.price * 0.7));
      }
      
      if (p.stock == 0) {
        outOfStockCount++;
      } else if (p.stock <= (p.minStock ?? 0)) {
        lowStockCount++;
      }
    }

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
                _buildHeader(context, warehouseList, inventoryProvider),
                _buildSearchBar(context),
                Expanded(
                  child: inventoryProvider.isLoading && inventoryProvider.warehouseProducts.isEmpty
                      ? const Center(child: WavyProgressIndicator(width: 150, height: 30, strokeWidth: 4))
                      : Column(
                          children: [
                            _buildKpiSection(context, totalProducts, totalInventoryValue, lowStockCount, outOfStockCount),
                            const SizedBox(height: 15),
                            Expanded(
                              child: filteredInventory.isEmpty
                                  ? _buildEmptyState(context)
                                  : ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      itemCount: paginatedInventory.length,
                                      itemBuilder: (context, index) {
                                        final prod = paginatedInventory[index];
                                        return _buildProductCard(context, prod);
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

  Widget _buildHeader(
    BuildContext context, 
    List<Map<String, dynamic>> warehouses,
    InventoryProvider provider,
  ) {
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
                  'Existencias por Bodega',
                  style: TextStyle(
                    color: AppColors.getSubtextColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                // Dropdown de almacén
                if (warehouses.isNotEmpty)
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.getCardColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedWarehouseId,
                        dropdownColor: AppColors.getCardColor(context),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.moradoPrincipal),
                        style: TextStyle(
                          color: AppColors.getTextColor(context),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        isExpanded: true,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedWarehouseId = val;
                            });
                            provider.fetchWarehouseInventory(val);
                          }
                        },
                        items: warehouses.map((w) {
                          return DropdownMenuItem<String>(
                            value: w['id'].toString(),
                            child: Text(w['name'] ?? 'Almacén'),
                          );
                        }).toList(),
                      ),
                    ),
                  )
                else
                  Text(
                    'Cargando almacenes...',
                    style: TextStyle(color: AppColors.getTextColor(context), fontSize: 16, fontWeight: FontWeight.bold),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                  hintText: 'Buscar por nombre o SKU...',
                  hintStyle: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.6), fontSize: 13),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
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
                  });
                },
                child: Icon(Icons.close, color: AppColors.getSubtextColor(context), size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiSection(
    BuildContext context, 
    int total, 
    double valor, 
    int bajo, 
    int agotado,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  context,
                  'PRODUCTOS',
                  '$total referencias',
                  Icons.grid_view_rounded,
                  AppColors.moradoPrincipal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  context,
                  'VALOR DEL INVENTARIO',
                  '\$${valor.toStringAsFixed(2)}',
                  Icons.monetization_on_outlined,
                  Colors.tealAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  context,
                  'STOCK BAJO',
                  '$bajo productos',
                  Icons.warning_amber_rounded,
                  Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  context,
                  'AGOTADOS',
                  '$agotado referencias',
                  Icons.cancel_presentation_rounded,
                  Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, 
    String label, 
    String value, 
    IconData icon, 
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
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
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.getSubtextColor(context).withValues(alpha: 0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.getTextColor(context),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    // Definir estado de stock y color
    Color stateColor = Colors.greenAccent;
    String stateLabel = "Normal";
    if (product.stock == 0) {
      stateColor = Colors.redAccent;
      stateLabel = "Agotado";
    } else if (product.stock <= (product.minStock ?? 0)) {
      stateColor = Colors.orangeAccent;
      stateLabel = "Bajo";
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.productDetail, arguments: product);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // Icono / Imagen del producto
            Container(
              height: 55, width: 55,
              decoration: BoxDecoration(
                color: AppColors.moradoPrincipal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.moradoPrincipal.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.inventory_2_rounded, color: AppColors.moradoPrincipal, size: 24),
            ),
            const SizedBox(width: 15),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.getTextColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'SKU: ${product.sku ?? "N/D"}',
                    style: TextStyle(
                      color: AppColors.getSubtextColor(context).withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.category ?? 'General',
                    style: TextStyle(
                      color: AppColors.moradoPrincipal.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${product.stock} u.',
                  style: TextStyle(
                    color: AppColors.getTextColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                
                // Badge de Estado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: stateColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: stateColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    stateLabel,
                    style: TextStyle(
                      color: stateColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, color: AppColors.getSubtextColor(context).withValues(alpha: 0.3), size: 50),
            const SizedBox(height: 15),
            Text(
              'No se encontraron productos',
              style: TextStyle(color: AppColors.getTextColor(context), fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              'Prueba buscando otro nombre o SKU.',
              style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
