class DamageFilters {
  final int? id;
  final int? inventoryBatchId;
  final int? productId;
  final bool includeActions;
  final bool includeInventoryBatch;
  final int page;
  final int pageSize;

  const DamageFilters({
    this.id,
    this.inventoryBatchId,
    this.productId,
    this.includeActions = true,
    this.includeInventoryBatch = true,
    this.page = 1,
    this.pageSize = 10,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      'isIncludeActions': includeActions,
      'isIncludeInventoryBatch': includeInventoryBatch,
    };

    if (id != null && id! > 0) map['id'] = id;
    if (inventoryBatchId != null && inventoryBatchId! > 0) {
      map['inventoryBatchId'] = inventoryBatchId;
    }
    if (productId != null && productId! > 0) map['productId'] = productId;

    return map;
  }
}
