import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/routes.dart';
import '../utils/app_colors.dart';
import '../utils/db_config.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final int _selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = Provider.of<AuthProvider>(context, listen: false).user?.role;
      if (role != 'ADMIN') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acceso denegado. Se requiere rol ADMIN.')));
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlurOrb(AppColors.moradoPrincipal.withValues(alpha: isDark ? 0.1 : 0.05), 300),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _buildBlurOrb(AppColors.azulPrincipal.withValues(alpha: isDark ? 0.1 : 0.05), 250),
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
                        _buildSectionTitle('Preferencias', context),
                        const SizedBox(height: 15),
                        _buildSettingsGroup(context, [
                          _buildSettingItem(
                            context,
                            Icons.palette_outlined, 
                            'Apariencia', 
                            isDark ? 'Modo Oscuro activado' : 'Modo Claro activado', 
                            trailing: _buildBadge(context, isDark ? 'Oscuro' : 'Claro', isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded),
                            onTap: () => themeProvider.toggleTheme(),
                          ),
                          _buildSettingItem(context, Icons.notifications_none_rounded, 'Notificaciones', 'Gestiona avisos', trailing: _buildSwitch(context, true)),
                          _buildSettingItem(context, Icons.trending_up_rounded, 'Moneda', 'Principal', trailing: _buildBadge(context, r'USD ($)', null)),
                          _buildSettingItem(context, Icons.language_rounded, 'Idioma', 'Aplicación', trailing: _buildBadge(context, 'Español', null)),
                          _buildSettingItem(
                            context,
                            Icons.business_center_outlined, 
                            'Proveedores', 
                            'Gestionar proveedores', 
                            onTap: () => Navigator.pushNamed(context, AppRoutes.suppliers),
                          ),
                          _buildSettingItem(
                            context,
                            Icons.warehouse_outlined, 
                            'Almacenes', 
                            'Gestionar bodegas y ubicaciones', 
                            onTap: () => Navigator.pushNamed(context, AppRoutes.warehouses),
                          ),
                          _buildSettingItem(
                            context,
                            Icons.assessment_outlined, 
                            'Inventario por Almacén', 
                            'Ver existencias valoradas por sucursal', 
                            onTap: () => Navigator.pushNamed(context, AppRoutes.inventoryByWarehouse),
                          ),
                          _buildSettingItem(
                            context,
                            Icons.swap_horiz_rounded, 
                            'Transferencias', 
                            'Mover mercancía entre almacenes', 
                            onTap: () => Navigator.pushNamed(context, AppRoutes.transfers),
                          ),
                        ]),
                        const SizedBox(height: 25),
                        _buildSectionTitle('Seguridad', context),
                        const SizedBox(height: 15),
                        _buildSettingsGroup(context, [
                          _buildSettingItem(
                            context, 
                            Icons.lock_outline_rounded, 
                            'Actualizar contraseña', 
                            'Cambia tu clave de acceso', 
                            color: Colors.greenAccent,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.updatePassword),
                          ),
                          _buildSettingItem(context, Icons.security_outlined, 'Biometría', 'Huella o Face ID', color: Colors.greenAccent, trailing: _buildSwitch(context, true)),
                        ]),
                        const SizedBox(height: 25),
                        _buildSectionTitle('Más opciones', context),
                        const SizedBox(height: 15),
                        _buildOptionsGrid(context),
                        const SizedBox(height: 15),
                        _buildSettingsGroup(context, [
                          _buildSettingItem(
                            context,
                            Icons.backup_outlined,
                            'Respaldo Manual',
                            'Crear copia de seguridad de la BD',
                            color: Colors.blueAccent,
                            onTap: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Generando respaldo en el servidor...')),
                              );
                              try {
                                final response = await http.post(Uri.parse('${DbConfig.apiBaseUrl}/backup'));
                                if (response.statusCode == 200) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Respaldo generado exitosamente.'), backgroundColor: Colors.green),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Error al generar respaldo.'), backgroundColor: Colors.red),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Error de conexión con el servidor.'), backgroundColor: Colors.red),
                                );
                              }
                            },
                          ),
                        ]),
                        const SizedBox(height: 30),
                        _buildLogoutButton(context),
                        const SizedBox(height: 20),
                        Center(child: Text('Versión 1.2.3 (Build 45) 🛡️', style: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.5), fontSize: 12))),
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
                Text('Ajustes', style: TextStyle(color: AppColors.getTextColor(context), fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Personaliza tu experiencia', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 13)),
              ],
            ),
          ),
          const CircleAvatar(radius: 20, backgroundImage: NetworkImage('https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=150&auto=format&fit=crop')),
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

  Widget _buildBusinessCard(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.moradoPrincipal.withValues(alpha: isDark ? 0.4 : 0.2), AppColors.azulPrincipal.withValues(alpha: isDark ? 0.1 : 0.05)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: AppColors.moradoPrincipal.withValues(alpha: 0.05), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 55, width: 55,
                decoration: BoxDecoration(color: AppColors.getCardColor(context), shape: BoxShape.circle, border: Border.all(color: AppColors.moradoPrincipal, width: 2)),
                child: Icon(Icons.inventory_2_rounded, color: AppColors.moradoPrincipal, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text('Negocio Pro', 
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.moradoPrincipal.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(5)),
                          child: const Text('Premium', style: TextStyle(color: AppColors.moradoPrincipal, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    Text('juan.negocio@email.com', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11), overflow: TextOverflow.ellipsis),
                    Text('ID: NEG-2024-001', style: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.7), fontSize: 10)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.getSubtextColor(context).withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Uso: 60%', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 10)),
              Text('6 GB / 10 GB', style: TextStyle(color: AppColors.getTextColor(context), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(value: 0.6, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation<Color>(AppColors.moradoPrincipal), minHeight: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Text(title, style: TextStyle(color: AppColors.getTextColor(context), fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _buildSettingsGroup(BuildContext context, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context), 
        borderRadius: BorderRadius.circular(22), 
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildSettingItem(BuildContext context, IconData icon, String title, String sub, {Widget? trailing, Color? color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: (color ?? AppColors.moradoPrincipal).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color ?? AppColors.moradoPrincipal, size: 18),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.w500, fontSize: 14)),
                  Text(sub, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 10)),
                ],
              ),
            ),
            if (trailing != null) trailing else Icon(Icons.chevron_right_rounded, color: AppColors.getSubtextColor(context).withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.getSubtextColor(context).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, color: AppColors.moradoPrincipal, size: 12), const SizedBox(width: 4)],
          Text(text, style: TextStyle(color: AppColors.getTextColor(context), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSwitch(BuildContext context, bool val) {
    return Transform.scale(scale: 0.8, child: Switch(value: val, onChanged: (v) {}, activeColor: AppColors.moradoPrincipal));
  }

  Widget _buildOptionsGrid(BuildContext context) {
     return Column(
        children: [
          Row(children: [
            _optionGridItem(context, Icons.cloud_download_rounded, 'Copia', '8:30 AM', Colors.blue),
            const SizedBox(width: 12),
            _optionGridItem(context, Icons.download_rounded, 'Exportar', 'Datos', Colors.orange),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _optionGridItem(context, Icons.help_outline, 'Ayuda', 'FAQs', Colors.redAccent),
            const SizedBox(width: 12),
            _optionGridItem(context, Icons.comment_outlined, 'Feedback', 'Opinión', AppColors.moradoPrincipal),
          ]),
        ]
    );
  }

  Widget _optionGridItem(BuildContext context, IconData icon, String title, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context), 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 12)),
            Text(sub, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity, height: 50,
        decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
        child: const Center(child: Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
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
          else if (i == 3) Navigator.pushReplacementNamed(context, AppRoutes.exits);
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
