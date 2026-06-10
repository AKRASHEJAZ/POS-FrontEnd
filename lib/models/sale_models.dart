class AddInventoryActionDto {
  final int inventoryBatchId;
  final num quantity;
  final String? notes;

  const AddInventoryActionDto({
    required this.inventoryBatchId,
    required this.quantity,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'inventoryBatchId': inventoryBatchId,
      'quantity': quantity,
    };
    if (notes != null && notes!.trim().isNotEmpty) {
      map['notes'] = notes!.trim();
    }
    return map;
  }
}

class AddSaleDto {
  final int customerId;
  final List<AddInventoryActionDto> inventoryActions;

  const AddSaleDto({required this.customerId, required this.inventoryActions});

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'inventoryActions': inventoryActions.map((a) => a.toJson()).toList(),
  };
}

class AddDamageDto {
  final List<AddInventoryActionDto> inventoryActions;

  const AddDamageDto({required this.inventoryActions});

  Map<String, dynamic> toJson() => {
    'inventoryActions': inventoryActions.map((a) => a.toJson()).toList(),
  };
}
