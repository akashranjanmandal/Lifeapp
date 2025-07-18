import 'package:flutter/material.dart';
import '../models/model.dart';
import '../services/services.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService service;

  List<Product> _products = [];
  List<Purchase> _purchases = [];
  List<CoinTransaction> _coinTransactions = [];
  Purchase? getPurchaseByProductId(int productId) {
    try {
      return _purchases.firstWhere((purchase) => purchase.couponId == productId);
    } catch (e) {
      return null;
    }
  }


  int _coinBalance = 0;        // available coins
  int _totalEarnedCoins = 0;   // total earned coins

  bool _loading = false;
  String? _error;

  bool _disposed = false;

  ProductProvider(this.service);

  // Getters
  List<Product> get products => _products;
  List<Purchase> get purchases => _purchases;
  List<CoinTransaction> get coinTransactions => _coinTransactions;

  int get coinBalance => _coinBalance;
  int get totalEarnedCoins => _totalEarnedCoins;

  bool get loading => _loading;
  String? get error => _error;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _setLoading(bool val) {
    if (_disposed) return;
    _loading = val;
    notifyListeners();
  }

  void _setError(String? message) {
    if (_disposed) return;
    _error = message;
    notifyListeners();
  }

  Future<void> loadProducts() async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await service.fetchProductsWithCoins();

      if (_disposed) return;

      _coinBalance = response['available_coins'] ?? 0;
      _totalEarnedCoins = response['total_earned_coins'] ?? 0;

      final productsJson = response['coupons'] as List<dynamic>? ?? [];
      _products = productsJson.map((json) => Product.fromJson(json)).toList();

      _setLoading(false);
    } catch (e, stacktrace) {
      _setError(e.toString());
      _setLoading(false);
      print(stacktrace);
    }
  }

  Future<void> loadPurchases() async {
    _setLoading(true);
    _setError(null);

    try {
      final data = await service.fetchPurchaseHistory();

      if (_disposed) return;

      _purchases = data;

      _setLoading(false);
    } catch (e, stacktrace) {
      _setError(e.toString());
      _setLoading(false);
      print(stacktrace);
    }
  }

  Future<Purchase?> redeem(int productId) async {
    _setLoading(true);
    _setError(null);

    try {
      _coinBalance = await service.redeemProduct(productId);

      if (_disposed) return null;

      // Refresh your data after redeeming
      await loadProducts();
      await loadPurchases();

      _setLoading(false);

      // Return the purchase for this product
      return getPurchaseByProductId(productId);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  Future<void> loadCoinTransactions() async {
    _setLoading(true);
    _setError(null);

    try {
      _coinTransactions = await service.fetchCoinTransactions();

      if (_disposed) return;

      _setLoading(false);
    } catch (e, stacktrace) {
      _setError(e.toString());
      _setLoading(false);
      print(stacktrace);
    }
  }
}
