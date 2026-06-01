import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/routes.dart';
import 'sweet_alert.dart';

class InactivityDetector extends StatefulWidget {
  final Widget child;
  const InactivityDetector({super.key, required this.child});

  @override
  State<InactivityDetector> createState() => _InactivityDetectorState();
}

class _InactivityDetectorState extends State<InactivityDetector> {
  Timer? _timer;
  
  // Tiempo de inactividad: 5 minutos (300 segundos)
  static const int _inactivityMinutes = 5;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _timer?.cancel();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      return;
    }

    _timer = Timer(const Duration(minutes: _inactivityMinutes), _handleTimeout);
  }

  void _handleTimeout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      await authProvider.logout();
      
      // Redirigir al Login y limpiar pila de navegación
      AppRoutes.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );

      // Mostrar alerta al usuario
      final BuildContext? navContext = AppRoutes.navigatorKey.currentContext;
      if (navContext != null) {
        SweetAlert.show(
          navContext,
          title: 'Sesión Expirada',
          message: 'Su sesión ha expirado por inactividad.',
          type: SweetAlertType.warning,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          // Si no está autenticado, no hacer nada y resetear timer para que se reactive al iniciar sesión
          _timer?.cancel();
          return widget.child;
        }

        return Listener(
          onPointerDown: (_) => _resetTimer(),
          onPointerMove: (_) => _resetTimer(),
          onPointerHover: (_) => _resetTimer(),
          onPointerSignal: (_) => _resetTimer(),
          behavior: HitTestBehavior.translucent,
          child: widget.child,
        );
      },
    );
  }
}
