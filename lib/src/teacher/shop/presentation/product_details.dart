import 'package:flutter/material.dart';
import 'package:lifelab3/src/teacher/shop/presentation/product_list.dart';
import 'package:lifelab3/src/teacher/shop/presentation/products.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../utils/storage_utils.dart';
import '../../teacher_tool/presentations/pages/teacher_class_page.dart';
import '../models/model.dart';
import '../provider/provider.dart';
import '../services/services.dart';
import 'purchase_history.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';
class ProductDetail extends StatelessWidget {
  final Product product;
  final Purchase purchase;
  final Color primaryColor = const Color(0xFF6574F9);
  final Color secondaryColor = const Color(0xFFF5F7FF);

  const ProductDetail({
    required this.product,
    required this.purchase,
    super.key,
  });

  Widget _buildActionButton(
      BuildContext context,
      String text,
      IconData icon,
      VoidCallback onPressed, {
        bool filled = true,
      }) {
    return SizedBox(
      width: double.infinity,
      child: filled
          ? ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      )
          : OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Product',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () {
            // Track back icon clicked
            MixpanelService.track("Back icon clicked in product detail page", properties: {
              "product_title": product.title,
              "product_id": product.id ?? "",
              "timestamp": DateTime.now().toIso8601String(),
            });
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(  // <-- This makes the entire page scrollable
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Product Image
            Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: product.imageUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
                  : const Icon(Icons.image_outlined, size: 60, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            // Product Title
            Align(
              alignment: Alignment.center,
              child: Text(
                product.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6574F9),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Product Info',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.details.isEmpty ? 'No information given' : product.details,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            // Shipping Status Section
            const SizedBox(height: 16),
            // Shipping Address and Shipping Date Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          purchase.status ?? 'Not Provided',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Date',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          purchase.redeemedAt != null
                              ? DateFormat('d MMM yyyy, h:mm a').format(DateTime.parse(purchase.redeemedAt!))
                              : 'Not redeemed',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Shop More',
                        Icons.shopping_bag_outlined,
                            () {
                              MixpanelService.track("Shop More button clicked in product detail", properties: {
                                "product_title": product.title,
                                "timestamp": DateTime.now().toIso8601String(),
                              });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider(
                                create: (_) => ProductProvider(
                                  ProductService(StorageUtil.getString('auth_token')),
                                )..loadProducts(),
                                child: const ProductList(),
                              ),
                            ),
                          );
                        },
                        filled: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Earn More Coins',
                        Icons.monetization_on_outlined,
                            () {
                              MixpanelService.track("Earn More Coins button clicked in product detail", properties: {
                                "product_title": product.title,
                                "timestamp": DateTime.now().toIso8601String(),
                              });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TeacherClassPage(),
                            ),
                          );
                        },
                        filled: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
              ],
            ),
            const SizedBox(height: 4), // Space before the bottom button
            // Bottom button (now part of the scrollable content)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  MixpanelService.track("View Purchase History button clicked", properties: {
                    "product_title": product.title,
                    "timestamp": DateTime.now().toIso8601String(),

                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: Provider.of<ProductProvider>(context, listen: false),
                        child: const PurchaseHistory(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6574F9),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Purchase History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24), // Bottom padding
          ],
        ),
      ),
    );
  }
}