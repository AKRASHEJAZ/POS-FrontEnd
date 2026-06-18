class ReturnFilters {
  final int? id;
  final int? inventoryBatchId;
  final int? customerId;
  final bool includeActions;
  final bool includeInventoryBatch;
  final bool includeSale;
  final int page;
  final int pageSize;

  const ReturnFilters({
    this.id,
    this.inventoryBatchId,
    this.customerId,
    this.includeActions = true,
    this.includeInventoryBatch = true,
    this.includeSale = true,
    this.page = 1,
    this.pageSize = 10,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      'isIncludeActions': includeActions,
      'isIncludeInventoryBatch': includeInventoryBatch,
      'isIncludeSale': includeSale,
    };

    if (id != null && id! > 0) map['id'] = id;
    if (inventoryBatchId != null && inventoryBatchId! > 0) {
      map['inventoryBatchId'] = inventoryBatchId;
    }
    if (customerId != null && customerId! > 0) {
      map['customerId'] = customerId;
    }

    return map;
  }
}
