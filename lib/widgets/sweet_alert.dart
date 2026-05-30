import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/app_colors.dart';

enum SweetAlertType { success, error, warning, info }

class SweetAlert extends StatelessWidget {
  final String title;
  final String message;
  final SweetAlertType type;
  final String confirmButtonText;
  final VoidCallback? onConfirm;

  const SweetAlert({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    this.confirmButtonText = 'Aceptar',
    this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    SweetAlertType type = SweetAlertType.success,
    String confirmButtonText = 'Aceptar',
    VoidCallback? onConfirm,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return SweetAlert(
          title: title,
          message: message,
          type: type,
          confirmButtonText: confirmButtonText,
          onConfirm: onConfirm,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut).value,
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color iconColor;
    Color glowColor;
    IconData iconData;

    switch (type) {
      case SweetAlertType.success:
        iconColor = Colors.green;
        glowColor = Colors.green.withValues(alpha: 0.15);
        iconData = Icons.check_circle_outline_rounded;
        break;
      case SweetAlertType.error:
        iconColor = Colors.redAccent;
        glowColor = Colors.redAccent.withValues(alpha: 0.15);
        iconData = Icons.error_outline_rounded;
        break;
      case SweetAlertType.warning:
        iconColor = Colors.orange;
        glowColor = Colors.orange.withValues(alpha: 0.15);
        iconData = Icons.warning_amber_rounded;
        break;
      case SweetAlertType.info:
        iconColor = Colors.blue;
        glowColor = Colors.blue.withValues(alpha: 0.15);
        iconData = Icons.info_outline_rounded;
        break;
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono animado con halo brillante
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: glowColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: iconColor.withValues(alpha: 0.2), width: 1.5),
                ),
                child: Icon(iconData, color: iconColor, size: 48),
              ),
              const SizedBox(height: 24),
              
              // Título del modal
              Text(
                title,
                style: TextStyle(
                  color: AppColors.getTextColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Cuerpo del mensaje
              Text(
                message,
                style: TextStyle(
                  color: AppColors.getSubtextColor(context),
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              
              // Botón estilizado
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  if (onConfirm != null) onConfirm!();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: type == SweetAlertType.success
                          ? [Colors.green, Colors.greenAccent]
                          : type == SweetAlertType.error
                              ? [Colors.redAccent, Colors.deepOrangeAccent]
                              : [AppColors.moradoPrincipal, AppColors.azulPrincipal],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (type == SweetAlertType.success
                                ? Colors.green
                                : type == SweetAlertType.error
                                    ? Colors.redAccent
                                    : AppColors.moradoPrincipal)
                            .withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      confirmButtonText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
