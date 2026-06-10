import 'package:web_end/models/sale_view_model.dart';
import 'package:web_end/models/user_model.dart';

T? _read<T>(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) return json[key] as T?;
  }
  return null;
}

class DamageModel {
  final int id;
  final DateTime? damageDate;
  final UserModel? createdBy;
  final List<SaleActionModel> actions;

  const DamageModel({
    required this.id,
    this.damageDate,
    this.createdBy,
    this.actions = const [],
  });

  factory DamageModel.fromJson(Map<String, dynamic> json) {
    final createdByJson = _read<Map<String, dynamic>>(json, [
      'createdBy',
      'CreatedBy',
    ]);
    final actionsJson = _read<List>(json, ['actions', 'Actions']);
    final damageDate = _read<dynamic>(json, ['damageDate', 'DamageDate']);

    return DamageModel(
      id: (_read<num>(json, ['id', 'Id']) ?? 0).toInt(),
      damageDate: damageDate == null
          ? null
          : DateTime.tryParse(damageDate.toString()),
      createdBy: createdByJson == null
          ? null
          : UserModel.fromJson(createdByJson),
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

  double get totalDamagedQuantity =>
      actions.fold<double>(0, (sum, action) => sum + action.quantity);
}
