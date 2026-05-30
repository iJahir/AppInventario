import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/routes.dart';
import '../providers/inventory_provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';

class NuevaSalidaScreen extends StatefulWidget {
  const NuevaSalidaScreen({super.key});

  @override
  State<NuevaSalidaScreen> createState() => _NuevaSalidaScreenState();
}

class _NuevaSalidaScreenState extends State<NuevaSalidaScreen> {
  final List<Map<String, dynamic>> _productos = []; // { productId, name, quantity, price }
  String? _selectedCustomerId;
  String? _selectedWarehouseId;
  final TextEditingController _obsController = TextEditingController();
  final DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchConfigData();
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final inventoryProvider = Provider.of<InventoryProvider>(context);

    // Listas dinámicas desde SQL Server
    final customerItems = inventoryProvider.customers.map((c) => {
      'id': c['id'].toString(),
      'name': c['name'].toString()
    }).toList();

    final warehousesItems = inventoryProvider.warehouses.map((w) => {
      'id': w['id'].toString(),
      'name': w['name'].toString()
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: _buildBlurOrb(AppColors.azulPrincipal.withValues(alpha: isDark ? 0.15 : 0.05), 300),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: _buildBlurOrb(AppColors.moradoPrincipal.withValues(alpha: isDark ? 0.15 : 0.05), 300),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: inventoryProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.azulPrincipal))
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildSectionTitle(context, 'Información general'),
                          const SizedBox(height: 15),
                          _buildDropdownField(
                            context,
                            label: 'Cliente',
                            hint: 'Seleccionar cliente',
                            value: _selectedCustomerId,
                            items: customerItems,
                            onChanged: (val) => setState(() => _selectedCustomerId = val),
                          ),
                          const SizedBox(height: 15),
                          _buildDateField(context, 'Fecha', _selectedDate),
                          const SizedBox(height: 15),
                          _buildDropdownField(
                            context,
                            label: 'Almacén de origen',
                            hint: 'Seleccionar almacén',
                            value: _selectedWarehouseId,
                            items: warehousesItems,
                            onChanged: (val) => setState(() => _selectedWarehouseId = val),
                          ),
                          const SizedBox(height: 15),
                          _buildTextAreaField(context, 'Observaciones (opcional)', 'Escribe una observación...', _obsController),
                          
                          const SizedBox(height: 30),
                          _buildSectionTitle(context, 'Productos'),
                          const SizedBox(height: 15),
                          _buildAddProductButton(),
                          
                          const SizedBox(height: 20),
                          if (_productos.isEmpty)
                            _buildEmptyProducts(context)
                          else
                            ..._productos.map((p) => _buildProductCard(context, p)).toList(),
                          
                          const SizedBox(height: 30),
                          _buildSummary(context),
                          const SizedBox(height: 40),
                          _buildActionButtons(context),
                          const SizedBox(height: 30),
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

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.getTextColor(context).withValues(alpha: 0.1)),
              ),
              child: Icon(Icons.arrow_back_rounded, color: AppColors.getTextColor(context), size: 20),
            ),
          ),
          const SizedBox(width: 20),
          Text(
            'Nueva salida',
            style: TextStyle(color: AppColors.getTextColor(context), fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(color: AppColors.azulPrincipal, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
    );
  }

  Widget _buildDropdownField(BuildContext context, {
    required String label,
    required String hint,
    required String? value,
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.getTextColor(context).withValues(alpha: 0.05)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 14)),
              dropdownColor: AppColors.getCardColor(context),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.azulPrincipal),
              isExpanded: true,
              style: TextStyle(color: AppColors.getTextColor(context), fontSize: 14),
              items: items.map((e) => DropdownMenuItem(value: e['id'], child: Text(e['name']!))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context, String label, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.getTextColor(context).withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${date.day}/${date.month}/${date.year}",
                style: TextStyle(color: AppColors.getTextColor(context), fontSize: 14),
              ),
              const Icon(Icons.calendar_today_rounded, color: AppColors.azulPrincipal, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField(BuildContext context, String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.getTextColor(context).withValues(alpha: 0.05)),
          ),
          child: TextField(
            controller: controller,
            maxLines: 3,
            style: TextStyle(color: AppColors.getTextColor(context), fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddProductButton() {
    return GestureDetector(
      onTap: () => _showAddProductModal(),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.azulPrincipal, AppColors.moradoPrincipal]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColors.azulPrincipal.withValues(alpha: 0.2), blurRadius: 10)],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('Agregar producto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyProducts(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.shopping_cart_outlined, color: AppColors.getSubtextColor(context).withValues(alpha: 0.3), size: 60),
            const SizedBox(height: 10),
            Text('No hay productos en esta salida', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getTextColor(context).withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.azulPrincipal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.outbox_rounded, color: AppColors.azulPrincipal),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'], style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold)),
                Text("Cant: ${product['quantity']} | Unit: \$${product['price']}", style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12)),
              ],
            ),
          ),
          Text("\$${(product['quantity'] * product['price']).toStringAsFixed(2)}", style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    double subtotal = _productos.fold(0.0, (sum, item) => sum + (item['quantity'] * item['price']));
    double discount = subtotal * 0.05; // 5% Descuento estándar
    double total = subtotal - discount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getTextColor(context).withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _summaryRow(context, 'Total productos:', '${_productos.length}'),
          _summaryRow(context, 'Total unidades:', '${_productos.fold(0, (sum, item) => sum + (item['quantity'] as int))}'),
          Divider(color: AppColors.getTextColor(context).withValues(alpha: 0.1), height: 20),
          _summaryRow(context, 'Subtotal:', '\$${subtotal.toStringAsFixed(2)}'),
          _summaryRow(context, 'Descuento (5%):', '-\$${discount.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _summaryRow(context, 'Total a pagar:', '\$${total.toStringAsFixed(2)}', isTotal: true),
        ],
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isTotal ? AppColors.getTextColor(context) : AppColors.getSubtextColor(context), fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: isTotal ? AppColors.azulPrincipal : AppColors.getTextColor(context), fontSize: isTotal ? 20 : 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.getTextColor(context).withValues(alpha: 0.1)),
              ),
              child: Center(child: Text('Cancelar', style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold))),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: GestureDetector(
            onTap: inventoryProvider.isLoading
                ? null
                : () async {
                    if (_selectedWarehouseId == null || _selectedCustomerId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor selecciona Almacén y Cliente')),
                      );
                      return;
                    }
                    if (_productos.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Agrega al menos un producto a la salida')),
                      );
                      return;
                    }

                    final success = await inventoryProvider.createTransaction(
                      type: 'SALIDA',
                      warehouseId: _selectedWarehouseId!,
                      customerId: _selectedCustomerId!,
                      observations: _obsController.text.trim(),
                      items: _productos,
                    );

                    if (context.mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Salida registrada exitosamente en SQL Server')),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(inventoryProvider.errorMessage ?? 'Error al guardar la salida')),
                        );
                      }
                    }
                  },
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.azulPrincipal, AppColors.moradoPrincipal]),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: AppColors.azulPrincipal.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Center(
                child: inventoryProvider.isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Guardar salida', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddProductModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AgregarProductoSalidaModal(
        onAdd: (product) {
          setState(() {
            _productos.add(product);
          });
        },
      ),
    );
  }
}

class _AgregarProductoSalidaModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  const _AgregarProductoSalidaModal({required this.onAdd});

  @override
  State<_AgregarProductoSalidaModal> createState() => _AgregarProductoSalidaModalState();
}

class _AgregarProductoSalidaModalState extends State<_AgregarProductoSalidaModal> {
  String? _selectedProductId;
  int _quantity = 1;
  double _price = 0.0;
  int _availableStock = 0;

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    
    final productsItems = productProvider.products.map((p) => {
      'id': p.id.toString(),
      'name': p.name
    }).toList();

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: AppColors.getBackgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: AppColors.getTextColor(context).withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agregar producto (Salida)',
              style: TextStyle(color: AppColors.getTextColor(context), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            _buildDropdownField(
              context,
              label: 'Producto',
              hint: 'Seleccionar producto',
              value: _selectedProductId,
              items: productsItems,
              onChanged: (val) {
                setState(() {
                  _selectedProductId = val;
                  final prod = productProvider.products.firstWhere((p) => p.id == val);
                  _price = prod.price;
                  _availableStock = prod.stock;
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildQuantitySelector(context)),
                const SizedBox(width: 20),
                Expanded(child: _buildPriceInput(context)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Stock disponible: $_availableStock",
              style: TextStyle(color: _quantity > _availableStock ? Colors.redAccent : Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            _buildSubtotal(context),
            const SizedBox(height: 30),
            _buildModalButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(BuildContext context, {
    required String label,
    required String hint,
    required String? value,
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.getTextColor(context).withValues(alpha: 0.05)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 14)),
              dropdownColor: AppColors.getCardColor(context),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.azulPrincipal),
              isExpanded: true,
              style: TextStyle(color: AppColors.getTextColor(context), fontSize: 14),
              items: items.map((e) => DropdownMenuItem(value: e['id'], child: Text(e['name']!))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cantidad', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          height: 55,
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.getTextColor(context).withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() { if(_quantity > 1) _quantity--; }),
                icon: Icon(Icons.remove, color: AppColors.getTextColor(context), size: 20),
              ),
              Text('$_quantity', style: TextStyle(color: AppColors.getTextColor(context), fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => setState(() => _quantity++),
                icon: Icon(Icons.add, color: AppColors.getTextColor(context), size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Precio unitario', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.getTextColor(context).withValues(alpha: 0.05)),
          ),
          child: Center(
            child: TextFormField(
              keyboardType: TextInputType.number,
              key: ValueKey('price_field_$_selectedProductId'),
              initialValue: _price > 0 ? _price.toStringAsFixed(2) : '',
              style: TextStyle(color: AppColors.getTextColor(context), fontSize: 16),
              onChanged: (val) => setState(() => _price = double.tryParse(val) ?? 0.0),
              decoration: const InputDecoration(
                prefixText: '\$ ',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtotal(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Subtotal:', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 14)),
        Text('\$${(_quantity * _price).toStringAsFixed(2)}', 
          style: TextStyle(color: AppColors.getTextColor(context), fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildModalButtons(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.getTextColor(context).withValues(alpha: 0.1)),
              ),
              child: Center(child: Text('Cancelar', style: TextStyle(color: AppColors.getTextColor(context)))),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_selectedProductId != null && _quantity <= _availableStock) {
                final p = productProvider.products.firstWhere((prod) => prod.id == _selectedProductId);
                widget.onAdd({
                  'productId': _selectedProductId,
                  'name': p.name,
                  'quantity': _quantity,
                  'price': _price,
                });
                Navigator.pop(context);
              } else if (_quantity > _availableStock) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No hay suficiente stock disponible')),
                );
              }
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.azulPrincipal,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.azulPrincipal.withValues(alpha: 0.3), blurRadius: 10)],
              ),
              child: const Center(child: Text('Agregar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
          ),
        ),
      ],
    );
  }
}
