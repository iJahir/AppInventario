import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../utils/app_colors.dart';

class WarehousesManagementScreen extends StatefulWidget {
  const WarehousesManagementScreen({super.key});

  @override
  State<WarehousesManagementScreen> createState() => _WarehousesManagementScreenState();
}

class _WarehousesManagementScreenState extends State<WarehousesManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchConfigData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Filtrar almacenes según la búsqueda
    final filteredWarehouses = inventoryProvider.warehouses.where((w) {
      final name = (w['name'] ?? '').toString().toLowerCase();
      final location = (w['location'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || location.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: Stack(
        children: [
          // Orbes de fondo premium
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlurOrb(AppColors.moradoPrincipal.withValues(alpha: isDark ? 0.15 : 0.05), 300),
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
                _buildSearchBar(context),
                Expanded(
                  child: inventoryProvider.isLoading && inventoryProvider.warehouses.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: AppColors.moradoPrincipal))
                      : filteredWarehouses.isEmpty
                          ? _buildEmptyState(context)
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: filteredWarehouses.length,
                              itemBuilder: (context, index) {
                                final w = filteredWarehouses[index];
                                return _buildWarehouseCard(context, w);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWarehouseModal(context),
        label: const Text('Nuevo Almacén', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: AppColors.moradoPrincipal,
        elevation: 5,
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildCircleIconButton(
            context,
            Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Almacenes',
                  style: TextStyle(
                    color: AppColors.getTextColor(context),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Gestiona tus bodegas y ubicaciones',
                  style: TextStyle(
                    color: AppColors.getSubtextColor(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _buildCircleIconButton(
            context,
            Icons.refresh_rounded,
            onTap: () => Provider.of<InventoryProvider>(context, listen: false).fetchConfigData(),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton(BuildContext context, IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            )
          ],
        ),
        child: Icon(icon, color: AppColors.getTextColor(context), size: 22),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
            )
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.getSubtextColor(context), size: 22),
            const SizedBox(width: 15),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: AppColors.getTextColor(context)),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o ubicación...',
                  hintStyle: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 14),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: Icon(Icons.close, color: AppColors.getSubtextColor(context), size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.moradoPrincipal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warehouse_outlined, size: 50, color: AppColors.moradoPrincipal),
          ),
          const SizedBox(height: 20),
          Text(
            'No se encontraron almacenes',
            style: TextStyle(color: AppColors.getTextColor(context), fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega un almacén o bodega para iniciar.',
            style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseCard(BuildContext context, Map<String, dynamic> w) {
    final String id = w['id'].toString();
    final String name = w['name'] ?? 'Almacén';
    final String location = w['location'] ?? 'Sin ubicación';
    
    String formattedDate = '';
    if (w['createdAt'] != null) {
      try {
        final date = DateTime.parse(w['createdAt'].toString());
        formattedDate = "Creado el ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.moradoPrincipal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warehouse_outlined, color: AppColors.moradoPrincipal, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.getTextColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: TextStyle(
                    color: AppColors.getSubtextColor(context),
                    fontSize: 12,
                  ),
                ),
                if (formattedDate.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: AppColors.getSubtextColor(context).withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCardActionButton(
                context,
                Icons.edit_rounded,
                Colors.blueAccent,
                onTap: () => _showWarehouseModal(context, warehouse: w),
              ),
              const SizedBox(width: 10),
              _buildCardActionButton(
                context,
                Icons.delete_outline_rounded,
                Colors.redAccent,
                onTap: () => _confirmDelete(context, id, name),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardActionButton(BuildContext context, IconData icon, Color color, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _showWarehouseModal(BuildContext context, {Map<String, dynamic>? warehouse}) {
    final isEdit = warehouse != null;
    final nameController = TextEditingController(text: isEdit ? warehouse['name'] : '');
    final locationController = TextEditingController(text: isEdit ? warehouse['location'] : '');

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'WarehouseModal',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: SingleChildScrollView(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: AppColors.getCardColor(context),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.moradoPrincipal.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Editar Almacén' : 'Nuevo Almacén',
                      style: TextStyle(
                        color: AppColors.getTextColor(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildModalInputField(
                      context,
                      icon: Icons.warehouse_outlined,
                      hint: 'Nombre del Almacén / Bodega',
                      controller: nameController,
                    ),
                    const SizedBox(height: 15),
                    _buildModalInputField(
                      context,
                      icon: Icons.location_on_outlined,
                      hint: 'Dirección o Ubicación',
                      controller: locationController,
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(color: AppColors.getSubtextColor(context)),
                          ),
                        ),
                        const SizedBox(width: 15),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.moradoPrincipal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                          ),
                          onPressed: () async {
                            final name = nameController.text.trim();
                            final location = locationController.text.trim();

                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Por favor ingresa un nombre.')),
                              );
                              return;
                            }

                            final provider = Provider.of<InventoryProvider>(context, listen: false);
                            bool success = false;

                            if (isEdit) {
                              success = await provider.updateWarehouse(warehouse['id'].toString(), name, location);
                            } else {
                              success = await provider.addWarehouse(name, location);
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? (isEdit ? 'Almacén actualizado con éxito.' : 'Almacén creado con éxito.')
                                        : (provider.errorMessage ?? 'Error al guardar almacén.'),
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  Widget _buildModalInputField(BuildContext context, {required IconData icon, required String hint, required TextEditingController controller}) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.getTextColor(context).withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.moradoPrincipal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: AppColors.getTextColor(context), fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.getCardColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('¿Eliminar Almacén?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          content: Text('¿Estás seguro de que deseas eliminar a "$name"?', style: TextStyle(color: AppColors.getSubtextColor(context))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: AppColors.getSubtextColor(context))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                final provider = Provider.of<InventoryProvider>(context, listen: false);
                final success = await provider.deleteWarehouse(id);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Almacén eliminado.' : (provider.errorMessage ?? 'Error al eliminar almacén.'),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
