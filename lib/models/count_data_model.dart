class CountDataModel {
  final int totalProducts;
  final int activeProducts;
  final int totalUsers;
  final int activeUsers;
  final double totalSale;
  final double totalDamages;
  final double totalReturns;

  const CountDataModel({
    required this.totalProducts,
    required this.activeProducts,
    required this.totalUsers,
    required this.activeUsers,
    required this.totalSale,
    required this.totalDamages,
    required this.totalReturns,
  });

  factory CountDataModel.fromJson(Map<String, dynamic> json) {
    final userData = json['userData'] ?? json['UserData'] ?? {};
    return CountDataModel(
      totalProducts: _toInt(json['totalProducts'] ?? json['TotalProducts']),
      activeProducts: _toInt(json['activeProduct'] ?? json['ActiveProduct']),
      totalUsers: _toInt(userData['totalUsers'] ?? userData['TotalUsers']),
      activeUsers: _toInt(userData['activeUsers'] ?? userData['ActiveUsers']),
      totalSale: _toDouble(json['totalSale'] ?? json['TotalSale']),
      totalDamages: _toDouble(json['totalDamages'] ?? json['TotalDamages']),
      totalReturns: _toDouble(json['totalReturns'] ?? json['TotalReturns']),
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
