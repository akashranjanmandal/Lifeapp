import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/model.dart';
import 'congratulations.dart';
import 'product_details.dart';
import '../provider/provider.dart';

class Products extends StatelessWidget {
  final Product product;

  const Products({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final coinBalance = provider.coinBalance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Products',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 26),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF6574F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Life App Coin Balance ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    coinBalance.toString(),
                    style: TextStyle(
                      color: Colors.amber[200],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Image.asset(
                      'assets/images/coin.png',
                      color: Colors.amber[200],
                      fit: BoxFit.contain,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.35,
                child: product.imageUrl != null
                    ? Image.network(product.imageUrl!, fit: BoxFit.contain)
                    : Image.asset('assets/balloon.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.2),
                      blurRadius: 3,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Text(
                  product.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    color: Colors.blueAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              child: const Text(
                'Description',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 19,
                  color: Colors.black,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6574F9),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      product.details,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (product.redeemed) {
                    // Ensure purchases are loaded
                    await provider.loadPurchases();

                    final purchase = provider.getPurchaseByProductId(product.id);
                    if (purchase != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetail(product: product, purchase: purchase),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Product redeemed, but purchase details not found.")),
                      );
                    }
                    return;
                  }

                  // Only redeem if not already redeemed
                  if (coinBalance >= product.coin) {
                    final newPurchase = await provider.redeem(product.id);

                    if (newPurchase != null && provider.error == null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetail(product: product, purchase: newPurchase),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(provider.error ?? 'Error: Could not redeem product')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You do not have enough coins to redeem this product.')),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
                  backgroundColor: product.redeemed || coinBalance >= product.coin
                      ? const Color(0xFF6574F9)
                      : Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.redeemed ? 'View Order Details' : 'Redeem with ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (!product.redeemed)
                      Text(
                        product.coin.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Image.asset(
                      'assets/images/coin.png',
                      width: 20,
                      height: 20,
                      color: Colors.amber[200],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}