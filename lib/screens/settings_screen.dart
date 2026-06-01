import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/routes.dart';
import '../utils/app_colors.dart';
import '../utils/db_config.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/inventory_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final int _selectedIndex = 4;
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricsPreference();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = Provider.of<AuthProvider>(context, listen: false).user?.role;
      if (role != 'ADMIN') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acceso denegado. Se requiere rol ADMIN.')));
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    });
  }

  Future<void> _loadBiometricsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final LocalAuthentication auth = LocalAuthentication();
      try {
        final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
        final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();
        
        if (!canAuthenticate) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Este dispositivo no soporta autenticación biométrica.')),
          );
          return;
        }
        
        final bool authenticated = await auth.authenticate(
          localizedReason: 'Por favor autentícate para activar el acceso rápido por Biometría',
          biometricOnly: true,
          persistAcrossBackgrounding: true,
        );
        
        if (!authenticated) return;

        // Pedir al usuario su contraseña para guardarla de forma segura
        final user = Provider.of<AuthProvider>(context, listen: false).user;
        if (user == null) return;

        final prefs = await SharedPreferences.getInstance();
        final String? alreadySaved = prefs.getString('biometric_password');

        if (alreadySaved == null || alreadySaved.isEmpty) {
          // Solicitar contraseña al usuario para guardarla
          final String? password = await _askUserPassword(context);
          if (password == null || password.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Se requiere la contraseña para activar la biometría.'), backgroundColor: Colors.orange),
            );
            return;
          }
          await prefs.setString('biometric_email', user.email);
          await prefs.setString('biometric_password', password);
        } else {
          // Actualizar el email por si cambió de usuario
          await prefs.setString('biometric_email', user.email);
        }
      } catch (e) {
        print("Error authenticating biometrics: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al verificar biometría: $e')),
        );
        return;
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometrics_enabled', value);
    if (!value) {
      // Al desactivar, limpiar credenciales guardadas
      await prefs.remove('biometric_email');
      await prefs.remove('biometric_password');
    }
    setState(() {
      _biometricsEnabled = value;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Acceso rápido con Biometría activado.' : 'Acceso rápido con Biometría desactivado.'),
        backgroundColor: value ? Colors.green : Colors.orange,
      ),
    );
  }

  /// Muestra un diálogo para que el usuario ingrese su contraseña
  Future<String?> _askUserPassword(BuildContext context) async {
    final TextEditingController passCtrl = TextEditingController();
    bool obscure = true;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.getCardColor(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const Icon(Icons.fingerprint_rounded, color: AppColors.moradoPrincipal, size: 28),
                  const SizedBox(width: 10),
                  Text('Confirmar Contraseña',
                      style: TextStyle(color: AppColors.getTextColor(context), fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ingresa tu contraseña actual para habilitar el acceso biométrico. Se guardará de forma segura en este dispositivo.',
                    style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passCtrl,
                    obscureText: obscure,
                    style: TextStyle(color: AppColors.getTextColor(context)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.1),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.moradoPrincipal),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.getSubtextColor(context), size: 20),
                        onPressed: () => setStateDialog(() => obscure = !obscure),
                      ),
                      hintText: 'Tu contraseña',
                      hintStyle: TextStyle(color: AppColors.getSubtextColor(context)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, null),
                  child: Text('Cancelar', style: TextStyle(color: AppColors.getSubtextColor(context))),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogCtx, passCtrl.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.moradoPrincipal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Confirmar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
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
                        _buildBusinessCard(context),
                        const SizedBox(height: 25),
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
                          _buildSettingItem(
                            context,
                            Icons.person_outline_rounded, 
                            'Editar Perfil', 
                            'Cambiar nombre y foto de perfil', 
                            onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
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
                            Icons.people_alt_rounded, 
                            'Clientes', 
                            'Gestionar clientes y compradores', 
                            onTap: () => Navigator.pushNamed(context, AppRoutes.customers),
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
                           _buildSettingItem(
                             context, 
                             Icons.security_outlined, 
                             'Biometría', 
                             'Huella o Face ID', 
                             color: Colors.greenAccent, 
                             trailing: Transform.scale(
                               scale: 0.8,
                               child: Switch(
                                 value: _biometricsEnabled,
                                 onChanged: _toggleBiometrics,
                                 activeColor: AppColors.moradoPrincipal,
                               ),
                             ),
                           ),
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
                        Center(child: Text('Versión 1.0.0 🛡️', style: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.5), fontSize: 12))),
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

  Widget _buildBlurOrb(Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final imageUrl = _getProfileImageUrl(user?.profileImageUrl);
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
          CircleAvatar(
            radius: 20, 
            backgroundColor: AppColors.moradoPrincipal.withValues(alpha: 0.2),
            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty ? Icon(Icons.person_rounded, color: AppColors.moradoPrincipal, size: 20) : null,
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

  Widget _buildBusinessCard(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final user = Provider.of<AuthProvider>(context).user;
    final imageUrl = _getProfileImageUrl(user?.profileImageUrl);
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
                decoration: BoxDecoration(
                  color: AppColors.getCardColor(context), 
                  shape: BoxShape.circle, 
                  border: Border.all(color: AppColors.moradoPrincipal, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27.5),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.person_rounded, color: AppColors.moradoPrincipal, size: 24),
                        )
                      : Icon(Icons.person_rounded, color: AppColors.moradoPrincipal, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user?.name ?? 'Usuario', 
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.moradoPrincipal.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(5)),
                          child: Text(
                            user?.role ?? 'ALMACENERO', 
                            style: const TextStyle(color: AppColors.moradoPrincipal, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Text(user?.email ?? 'usuario@email.com', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11), overflow: TextOverflow.ellipsis),
                    Text('ID de Usuario: ${user?.id ?? "N/D"}', style: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.7), fontSize: 10)),
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
              Text('Almacén Activo', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 10)),
              Text('Principal', style: TextStyle(color: AppColors.getTextColor(context), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(value: 1.0, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation<Color>(AppColors.moradoPrincipal), minHeight: 4),
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
            _optionGridItem(context, Icons.cloud_download_rounded, 'Copia', '8:30 AM', Colors.blue, onTap: () => _showBackupsListDialog(context)),
            const SizedBox(width: 12),
            _optionGridItem(context, Icons.download_rounded, 'Exportar', 'Datos', Colors.orange, onTap: () => _showExportBottomSheet(context)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _optionGridItem(context, Icons.help_outline, 'Ayuda', 'FAQs', Colors.redAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen()))),
            const SizedBox(width: 12),
            _optionGridItem(context, Icons.comment_outlined, 'Feedback', 'Opinión', AppColors.moradoPrincipal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackScreen()))),
          ]),
        ]
    );
  }

  Widget _optionGridItem(BuildContext context, IconData icon, String title, String sub, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }

  Future<void> _showBackupsListDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: AppColors.getCardColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.cloud_download_rounded, color: Colors.blue, size: 24),
              const SizedBox(width: 10),
              Text(
                'Copias de Seguridad',
                style: TextStyle(color: AppColors.getTextColor(context), fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: FutureBuilder<http.Response>(
              future: http.get(Uri.parse('${DbConfig.apiBaseUrl}/backups')),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
                  );
                }
                if (snapshot.hasError) {
                  return _buildBackupErrorState(context);
                }
                
                List<dynamic> backups = [];
                try {
                  if (snapshot.hasData && snapshot.data!.statusCode == 200) {
                    backups = jsonDecode(snapshot.data!.body);
                  }
                } catch (e) {
                  // Fallback
                }

                if (backups.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.backup_table_rounded, size: 48, color: AppColors.getSubtextColor(context).withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text('No hay respaldos automáticos aún', style: TextStyle(color: AppColors.getTextColor(context), fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Los respaldos se crean a las 2:00 AM', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11), textAlign: TextAlign.center),
                    ],
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: backups.length,
                  itemBuilder: (context, index) {
                    final backup = backups[index];
                    final String name = backup['name'] ?? 'Respaldo';
                    final String rawDate = backup['date'] ?? '';
                    final int sizeBytes = backup['size'] ?? 0;
                    final double sizeMb = sizeBytes / (1024 * 1024);
                    
                    String formattedDate = rawDate;
                    try {
                      final parsedDate = DateTime.parse(rawDate).toLocal();
                      formattedDate = '${parsedDate.day}/${parsedDate.month}/${parsedDate.year} - ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';
                    } catch (e) {
                      // Usar original
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.insert_drive_file_rounded, color: Colors.blue, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name, 
                                  style: TextStyle(color: AppColors.getTextColor(context), fontSize: 12, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(formattedDate, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 10)),
                                    const SizedBox(width: 8),
                                    Text('•', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 10)),
                                    const SizedBox(width: 8),
                                    Text('${sizeMb.toStringAsFixed(2)} MB', style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cerrar', style: TextStyle(color: AppColors.getSubtextColor(context))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBackupErrorState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
        const SizedBox(height: 12),
        Text('Error de conexión', style: TextStyle(color: AppColors.getTextColor(context), fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('No se pudieron obtener los respaldos desde el servidor.', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11), textAlign: TextAlign.center),
      ],
    );
  }

  void _showExportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getCardColor(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (BuildContext sheetContext) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50, height: 5,
                  decoration: BoxDecoration(color: AppColors.getSubtextColor(context).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Exportar Inventario',
                style: TextStyle(color: AppColors.getTextColor(context), fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona el formato en el que deseas exportar tus datos:',
                style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12),
              ),
              const SizedBox(height: 20),
              _buildExportOption(
                context,
                sheetContext,
                Icons.table_view_rounded,
                'Exportar a Excel (.xlsx)',
                'Formato ideal para cálculos y edición en Microsoft Excel.',
                Colors.green,
                () => _performRealExport(context, 'Excel (.xlsx)'),
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                context,
                sheetContext,
                Icons.picture_as_pdf_rounded,
                'Exportar a Reporte PDF (.pdf)',
                'Genera un documento PDF profesional con existencias y movimientos.',
                Colors.redAccent,
                () => _performRealExport(context, 'PDF (.pdf)'),
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                context,
                sheetContext,
                Icons.code_rounded,
                'Exportar a CSV (.csv)',
                'Formato ligero separado por comas para otros sistemas.',
                Colors.blue,
                () => _performRealExport(context, 'CSV (.csv)'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportOption(
    BuildContext context, 
    BuildContext sheetContext,
    IconData icon, 
    String title, 
    String description, 
    Color color,
    VoidCallback onTap
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        Navigator.pop(sheetContext);
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isDark ? 0.02 : 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: AppColors.getTextColor(context), fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 10)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.getSubtextColor(context).withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Future<void> _performRealExport(BuildContext context, String format) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext progressContext) {
        return AlertDialog(
          backgroundColor: AppColors.getCardColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.moradoPrincipal)),
              const SizedBox(height: 20),
              Text(
                'Generando Reporte...', 
                style: TextStyle(color: AppColors.getTextColor(context), fontSize: 16, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              Text(
                'Procesando existencias y movimientos para $format',
                style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      }
    );

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      await productProvider.fetchProducts();
      final products = productProvider.products;

      final directory = await getTemporaryDirectory();

      if (format.contains('PDF')) {
        final doc = pw.Document();
        final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
        await inventoryProvider.fetchTransactions();
        final transactions = inventoryProvider.transactions;

        doc.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(1.2 * PdfPageFormat.cm),
            header: (pw.Context context) {
              return pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(bottom: 0.8 * PdfPageFormat.cm),
                child: pw.Text(
                  'REPORTE DE INVENTARIO - ERP ENTERPRISE',
                  style: pw.TextStyle(color: PdfColors.grey, fontSize: 8),
                ),
              );
            },
            footer: (pw.Context context) {
              return pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(top: 0.8 * PdfPageFormat.cm),
                child: pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: const pw.TextStyle(color: PdfColors.grey, fontSize: 8),
                ),
              );
            },
            build: (pw.Context context) {
              return [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Reporte General del ERP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
                      pw.Text('v1.0.0', style: const pw.TextStyle(color: PdfColors.grey, fontSize: 9)),
                    ],
                  ),
                ),
                pw.Paragraph(
                  text: 'Este reporte consolida el estado actual de las existencias en almacén y el histórico total de transacciones (entradas y salidas) ejecutadas en el sistema.',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 15),
                
                pw.Text('1. Catálogo de Existencias de Productos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.purple800)),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: ['Nombre', 'SKU', 'Categoría', 'Stock', 'Mínimo', 'Costo', 'Venta'],
                  data: List<List<dynamic>>.generate(products.length, (index) {
                    final p = products[index];
                    return [
                      p.name,
                      p.sku ?? 'N/D',
                      p.category ?? 'General',
                      '${p.stock}',
                      '${p.minStock ?? 0}',
                      '\$${(p.purchasePrice ?? 0.0).toStringAsFixed(2)}',
                      '\$${p.price.toStringAsFixed(2)}',
                    ];
                  }),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.purple800),
                  rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: .5))),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellStyle: const pw.TextStyle(fontSize: 7.5),
                ),
                
                pw.SizedBox(height: 25),
                pw.Text('2. Historial de Transacciones (Entradas y Salidas)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.purple800)),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: ['ID', 'Operación', 'Almacén', 'Operador', 'Razón / Detalle', 'Fecha'],
                  data: List<List<dynamic>>.generate(transactions.length, (index) {
                    final t = transactions[index];
                    final String id = '#${t['id']?.toString() ?? 'N/D'}';
                    final String movementType = t['type'] ?? 'MOVIMIENTO';
                    final String warehouse = t['originWarehouseName'] ?? t['warehouseName'] ?? 'Almacén';
                    final String user = t['userName'] ?? 'Usuario';
                    
                    String detail = '';
                    if (movementType == 'ENTRADA') {
                      detail = 'Proveedor: ${t['supplierName'] ?? 'General'}';
                    } else if (movementType == 'SALIDA') {
                      detail = '${t['reason'] ?? "Venta"} (Cliente: ${t['customerName'] ?? "Consumidor"})';
                    } else {
                      detail = t['reason'] ?? 'Ajuste';
                    }

                    String dateStr = '';
                    if (t['date'] != null) {
                      try {
                        final parsedDate = DateTime.parse(t['date'].toString()).toLocal();
                        dateStr = '${parsedDate.day}/${parsedDate.month}/${parsedDate.year} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';
                      } catch (e) {
                        dateStr = t['date'].toString();
                      }
                    }
                    
                    return [
                      id,
                      movementType,
                      warehouse,
                      user,
                      detail,
                      dateStr,
                    ];
                  }),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.purple800),
                  rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: .5))),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellStyle: const pw.TextStyle(fontSize: 7.5),
                ),
              ];
            },
          ),
        );

        final docBytes = await doc.save();
        final pdfFile = File('${directory.path}/Inventario_Movimientos_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await pdfFile.writeAsBytes(docBytes);

        if (context.mounted) Navigator.pop(context); // Close progress dialog

        await Share.shareXFiles(
          [XFile(pdfFile.path, mimeType: 'application/pdf')],
          subject: 'Reporte Completo ERP ${DateTime.now().toLocal().toString().split(' ')[0]}',
        );
      } else {
        // Excel/CSV export
        final StringBuffer csvBuffer = StringBuffer();
        csvBuffer.write('\uFEFF'); // BOM for Excel
        csvBuffer.writeln('ID,Código (SKU),Nombre,Descripción,Precio Venta,Precio Compra,Stock,Categoría,Unidad Medida,Stock Mínimo');

        for (var p in products) {
          final String id = p.id ?? '';
          final String sku = p.sku ?? '';
          final String name = p.name.replaceAll('"', '""');
          final String desc = p.description.replaceAll('"', '""');
          final String price = p.price.toString();
          final String purchasePrice = (p.purchasePrice ?? 0.0).toString();
          final String stock = p.stock.toString();
          final String category = (p.category ?? '').replaceAll('"', '""');
          final String unit = p.unitMeasure ?? '';
          final String minStock = (p.minStock ?? 0).toString();

          csvBuffer.writeln('"$id","$sku","$name","$desc",$price,$purchasePrice,$stock,"$category","$unit",$minStock');
        }

        final filename = 'Inventario_${DateTime.now().millisecondsSinceEpoch}.csv';
        final file = File('${directory.path}/$filename');
        await file.writeAsString(csvBuffer.toString());

        if (context.mounted) Navigator.pop(context); // Close progress dialog

        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'text/csv')],
          subject: 'Reporte de Inventario ${DateTime.now().toLocal().toString().split(' ')[0]}',
        );
      }

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext successContext) {
            return AlertDialog(
              backgroundColor: AppColors.getCardColor(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 48),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '¡Exportación Exitosa!', 
                    style: TextStyle(color: AppColors.getTextColor(context), fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los datos se han procesado y compartido exitosamente en formato $format.',
                    style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(successContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Aceptar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Close progress dialog
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar inventario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getLogoUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    final serverBase = DbConfig.apiBaseUrl.replaceAll('/api', '');
    return '$serverBase/api/uploads/$relativePath';
  }

  Widget _buildLogoSection(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final logoUrl = _getLogoUrl(inventoryProvider.logoUrl);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Logo preview
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.moradoPrincipal.withValues(alpha: 0.5), width: 2),
              color: AppColors.moradoPrincipal.withValues(alpha: 0.05),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: logoUrl.isNotEmpty
                  ? Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported_outlined, color: AppColors.getSubtextColor(context), size: 36),
                          const SizedBox(height: 6),
                          Text('Sin logo', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11)),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: AppColors.moradoPrincipal, size: 36),
                        const SizedBox(height: 6),
                        Text('Sin logo', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Instructions text
          Text(
            'Sube el logo o ícono de tu empresa',
            style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Pon una imagen PNG o JPG. El logo aparecerá en el inicio del dashboard. La foto anterior se elimina automáticamente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11),
          ),
          const SizedBox(height: 20),

          // Upload button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: inventoryProvider.isLoading ? null : () => _pickAndUploadLogo(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.moradoPrincipal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                shadowColor: AppColors.moradoPrincipal.withValues(alpha: 0.3),
              ),
              icon: inventoryProvider.isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.upload_rounded, color: Colors.white, size: 20),
              label: Text(
                inventoryProvider.isLoading ? 'Subiendo...' : 'Subir o Cambiar Logo',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          if (logoUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '✅ Logo activo en el servidor',
              style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAndUploadLogo(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Seleccionar Logo',
              style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.moradoPrincipal),
              title: Text('Tomar Foto', style: TextStyle(color: AppColors.getTextColor(context))),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 512, maxHeight: 512);
                if (image != null && context.mounted) _uploadLogoFile(context, image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.azulPrincipal),
              title: Text('Elegir de Galería', style: TextStyle(color: AppColors.getTextColor(context))),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 512, maxHeight: 512);
                if (image != null && context.mounted) _uploadLogoFile(context, image);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadLogoFile(BuildContext context, XFile file) async {
    final bytes = await file.readAsBytes();
    final base64Image = base64.encode(bytes);

    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final success = await inventoryProvider.uploadLogo(base64Image);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ Logo actualizado exitosamente.' : '❌ Error al subir el logo.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
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

// ==========================================
// VISTA DE AYUDA (FAQs)
// ==========================================
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
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
                        Text('Ayuda y FAQs', style: TextStyle(color: AppColors.getTextColor(context), fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Guías básicas de uso', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildHelpCard(
                      context,
                      '📦',
                      '¿Cómo subir y registrar productos?',
                      'Sigue estos sencillos pasos para agregar nuevos productos a tu inventario:\n\n'
                      '1. Dirígete a la pestaña "Producto" en el menú inferior.\n'
                      '2. Presiona el botón flotante "+" o el botón "Añadir".\n'
                      '3. Rellena los datos básicos: Nombre, Código, Categoría y Proveedor.\n'
                      '4. Ingresa el precio de compra, precio de venta y el stock inicial.\n'
                      '5. Presiona "Guardar" para registrar el producto exitosamente.',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpCard(
                      context,
                      '📥',
                      '¿Cómo registrar una entrada de mercancía?',
                      'Para registrar el ingreso de nuevo stock al almacén:\n\n'
                      '1. Ve a la pestaña "Entradas" en el menú inferior.\n'
                      '2. Presiona en "Nueva Entrada".\n'
                      '3. Selecciona el producto que está ingresando.\n'
                      '4. Digita la cantidad y el precio de compra.\n'
                      '5. Elige el almacén de destino y presiona "Confirmar".\n'
                      '6. ¡El stock se sumará automáticamente!',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpCard(
                      context,
                      '📤',
                      '¿Cómo registrar una salida de productos?',
                      'Cuando realizas una venta o retiras productos:\n\n'
                      '1. Entra a la pestaña "Salidas" en el menú inferior.\n'
                      '2. Presiona "Nueva Salida".\n'
                      '3. Selecciona el producto y la cantidad a retirar.\n'
                      '4. Especifica el motivo (Venta, Pérdida, Ajuste) y el almacén.\n'
                      '5. Presiona "Confirmar" para restar el stock al instante.',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpCard(
                      context,
                      '💾',
                      '¿Cómo funcionan los respaldos automáticos?',
                      'Tu información está totalmente segura con nosotros:\n\n'
                      '• El sistema realiza un respaldo automático diariamente a las 2:00 AM.\n'
                      '• Puedes descargar o visualizar los respaldos en la opción "Copia" de los Ajustes.\n'
                      '• También puedes forzar un "Respaldo Manual" inmediato en cualquier momento.',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpCard(
                      context,
                      '🔄',
                      '¿Cómo transferir mercancía entre bodegas?',
                      'Para mover stock de un almacén a otro sin alterar el stock global:\n\n'
                      '1. En Ajustes, ve a "Transferencias".\n'
                      '2. Presiona en "Nueva Transferencia".\n'
                      '3. Selecciona el almacén de origen y el almacén de destino.\n'
                      '4. Agrega los productos a transferir y la cantidad.\n'
                      '5. Confirma la operación. ¡El stock se debitará del origen y se acreditará al destino automáticamente!',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpCard(
                      context,
                      '📊',
                      '¿Cómo exportar reportes y auditoría?',
                      'Puedes exportar tu información en múltiples formatos altamente compatibles:\n\n'
                      '1. Dirígete a la pestaña "Ajustes" -> "Exportar Datos" o ve a "Centro Analítico" en la barra superior del Dashboard.\n'
                      '2. Selecciona entre PDF, Excel (.xlsx) o CSV (.csv).\n'
                      '3. El sistema compilará el archivo y te permitirá compartirlo inmediatamente (WhatsApp, Gmail, etc.) y guardará una bitácora de auditoría en la BD.',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpCard(
                      context,
                      '👥',
                      '¿Cómo gestionar Proveedores y Clientes?',
                      'Para registrar y mantener tus canales de suministro y ventas organizados:\n\n'
                      '1. En Ajustes, selecciona "Proveedores" o "Clientes".\n'
                      '2. Presiona en "Nuevo" para agregar un registro con su nombre y contacto.\n'
                      '3. Podrás editarlos o eliminarlos directamente desde la tarjeta usando los botones de acción rápida.',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpCard(
                      context,
                      '📶',
                      '¿Cómo funciona el Modo Offline?',
                      'El ERP incluye sincronización automática SQLite de nivel corporativo:\n\n'
                      '• Si pierdes la conexión, puedes continuar registrando entradas, salidas y transferencias con total normalidad.\n'
                      '• Los movimientos se almacenarán de forma segura en una cola local interna.\n'
                      '• Al recuperar el acceso a internet (Wi-Fi o Datos), la app transmitirá silenciosamente todas las transacciones en cola al servidor SQL Server sin interrumpir tu flujo de trabajo.',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpCard(
                      context,
                      '🔍',
                      '¿Cómo usar el Escáner de Códigos QR?',
                      'Para acelerar los flujos de entradas y salidas con escaneo rápido:\n\n'
                      '1. En los formularios de "Nueva Entrada" o "Nueva Salida", presiona el botón del Escáner (icono de Cámara).\n'
                      '2. Enfoca el código QR del producto con la cámara de tu móvil.\n'
                      '3. El sistema autocompletará el SKU, nombre del producto, precios de lista y enfocará automáticamente el campo de cantidad para que solo digites las unidades.',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpCard(
                      context,
                      '🏷️',
                      '¿Cómo descargar o imprimir Etiquetas QR?',
                      'Puedes generar etiquetas de producto físicas en dos formatos corporativos:\n\n'
                      '• Impresión Térmica POS: Presiona "Imprimir POS" en la ficha del producto para buscar e imprimir instantáneamente etiquetas de 58mm/80mm por Bluetooth/Wi-Fi.\n'
                      '• Descargar PDF (10cm x 10cm): Presiona "Descargar QR", selecciona la cantidad de etiquetas que requieres (ej. 10 unidades) y la app creará un PDF vectorizado de alta resolución con las 10 etiquetas, listo para imprimir en hojas adhesivas.',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpCard(
                      context,
                      '🎨',
                      '¿Cómo activar el modo oscuro o claro?',
                      'La aplicación cuenta con soporte premium para temas adaptativos:\n\n'
                      '1. Ve a Ajustes -> "Apariencia" en la sección Preferencias.\n'
                      '2. Toca la opción para alternar instantáneamente entre el Modo Oscuro Premium y el Modo Claro.',
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard(BuildContext context, String emoji, String title, String content) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
        ),
        child: ExpansionTile(
          leading: Text(emoji, style: const TextStyle(fontSize: 22)),
          title: Text(title, style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 14)),
          iconColor: AppColors.moradoPrincipal,
          collapsedIconColor: AppColors.getSubtextColor(context),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedAlignment: Alignment.topLeft,
          children: [
            Text(
              content,
              style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// VISTA DE FEEDBACK (OPINIÓN)
// ==========================================
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _selectedRating = 5;
  final TextEditingController _commentController = TextEditingController();

  final List<Map<String, dynamic>> _emojis = [
    {'emoji': '😠', 'label': 'Terrible'},
    {'emoji': '🙁', 'label': 'Malo'},
    {'emoji': '😐', 'label': 'Regular'},
    {'emoji': '🙂', 'label': 'Bueno'},
    {'emoji': '😍', 'label': '¡Excelente!'},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
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
                          Text('Feedback', style: TextStyle(color: AppColors.getTextColor(context), fontSize: 24, fontWeight: FontWeight.bold)),
                          Text('Ayúdanos a mejorar', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.getCardColor(context),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '¿Cómo calificarías tu experiencia?',
                            style: TextStyle(color: AppColors.getTextColor(context), fontSize: 15, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(5, (index) {
                              final int rating = index + 1;
                              final bool isSelected = _selectedRating == rating;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedRating = rating),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? AppColors.moradoPrincipal.withValues(alpha: 0.15) 
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected 
                                          ? AppColors.moradoPrincipal 
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(_emojis[index]['emoji'], style: const TextStyle(fontSize: 28)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _emojis[index]['label'], 
                                        style: TextStyle(
                                          color: isSelected 
                                              ? AppColors.moradoPrincipal 
                                              : AppColors.getSubtextColor(context), 
                                          fontSize: 9,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Déjanos tu opinión o sugerencia:',
                      style: TextStyle(color: AppColors.getTextColor(context), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentController,
                      maxLines: 5,
                      style: TextStyle(color: AppColors.getTextColor(context), fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Cuéntanos qué podemos mejorar o qué te gusta de la aplicación...',
                        hintStyle: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.6), fontSize: 12),
                        filled: true,
                        fillColor: AppColors.getCardColor(context),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.moradoPrincipal, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    InkWell(
                      onTap: () {
                        if (_commentController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor, escribe un comentario antes de enviar.')),
                          );
                          return;
                        }
                        
                        showDialog(
                          context: context,
                          builder: (BuildContext successContext) {
                            return AlertDialog(
                              backgroundColor: AppColors.getCardColor(context),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: AppColors.moradoPrincipal.withValues(alpha: 0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.favorite_rounded, color: AppColors.moradoPrincipal, size: 48),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    '¡Muchísimas Gracias!', 
                                    style: TextStyle(color: AppColors.getTextColor(context), fontSize: 18, fontWeight: FontWeight.bold)
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tu opinión es súper valiosa y nos ayuda a seguir construyendo la mejor app de inventario.',
                                    style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(successContext); // cerrar dialog
                                      Navigator.pop(context); // regresar a ajustes
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.moradoPrincipal,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    ),
                                    child: const Text('De acuerdo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          }
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.moradoPrincipal, AppColors.azulPrincipal],
                            begin: Alignment.centerLeft, end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.moradoPrincipal.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Enviar Opinión',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

