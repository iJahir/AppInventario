import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/product_provider.dart';
import '../utils/app_colors.dart';
import '../utils/routes.dart';

class AllOutputsScreen extends StatefulWidget {
  const AllOutputsScreen({super.key});

  @override
  State<AllOutputsScreen> createState() => _AllOutputsScreenState();
}

class _AllOutputsScreenState extends State<AllOutputsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _sortOption = 'Recientes';
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final inventoryProvider = Provider.of<InventoryProvider>(context);

    // Filter and Sort exits
    var filteredExits = List<Map<String, dynamic>>.from(inventoryProvider.exits);
    if (_searchQuery.isNotEmpty) {
      filteredExits = filteredExits.where((tx) {
        final pNames = (tx['items'] as List?)?.map((i) => i['productName']).join(', ').toLowerCase() ?? '';
        final client = (tx['customerName']?.toString().toLowerCase() ?? '');
        return pNames.contains(_searchQuery) || client.contains(_searchQuery);
      }).toList();
    }

    filteredExits.sort((a, b) {
      if (_sortOption == 'Mayor Monto' || _sortOption == 'Menor Monto') {
        final amtA = (a['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final amtB = (b['totalAmount'] as num?)?.toDouble() ?? 0.0;
        return _sortOption == 'Mayor Monto' ? amtB.compareTo(amtA) : amtA.compareTo(amtB);
      } else {
        final dateA = DateTime.tryParse(a['transactionDate']?.toString() ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['transactionDate']?.toString() ?? '') ?? DateTime.now();
        return _sortOption == 'Antiguas' ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      }
    });

    final int totalItems = filteredExits.length;
    final int totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    }

    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage) > totalItems ? totalItems : (startIndex + _itemsPerPage);

    final paginatedExits = filteredExits.isEmpty ? [] : filteredExits.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(color: const Color(0xFFFFAB40).withOpacity(isDark ? 0.15 : 0.05), shape: BoxShape.circle),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildSearchAndFilter(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        if (filteredExits.isEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 80),
                            child: Center(child: Text('No hay salidas registradas.', style: TextStyle(color: Colors.white54))),
                          )
                        ] else ...[
                          // Rango de items
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mostrando ${startIndex + 1}-$endIndex de $totalItems salidas',
                                style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 12),
                              ),
                              Text(
                                'Pág. $_currentPage de $totalPages',
                                style: const TextStyle(color: Color(0xFFFF9100), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          ...paginatedExits.map((tx) {
                            final pNames = (tx['items'] as List?)?.map((i) => i['productName']).join(', ') ?? 'Varios';
                            final client = tx['customerName'] ?? 'General';
                            final val = '\$${((tx['totalAmount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}';
                            
                            final DateTime dt = tx['transactionDate'] != null 
                                ? DateTime.parse(tx['transactionDate'].toString()) 
                                : DateTime.now();
                            final dateStr = "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

                            final String reason = tx['reason'] ?? 'Venta';
                            Color statusColor = Colors.greenAccent;
                            if (reason == 'Daño') {
                              statusColor = Colors.redAccent;
                            } else if (reason == 'Servicio') {
                              statusColor = Colors.cyanAccent;
                            } else if (reason == 'Consumo') {
                              statusColor = Colors.orangeAccent;
                            }

                            return GestureDetector(
                              onTap: () => _showDetails(context, tx),
                              child: _salidaItem(context, pNames, client, dateStr, reason, val, statusColor),
                            );
                          }),
                          const SizedBox(height: 20),
                          if (totalPages > 1) _buildPaginationControls(context, totalPages),
                        ],
                        const SizedBox(height: 50),
                      ],
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context), 
                shape: BoxShape.circle, 
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(Icons.arrow_back_rounded, color: AppColors.getTextColor(context), size: 22),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Todas las Salidas', style: TextStyle(color: AppColors.getTextColor(context), fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Historial completo de egresos', style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context), 
                borderRadius: BorderRadius.circular(15), 
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.getSubtextColor(context), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                          _currentPage = 1;
                        });
                      },
                      style: TextStyle(color: AppColors.getTextColor(context), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Buscar salidas...',
                        hintStyle: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            onSelected: (val) {
              setState(() {
                _sortOption = val;
                _currentPage = 1;
              });
            },
            color: AppColors.getCardColor(context),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Recientes', child: Text('Recientes', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'Antiguas', child: Text('Más Antiguas', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'Mayor Monto', child: Text('Mayor Monto', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'Menor Monto', child: Text('Menor Monto', style: TextStyle(color: Colors.white))),
            ],
            child: Container(
              height: 50, width: 50,
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context), 
                borderRadius: BorderRadius.circular(15), 
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Icon(Icons.tune_rounded, color: AppColors.getSubtextColor(context), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _salidaItem(BuildContext context, String name, String client, String date, String status, String value, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context), 
        borderRadius: BorderRadius.circular(22), 
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.upload_rounded, color: statusColor, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                Text(client, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11)),
                Text(date, style: TextStyle(color: AppColors.getSubtextColor(context).withOpacity(0.6), fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(status, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(color: AppColors.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(width: 5),
          Icon(Icons.chevron_right_rounded, color: AppColors.getSubtextColor(context).withOpacity(0.3)),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(BuildContext context, int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _currentPage > 1 ? AppColors.getCardColor(context) : AppColors.getCardColor(context).withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              color: _currentPage > 1 ? AppColors.getTextColor(context) : AppColors.getSubtextColor(context).withOpacity(0.3),
            ),
          ),
        ),
        const SizedBox(width: 15),
        ...List.generate(totalPages, (index) {
          final pageNum = index + 1;
          final bool isSelected = pageNum == _currentPage;

          if (totalPages > 5 && (pageNum - _currentPage).abs() > 1 && pageNum != 1 && pageNum != totalPages) {
            if (pageNum == 2 || pageNum == totalPages - 1) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('...', style: TextStyle(color: Colors.white30)),
              );
            }
            return const SizedBox.shrink();
          }

          return GestureDetector(
            onTap: () => setState(() => _currentPage = pageNum),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange : AppColors.getCardColor(context),
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? Colors.orange : Colors.white.withOpacity(0.05)),
                boxShadow: isSelected ? [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8)] : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '$pageNum',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 15),
        GestureDetector(
          onTap: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _currentPage < totalPages ? AppColors.getCardColor(context) : AppColors.getCardColor(context).withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              color: _currentPage < totalPages ? AppColors.getTextColor(context) : AppColors.getSubtextColor(context).withOpacity(0.3),
            ),
          ),
        ),
      ],
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _TransactionDetailSheet(tx: tx, isEntrada: false);
      },
    );
  }
}

class _TransactionDetailSheet extends StatefulWidget {
  final Map<String, dynamic> tx;
  final bool isEntrada;

  const _TransactionDetailSheet({
    required this.tx,
    required this.isEntrada,
  });

  @override
  State<_TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<_TransactionDetailSheet> {
  List<Map<String, dynamic>> fifoDetail = [];
  bool fifoLoaded = false;
  bool fifoLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFifoDetail();
  }

  Future<void> _loadFifoDetail() async {
    try {
      final String transactionId = widget.tx['id']?.toString() ?? '';
      if (transactionId.isNotEmpty) {
        final detail = await Provider.of<ProductProvider>(context, listen: false)
            .fetchTransactionFifoDetail(transactionId);
        if (mounted) {
          setState(() {
            fifoDetail = detail;
            fifoLoaded = true;
            fifoLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            fifoLoaded = true;
            fifoLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          fifoDetail = [];
          fifoLoaded = true;
          fifoLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final items = widget.tx['items'] as List? ?? [];
    final String partnerLabel = widget.isEntrada ? 'Proveedor' : 'Cliente';
    final String partnerName = widget.isEntrada 
        ? (widget.tx['supplierName'] ?? 'General') 
        : (widget.tx['customerName'] ?? 'General');
    final String dateStr = widget.tx['transactionDate'] != null 
        ? DateTime.parse(widget.tx['transactionDate'].toString()).toLocal().toString().substring(0, 16)
        : 'N/A';
    final totalAmount = (widget.tx['totalAmount'] as num?)?.toDouble() ?? 0.0;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context).withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isEntrada ? 'Detalle de Entrada' : 'Detalle de Salida',
                    style: TextStyle(color: AppColors.getTextColor(context), fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Builder(
                    builder: (context) {
                      final String reason = widget.tx['reason'] ?? (widget.isEntrada ? 'Compra' : 'Venta');
                      Color reasonColor = Colors.greenAccent;
                      if (reason == 'Daño') {
                        reasonColor = Colors.redAccent;
                      } else if (reason == 'Servicio') {
                        reasonColor = Colors.cyanAccent;
                      } else if (reason == 'Consumo') {
                        reasonColor = Colors.orangeAccent;
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: reasonColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          reason,
                          style: TextStyle(
                            color: reasonColor,
                            fontSize: 11, fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 15),
              
              // Info Grid
              Row(
                children: [
                  Expanded(
                    child: _infoDetailItem(context, Icons.calendar_today_rounded, 'Fecha y Hora', dateStr),
                  ),
                  Expanded(
                    child: _infoDetailItem(context, Icons.warehouse_rounded, 'Almacén', widget.tx['warehouseName'] ?? 'Principal'),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _infoDetailItem(
                      context, 
                      widget.isEntrada ? Icons.local_shipping_rounded : Icons.person_rounded, 
                      partnerLabel, 
                      partnerName,
                    ),
                  ),
                  Expanded(
                    child: _infoDetailItem(context, Icons.badge_rounded, 'Registrado por', 'ID Usuario: ${widget.tx['userId'] ?? '1'}'),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              if (widget.tx['observations'] != null && widget.tx['observations'].toString().isNotEmpty) ...[
                _infoDetailItem(context, Icons.notes_rounded, 'Observaciones', widget.tx['observations'].toString()),
                const SizedBox(height: 20),
              ],

              const Text(
                'Productos Incluidos',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final double qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
                  final double price = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;
                  final subtotal = qty * price;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.02 : 0.04),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.03)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.moradoPrincipal.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.inventory_2_rounded, color: AppColors.moradoPrincipal, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['productName'] ?? 'Producto',
                                style: TextStyle(color: AppColors.getTextColor(context), fontSize: 13, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${qty.toStringAsFixed(0)} un. x \$${price.toStringAsFixed(2)}',
                                style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${subtotal.toStringAsFixed(2)}',
                          style: TextStyle(color: AppColors.getTextColor(context), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),


              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monto Total',
                    style: TextStyle(color: AppColors.getTextColor(context), fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.isEntrada 
                          ? [Colors.green, Colors.teal] 
                          : [Colors.orange, Colors.redAccent],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isEntrada ? Colors.green : Colors.orange).withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      '\$${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fifoMetaChip(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Icon(icon, color: widget.isEntrada ? Colors.greenAccent : const Color(0xFFB39DDB), size: 11),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoDetailItem(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.getSubtextColor(context), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 10)),
              const SizedBox(height: 2),
              Text(
                value, 
                style: TextStyle(color: AppColors.getTextColor(context), fontSize: 12, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
