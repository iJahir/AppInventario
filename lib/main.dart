import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/routes.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/reports_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestión de Inventario',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: AppRoutes.login,
      routes: AppRoutes.getRoutes(),
    );
  }
}
