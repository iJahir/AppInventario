import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/routes.dart';
import '../utils/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlurOrb(AppColors.moradoPrincipal.withValues(alpha: isDark ? 0.15 : 0.05), 300),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _buildBlurOrb(AppColors.azulPrincipal.withValues(alpha: isDark ? 0.15 : 0.05), 300),
          ),

          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    _buildCircleIconButton(context, Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildHeaderIcon(),
                                const SizedBox(height: 30),
                                Text(
                                  'CREAR CUENTA',
                                  style: TextStyle(color: AppColors.getTextColor(context), fontSize: 26, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                Text('Completa los campos para registrarte', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 14)),
                                const SizedBox(height: 40),
                                _buildInputField(context, icon: Icons.person_outline_rounded, hint: 'Nombre completo', controller: _nameController),
                                const SizedBox(height: 20),
                                _buildInputField(context, icon: Icons.alternate_email_rounded, hint: 'Nombre de usuario', controller: _usernameController),
                                const SizedBox(height: 20),
                                _buildInputField(context, icon: Icons.email_outlined, hint: 'Correo electrónico', controller: _emailController),
                                const SizedBox(height: 20),
                                _buildInputField(
                                  context,
                                  icon: Icons.lock_outline_rounded, 
                                  hint: 'Contraseña', 
                                  isPassword: true,
                                  isObscured: _obscurePassword,
                                  onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                                  controller: _passwordController,
                                ),
                                const SizedBox(height: 20),
                                _buildInputField(
                                  context,
                                  icon: Icons.lock_reset_rounded, 
                                  hint: 'Confirmar contraseña', 
                                  isPassword: true,
                                  isObscured: _obscureConfirmPassword,
                                  onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  controller: _confirmPasswordController,
                                ),
                                const SizedBox(height: 40),
                                _buildRegisterButton(context),
                              ],
                            ),
                            Column(
                              children: [
                                const SizedBox(height: 40),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('¿Ya tienes una cuenta? ', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 13)),
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: const Text('Inicia sesión', style: TextStyle(color: AppColors.moradoPrincipal, fontSize: 13, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
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

  Widget _buildCircleIconButton(BuildContext context, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.getTextColor(context).withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: AppColors.getTextColor(context), size: 22),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.greenAccent.withValues(alpha: 0.1),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2), width: 2),
      ),
      child: const Center(
        child: Icon(Icons.person_add_alt_1_rounded, size: 50, color: Colors.greenAccent),
      ),
    );
  }

  Widget _buildInputField(BuildContext context, {
    required IconData icon, 
    required String hint, 
    required TextEditingController controller,
    bool isPassword = false,
    bool isObscured = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.getTextColor(context).withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.moradoPrincipal, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword && isObscured,
              style: TextStyle(color: AppColors.getTextColor(context)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          if (isPassword)
            GestureDetector(
              onTap: onToggleVisibility,
              child: Icon(isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.getSubtextColor(context), size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return GestureDetector(
      onTap: authProvider.isLoading
          ? null
          : () async {
              final name = _nameController.text.trim();
              final username = _usernameController.text.trim();
              final email = _emailController.text.trim();
              final password = _passwordController.text.trim();
              final confirmPassword = _confirmPasswordController.text.trim();

              if (name.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor completa todos los campos')),
                );
                return;
              }

              if (password != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Las contraseñas no coinciden')),
                );
                return;
              }

              final success = await authProvider.register(name, username, email, password);

              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuario registrado exitosamente en la base de datos')),
                  );
                  Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(authProvider.errorMessage ?? 'Error al registrar usuario')),
                  );
                }
              }
            },
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.greenAccent, Color(0xFF00D2FF)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Center(
          child: authProvider.isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('CREAR CUENTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
        ),
      ),
    );
  }
}
