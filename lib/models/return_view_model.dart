import 'package:web_end/models/sale_view_model.dart';

T? _read<T>(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) return json[key] as T?;
  }
  return null;
}

class ReturnModel {
  final int id;
  final int saleId;
  final int customerId;
  final DateTime? returnDate;
  final String? reason;
  final List<SaleActionModel> actions;

  const ReturnModel({
    required this.id,
    required this.saleId,
    required this.customerId,
    this.returnDate,
    this.reason,
    this.actions = const [],
  });

  factory ReturnModel.fromJson(Map<String, dynamic> json) {
    final actionsJson = _read<List>(json, ['actions', 'Actions']);
    final returnDate = _read<dynamic>(json, ['returnDate', 'ReturnDate']);

    return ReturnModel(
      id: (_read<num>(json, ['id', 'Id']) ?? 0).toInt(),
      saleId: (_read<num>(json, ['saleId', 'SaleId']) ?? 0).toInt(),
      customerId: (_read<num>(json, ['customerId', 'CustomerId']) ?? 0).toInt(),
      returnDate: returnDate == null
          ? null
          : DateTime.tryParse(returnDate.toString()),
      reason: _read<String>(json, ['reason', 'Reason']),
      actions: actionsJson == null
          ? const []
          : actionsJson
                .whereType<Map>()
                .map(
                  (item) =>
                      SaleActionModel.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(),
    );
  }

  double get totalReturnedQuantity =>
      actions.fold<double>(0, (sum, action) => sum + action.quantity);
}
