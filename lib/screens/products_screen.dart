import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import '../utils/app_colors.dart';
import '../utils/routes.dart';
import '../widgets/wavy_progress_indicator.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final int _selectedIndex = 1;
  String _selectedCategory = 'Todos';
  bool _isSearching = false;
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
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final productProvider = Provider.of<ProductProvider>(context);

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
            child: _buildBlurOrb(AppColors.moradoPrincipal.withValues(alpha: isDark ? 0.1 : 0.03), 250),
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
                        _buildSummarySection(context),
                        const SizedBox(height: 20),
                        _buildActionButton(context),
                        const SizedBox(height: 25),
                        _buildCategories(context),
                        const SizedBox(height: 20),
                        _buildProductList(context),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Wavy Progress Indicator en superposición difuminada (Overlay)
          if (productProvider.isLoading && productProvider.products.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: AppColors.getCardColor(context).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 15,
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const WavyProgressIndicator(width: 150, height: 30, strokeWidth: 5),
                            const SizedBox(height: 15),
                            Text(
                              'Procesando en SQL Server...',
                              style: TextStyle(
                                color: AppColors.getTextColor(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
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
            child: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(color: AppColors.getTextColor(context)),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o SKU...',
                      hintStyle: TextStyle(color: AppColors.getSubtextColor(context)),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.toLowerCase();
                      });
                    },
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Productos', style: TextStyle(color: AppColors.getTextColor(context), fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('Gestiona tu catálogo', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 13)),
                    ],
                  ),
          ),
          _buildCircleIconButton(
            context, 
            _isSearching ? Icons.close_rounded : Icons.search_rounded, 
            onTap: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            }
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton(BuildContext context, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context), 
          shape: BoxShape.circle, 
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Icon(icon, color: AppColors.getTextColor(context), size: 22),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final total = productProvider.products.length.toString();
    final noStock = productProvider.products.where((p) => p.stock <= 0).length.toString();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.moradoPrincipal, AppColors.azulPrincipal], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: AppColors.azulPrincipal.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryMetric(total, 'Total productos', Icons.inventory_2_rounded),
          Container(width: 1, height: 40, color: Colors.white24),
          _summaryMetric(noStock, 'Sin stock', Icons.warning_amber_rounded),
        ],
      ),
    );
  }

  Widget _summaryMetric(String val, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 8),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.addProduct),
      child: Container(
        width: double.infinity, height: 55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.moradoPrincipal, Color(0xFF6A11CB)]),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: AppColors.moradoPrincipal.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Añadir producto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    final List<String> cats = ['Todos', 'Electrónica', 'Hogar', 'Moda', 'Deportes'];
    return Container(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        itemBuilder: (context, i) {
          bool active = cats[i] == _selectedCategory;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = cats[i];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: active ? AppColors.moradoPrincipal : AppColors.getCardColor(context),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: active ? AppColors.moradoPrincipal : Colors.white.withValues(alpha: 0.1)),
              ),
              alignment: Alignment.center,
              child: Text(cats[i], style: TextStyle(color: active ? Colors.white : AppColors.getTextColor(context), fontWeight: active ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductList(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    if (productProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: WavyProgressIndicator(width: 120, height: 25, strokeWidth: 4),
        ),
      );
    }

    if (productProvider.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(
          productProvider.errorMessage!,
          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (productProvider.products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text(
          'No hay productos registrados en la base de datos remota.',
          style: TextStyle(color: Colors.white54, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    var filteredProducts = _selectedCategory == 'Todos'
        ? productProvider.products
        : productProvider.products.where((p) => p.category?.toLowerCase() == _selectedCategory.toLowerCase()).toList();

    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((p) {
        final nameMatches = p.name.toLowerCase().contains(_searchQuery);
        final skuMatches = (p.sku?.toLowerCase() ?? '').contains(_searchQuery);
        return nameMatches || skuMatches;
      }).toList();
    }

    if (filteredProducts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text(
          'No hay productos registrados en esta categoría o búsqueda.',
          style: TextStyle(color: Colors.white54, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: filteredProducts
          .map((p) => _buildProductItem(context, p))
          .toList(),
    );
  }

  Widget _buildProductItem(BuildContext context, ProductModel product) {
    final bool isOutOfStock = product.stock <= 0;
    
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              height: 60, width: 60,
              decoration: BoxDecoration(color: AppColors.moradoPrincipal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.image_outlined, color: AppColors.moradoPrincipal),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(product.category ?? 'Sin Categoría', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12)),
                  const SizedBox(height: 5),
                  Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.moradoPrincipal, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isOutOfStock ? Colors.redAccent : Colors.greenAccent).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOutOfStock ? 'Agotado' : '${product.stock} en stock',
                    style: TextStyle(color: isOutOfStock ? Colors.redAccent : Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white24),
                  onSelected: (value) async {
                    if (value == 'eliminar' && product.id != null) {
                      final success = await Provider.of<ProductProvider>(context, listen: false)
                          .deleteProduct(product.id!);
                      if (context.mounted) {
                        _showPremiumSnackBar(
                          context, 
                          success ? 'Producto eliminado correctamente.' : 'Error al eliminar producto.',
                          isError: !success,
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetailsBottomSheet(BuildContext context, ProductModel product) {
    final bool isOutOfStock = product.stock <= 0;
    final double purchase = product.purchasePrice ?? 0.0;
    final double sale = product.price;
    final double margin = sale > 0 ? ((sale - purchase) / sale) * 100 : 0.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context).withValues(alpha: 0.95),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 25),
                      decoration: BoxDecoration(
                        color: AppColors.getSubtextColor(context).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header / Icon / Category & SKU
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          color: AppColors.moradoPrincipal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.inventory_2_rounded, color: AppColors.moradoPrincipal, size: 32),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: TextStyle(
                                color: AppColors.getTextColor(context),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.moradoPrincipal.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    product.category ?? 'Sin Categoría',
                                    style: const TextStyle(
                                      color: AppColors.moradoPrincipal,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  product.unitMeasure != null ? 'Medida: ${product.unitMeasure}' : 'Medida: Unidad',
                                  style: TextStyle(
                                    color: AppColors.getSubtextColor(context),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'SKU: ${product.sku ?? "PROD-${DateTime.now().year}-NA"}',
                              style: TextStyle(
                                color: AppColors.getSubtextColor(context).withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 15),

                  // Primera Fila de Métricas: Precios de Costo y Venta
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailMetric(
                          context,
                          'COSTO DE COMPRA',
                          '\$${purchase.toStringAsFixed(2)}',
                          Icons.shopping_bag_outlined,
                          Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildDetailMetric(
                          context,
                          'PRECIO DE VENTA',
                          '\$${sale.toStringAsFixed(2)}',
                          Icons.attach_money_rounded,
                          Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Segunda Fila de Métricas: Stock y Stock Mínimo
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailMetric(
                          context,
                          'STOCK DISPONIBLE',
                          isOutOfStock ? 'Agotado' : '${product.stock} unidades',
                          Icons.warehouse_outlined,
                          isOutOfStock ? Colors.redAccent : Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildDetailMetric(
                          context,
                          'ALERTA MÍNIMA',
                          '${product.minStock ?? 0} u.',
                          Icons.warning_amber_rounded,
                          Colors.redAccent.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Tercera Fila de Métricas: Margen de Utilidad e Impuestos
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailMetric(
                          context,
                          'MARGEN GANANCIA',
                          '${margin.toStringAsFixed(1)}%',
                          Icons.trending_up_rounded,
                          Colors.purpleAccent,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildDetailMetric(
                          context,
                          'IMPUESTO (IVA)',
                          '${product.taxPercentage?.toStringAsFixed(0) ?? "13"}%',
                          Icons.percent_rounded,
                          Colors.tealAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Description Section
                  Text(
                    'DESCRIPCIÓN',
                    style: TextStyle(
                      color: AppColors.getSubtextColor(context).withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.getBackgroundColor(context).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Text(
                      product.description.isEmpty ? 'Este producto no cuenta con una descripción detallada registrada.' : product.description,
                      style: TextStyle(
                        color: AppColors.getTextColor(context),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.getSubtextColor(context).withValues(alpha: 0.2)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: AppColors.getSubtextColor(context), size: 20),
                          label: Text(
                            'Cerrar',
                            style: TextStyle(color: AppColors.getSubtextColor(context), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: const BorderSide(color: Colors.redAccent, width: 1),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmDeleteProduct(context, product);
                          },
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          label: const Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildDetailMetric(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.getBackgroundColor(context).withValues(alpha: 0.3),
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
              Text(
                label,
                style: TextStyle(
                  color: AppColors.getSubtextColor(context),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.getTextColor(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.getCardColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('¿Eliminar Producto?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          content: Text('¿Estás seguro de que deseas eliminar a "${product.name}" de forma permanente?', style: TextStyle(color: AppColors.getSubtextColor(context))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: AppColors.getSubtextColor(context))),
            ),
             ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                if (product.id != null) {
                  final success = await Provider.of<ProductProvider>(context, listen: false)
                      .deleteProduct(product.id!);
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showPremiumSnackBar(
                      context, 
                      success ? 'Producto eliminado correctamente.' : 'Error al eliminar producto.',
                      isError: !success,
                    );
                  }
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showPremiumSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isError 
                      ? [Colors.redAccent.withValues(alpha: 0.9), Colors.red.withValues(alpha: 0.7)]
                      : [AppColors.moradoPrincipal.withValues(alpha: 0.9), AppColors.azulPrincipal.withValues(alpha: 0.9)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
          else if (i == 2) Navigator.pushReplacementNamed(context, AppRoutes.entries);
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
}
