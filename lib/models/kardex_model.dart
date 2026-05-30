class KardexModel {
  final DateTime date;
  final String type; // 'ENTRADA' | 'SALIDA'
  final int quantity;
  final double unitPrice;
  final int runningStock;
  final String userName;
  final String observations;

  KardexModel({
    required this.date,
    required this.type,
    required this.quantity,
    required this.unitPrice,
    required this.runningStock,
    required this.userName,
    required this.observations,
  });

  factory KardexModel.fromJson(Map<String, dynamic> json) {
    return KardexModel(
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      type: json['type'] ?? 'ENTRADA',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
      runningStock: json['runningStock'] ?? 0,
      userName: json['userName'] ?? 'Desconocido',
      observations: json['observations'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'type': type,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'runningStock': runningStock,
      'userName': userName,
      'observations': observations,
    };
  }
}
