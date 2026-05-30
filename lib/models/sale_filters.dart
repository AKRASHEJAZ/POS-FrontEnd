class SaleFilters {
  final int? id;
  final int? customerId;
  final bool includeCustomer;
  final bool includeUser;
  final bool includeActions;
  final bool includeInventoryBatch;
  final int page;
  final int pageSize;

  const SaleFilters({
    this.id,
    this.customerId,
    this.includeCustomer = true,
    this.includeUser = true,
    this.includeActions = true,
    this.includeInventoryBatch = true,
    this.page = 1,
    this.pageSize = 10,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      'isIncludeCustomer': includeCustomer,
      'isIncludeUser': includeUser,
      'isInculdeActions': includeActions,
      'isIncludeInventoryBatch': includeInventoryBatch,
    };
    if (id != null && id! > 0) map['id'] = id;
    if (customerId != null && customerId! > 0) map['customerId'] = customerId;
    return map;
  }
}

