import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/routes.dart';
import '../utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
            left: -50,
            child: _buildBlurOrb(AppColors.moradoPrincipal.withValues(alpha: isDark ? 0.15 : 0.05), 300),
          ),
          Positioned(
            bottom: -100,
            right: -50,
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
                                Text(
                                  'SISTEMA DE INVENTARIO',
                                  style: TextStyle(
                                    color: AppColors.getTextColor(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 3,
                                  ),
                                ),
                                const SizedBox(height: 50),
                                _buildLogo(context),
                                const SizedBox(height: 40),
                                Text(
                                  'BIENVENIDO DE NUEVO',
                                  style: TextStyle(color: AppColors.getTextColor(context), fontSize: 26, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                Text('Inicia sesión para continuar', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 14)),
                                const SizedBox(height: 50),
                                _buildInputField(context, icon: Icons.person_outline_rounded, hint: 'Correo o usuario', controller: _emailController),
                                const SizedBox(height: 20),
                                _buildInputField(context, icon: Icons.lock_outline_rounded, hint: 'Contraseña', controller: _passwordController, isPassword: true),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          height: 18,
                                          width: 18,
                                          decoration: BoxDecoration(color: AppColors.moradoPrincipal, borderRadius: BorderRadius.circular(4)),
                                          child: const Icon(Icons.check, color: Colors.white, size: 12),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Recordarme', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12)),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                                      child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: AppColors.moradoPrincipal, fontSize: 12, fontWeight: FontWeight.w500)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),
                                _buildLoginButton(context),
                                const SizedBox(height: 30),
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: AppColors.getTextColor(context).withValues(alpha: 0.1))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 15),
                                      child: Text('O continúa con', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12)),
                                    ),
                                    Expanded(child: Divider(color: AppColors.getTextColor(context).withValues(alpha: 0.1))),
                                  ],
                                ),
                                const SizedBox(height: 30),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _socialBtn(context, 'https://cdn-icons-png.flaticon.com/512/2991/2991148.png'),
                                    const SizedBox(width: 20),
                                    _socialBtn(context, 'https://cdn-icons-png.flaticon.com/512/0/747.png'),
                                    const SizedBox(width: 20),
                                    _socialBtn(context, 'https://cdn-icons-png.flaticon.com/512/732/732221.png'),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const SizedBox(height: 40),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('¿No tienes una cuenta? ', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 13)),
                                    GestureDetector(
                                      onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                                      child: const Text('Crear una ahora', style: TextStyle(color: AppColors.moradoPrincipal, fontSize: 13, fontWeight: FontWeight.bold)),
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

  Widget _buildLogo(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [AppColors.moradoPrincipal.withValues(alpha: 0.5), AppColors.azulPrincipal.withValues(alpha: 0.5)]),
            boxShadow: [BoxShadow(color: AppColors.moradoPrincipal.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 5)],
          ),
        ),
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.getBackgroundColor(context),
            border: Border.all(color: AppColors.getTextColor(context).withValues(alpha: 0.1)),
          ),
          child: Center(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(colors: [Colors.white, AppColors.moradoPrincipal]).createShader(bounds),
              child: Icon(Icons.inventory_2_rounded, size: 70, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.azulPrincipal),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(BuildContext context, {required IconData icon, required String hint, required TextEditingController controller, bool isPassword = false}) {
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
              obscureText: isPassword && _obscurePassword,
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
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.getSubtextColor(context), size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return GestureDetector(
      onTap: authProvider.isLoading
          ? null
          : () async {
              if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor completa todos los campos')),
                );
                return;
              }
              final success = await authProvider.login(
                _emailController.text.trim(),
                _passwordController.text.trim(),
              );
              if (success) {
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(authProvider.errorMessage ?? 'Error al iniciar sesión')),
                  );
                }
              }
            },
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.moradoPrincipal, AppColors.azulPrincipal]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: AppColors.azulPrincipal.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Center(
          child: authProvider.isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('INICIAR SESIÓN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                    SizedBox(width: 15),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _socialBtn(BuildContext context, String url) {
    return Container(
      height: 55,
      width: 70,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.getTextColor(context).withValues(alpha: 0.05)),
      ),
      child: Image.network(url, fit: BoxFit.contain),
    );
  }
}
