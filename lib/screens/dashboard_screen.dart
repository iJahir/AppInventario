import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../utils/routes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      Provider.of<InventoryProvider>(context, listen: false).fetchTransactions();
      Provider.of<InventoryProvider>(context, listen: false).fetchConfigData();
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
          const SizedBox(height: 30),
          _buildSectionTitle(context, 'Actividad reciente'),
          const SizedBox(height: 15),
          _buildActivityList(context),
          const SizedBox(height: 25),
          _buildWarehouseMovementsSection(context),
          const SizedBox(height: 25),
          _buildPromotionCard(context),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title, String subtitle) {
    return Row(
      children: [
        _buildIconBox(context, Icons.inventory_2_rounded),
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
        const CircleAvatar(
          radius: 22, 
          backgroundImage: NetworkImage('https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=150&auto=format&fit=crop'),
        ),
      ],
    );
  }

  void _showNotificationModal(BuildContext context) {
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
            width: 280,
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
                        child: const Text('3 Nuevas', style: TextStyle(color: AppColors.moradoPrincipal, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _notificationItem(context, Icons.info_outline_rounded, 'Información general', 'El sistema se actualizó correctamente.', AppColors.azulPrincipal),
                  _notificationItem(context, Icons.swap_horiz_rounded, 'Movimientos', 'Se detectó una salida inusual de stock.', Colors.orangeAccent),
                  _notificationItem(context, Icons.star_outline_rounded, 'Premium', 'Disfruta de tus nuevas gráficas.', AppColors.moradoPrincipal),
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

    final totalProducts = productProvider.products.length.toString();
    final totalStock = productProvider.products.fold(0, (sum, p) => sum + p.stock).toString();
    final totalEntries = inventoryProvider.entries.length.toString();
    final totalExits = inventoryProvider.exits.length.toString();
    final totalWarehouses = inventoryProvider.warehouses.length.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.moradoPrincipal, AppColors.azulPrincipal], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppColors.azulPrincipal.withValues(alpha: 0.3), blurRadius: 25, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Resumen general', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                child: const Text('Hoy', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem(totalProducts, 'Productos', Icons.grid_view_rounded),
              _summaryItem(totalStock, 'En stock', Icons.inventory_rounded),
              _summaryItem(totalWarehouses, 'Almacenes', Icons.warehouse_rounded),
              _summaryItem(totalEntries, 'Entradas', Icons.download_rounded),
              _summaryItem(totalExits, 'Salidas', Icons.upload_rounded),
            ],
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

  Widget _summaryItem(String val, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 10),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center),
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
      final title = isEntrada ? 'Entrada registrada' : 'Salida registrada';
      final pNames = (tx['items'] as List?)?.map((i) => i['productName']).join(', ') ?? 'Varios';
      activityWidgets.add(
        _activityItem(
          context, 
          title, 
          pNames, 
          isEntrada ? '+${tx['items']?.length ?? 0}' : '-${tx['items']?.length ?? 0}', 
          isEntrada ? Colors.greenAccent : Colors.orangeAccent
        )
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
             Navigator.pushNamed(context, AppRoutes.exits);
          } else if (i == 4) {
             Navigator.pushNamed(context, AppRoutes.settings);
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
