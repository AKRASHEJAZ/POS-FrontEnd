import 'package:web_end/models/product_model.dart';

/// Mirrors backend `ValidateStockEntry` rules for add-stock.
class StockEntryValidation {
  static String? productEligibility(ProductModel? product) {
    if (product == null) return null;
    if (!product.isActive) {
      return 'Cannot add stock for an inactive product.';
    }
    if (!product.isPurchasable) {
      return 'This product is not marked as purchasable.';
    }
    return null;
  }

  static String? purchasedQuantity(double? value) {
    if (value == null || value <= 0) {
      return 'Purchased amount must be greater than zero.';
    }
    return null;
  }

  static String? purchasePrice(double? value) {
    if (value == null || value <= 0) {
      return 'Purchase price must be greater than zero.';
    }
    return null;
  }

  static String? sellingPrice(double? value, double purchasePrice) {
    if (value == null || value <= 0) {
      return 'Selling price must be greater than zero.';
    }
    if (value < purchasePrice) {
      return 'Selling price cannot be less than purchase price.';
    }
    return null;
  }

  static String? expiryDate({
    required ProductModel product,
    DateTime? expiry,
    DateTime? mfg,
  }) {
    if (!product.doesExpire) return null;

    if (expiry == null) {
      return 'Expiry date is required for products that expire.';
    }

    final today = DateTime.now();
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    final todayDay = DateTime(today.year, today.month, today.day);

    if (!expiryDay.isAfter(todayDay)) {
      return 'Expiry date must be in the future.';
    }

    if (mfg != null) {
      final mfgDay = DateTime(mfg.year, mfg.month, mfg.day);
      if (!expiryDay.isAfter(mfgDay)) {
        return 'Expiry date must be after manufacturing date.';
      }
    }

    return null;
  }

  static String? validateAll({
    required ProductModel? product,
    required double? purchasedQuantity,
    required double? purchasePrice,
    required double? sellingPrice,
    DateTime? mfgDate,
    DateTime? expiryDate,
  }) {
    final productError = productEligibility(product);
    if (productError != null) return productError;
    if (product == null) return 'Search and select a product.';

    return StockEntryValidation.purchasedQuantity(purchasedQuantity) ??
        StockEntryValidation.purchasePrice(purchasePrice) ??
        StockEntryValidation.sellingPrice(sellingPrice, purchasePrice!) ??
        StockEntryValidation.expiryDate(
          product: product,
          expiry: expiryDate,
          mfg: mfgDate,
        );
  }
}
