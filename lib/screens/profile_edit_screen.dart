import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';
import '../utils/db_config.dart';
import '../widgets/sweet_alert.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  XFile? _pickedImageFile;
  String? _base64Image;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Seleccionar Origen',
              style: TextStyle(
                color: AppColors.getTextColor(context),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.moradoPrincipal),
              title: Text('Tomar Foto (Cámara)', style: TextStyle(color: AppColors.getTextColor(context))),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 35,
                  maxWidth: 600,
                  maxHeight: 600,
                );
                if (image != null) {
                  final bytes = await image.readAsBytes();
                  setState(() {
                    _pickedImageFile = image;
                    _base64Image = base64.encode(bytes);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.azulPrincipal),
              title: Text('Elegir de Galería', style: TextStyle(color: AppColors.getTextColor(context))),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 35,
                  maxWidth: 600,
                  maxHeight: 600,
                );
                if (image != null) {
                  final bytes = await image.readAsBytes();
                  setState(() {
                    _pickedImageFile = image;
                    _base64Image = base64.encode(bytes);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.updateProfile(
        _nameController.text.trim(),
        _base64Image,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          SweetAlert.show(
            context,
            title: '¡Perfil Actualizado!',
            message: 'Tu perfil ha sido actualizado exitosamente.',
            type: SweetAlertType.success,
            onConfirm: () {
              Navigator.pop(context);
            },
          );
        } else {
          SweetAlert.show(
            context,
            title: 'Error de Actualización',
            message: authProvider.errorMessage ?? 'Ocurrió un error al actualizar el perfil.',
            type: SweetAlertType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        SweetAlert.show(
          context,
          title: 'Error',
          message: 'Error al actualizar el perfil: $e',
          type: SweetAlertType.error,
        );
      }
    }
  }

  Widget _buildBlurOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: Stack(
        children: [
          // Blur Orbs
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
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.getTextColor(context)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Editar Perfil',
                            style: TextStyle(
                              color: AppColors.getTextColor(context),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance for arrow button
                    ],
                  ),
                ),

                // Form & content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          
                          // Avatar selection
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.moradoPrincipal.withValues(alpha: 0.8),
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.moradoPrincipal.withValues(alpha: 0.2),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(65),
                                    child: _pickedImageFile != null
                                        ? Image.file(
                                            File(_pickedImageFile!.path),
                                            fit: BoxFit.cover,
                                          )
                                        : (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty)
                                            ? Image.network(
                                                _getProfileImageUrl(user.profileImageUrl),
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  color: Colors.grey.shade900,
                                                  child: const Icon(
                                                    Icons.person_rounded,
                                                    size: 60,
                                                    color: Colors.white60,
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                color: Colors.grey.shade900,
                                                child: const Icon(
                                                  Icons.person_rounded,
                                                  size: 60,
                                                  color: Colors.white60,
                                                ),
                                              ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: AppColors.moradoPrincipal,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Toca para cambiar foto',
                            style: TextStyle(
                              color: AppColors.getSubtextColor(context),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Profile Info Card (Glassmorphic look)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.getCardColor(context).withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Full Name (Editable)
                                Text(
                                  'Nombre Completo',
                                  style: TextStyle(
                                    color: AppColors.getSubtextColor(context),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _nameController,
                                  style: TextStyle(color: AppColors.getTextColor(context)),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.moradoPrincipal),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    hintText: 'Tu nombre',
                                    hintStyle: TextStyle(color: AppColors.getSubtextColor(context)),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'El nombre es obligatorio';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Email (Read-Only)
                                Text(
                                  'Correo Electrónico (No editable)',
                                  style: TextStyle(
                                    color: AppColors.getSubtextColor(context),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: user?.email,
                                  enabled: false,
                                  style: TextStyle(color: AppColors.getTextColor(context).withValues(alpha: 0.6)),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.black.withValues(alpha: 0.1),
                                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Username (Read-Only) - identificador de cuenta
                                Text(
                                  'Usuario (No editable)',
                                  style: TextStyle(
                                    color: AppColors.getSubtextColor(context),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: user?.email != null
                                      ? user!.email.contains('@')
                                          ? user.email.split('@')[0]
                                          : user.email
                                      : '',
                                  enabled: false,
                                  style: TextStyle(color: AppColors.getTextColor(context).withValues(alpha: 0.6)),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.black.withValues(alpha: 0.1),
                                    prefixIcon: const Icon(Icons.alternate_email_rounded, color: Colors.grey),
                                    hintText: 'usuario',
                                    hintStyle: TextStyle(color: AppColors.getSubtextColor(context)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Role (Read-Only)
                                Text(
                                  'Rol de Almacén (No editable)',
                                  style: TextStyle(
                                    color: AppColors.getSubtextColor(context),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: user?.role ?? 'ALMACENERO',
                                  enabled: false,
                                  style: TextStyle(color: AppColors.getTextColor(context).withValues(alpha: 0.6)),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.black.withValues(alpha: 0.1),
                                    prefixIcon: const Icon(Icons.badge_outlined, color: Colors.grey),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.moradoPrincipal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                elevation: 4,
                                shadowColor: AppColors.moradoPrincipal.withValues(alpha: 0.4),
                              ),
                              child: _isSaving
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Guardar Cambios',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
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
}
