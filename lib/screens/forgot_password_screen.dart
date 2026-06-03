import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/sweet_alert.dart';
import '../utils/routes.dart';
import '../utils/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      SweetAlert.show(
        context,
        title: 'Error de Validación',
        message: 'Por favor, ingresa tu correo electrónico.',
        type: SweetAlertType.error,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final result = await authProvider.forgotPassword(email);
      if (mounted) {
        String msg = 'Se han enviado las instrucciones al correo electrónico.';
        if (result != null && result['tempPassword'] != null) {
          msg = 'Hemos restablecido tu contraseña. Tu contraseña temporal es: ${result['tempPassword']}\n\nPor favor, úsala para iniciar sesión y cámbiala de inmediato.';
        }
        
        SweetAlert.show(
          context,
          title: 'Correo Enviado',
          message: msg,
          type: SweetAlertType.success,
          onConfirm: () {
            Navigator.pop(context); // Regresa a la pantalla de login
          },
        );
      }
    } catch (e) {
      if (mounted) {
        SweetAlert.show(
          context,
          title: 'Error',
          message: e.toString(),
          type: SweetAlertType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isLoading = Provider.of<AuthProvider>(context).isLoading;

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
                                const SizedBox(height: 40),
                                _buildHeaderIcon(),
                                const SizedBox(height: 40),
                                Text(
                                  'RECUPERAR CONTRASEÑA',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.getTextColor(context), fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Ingresa tu correo electrónico y te enviaremos instrucciones para recuperar tu contraseña.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 14, height: 1.5),
                                ),
                                const SizedBox(height: 50),
                                _buildInputField(context, icon: Icons.email_outlined, hint: 'Correo electrónico'),
                                const SizedBox(height: 40),
                                isLoading 
                                    ? const Center(child: CircularProgressIndicator(color: AppColors.moradoPrincipal))
                                    : _buildSendButton(context),
                              ],
                            ),
                            Column(
                              children: [
                                const SizedBox(height: 40),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text(
                                    'Volver al inicio de sesión',
                                    style: TextStyle(color: AppColors.moradoPrincipal, fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
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
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.moradoPrincipal.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.moradoPrincipal.withValues(alpha: 0.2), width: 2),
      ),
      child: const Center(
        child: Icon(Icons.mail_lock_rounded, size: 60, color: AppColors.moradoPrincipal),
      ),
    );
  }

  Widget _buildInputField(BuildContext context, {required IconData icon, required String hint}) {
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
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: AppColors.getTextColor(context)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton(BuildContext context) {
    return GestureDetector(
      onTap: _handleResetPassword,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.moradoPrincipal, AppColors.azulPrincipal]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: AppColors.azulPrincipal.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: const Center(
          child: Text('ENVIAR INSTRUCCIONES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
        ),
      ),
    );
  }
}
