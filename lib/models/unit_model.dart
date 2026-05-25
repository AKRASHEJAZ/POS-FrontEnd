class UnitModel {
  final int id;
  final String name;
  final String symbol;
  final DateTime? createdAt;

  const UnitModel({
    required this.id,
    required this.name,
    required this.symbol,
    this.createdAt,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
