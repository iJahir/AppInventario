import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../utils/routes.dart';
import '../utils/db_config.dart';
import '../services/notification_service.dart';
import '../widgets/sweet_alert.dart';
import '../widgets/transaction_detail_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  int _profileTapCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts().then((_) {
        if (mounted) {
          _triggerDailySummaryNotification();
        }
      });
      Provider.of<InventoryProvider>(context, listen: false).fetchTransactions();
      Provider.of<InventoryProvider>(context, listen: false).fetchConfigData();
    });
  }

  void _triggerDailySummaryNotification() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final outOfStockCount = productProvider.products.where((p) => p.stock == 0).length;
    final lowStockCount = productProvider.products.where((p) => p.stock > 0 && p.stock <= (p.minStock ?? 0)).length;
    
    if (outOfStockCount > 0 || lowStockCount > 0) {
      await NotificationService.showDailySummaryNotification(
        id: 999,
        criticalCount: lowStockCount,
        outOfStockCount: outOfStockCount,
      );
    }
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
            child: _buildBlurOrb(AppColors.moradoPrincipal.withValues(alpha: isDark ? 0.1 : 0.03), 250),
          ),
          
          SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildInicioPage(context),
                const Center(child: Text('Cargando Productos...')),
                const Center(child: Text('Cargando Entradas...')),
                const Center(child: Text('Cargando Salidas...')),
                const Center(child: Text('Cargando Ajustes...')),
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
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildInicioPage(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildHeader(context, 'Hola, ${Provider.of<AuthProvider>(context).user?.name ?? "Usuario"} 👋', 'Bienvenido de nuevo'),
          const SizedBox(height: 30),
          _buildSummaryCard(),
          const SizedBox(height: 25),
          _buildQuickActions(context),
          const SizedBox(height: 25),
          _buildSectionTitle(context, 'Actividad reciente'),
          const SizedBox(height: 15),
          _buildActivityList(context),
          const SizedBox(height: 25),
          _buildWarehouseMovementsSection(context),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accesos Directos Ejecutivos',
          style: TextStyle(
            color: AppColors.getTextColor(context),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildQuickActionItem(
                context: context,
                label: 'Reportes',
                icon: Icons.bar_chart_rounded,
                color: Colors.purpleAccent,
                route: AppRoutes.reports,
              ),
              _buildQuickActionItem(
                context: context,
                label: 'Transferir',
                icon: Icons.swap_horiz_rounded,
                color: AppColors.azulPrincipal,
                route: AppRoutes.transfers,
              ),
              _buildQuickActionItem(
                context: context,
                label: 'Auditoría',
                icon: Icons.warehouse_rounded,
                color: Colors.orangeAccent,
                route: AppRoutes.inventoryByWarehouse,
              ),
              _buildQuickActionItem(
                context: context,
                label: 'Sedes/Almacén',
                icon: Icons.store_rounded,
                color: Colors.tealAccent,
                route: AppRoutes.warehouses,
              ),
              _buildQuickActionItem(
                context: context,
                label: 'Proveedores',
                icon: Icons.business_rounded,
                color: Colors.pinkAccent,
                route: AppRoutes.suppliers,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: AppColors.getTextColor(context),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProfileImageUrl(String? localPath) {
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

  Widget _buildHeader(BuildContext context, String title, String subtitle) {
    final user = Provider.of<AuthProvider>(context).user;
    final imageUrl = _getProfileImageUrl(user?.profileImageUrl);
    return Row(
      children: [
        _buildLogoBox(context),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: AppColors.getTextColor(context), fontSize: 20, fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 13)),
            ],
          ),
        ),
        _buildCircleIconButton(context, Icons.bar_chart_rounded, onTap: () => Navigator.pushNamed(context, AppRoutes.reports)),
        const SizedBox(width: 12),
        _buildCircleIconButton(context, Icons.notifications_none_rounded, onTap: () => _showNotificationModal(context)),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            _profileTapCount++;
            if (_profileTapCount >= 3) {
              _profileTapCount = 0;
              _confirmLogout(context);
            }
          },
          child: CircleAvatar(
            radius: 22, 
            backgroundColor: AppColors.moradoPrincipal.withValues(alpha: 0.2),
            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty ? Icon(Icons.person_rounded, color: AppColors.moradoPrincipal, size: 22) : null,
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    SweetAlert.show(
      context,
      title: '¿Cerrar Sesión?',
      message: '¿Estás seguro de que deseas cerrar la sesión activa?',
      type: SweetAlertType.warning,
      confirmButtonText: 'Cerrar Sesión',
      cancelButtonText: 'Cancelar',
      onConfirm: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
        }
      },
    );
  }

  void _showNotificationModal(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final recentTx = inventoryProvider.transactions.take(5).toList();

    // Buscar si hay algún ajuste crítico reciente (Daño o Servicio)
    bool hasCriticalAdjustment = false;
    String adjustmentDetail = '';
    for (var tx in recentTx) {
      if (tx['type'] == 'SALIDA' && (tx['reason'] == 'Daño' || tx['reason'] == 'Servicio')) {
        hasCriticalAdjustment = true;
        final pNames = (tx['items'] as List?)?.map((i) => i['productName']).join(', ') ?? 'Varios';
        adjustmentDetail = 'Ajuste por ${tx['reason']}: $pNames';
        break;
      }
    }

    if (hasCriticalAdjustment) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.getCardColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              const SizedBox(width: 10),
              Text('Alerta de Ajuste', style: TextStyle(color: AppColors.getTextColor(context))),
            ],
          ),
          content: Text(
            'Se ha registrado un ajuste técnico en el inventario recientemente:\n\n$adjustmentDetail.\n\nPor favor revise los reportes para más detalles.',
            style: TextStyle(color: AppColors.getSubtextColor(context)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _openNotificationsPanel(context, recentTx, hasCriticalAdjustment, adjustmentDetail);
              },
              child: const Text('Ver Notificaciones', style: TextStyle(color: AppColors.moradoPrincipal)),
            ),
          ],
        ),
      );
      return;
    }

    _openNotificationsPanel(context, recentTx, hasCriticalAdjustment, adjustmentDetail);
  }

  void _openNotificationsPanel(BuildContext context, List<Map<String, dynamic>> recentTx, bool hasCriticalAdjustment, String adjustmentDetail) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topRight,
          child: Container(
            margin: const EdgeInsets.only(top: 80, right: 20),
            padding: const EdgeInsets.all(20),
            width: 320,
            decoration: BoxDecoration(
              color: AppColors.getCardColor(context),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.moradoPrincipal.withValues(alpha: 0.3)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Notificaciones', style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.moradoPrincipal.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                        child: Text('${recentTx.length} Nuevas', style: const TextStyle(color: AppColors.moradoPrincipal, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (hasCriticalAdjustment)
                    Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Alerta: Se detectó un ajuste reciente.\n($adjustmentDetail)',
                              style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (recentTx.isEmpty)
                    const Text('No hay notificaciones recientes.', style: TextStyle(color: Colors.white54, fontSize: 12))
                  else
                    ...recentTx.map((tx) {
                      final isEntrada = tx['type'] == 'ENTRADA';
                      final isSalida = tx['type'] == 'SALIDA';
                      final pNames = (tx['items'] as List?)?.map((i) => i['productName']).join(', ') ?? 'Varios';
                      
                      int totalQty = 0;
                      if (tx['items'] != null && tx['items'] is List) {
                        for (var item in tx['items']) {
                          totalQty += (item['quantity'] as num?)?.toInt() ?? 0;
                        }
                      }
                      
                      String title = isEntrada ? 'Entrada registrada' : (isSalida ? 'Salida registrada' : 'Transferencia');
                      if (isSalida) {
                        final reason = tx['reason'] ?? 'Venta';
                        title = 'Salida ($reason)';
                      }
                      
                      final color = isEntrada ? Colors.greenAccent : (isSalida ? Colors.orangeAccent : Colors.blueAccent);
                      final icon = isEntrada ? Icons.download_rounded : (isSalida ? Icons.upload_rounded : Icons.swap_horiz_rounded);
                      return _notificationItem(context, icon, title, '$pNames ($totalQty uds.)', color);
                    }),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cerrar', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.1, -0.1), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  Widget _notificationItem(BuildContext context, IconData icon, String title, String sub, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 13)),
                Text(sub, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLogoUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    final serverBase = DbConfig.apiBaseUrl.replaceAll('/api', '');
    return '$serverBase/api/uploads/$relativePath';
  }

  Widget _buildLogoBox(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final logoNetworkUrl = _getLogoUrl(inventoryProvider.logoUrl);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: logoNetworkUrl.isNotEmpty
            ? Image.network(
                logoNetworkUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.inventory_2_rounded, color: AppColors.azulPrincipal, size: 28),
              )
            : Icon(Icons.inventory_2_rounded, color: AppColors.azulPrincipal, size: 28),
      ),
    );
  }

  Widget _buildIconBox(BuildContext context, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.getCardColor(context), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
      child: Icon(icon, color: AppColors.azulPrincipal, size: 28),
    );
  }

  Widget _buildCircleIconButton(BuildContext context, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.getCardColor(context), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
        child: Icon(icon, color: AppColors.getTextColor(context), size: 22),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final productProvider = Provider.of<ProductProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final totalProducts = productProvider.products.length;
    final totalStock = productProvider.products.fold(0, (sum, p) => sum + p.stock);
    final totalWarehouses = inventoryProvider.warehouses.length;
    final totalSuppliers = inventoryProvider.suppliers.length;
    
    // Calcular valor total del inventario: existencias * precio de compra (o precio * 0.7 de fallback)
    final double totalValue = productProvider.products.fold(
      0.0, 
      (sum, p) => sum + (p.stock * (p.purchasePrice ?? (p.price * 0.7)))
    );

    // Identificar alertas de stock
    final outOfStockCount = productProvider.products.where((p) => p.stock == 0).length;
    final lowStockCount = productProvider.products.where((p) => p.stock > 0 && p.stock <= (p.minStock ?? 0)).length;
    final totalAlerts = outOfStockCount + lowStockCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Principal: Valor Total de Inventario (Financial Portfolio)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.moradoPrincipal.withValues(alpha: 0.85),
                AppColors.azulPrincipal.withValues(alpha: 0.85)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: AppColors.azulPrincipal.withValues(alpha: 0.35),
                blurRadius: 25,
                offset: const Offset(0, 10)
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Valor de Inventario (Costo)',
                            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        const Text('En tiempo real', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '\$${totalValue.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Unidades globales: $totalStock',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const Icon(Icons.trending_up_rounded, color: Colors.greenAccent, size: 20),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        
        // Cuadrícula 2x2 de KPIs Ejecutivos Premium
        Row(
          children: [
            Expanded(
              child: _buildExecutiveKpiCard(
                title: 'Total Productos',
                value: totalProducts.toString(),
                subtitle: 'SKUs Registrados',
                icon: Icons.grid_view_rounded,
                color: AppColors.azulPrincipal,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildExecutiveKpiCard(
                title: 'Almacenes',
                value: totalWarehouses.toString(),
                subtitle: 'Sedes Activas',
                icon: Icons.warehouse_rounded,
                color: AppColors.moradoPrincipal,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildExecutiveKpiCard(
                title: 'Proveedores',
                value: totalSuppliers.toString(),
                subtitle: 'Socios Activos',
                icon: Icons.people_alt_rounded,
                color: Colors.teal,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildExecutiveKpiCard(
                title: 'Alertas de Stock',
                value: totalAlerts.toString(),
                subtitle: outOfStockCount > 0 ? '$outOfStockCount Agotados' : '$lowStockCount Stock Bajo',
                icon: Icons.warning_amber_rounded,
                color: totalAlerts > 0 ? (outOfStockCount > 0 ? Colors.redAccent : Colors.orangeAccent) : Colors.greenAccent,
                isDark: isDark,
                glow: totalAlerts > 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExecutiveKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    bool glow = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: glow ? color.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
          width: glow ? 1.5 : 1,
        ),
        boxShadow: [
          if (glow)
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 15,
              spreadRadius: 1,
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.getSubtextColor(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: AppColors.getTextColor(context),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: glow ? color : AppColors.getSubtextColor(context).withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: glow ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseMovementsSection(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    
    // Calcular movimientos por almacén
    final Map<String, int> warehouseMovements = {};
    for (var tx in inventoryProvider.transactions) {
      final wName = tx['warehouseName'] ?? 'Almacén';
      warehouseMovements[wName] = (warehouseMovements[wName] ?? 0) + 1;
    }

    // Para almacenes sin movimientos, asegurar que aparezcan con 0
    for (var w in inventoryProvider.warehouses) {
      final wName = w['name'] ?? 'Almacén';
      if (!warehouseMovements.containsKey(wName)) {
        warehouseMovements[wName] = 0;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Movimientos por Almacén'),
        const SizedBox(height: 15),
        if (inventoryProvider.warehouses.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.getCardColor(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Center(
              child: Text(
                'No hay almacenes registrados.',
                style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 13),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.getCardColor(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: warehouseMovements.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.moradoPrincipal.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warehouse_outlined, color: AppColors.moradoPrincipal, size: 18),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                color: AppColors.getTextColor(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${entry.value} transacciones registradas',
                              style: TextStyle(
                                color: AppColors.getSubtextColor(context),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.moradoPrincipal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${entry.value} movs',
                          style: const TextStyle(
                            color: AppColors.moradoPrincipal,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: AppColors.getTextColor(context), fontSize: 18, fontWeight: FontWeight.bold)),
        Text('Ver todo', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12)),
      ],
    );
  }

  Widget _buildActivityList(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    
    final List<Widget> activityWidgets = [];

    final recentTx = inventoryProvider.transactions.take(3).toList();
    for (var tx in recentTx) {
      final isEntrada = tx['type'] == 'ENTRADA';
      String title = isEntrada ? 'Entrada registrada' : 'Salida registrada';
      Color itemColor = isEntrada ? Colors.greenAccent : Colors.orangeAccent;
      
      if (!isEntrada) {
        final reason = tx['reason'] ?? 'Venta';
        if (reason == 'Daño') {
          title = 'Salida por Daño';
          itemColor = Colors.redAccent;
        } else if (reason == 'Servicio') {
          title = 'Salida por Servicio';
          itemColor = Colors.cyanAccent;
        } else if (reason == 'Consumo') {
          title = 'Consumo Interno';
          itemColor = Colors.orangeAccent;
        } else {
          title = 'Salida por Venta';
          itemColor = Colors.greenAccent;
        }
      }

      int totalQty = 0;
      if (tx['items'] != null && tx['items'] is List) {
        for (var item in tx['items']) {
          totalQty += (item['quantity'] as num?)?.toInt() ?? 0;
        }
      }

      final pNames = (tx['items'] as List?)?.map((i) => i['productName']).join(', ') ?? 'Varios';
      activityWidgets.add(
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) {
                return TransactionDetailSheet(tx: tx, isEntrada: isEntrada);
              },
            );
          },
          child: _activityItem(
            context, 
            title, 
            pNames, 
            isEntrada ? '+$totalQty' : '-$totalQty', 
            itemColor
          ),
        ),
      );
    }

    if (recentTx.isEmpty) {
      final recentProducts = productProvider.products.take(3).toList();
      for (var p in recentProducts) {
        activityWidgets.add(
          _activityItem(context, 'Nuevo producto', p.name, '>', AppColors.azulPrincipal)
        );
      }
    }

    if (activityWidgets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('No hay actividad reciente en la base de datos.', style: TextStyle(color: Colors.white30, fontSize: 13)),
      );
    }

    return Column(
      children: activityWidgets,
    );
  }

  Widget _activityItem(BuildContext context, String t, String s, String v, Color c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10), 
            decoration: BoxDecoration(color: c.withValues(alpha: 0.1), shape: BoxShape.circle), 
            child: Icon(Icons.history, color: c, size: 18)
          ),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold)), Text(s, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12))])),
          Text(v, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPromotionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.getCardColor(context), borderRadius: BorderRadius.circular(25), border: Border.all(color: AppColors.azulPrincipal.withValues(alpha: 0.2))),
      child: Row(
        children: [
          Container(height: 60, width: 60, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.azulPrincipal, AppColors.moradoPrincipal]), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 30)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¡Todo bajo control!', style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Lleva un control eficiente de tu inventario.', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12)),
                const SizedBox(height: 5),
                Text('Ver reportes >', style: const TextStyle(color: AppColors.moradoPrincipal, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnakeNavBar(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double barWidth = width - 40;
    double itemWidth = barWidth / 5;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            left: (_selectedIndex * itemWidth) + (itemWidth / 2) - 30,
            top: 10,
            child: Container(
              width: 60,
              height: 55,
              decoration: BoxDecoration(
                color: AppColors.moradoPrincipal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.moradoPrincipal.withValues(alpha: 0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(color: AppColors.moradoPrincipal.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 1),
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            left: (_selectedIndex * itemWidth) + (itemWidth / 2) - 2.5,
            bottom: 8,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(color: AppColors.moradoPrincipal, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.moradoPrincipal, blurRadius: 4, spreadRadius: 1)]),
            ),
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
          if (i == 1) {
             Navigator.pushNamed(context, AppRoutes.products);
          } else if (i == 2) {
             Navigator.pushNamed(context, AppRoutes.entries);
          } else if (i == 3) {
             Navigator.pushReplacementNamed(context, AppRoutes.exits);
          } else if (i == 4) {
            Navigator.pushReplacementNamed(context, AppRoutes.settings);
          } else {
            setState(() => _selectedIndex = i);
          }
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
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
