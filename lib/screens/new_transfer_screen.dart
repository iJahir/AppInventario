import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/inventory_provider.dart';
import '../utils/app_colors.dart';
import '../utils/routes.dart';
import '../widgets/wavy_progress_indicator.dart';
import '../widgets/sweet_alert.dart';

class NewTransferScreen extends StatefulWidget {
  const NewTransferScreen({super.key});

  @override
  State<NewTransferScreen> createState() => _NewTransferScreenState();
}

class _NewTransferScreenState extends State<NewTransferScreen> {
  String? _fromWarehouseId;
  String? _toWarehouseId;
  final TextEditingController _observationsController = TextEditingController();
  
  // Lista de items agregados a la transferencia: { 'product': ProductModel, 'quantity': int }
  final List<Map<String, dynamic>> _selectedItems = [];
  
  // Para buscador de productos
  String _productSearchQuery = '';
  final TextEditingController _productSearchController = TextEditingController();
  bool _isSearchingProducts = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ip = Provider.of<InventoryProvider>(context, listen: false);
      ip.fetchConfigData();
    });
  }

  @override
  void dispose() {
    _observationsController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }

  void _onOriginWarehouseChanged(String? val) {
    if (val == null) return;
    setState(() {
      _fromWarehouseId = val;
      // Limpiar productos previamente agregados ya que cambian de origen y stock disponible
      _selectedItems.clear();
      
      // Si el destino es igual al origen, resetear destino
      if (_toWarehouseId == _fromWarehouseId) {
        _toWarehouseId = null;
      }
    });
    // Cargar inventario disponible de ese almacén en el backend
    Provider.of<InventoryProvider>(context, listen: false).fetchWarehouseInventory(val);
  }

  void _addProduct(ProductModel product) {
    // Si ya fue agregado, no duplicar
    final exists = _selectedItems.any((item) => item['product'].id == product.id);
    if (exists) {
      SweetAlert.show(
        context,
        title: 'Producto Duplicado',
        message: 'Este producto ya fue agregado. Modifica su cantidad en la lista.',
        type: SweetAlertType.warning,
      );
      return;
    }

    if (product.stock <= 0) {
      SweetAlert.show(
        context,
        title: 'Stock Agotado',
        message: 'Este producto no tiene existencias disponibles en el origen.',
        type: SweetAlertType.warning,
      );
      return;
    }

    setState(() {
      _selectedItems.add({
        'product': product,
        'quantity': 1,
      });
      _productSearchQuery = '';
      _productSearchController.clear();
      _isSearchingProducts = false;
    });
  }

  void _updateQuantity(int index, int newQty) {
    final maxStock = (_selectedItems[index]['product'] as ProductModel).stock;
    if (newQty > maxStock) {
      SweetAlert.show(
        context,
        title: 'Cantidad Excedida',
        message: 'No puedes transferir más de la existencia disponible ($maxStock u.)',
        type: SweetAlertType.warning,
      );
      return;
    }
    if (newQty <= 0) return;

    setState(() {
      _selectedItems[index]['quantity'] = newQty;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }

  Future<void> _submitTransfer() async {
    if (_fromWarehouseId == null || _toWarehouseId == null) {
      SweetAlert.show(
        context,
        title: 'Almacenes Requeridos',
        message: 'Debes seleccionar el almacén de origen y destino.',
        type: SweetAlertType.warning,
      );
      return;
    }
    if (_selectedItems.isEmpty) {
      SweetAlert.show(
        context,
        title: 'Sin Productos',
        message: 'Debes agregar al menos un producto a la transferencia.',
        type: SweetAlertType.warning,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final ip = Provider.of<InventoryProvider>(context, listen: false);

    // Formatear items para el payload de la API
    final List<Map<String, dynamic>> itemsPayload = _selectedItems.map((item) {
      final ProductModel prod = item['product'];
      return {
        'productId': prod.id,
        'quantity': item['quantity'],
        'unitPrice': prod.purchasePrice ?? (prod.price * 0.7),
      };
    }).toList();

    // userId por defecto 1 (o el usuario logueado en la vida real)
    final success = await ip.createTransfer(
      fromWarehouseId: _fromWarehouseId!,
      toWarehouseId: _toWarehouseId!,
      observations: _observationsController.text,
      items: itemsPayload,
      userId: '1',
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      SweetAlert.show(
        context,
        title: 'Transferencia Exitosa',
        message: 'Transferencia registrada exitosamente.',
        type: SweetAlertType.success,
        onConfirm: () {
          if (mounted) Navigator.pop(context);
        },
      );
    } else if (mounted) {
      SweetAlert.show(
        context,
        title: 'Error de Transferencia',
        message: ip.errorMessage ?? 'Error al procesar la transferencia.',
        type: SweetAlertType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredProducts = inventoryProvider.warehouseProducts.where((p) {
      final query = _productSearchQuery.toLowerCase();
      return p.name.toLowerCase().contains(query) || (p.sku ?? '').toLowerCase().contains(query);
    }).toList();

    int totalRefs = _selectedItems.length;
    int totalUnits = _selectedItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));

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
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWarehouseSelectors(context, inventoryProvider),
                        const SizedBox(height: 20),
                        _buildObservationsInput(context),
                        const SizedBox(height: 25),
                        _buildProductSearchSection(context, filteredProducts, inventoryProvider.isLoading),
                        const SizedBox(height: 20),
                        _buildSelectedProductsList(context),
                        const SizedBox(height: 25),
                        _buildSummaryPanel(context, totalRefs, totalUnits),
                        const SizedBox(height: 30),
                        _buildSubmitButton(context),
                        const SizedBox(height: 60),
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
                  'Nueva Transferencia',
                  style: TextStyle(color: AppColors.getTextColor(context), fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Registra un movimiento interno de stock',
                  style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseSelectors(BuildContext context, InventoryProvider ip) {
    final list = ip.warehouses;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // ORIGEN
          Row(
            children: [
              const Icon(Icons.outbound_rounded, color: Colors.orangeAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bodega de Origen', style: TextStyle(color: AppColors.grisTexto, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        hint: const Text('Seleccionar origen', style: TextStyle(color: Colors.white30, fontSize: 14)),
                        value: _fromWarehouseId,
                        dropdownColor: AppColors.getCardColor(context),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.moradoPrincipal),
                        style: TextStyle(color: AppColors.getTextColor(context), fontSize: 14, fontWeight: FontWeight.bold),
                        onChanged: _onOriginWarehouseChanged,
                        items: list.map((w) {
                          return DropdownMenuItem<String>(
                            value: w['id'].toString(),
                            child: Text(w['name'] ?? ''),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 15),
          // DESTINO
          Row(
            children: [
              const Icon(Icons.login_rounded, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bodega de Destino', style: TextStyle(color: AppColors.grisTexto, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        hint: const Text('Seleccionar destino', style: TextStyle(color: Colors.white30, fontSize: 14)),
                        value: _toWarehouseId,
                        dropdownColor: AppColors.getCardColor(context),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.moradoPrincipal),
                        style: TextStyle(color: AppColors.getTextColor(context), fontSize: 14, fontWeight: FontWeight.bold),
                        onChanged: (val) {
                          if (val == _fromWarehouseId) {
                            SweetAlert.show(
                              context,
                              title: 'Bodega Inválida',
                              message: 'El almacén de destino no puede ser el mismo que el de origen.',
                              type: SweetAlertType.warning,
                            );
                            return;
                          }
                          setState(() {
                            _toWarehouseId = val;
                          });
                        },
                        items: list.map((w) {
                          return DropdownMenuItem<String>(
                            value: w['id'].toString(),
                            child: Text(w['name'] ?? ''),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObservationsInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: _observationsController,
        style: TextStyle(color: AppColors.getTextColor(context), fontSize: 14),
        maxLines: 2,
        decoration: InputDecoration(
          icon: Icon(Icons.comment_outlined, color: AppColors.getSubtextColor(context).withValues(alpha: 0.5), size: 20),
          hintText: 'Observaciones de la transferencia (opcional)...',
          hintStyle: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.5), fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildProductSearchSection(BuildContext context, List<ProductModel> products, bool isQueryLoading) {
    if (_fromWarehouseId == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
        ),
        child: const Center(
          child: Text(
            '⚠️ Selecciona primero la bodega de origen para poder ver y agregar productos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Productos a Transferir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        Container(
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
                  controller: _productSearchController,
                  style: TextStyle(color: AppColors.getTextColor(context), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar producto por nombre o SKU...',
                    hintStyle: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.5), fontSize: 13),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _productSearchQuery = val;
                      _isSearchingProducts = val.isNotEmpty;
                    });
                  },
                ),
              ),
              if (_productSearchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _productSearchController.clear();
                    setState(() {
                      _productSearchQuery = '';
                      _isSearchingProducts = false;
                    });
                  },
                  child: Icon(Icons.close, color: AppColors.getSubtextColor(context), size: 18),
                ),
            ],
          ),
        ),
        if (_isSearchingProducts) ...[
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AppColors.getCardColor(context),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: isQueryLoading
                ? const Padding(
                    padding: EdgeInsets.all(15.0),
                    child: Center(child: CircularProgressIndicator(color: AppColors.moradoPrincipal)),
                  )
                : products.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(15.0),
                        child: Text('No se encontraron productos con stock en origen.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final p = products[index];
                          return ListTile(
                            leading: const Icon(Icons.inventory_2_rounded, color: AppColors.moradoPrincipal, size: 20),
                            title: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text('SKU: ${p.sku ?? "N/D"} • Disp: ${p.stock} u.', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.moradoPrincipal.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.add, color: AppColors.moradoPrincipal, size: 16),
                            ),
                            onTap: () => _addProduct(p),
                          );
                        },
                      ),
          ),
        ]
      ],
    );
  }

  Widget _buildSelectedProductsList(BuildContext context) {
    if (_selectedItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        ),
        child: Column(
          children: [
            Icon(Icons.playlist_add_rounded, color: AppColors.getSubtextColor(context).withValues(alpha: 0.3), size: 40),
            const SizedBox(height: 10),
            const Text(
              'No has agregado productos a transferir',
              style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lista de Productos', style: TextStyle(color: AppColors.grisTexto, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selectedItems.length,
          itemBuilder: (context, index) {
            final item = _selectedItems[index];
            final ProductModel prod = item['product'];
            final int qty = item['quantity'];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_rounded, color: AppColors.moradoPrincipal, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prod.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'SKU: ${prod.sku ?? "N/D"} • Disp: ${prod.stock} u.',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _updateQuantity(index, qty - 1),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.remove, color: Colors.white, size: 14),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$qty',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _updateQuantity(index, qty + 1),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.add, color: Colors.white, size: 14),
                        ),
                      ),
                      const SizedBox(width: 15),
                      GestureDetector(
                        onTap: () => _removeItem(index),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryPanel(BuildContext context, int refs, int units) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                'PRODUCTOS',
                style: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                '$refs ref.',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(width: 1, height: 35, color: Colors.white10),
          Column(
            children: [
              Text(
                'UNIDADES TOTALES',
                style: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                '$units u.',
                style: const TextStyle(color: AppColors.moradoPrincipal, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return GestureDetector(
      onTap: _isSubmitting ? null : _submitTransfer,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.moradoPrincipal, AppColors.azulPrincipal]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.moradoPrincipal.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _isSubmitting
              ? const WavyProgressIndicator(width: 80, height: 20, strokeWidth: 3)
              : const Text(
                  'Confirmar Transferencia',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
        ),
      ),
    );
  }
}
