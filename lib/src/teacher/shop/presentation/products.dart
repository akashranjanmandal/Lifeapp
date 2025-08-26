import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../teacher_profile/presentations/pages/teacher_profile_page.dart';
import '../models/model.dart';
import 'congratulations.dart';
import 'product_details.dart';
import '../provider/provider.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class Products extends StatefulWidget {
  final Product product;

  const Products({super.key, required this.product});

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  DateTime? _startTime;
  bool _budgetExceeded = false;
  bool _schoolCodeValid = true;
  bool _schoolCodeDialogShown = false;
  bool _budgetDialogShown = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _fetchAndSetFlags();
    MixpanelService.track("Shop page opened", properties: {
      "product_title": widget.product.title,
      "timestamp": DateTime.now().toIso8601String(),
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchAndSetFlags(); // Refresh flags when coming back from other pages
  }

  Future<void> _fetchAndSetFlags() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    try {
      final response = await provider.service.fetchProductsWithCoins();
      final budgetExceeded = response['budget_exceeded'] ?? false;
      final schoolCodeValid = response['school_code'] ?? true;

      setState(() {
        _budgetExceeded = budgetExceeded;
        _schoolCodeValid = schoolCodeValid;

        // Reset dialog flags if issues were resolved
        if (schoolCodeValid) _schoolCodeDialogShown = false;
        if (!budgetExceeded) _budgetDialogShown = false;
      });

      if (!schoolCodeValid && !_schoolCodeDialogShown) {
        _schoolCodeDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showInvalidSchoolCodeDialog();
        });
      } else if (budgetExceeded &&
          !_budgetDialogShown &&
          !widget.product.redeemed) {
        _budgetDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showBudgetExceededDialog();
        });
      }
    } catch (e) {
      print('Error fetching flags: $e');
    }
  }

  void _showBudgetExceededDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
              SizedBox(width: 10),
              Text(
                'Budget Exceeded',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 19,
                ),
              ),
            ],
          ),
          content: const Text(
            "Your shopping budget has been exceeded for this month.\n\nYou'll need to wait until it resets before making new purchases.",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF6574F9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Close',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showInvalidSchoolCodeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.school, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Text(
                'Update Required',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Text(
            "Oops! We need your school code to process this purchase. Please update it in your profile and try again.",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TeacherProfilePage()),
                ).then((_) => _fetchAndSetFlags()); // Refresh flags on return
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text('Update Now',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    if (_startTime != null) {
      final duration = DateTime.now().difference(_startTime!).inSeconds;
      MixpanelService.track("Shop screen activity time", properties: {
        "duration_seconds": duration,
        "product_title": widget.product.title,
        "timestamp": DateTime.now().toIso8601String(),
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final coinBalance = provider.coinBalance;
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Products',
            style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 26),
          onPressed: () {
            MixpanelService.track("Back icon clicked", properties: {
              "product_title": product.title,
              "timestamp": DateTime.now().toIso8601String(),
            });
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coin balance
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFF6574F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Life App Coin Balance ',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                  Text(coinBalance.toString(),
                      style: TextStyle(
                          color: Colors.amber[200],
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  SizedBox(width: 6),
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Image.asset('assets/images/coin.png',
                        color: Colors.amber[200]),
                  )
                ],
              ),
            ),

            // Image
            SizedBox(height: 10),
            Center(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.35,
                child: product.imageUrl != null
                    ? Image.network(product.imageUrl!, fit: BoxFit.contain)
                    : Image.asset('assets/balloon.png', fit: BoxFit.contain),
              ),
            ),

            // Title
            SizedBox(height: 10),
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.2),
                      blurRadius: 3,
                      spreadRadius: 1,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Text(
                  product.title,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: Colors.blueAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Description
            SizedBox(height: 20),
            Text('Description',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 19,
                    color: Colors.black)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 6, right: 12),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Color(0xFF6574F9),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Expanded(
                  child: Text(
                    product.details,
                    style: TextStyle(
                        fontSize: 16, color: Colors.black87, height: 1.5),
                  ),
                ),
              ],
            ),

            // Redeem Button
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _fetchAndSetFlags(); // Ensure flags are fresh before proceeding

                  if (!_schoolCodeValid) {
                    _showInvalidSchoolCodeDialog();
                    return;
                  }

                  if (_budgetExceeded && !product.redeemed) {
                    _showBudgetExceededDialog();
                    return;
                  }

                  MixpanelService.track(
                      product.redeemed
                          ? "Product View Order Details clicked"
                          : "Product Redeem clicked",
                      properties: {
                        "product_title": product.title,
                        "product_id": product.id ?? "",
                        "redeemed": product.redeemed,
                        "timestamp": DateTime.now().toIso8601String(),
                      });

                  if (product.redeemed) {
                    await provider.loadPurchases();
                    final purchase =
                        provider.getPurchaseByProductId(product.id);
                    if (purchase != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetail(
                            product: product,
                            purchase: purchase,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                "Product redeemed, but purchase details not found.")),
                      );
                    }
                  } else {
                    if (coinBalance >= product.coin) {
                      final newPurchase = await provider.redeem(product.id);
                      if (newPurchase != null && provider.error == null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  BoughtProduct(product: product)),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(provider.error ??
                                  'Could not redeem product')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'You do not have enough coins to redeem this product.')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      product.redeemed || coinBalance >= product.coin
                          ? Color(0xFF6574F9)
                          : Colors.grey.shade400,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.redeemed ? 'View Order Details' : 'Redeem with ',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16),
                    ),
                    if (!product.redeemed)
                      Text(product.coin.toString(),
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                    SizedBox(width: 8),
                    Image.asset('assets/images/coin.png',
                        width: 20, height: 20, color: Colors.amber[200]),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
