import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../utils/app_colors.dart';

class TransactionDetailSheet extends StatefulWidget {
  final Map<String, dynamic> tx;
  final bool isEntrada;

  const TransactionDetailSheet({
    super.key,
    required this.tx,
    required this.isEntrada,
  });

  @override
  State<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<TransactionDetailSheet> {
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

              if (true) ...[
                const SizedBox(height: 20),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: widget.isEntrada
                            ? const LinearGradient(colors: [Colors.green, Colors.teal])
                            : const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.isEntrada ? Icons.add_to_photos_rounded : Icons.layers_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.isEntrada ? 'Trazabilidad PEPS — Lote Generado' : 'Trazabilidad PEPS — Consumo por Lote',
                      style: TextStyle(
                        color: AppColors.getTextColor(context),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (fifoLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.moradoPrincipal,
                        ),
                      ),
                    ),
                  )
                else if (fifoDetail.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.02 : 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.getSubtextColor(context), size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.isEntrada 
                              ? 'Esta entrada no tiene lotes registrados (puede ser anterior a PEPS).'
                              : 'Esta transacción no tiene trazabilidad de lotes registrada (puede ser anterior a PEPS).',
                            style: TextStyle(color: AppColors.getSubtextColor(context), fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...fifoDetail.map((detail) {
                    final lotId = detail['lotId']?.toString() ?? '?';
                    final int qtyLot = int.tryParse(detail['quantity']?.toString() ?? '') ?? 0;
                    final double unitCost = double.tryParse(detail['unitPrice']?.toString() ?? '') ?? 0.0;
                    final double subtotalLot = qtyLot * unitCost;
                    final String productName = detail['productName'] ?? '';
                    final lotDateRaw = detail['lotEntryDate'];
                    String lotDateStr = 'N/A';
                    if (lotDateRaw != null) {
                      try {
                        final d = DateTime.parse(lotDateRaw.toString()).toLocal();
                        lotDateStr = '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
                      } catch (_) {}
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isEntrada
                            ? [
                                Colors.green.withOpacity(isDark ? 0.08 : 0.04),
                                Colors.teal.withOpacity(isDark ? 0.06 : 0.03),
                              ]
                            : [
                                const Color(0xFF6A11CB).withOpacity(isDark ? 0.08 : 0.04),
                                const Color(0xFF2575FC).withOpacity(isDark ? 0.06 : 0.03),
                              ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: widget.isEntrada 
                            ? Colors.green.withOpacity(0.1) 
                            : const Color(0xFF6A11CB).withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: widget.isEntrada 
                                          ? Colors.green.withOpacity(0.15) 
                                          : const Color(0xFF6A11CB).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Lote #$lotId',
                                        style: TextStyle(
                                          color: widget.isEntrada ? Colors.greenAccent : const Color(0xFFB39DDB),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (productName.isNotEmpty)
                                      Flexible(
                                        child: Text(
                                          productName,
                                          style: TextStyle(
                                            color: AppColors.getSubtextColor(context),
                                            fontSize: 11,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '\$${subtotalLot.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: widget.isEntrada ? Colors.greenAccent : const Color(0xFF64B5F6),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _fifoMetaChip(Icons.event_rounded, widget.isEntrada ? 'Fecha lote' : 'Entrada lote', lotDateStr),
                              _fifoMetaChip(Icons.numbers_rounded, widget.isEntrada ? 'Cant. Gen' : 'Cant.', '$qtyLot u.'),
                              _fifoMetaChip(Icons.attach_money_rounded, widget.isEntrada ? 'Costo Compra' : 'Costo U.', '\$${unitCost.toStringAsFixed(2)}'),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],

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
