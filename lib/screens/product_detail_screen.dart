import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io' as io;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product_model.dart';
import '../models/kardex_model.dart';
import '../providers/product_provider.dart';
import '../utils/app_colors.dart';
import '../utils/routes.dart';
import '../utils/db_config.dart';
import '../widgets/wavy_progress_indicator.dart';
import '../widgets/sweet_alert.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isLoadingKardex = true;
  List<KardexModel> _kardexMovements = [];
  bool _isKardexLoaded = false;

  String _getProductImageUrl(String? localPath) {
    if (localPath == null || localPath.isEmpty) return '';
    if (localPath.startsWith('http://') || localPath.startsWith('https://')) {
      return localPath;
    }
    final cleanedPath = localPath
        .replaceAll('C:\\Users\\aldo1\\Documents\\InventarioAPP\\', '')
        .replaceAll('C:\\Users\\aldo1\\Documents\\InventarioAPP', '')
        .replaceAll('\\', '/');
    
    final serverBase = DbConfig.apiBaseUrl.replaceAll('/api', '');
    return '$serverBase/api/uploads/$cleanedPath';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isKardexLoaded) {
      final product = ModalRoute.of(context)!.settings.arguments as ProductModel;
      if (product.id != null) {
        _isKardexLoaded = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadRecentMovements(product.id!);
          }
        });
      } else {
        setState(() {
          _isLoadingKardex = false;
        });
      }
    }
  }

  Future<void> _loadRecentMovements(String productId) async {
    final movements = await Provider.of<ProductProvider>(context, listen: false)
        .fetchProductKardex(productId);
    if (mounted) {
      setState(() {
        // Ordenamos descendente para mostrar los más recientes arriba
        _kardexMovements = List<KardexModel>.from(movements.reversed);
        _isLoadingKardex = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialProduct = ModalRoute.of(context)!.settings.arguments as ProductModel;
    final productProvider = Provider.of<ProductProvider>(context);
    final product = productProvider.products.firstWhere(
      (p) => p.id == initialProduct.id,
      orElse: () => initialProduct,
    );
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Cálculos comerciales
    final double purchase = product.purchasePrice ?? 0.0;
    final double sale = product.price;
    final double margin = sale > 0 ? ((sale - purchase) / sale) * 100 : 0.0;

    // Estado del stock
    Color stockColor = Colors.greenAccent;
    String stockStatusText = "Stock normal";
    if (product.stock == 0) {
      stockColor = Colors.redAccent;
      stockStatusText = "Stock crítico (Agotado)";
    } else if (product.stock <= (product.minStock ?? 0)) {
      stockColor = Colors.orangeAccent;
      stockStatusText = "Stock bajo (Reordenar)";
    }

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: Stack(
        children: [
          // Blur Orbs Premium
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
                _buildHeader(context, product),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductIdentityCard(context, product, stockColor, stockStatusText),
                        const SizedBox(height: 20),
                        _buildQRCodeSection(context, product),
                        const SizedBox(height: 25),
                        
                        _buildSectionTitle(context, 'Métricas Comerciales'),
                        const SizedBox(height: 15),
                        _buildMetricsGrid(context, product, purchase, sale, margin),
                        const SizedBox(height: 25),
                        
                        _buildSectionTitle(context, 'Descripción'),
                        const SizedBox(height: 15),
                        _buildDescriptionArea(context, product.description),
                        const SizedBox(height: 25),

                        _buildSectionTitle(context, 'Fechas de Auditoría'),
                        const SizedBox(height: 15),
                        _buildAuditDates(context),
                        const SizedBox(height: 25),

                        _buildPepsLotsButton(context, product),
                        const SizedBox(height: 25),

                        _buildSectionTitle(context, 'Últimos 5 Movimientos'),
                        const SizedBox(height: 15),
                        _buildRecentMovementsSection(context, product),
                        const SizedBox(height: 40),

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

  Widget _buildHeader(BuildContext context, ProductModel product) {
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
                  'Ficha de Producto',
                  style: TextStyle(
                     color: AppColors.getSubtextColor(context),
                     fontSize: 12,
                     fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  product.name,
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
          const SizedBox(width: 15),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context, 
                AppRoutes.addProduct, 
                arguments: product,
              ).then((_) {
                // Refresh list
                Provider.of<ProductProvider>(context, listen: false).fetchProducts();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.edit_rounded, color: AppColors.moradoPrincipal, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.moradoPrincipal,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildProductIdentityCard(
    BuildContext context, 
    ProductModel product, 
    Color stockColor, 
    String stockStatusText,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen o ícono de repuesto
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.moradoPrincipal.withValues(alpha: 0.2), AppColors.azulPrincipal.withValues(alpha: 0.1)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.moradoPrincipal.withValues(alpha: 0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(
                      _getProductImageUrl(product.imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.inventory_2_rounded,
                        color: AppColors.moradoPrincipal,
                        size: 36,
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.moradoPrincipal,
                            ),
                          ),
                        );
                      },
                    )
                  : const Icon(Icons.inventory_2_rounded, color: AppColors.moradoPrincipal, size: 36),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.moradoPrincipal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.category ?? 'General',
                        style: const TextStyle(
                          color: AppColors.moradoPrincipal,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: stockColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        stockStatusText,
                        style: TextStyle(
                          color: stockColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  product.name,
                  style: TextStyle(
                    color: AppColors.getTextColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'SKU: ${product.sku ?? "N/D"}',
                  style: TextStyle(
                    color: AppColors.getSubtextColor(context).withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Medida: ${product.unitMeasure ?? "Unidad"}',
                  style: TextStyle(
                    color: AppColors.getSubtextColor(context).withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context, 
    ProductModel product,
    double purchase,
    double sale,
    double margin,
  ) {
    final bool isOutOfStock = product.stock <= 0;
    return Column(
      children: [
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
        Row(
          children: [
            Expanded(
              child: _buildDetailMetric(
                context,
                'STOCK DISPONIBLE',
                isOutOfStock ? 'Agotado' : '${product.stock} u.',
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
                '${product.taxPercentage?.toStringAsFixed(0) ?? "0"}%',
                Icons.percent_rounded,
                Colors.tealAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailMetric(
    BuildContext context, 
    String label, 
    String value, 
    IconData icon, 
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
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

  Widget _buildDescriptionArea(BuildContext context, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Text(
        description.isEmpty ? 'Este producto no cuenta con una descripción detallada.' : description,
        style: TextStyle(
          color: AppColors.getTextColor(context),
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildAuditDates(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CREACIÓN',
                  style: TextStyle(
                    color: AppColors.getSubtextColor(context),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '29/05/2026 17:30',
                  style: TextStyle(
                    color: AppColors.getTextColor(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 35, color: Colors.white10),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ÚLTIMA MODIFICACIÓN',
                  style: TextStyle(
                    color: AppColors.getSubtextColor(context),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Hoy (Hace unos instantes)',
                  style: TextStyle(
                    color: AppColors.getTextColor(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMovementsSection(BuildContext context, ProductModel product) {
    if (_isLoadingKardex) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const WavyProgressIndicator(width: 100, height: 20, strokeWidth: 3),
      );
    }

    if (_kardexMovements.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off_rounded, color: AppColors.getSubtextColor(context).withValues(alpha: 0.4), size: 36),
            const SizedBox(height: 10),
            Text(
              'Sin movimientos registrados',
              style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Obtenemos los últimos 5 movimientos
    final recent5 = _kardexMovements.take(5).toList();

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent5.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, index) {
              final move = recent5[index];
              final isEntrada = move.type == 'ENTRADA';
              
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isEntrada ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEntrada ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: isEntrada ? Colors.greenAccent : Colors.redAccent,
                    size: 16,
                  ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      move.type,
                      style: TextStyle(
                        color: isEntrada ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${isEntrada ? "+" : "-"}${move.quantity} u.',
                      style: TextStyle(
                        color: AppColors.getTextColor(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Por: ${move.userName}',
                        style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11),
                      ),
                      Text(
                        '${move.date.day}/${move.date.month}/${move.date.year} ${move.date.hour.toString().padLeft(2, '0')}:${move.date.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.6), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        
        // BOTÓN: Ver Kardex Histórico
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context, 
              AppRoutes.productKardex,
              arguments: {
                'product': product,
                'kardex': List<KardexModel>.from(_kardexMovements.reversed), // lo pasamos cronológico (viejo a nuevo) para el Kardex
              },
            );
          },
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.moradoPrincipal, Color(0xFF6A11CB)],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppColors.moradoPrincipal.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Ver Kardex Histórico',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQRCodeSection(BuildContext context, ProductModel product) {
    final String qrData = product.sku ?? product.id ?? product.name;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Código QR de Producto',
            style: TextStyle(
              color: AppColors.getTextColor(context),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 110.0,
                  gapless: false,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.getTextColor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Código/SKU: $qrData',
                      style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Precio: \$${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.azulPrincipal,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GestureDetector(
                          onTap: () => _showQRQuantityDialog(context, product),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.moradoPrincipal, AppColors.azulPrincipal],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Icon(Icons.download_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Descargar QR',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _simulateThermalPrinting(context, product),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.getBackgroundColor(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Icon(Icons.print_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Imprimir POS',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  void _showQRQuantityDialog(BuildContext context, ProductModel product) {
    int qty = 1;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.getCardColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cantidad de Etiquetas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecciona cuántas etiquetas QR de 10cm x 10cm deseas generar en el archivo PDF.',
                style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => setDialogState(() { if (qty > 1) qty--; }),
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.moradoPrincipal, size: 30),
                  ),
                  const SizedBox(width: 15),
                  Text('$qty', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 15),
                  IconButton(
                    onPressed: () => setDialogState(() { if (qty < 100) qty++; }),
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.moradoPrincipal, size: 30),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: TextStyle(color: AppColors.getSubtextColor(context))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.moradoPrincipal),
              onPressed: () {
                Navigator.pop(ctx);
                _generateAndShareQRLabels(context, product, qty);
              },
              child: const Text('Generar PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndShareQRLabels(BuildContext context, ProductModel product, int quantity) async {
    final doc = pw.Document();
    final int itemsPerPage = 8;

    for (int i = 0; i < quantity; i += itemsPerPage) {
      final int end = (i + itemsPerPage < quantity) ? i + itemsPerPage : quantity;
      final int pageItemsCount = end - i;

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(1.5 * PdfPageFormat.cm),
          build: (pw.Context ctx) {
            return pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              crossAxisSpacing: 1.0 * PdfPageFormat.cm,
              mainAxisSpacing: 1.0 * PdfPageFormat.cm,
              children: List<pw.Widget>.generate(pageItemsCount, (index) {
                return pw.Container(
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  padding: const pw.EdgeInsets.all(0.5 * PdfPageFormat.cm),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: product.sku ?? product.id ?? product.name,
                    width: 140,
                    height: 140,
                  ),
                );
              }),
            );
          },
        ),
      );
    }

    final bytes = await doc.save();
    
    // Guardar en la carpeta pública de descargas (Android) con fallbacks
    bool savedLocally = false;
    String localPath = '';
    try {
      final cleanedName = product.name.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_');
      final filename = '${cleanedName}_qr.pdf';
      
      io.Directory? downloadDir;
      if (io.Platform.isAndroid) {
        final publicDir = io.Directory('/storage/emulated/0/Download');
        if (await publicDir.exists()) {
          downloadDir = publicDir;
        }
      }
      
      if (downloadDir == null) {
        try {
          downloadDir = await getDownloadsDirectory();
        } catch (_) {}
      }
      if (downloadDir == null) {
        try {
          downloadDir = await getExternalStorageDirectory();
        } catch (_) {}
      }
      
      if (downloadDir != null) {
        final file = io.File('${downloadDir.path}/$filename');
        await file.writeAsBytes(bytes);
        savedLocally = true;
        localPath = file.path;
      }
    } catch (e) {
      // Ignorar si falla
    }

    if (context.mounted) {
      if (savedLocally) {
        SweetAlert.show(
          context,
          title: 'PDF Descargado',
          message: 'El archivo de etiquetas se ha guardado en la carpeta de Descargas:\n\n${localPath.split(io.Platform.pathSeparator).last}',
          type: SweetAlertType.success,
        );
      }
    }

    final cleanedShareName = product.name.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_');
    await Printing.sharePdf(bytes: bytes, filename: '${cleanedShareName}_qr.pdf');
  }

  void _simulateThermalPrinting(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) {
        double progress = 0.0;
        String statusText = "Buscando impresoras térmicas Bluetooth/Wi-Fi...";
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future.delayed(const Duration(milliseconds: 800), () {
              if (ctx.mounted && progress == 0.0) {
                setDialogState(() {
                  progress = 0.4;
                  statusText = "Conectando a 'SPP-R200II' (Bluetooth 5.0)...";
                });
              }
            });
            Future.delayed(const Duration(milliseconds: 1600), () {
              if (ctx.mounted && progress == 0.4) {
                setDialogState(() {
                  progress = 0.8;
                  statusText = "Transmitiendo datos de etiqueta de 58mm...";
                });
              }
            });
            Future.delayed(const Duration(milliseconds: 2400), () {
              if (ctx.mounted && progress == 0.8) {
                setDialogState(() {
                  progress = 1.0;
                  statusText = "¡Etiqueta física impresa con éxito!";
                });
              }
            });

            return Dialog(
              backgroundColor: AppColors.getCardColor(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.print_rounded, color: AppColors.moradoPrincipal, size: 48),
                    const SizedBox(height: 15),
                    const Text(
                      'Impresión Térmica POS',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.azulPrincipal),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      statusText,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12),
                    ),
                    const SizedBox(height: 25),
                    if (progress >= 1.0)
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          width: double.infinity,
                          height: 45,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.moradoPrincipal, AppColors.azulPrincipal]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Listo',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPepsLotsButton(BuildContext context, ProductModel product) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/product-lots',
        arguments: product,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6A11CB).withValues(alpha: 0.15),
              const Color(0xFF2575FC).withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6A11CB).withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A11CB).withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.layers_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lotes PEPS / FIFO',
                    style: TextStyle(
                      color: AppColors.getTextColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Ver trazabilidad por lote · Activos y agotados',
                    style: TextStyle(
                      color: AppColors.getSubtextColor(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.getSubtextColor(context).withValues(alpha: 0.5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

