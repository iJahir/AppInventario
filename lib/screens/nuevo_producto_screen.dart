import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:io' as io;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import '../utils/app_colors.dart';
import '../utils/routes.dart';
import '../widgets/sweet_alert.dart';

class NuevoProductoScreen extends StatefulWidget {
  const NuevoProductoScreen({super.key});

  @override
  State<NuevoProductoScreen> createState() => _NuevoProductoScreenState();
}

class _NuevoProductoScreenState extends State<NuevoProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  ProductModel? _productToEdit;
  bool _isEditMode = false;
  bool _isInitialized = false;
  
  XFile? _pickedImageFile;
  String? _base64Image;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceBuyController = TextEditingController();
  final TextEditingController _priceSellController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _marginController = TextEditingController();
  
  int _stock = 1;
  int _minStock = 0;

  final List<String> _categories = ['General', 'Electrónica', 'Hogar', 'Moda', 'Deportes'];
  final List<String> _units = ['Unidad', 'Set / Kit / Juego', 'Par', 'Docena'];
  
  late List<String> _categoriesList;
  String _selectedCategory = 'General';
  String _selectedUnit = 'Unidad';

  @override
  void initState() {
    super.initState();
    _categoriesList = List<String>.from(_categories);
    _priceBuyController.addListener(_calculateMargin);
    _priceSellController.addListener(_calculateMargin);
    _categoryController.text = _selectedCategory;
    _unitController.text = _selectedUnit;
    _taxController.text = "0";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is ProductModel) {
        _productToEdit = args;
        _isEditMode = true;
        
        _nameController.text = _productToEdit!.name;
        _skuController.text = _productToEdit!.sku ?? '';
        _descriptionController.text = _productToEdit!.description;
        _priceBuyController.text = _productToEdit!.purchasePrice?.toStringAsFixed(2) ?? '';
        _priceSellController.text = _productToEdit!.price.toStringAsFixed(2);
        _taxController.text = _productToEdit!.taxPercentage?.toStringAsFixed(0) ?? '0';
        _stock = _productToEdit!.stock;
        _minStock = _productToEdit!.minStock ?? 0;
        
        _selectedCategory = _productToEdit!.category ?? 'General';
        if (!_categoriesList.contains(_selectedCategory)) {
          _categoriesList.add(_selectedCategory);
        }
        _categoryController.text = _selectedCategory;
        
        _selectedUnit = _productToEdit!.unitMeasure ?? 'Unidad';
        _unitController.text = _selectedUnit;
        
        _calculateMargin();
      }
      _isInitialized = true;
    }
  }

  void _calculateMargin() {
    final double buy = double.tryParse(_priceBuyController.text.trim()) ?? 0.0;
    final double sell = double.tryParse(_priceSellController.text.trim()) ?? 0.0;
    
    if (sell > 0) {
      final double margin = ((sell - buy) / sell) * 100;
      _marginController.text = "${margin.toStringAsFixed(1)}%";
    } else {
      _marginController.text = "0.0%";
    }
  }

  void _showCreateCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.getCardColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Crear Nueva Categoría', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          content: Container(
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: AppColors.getBackgroundColor(context),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Nombre de la categoría...',
                hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: AppColors.getSubtextColor(context))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.moradoPrincipal),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    if (!_categoriesList.contains(text)) {
                      _categoriesList.add(text);
                    }
                    _selectedCategory = text;
                    _categoryController.text = text;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Crear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    _priceBuyController.dispose();
    _priceSellController.dispose();
    _taxController.dispose();
    _marginController.dispose();
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
            right: -50,
            child: _buildBlurOrb(AppColors.moradoPrincipal.withValues(alpha: isDark ? 0.1 : 0.05), 300),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _buildBlurOrb(AppColors.azulPrincipal.withValues(alpha: isDark ? 0.05 : 0.03), 250),
          ),

          SafeArea(
            child: Form(
              key: _formKey,
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
                          _buildSectionTitle(context, 'Información general'),
                          const SizedBox(height: 15),
                          _buildInfoSection(context),
                          const SizedBox(height: 25),
                          _buildSectionTitle(context, 'Precios'),
                          const SizedBox(height: 15),
                          _buildPricesSection(context),
                          const SizedBox(height: 25),
                          _buildSectionTitle(context, 'Inventario'),
                          const SizedBox(height: 15),
                          _buildInventorySection(context),
                          const SizedBox(height: 25),
                           _buildSectionTitle(context, 'Imágenes del producto (opcional)'),
                           const SizedBox(height: 15),
                           _buildImageUploadArea(context),
                           const SizedBox(height: 30),
                            if (_isEditMode && _productToEdit != null) ...[
                             _buildSectionTitle(context, 'Código QR de Producto'),
                             const SizedBox(height: 15),
                             _buildQRCodeSection(context, _productToEdit!),
                             const SizedBox(height: 30),
                           ],
                           _buildActionButtons(context),
                           const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildSnakeNavBar(context),
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
          _buildCircleIconButton(context, Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppColors.moradoPrincipal.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.inventory_2_rounded, color: AppColors.moradoPrincipal, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isEditMode ? 'Editar Producto' : 'Nuevo Producto', 
                      style: TextStyle(color: AppColors.getTextColor(context), fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  _isEditMode ? 'Edita los detalles de este producto' : 'Crea un nuevo producto en el inventario', 
                  style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton(BuildContext context, IconData icon, {VoidCallback? onTap, Color? color, Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color ?? AppColors.getCardColor(context), 
          shape: BoxShape.circle, 
          border: Border.all(color: Colors.white.withValues(alpha: 0.1))
        ),
        child: Icon(icon, color: iconColor ?? AppColors.getTextColor(context), size: 22),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: const TextStyle(color: AppColors.moradoPrincipal, fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _buildInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildInputField(context, 'Nombre del producto', 'Ej. Laptop HP 15', Icons.edit_document, controller: _nameController)),
              const SizedBox(width: 15),
              Expanded(child: _buildInputField(context, 'SKU / Código', 'Ej. LAP-HP-15', Icons.tag_rounded, controller: _skuController)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _buildDropdownField(
                  context: context,
                  label: 'Categoría',
                  icon: Icons.category_outlined,
                  selectedValue: _selectedCategory,
                  items: _categoriesList,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                        _categoryController.text = val;
                      });
                    }
                  },
                  trailing: GestureDetector(
                    onTap: () => _showCreateCategoryDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.moradoPrincipal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add, color: AppColors.moradoPrincipal, size: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildDropdownField(
                  context: context,
                  label: 'Unidad de medida',
                  icon: Icons.straighten_rounded,
                  selectedValue: _selectedUnit,
                  items: _units,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedUnit = val;
                        _unitController.text = val;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildInputField(context, 'Descripción (opcional)', 'Describe las características del producto...', Icons.description_outlined, controller: _descriptionController, isMultiLine: true),
        ],
      ),
    );
  }

  Widget _buildPricesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildInputField(context, 'Precio de compra', '0.00', Icons.monetization_on_outlined, controller: _priceBuyController, keyboardType: TextInputType.number)),
              const SizedBox(width: 15),
              Expanded(child: _buildInputField(context, 'Precio de venta', '0.00', Icons.monetization_on_outlined, controller: _priceSellController, keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildInputField(context, 'Impuestos (%)', '0', Icons.percent_rounded, controller: _taxController, keyboardType: TextInputType.number)),
              const SizedBox(width: 15),
              Expanded(child: _buildInputField(context, 'Margen de ganancia (%)', '0', Icons.trending_up_rounded, controller: _marginController, keyboardType: TextInputType.number)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventorySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCounterField(context, 'Stock inicial', _stock, (val) {
                  setState(() => _stock = val);
                }),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildCounterField(context, 'Stock mínimo', _minStock, (val) {
                  setState(() => _minStock = val);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context, 
    String label, 
    String hint, 
    IconData icon, {
    required TextEditingController controller, 
    bool isMultiLine = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.getSubtextColor(context), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: isMultiLine ? 3 : 1,
                  style: TextStyle(color: AppColors.getTextColor(context), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.5), fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  validator: (value) {
                    if (label.contains('opcional') || label.contains('Margen') || label.contains('Impuestos') || label.contains('SKU')) {
                      return null;
                    }
                    if (value == null || value.trim().isEmpty) {
                      return 'Requerido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String selectedValue,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11)),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.getSubtextColor(context), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: items.contains(selectedValue) ? selectedValue : items.first,
                    dropdownColor: AppColors.getCardColor(context),
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.getSubtextColor(context), size: 18),
                    style: TextStyle(color: AppColors.getTextColor(context), fontSize: 13),
                    isExpanded: true,
                    onChanged: onChanged,
                    items: items.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCounterField(BuildContext context, String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 18),
                color: AppColors.getSubtextColor(context),
                onPressed: () {
                  if (value > 0) onChanged(value - 1);
                },
              ),
              Text('$value', style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 14)),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                color: AppColors.getSubtextColor(context),
                onPressed: () {
                  onChanged(value + 1);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadArea(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.moradoPrincipal.withValues(alpha: 0.2), style: BorderStyle.solid),
        ),
        child: _pickedImageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.file(
                        io.File(_pickedImageFile!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                        child: const Text('Cambiar', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              )
            : (_isEditMode && _productToEdit?.imageUrl != null)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      color: AppColors.moradoPrincipal.withValues(alpha: 0.05),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.photo_library_rounded, color: AppColors.moradoPrincipal, size: 28),
                          const SizedBox(height: 10),
                          const Text('Foto guardada en servidor local', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(
                            _productToEdit!.imageUrl!.split('\\').last,
                            style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 10),
                          ),
                          const SizedBox(height: 5),
                          Text('Toca para cambiar de foto (Cámara / Galería)', style: TextStyle(color: AppColors.getSubtextColor(context).withValues(alpha: 0.6), fontSize: 9)),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.moradoPrincipal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
                          child: const Icon(Icons.add_a_photo_outlined, color: AppColors.moradoPrincipal, size: 28),
                        ),
                        const SizedBox(height: 10),
                        Text('Agregar imagen', style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Optimización automática (Calidad 30% - Liviana)', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11)),
                      ],
                    ),
                  ),
      ),
    );
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
            const Text('Seleccionar Origen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.moradoPrincipal),
              title: const Text('Tomar Foto (Cámara)', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 30,
                  maxWidth: 800,
                  maxHeight: 800,
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
              title: const Text('Elegir de Galería', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 30,
                  maxWidth: 800,
                  maxHeight: 800,
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

  Widget _buildActionButtons(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Center(
                child: Text('Cancelar', style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: GestureDetector(
            onTap: productProvider.isLoading
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      final newProduct = ProductModel(
                        id: _isEditMode ? _productToEdit!.id : null,
                        name: _nameController.text.trim(),
                        description: _descriptionController.text.trim(),
                        price: double.tryParse(_priceSellController.text.trim()) ?? 0.0,
                        stock: _stock,
                        category: _selectedCategory,
                        sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
                        purchasePrice: double.tryParse(_priceBuyController.text.trim()) ?? 0.0,
                        taxPercentage: double.tryParse(_taxController.text.trim()) ?? 0.0,
                        unitMeasure: _selectedUnit,
                        minStock: _minStock,
                        base64Image: _base64Image,
                        imageUrl: _isEditMode ? _productToEdit!.imageUrl : null,
                      );
                      
                      final success = _isEditMode
                          ? await productProvider.updateProduct(newProduct)
                          : await productProvider.addProduct(newProduct);
                      
                      if (context.mounted) {
                        if (success) {
                          SweetAlert.show(
                            context,
                            title: '¡Operación Exitosa!',
                            message: _isEditMode 
                                ? 'El producto ha sido actualizado correctamente.' 
                                : 'El producto ha sido guardado exitosamente.',
                            type: SweetAlertType.success,
                            onConfirm: () {
                              Navigator.pop(context);
                            },
                          );
                        } else {
                          SweetAlert.show(
                            context,
                            title: 'Error al Guardar',
                            message: productProvider.errorMessage ?? 'Ocurrió un error al procesar el producto.',
                            type: SweetAlertType.error,
                          );
                        }
                      }
                    }
                  },
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.moradoPrincipal, Color(0xFF6A11CB)]),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: AppColors.moradoPrincipal.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Center(
                child: productProvider.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text('Guardar producto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSnakeNavBar(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double itemWidth = (width - 40) / 5;
    int selectedIndex = 1; // Productos activo
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
            left: (selectedIndex * itemWidth) + (itemWidth / 2) - 28,
            top: 10,
            child: Container(
              width: 56,
              height: 52,
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
            left: (selectedIndex * itemWidth) + (itemWidth / 2) - 2.5,
            bottom: 8,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(color: AppColors.moradoPrincipal, shape: BoxShape.circle),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navBtn(context, 0, Icons.home_rounded, 'Inicio'),
              _navBtn(context, 1, Icons.inventory_2_rounded, 'Productos'),
              _navBtn(context, 2, Icons.download_rounded, 'Entradas'),
              _navBtn(context, 3, Icons.upload_rounded, 'Salidas'),
              _navBtn(context, 4, Icons.settings_rounded, 'Ajustes'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navBtn(BuildContext context, int i, IconData ico, String lab) {
    bool act = i == 1;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (i == 0) {
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          } else if (i == 2) {
            Navigator.pushReplacementNamed(context, AppRoutes.entries);
          } else if (i == 3) {
            Navigator.pushReplacementNamed(context, AppRoutes.exits);
          } else if (i == 4) {
            Navigator.pushReplacementNamed(context, AppRoutes.settings);
          }
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

  Widget _buildQRCodeSection(BuildContext context, ProductModel product) {
    final String qrData = product.sku ?? product.id ?? product.name;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Código QR de Producto',
            style: TextStyle(
              color: AppColors.getTextColor(context),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 110.0,
                  gapless: false,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.getTextColor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Código/SKU: $qrData',
                      style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Precio: \$${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.azulPrincipal,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GestureDetector(
                          onTap: () => _showQRQuantityDialog(context, product),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.moradoPrincipal, AppColors.azulPrincipal],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Icon(Icons.download_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Descargar QR',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _simulateThermalPrinting(context, product),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.getBackgroundColor(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Icon(Icons.print_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Imprimir POS',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQRQuantityDialog(BuildContext context, ProductModel product) {
    int qty = 1;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.getCardColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cantidad de Etiquetas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecciona cuántas etiquetas QR de 10cm x 10cm deseas generar en el archivo PDF.',
                style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => setDialogState(() { if (qty > 1) qty--; }),
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.moradoPrincipal, size: 30),
                  ),
                  const SizedBox(width: 15),
                  Text('$qty', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 15),
                  IconButton(
                    onPressed: () => setDialogState(() { if (qty < 100) qty++; }),
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.moradoPrincipal, size: 30),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: TextStyle(color: AppColors.getSubtextColor(context))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.moradoPrincipal),
              onPressed: () {
                Navigator.pop(ctx);
                _generateAndShareQRLabels(context, product, qty);
              },
              child: const Text('Generar PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndShareQRLabels(BuildContext context, ProductModel product, int quantity) async {
    final doc = pw.Document();
    final int itemsPerPage = 8;

    for (int i = 0; i < quantity; i += itemsPerPage) {
      final int end = (i + itemsPerPage < quantity) ? i + itemsPerPage : quantity;
      final int pageItemsCount = end - i;

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(1.5 * PdfPageFormat.cm),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  product.name,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'SKU: ${product.sku ?? "N/A"}',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Expanded(
                  child: pw.GridView(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 1.0 * PdfPageFormat.cm,
                    mainAxisSpacing: 1.0 * PdfPageFormat.cm,
                    children: List<pw.Widget>.generate(pageItemsCount, (index) {
                      return pw.Container(
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        ),
                        padding: const pw.EdgeInsets.all(0.5 * PdfPageFormat.cm),
                        child: pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: product.sku ?? product.id ?? product.name,
                          width: 140,
                          height: 140,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    final bytes = await doc.save();
    
    // Guardar en la carpeta pública de descargas (Android)
    bool savedLocally = false;
    String localPath = '';
    try {
      final dir = io.Directory('/storage/emulated/0/Download');
      if (await dir.exists()) {
        final cleanedName = product.name.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_');
        final filename = 'etiquetas_${cleanedName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = io.File('${dir.path}/$filename');
        await file.writeAsBytes(bytes);
        savedLocally = true;
        localPath = file.path;
      }
    } catch (e) {
      // Ignorar si falla
    }

    if (context.mounted) {
      if (savedLocally) {
        SweetAlert.show(
          context,
          title: 'PDF Descargado',
          message: 'El archivo de etiquetas se ha guardado en la carpeta de Descargas:\n\n${localPath.split('/').last}',
          type: SweetAlertType.success,
        );
      }
    }

    await Printing.sharePdf(bytes: bytes, filename: 'etiquetas_${product.sku ?? product.id ?? product.name}.pdf');
  }

  void _simulateThermalPrinting(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) {
        double progress = 0.0;
        String statusText = "Buscando impresoras térmicas Bluetooth/Wi-Fi...";
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future.delayed(const Duration(milliseconds: 800), () {
              if (ctx.mounted && progress == 0.0) {
                setDialogState(() {
                  progress = 0.4;
                  statusText = "Conectando a 'SPP-R200II' (Bluetooth 5.0)...";
                });
              }
            });
            Future.delayed(const Duration(milliseconds: 1600), () {
              if (ctx.mounted && progress == 0.4) {
                setDialogState(() {
                  progress = 0.8;
                  statusText = "Transmitiendo datos de etiqueta de 58mm...";
                });
              }
            });
            Future.delayed(const Duration(milliseconds: 2400), () {
              if (ctx.mounted && progress == 0.8) {
                setDialogState(() {
                  progress = 1.0;
                  statusText = "¡Etiqueta física impresa con éxito!";
                });
              }
            });

            return Dialog(
              backgroundColor: AppColors.getCardColor(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.print_rounded, color: AppColors.moradoPrincipal, size: 48),
                    const SizedBox(height: 15),
                    const Text(
                      'Impresión Térmica POS',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.azulPrincipal),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      statusText,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12),
                    ),
                    const SizedBox(height: 25),
                    if (progress >= 1.0)
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          width: double.infinity,
                          height: 45,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.moradoPrincipal, AppColors.azulPrincipal]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Listo',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
