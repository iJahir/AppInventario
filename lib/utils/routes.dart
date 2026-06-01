import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/products_screen.dart';
import '../screens/nuevo_producto_screen.dart';
import '../screens/entrada_screen.dart';
import '../screens/nueva_entrada_screen.dart';
import '../screens/salida_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/nueva_salida_screen.dart';
import '../screens/update_password_screen.dart';
import '../screens/suppliers_management_screen.dart';
import '../screens/warehouses_management_screen.dart';
import '../screens/customers_management_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/product_kardex_screen.dart';
import '../screens/warehouse_inventory_screen.dart';
import '../screens/transfers_screen.dart';
import '../screens/new_transfer_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/profile_edit_screen.dart';
import '../screens/product_lots_screen.dart';
import '../screens/all_entries_screen.dart';
import '../screens/all_outputs_screen.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String products = '/products';
  static const String addProduct = '/add-product';
  static const String entries = '/entries';
  static const String addEntry = '/add-entry';
  static const String exits = '/exits';
  static const String addExit = '/add-exit';
  static const String settings = '/settings';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String updatePassword = '/update-password';
  static const String suppliers = '/suppliers';
  static const String warehouses = '/warehouses';
  static const String customers = '/customers';
  static const String productDetail = '/product-detail';
  static const String productKardex = '/product-kardex';
  static const String inventoryByWarehouse = '/inventory-by-warehouse';
  static const String transfers = '/transfers';
  static const String addTransfer = '/add-transfer';
  static const String reports = '/reports';
  static const String editProfile = '/edit-profile';
  static const String productLots = '/product-lots';
  static const String allEntries = '/all-entries';
  static const String allOutputs = '/all-outputs';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      dashboard: (context) => const DashboardScreen(),
      products: (context) => const ProductsScreen(),
      addProduct: (context) => const NuevoProductoScreen(),
      entries: (context) => const EntradaScreen(),
      addEntry: (context) => const NuevaEntradaScreen(),
      exits: (context) => const SalidaScreen(),
      addExit: (context) => const NuevaSalidaScreen(),
      settings: (context) => const SettingsScreen(),
      register: (context) => const RegisterScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      updatePassword: (context) => const UpdatePasswordScreen(),
      suppliers: (context) => const SuppliersManagementScreen(),
      warehouses: (context) => const WarehousesManagementScreen(),
      customers: (context) => const CustomersManagementScreen(),
      productDetail: (context) => const ProductDetailScreen(),
      productKardex: (context) => const ProductKardexScreen(),
      inventoryByWarehouse: (context) => const WarehouseInventoryScreen(),
      transfers: (context) => const TransfersScreen(),
      addTransfer: (context) => const NewTransferScreen(),
      reports: (context) => const ReportsScreen(),
      editProfile: (context) => const ProfileEditScreen(),
      productLots: (context) => const ProductLotsScreen(),
      allEntries: (context) => const AllEntriesScreen(),
      allOutputs: (context) => const AllOutputsScreen(),
    };
  }
}

