import 'package:flutter/material.dart';
import '../models/model.dart';
import '../services/services.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService service;

  // Data lists
  List<Product> _products = [];
  List<Purchase> _purchases = [];
  List<CoinTransaction> _coinTransactions = [];

  // Coin stats
  int _coinBalance = 0;        // Available coins
  int _totalEarnedCoins = 0;   // Total earned coins

  // Status flags
  bool _loading = false;
  String? _error;
  bool _disposed = false;

  // Flags from API
  bool _budgetExceeded = false;
  bool _schoolCode = true;

  ProductProvider(this.service);

  // ======= Getters =======
  List<Product> get products => _products;
  List<Purchase> get purchases => _purchases;
  List<CoinTransaction> get coinTransactions => _coinTransactions;

  int get coinBalance => _coinBalance;
  int get totalEarnedCoins => _totalEarnedCoins;

  bool get loading => _loading;
  String? get error => _error;

  bool get budgetExceeded => _budgetExceeded;
  bool get schoolCode => _schoolCode;

  // ======= Private setters =======
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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ======= Helper =======
  Purchase? getPurchaseByProductId(int productId) {
    try {
      return _purchases.firstWhere((purchase) => purchase.couponId == productId);
    } catch (_) {
      return null;
    }
  }

  // ======= Load products with flags and coins =======
  Future<void> loadProducts() async {
    _setLoading(true);
    _setError(null);

    try {
      final res = await service.fetchProductsWithCoins();

      // Log the full response for debugging
      debugPrint('Full API response in provider: $res');

      // Extract API flags at top-level
      _schoolCode = res['school_code'] == true;
      _budgetExceeded = res['budget_exceeded'] == true;

      final data = res['data'] as Map<String, dynamic>?;

      if (data == null) {
        throw Exception('No data found in API response');
      }

      _coinBalance = data['available_coins'] ?? 0;
      _totalEarnedCoins = data['total_earned_coins'] ?? 0;

      final couponsList = data['coupons'] as List<dynamic>? ?? [];
      _products = couponsList.map((item) => Product.fromJson(item)).toList();

      _setLoading(false);
    } catch (e, st) {
      _setError(e.toString());
      _setLoading(false);
      debugPrint('Error loading products: $e\n$st');
    }
  }

  // ======= Load purchase history =======
  Future<void> loadPurchases() async {
    _setLoading(true);
    _setError(null);

    try {
      final data = await service.fetchPurchaseHistory();

      if (_disposed) return;

      _purchases = data;
      _setLoading(false);
    } catch (e, st) {
      _setError(e.toString());
      _setLoading(false);
      debugPrint('Error loading purchases: $e\n$st');
    }
  }

  // ======= Redeem product =======
  Future<Purchase?> redeem(int productId) async {
    if (_budgetExceeded) {
      _setError('Budget limit exceeded. Cannot redeem.');
      return null;
    }
    if (!_schoolCode) {
      _setError('School code incomplete. Cannot redeem.');
      return null;
    }

    _setLoading(true);
    _setError(null);

    try {
      _coinBalance = await service.redeemProduct(productId);

      if (_disposed) return null;

      // Refresh products and purchases after redeem
      await loadProducts();
      await loadPurchases();

      _setLoading(false);

      return getPurchaseByProductId(productId);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  // ======= Load coin transaction history =======
  Future<void> loadCoinTransactions() async {
    _setLoading(true);
    _setError(null);

    try {
      _coinTransactions = await service.fetchCoinTransactions();

      if (_disposed) return;

      _setLoading(false);
    } catch (e, st) {
      _setError(e.toString());
      _setLoading(false);
      debugPrint('Error loading coin transactions: $e\n$st');
    }
  }
}
