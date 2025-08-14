import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../utils/storage_utils.dart';
import '../../teacher_dashboard/presentations/pages/teacher_dashboard_page.dart';
import '../provider/provider.dart'; // Your ProductProvider
import '../services/services.dart';

import 'assignment_list.dart';
import 'products.dart'; // Product detail page
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

const _kPurple = Color(0xFF6574F9);
const _kCoinGold = Color(0xFFFFB400);

const String imageBaseUrl = 'https://lifeappmedia.blr1.digitaloceanspaces.com/';

class ProductList extends StatefulWidget {
  const ProductList({super.key});

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    // Track screen opened
    MixpanelService.track("Shop screen opened", properties: {
      "timestamp": DateTime.now().toIso8601String(),
    });
  }

  @override
  void dispose() {
    if (_startTime != null) {
      final duration = DateTime.now().difference(_startTime!).inSeconds;
      MixpanelService.track("Shop screen activity time", properties: {
        "duration_seconds": duration,
        "timestamp": DateTime.now().toIso8601String(),
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Home',
          style: TextStyle(
            color: Color.fromARGB(255, 71, 70, 70),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
          onPressed: () {
            MixpanelService.track("Back icon clicked", properties: {
              "timestamp": DateTime.now().toIso8601String(),
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) => ProductProvider(
                    ProductService(StorageUtil.getString('auth_token')),
                  )..loadProducts(),
                  child: const TeacherDashboardPage(),
                ),
              ),
            );
          },
        ),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          return RefreshIndicator(
            onRefresh: () async => await provider.loadProducts(),
            child: Container(
              color: const Color(0xFFF7F8FA),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 20),
                children: [
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              MixpanelService.track(
                                "Total coin earned button clicked",
                                properties: {
                                  "timestamp": DateTime.now().toIso8601String(),
                                  "coin_earned": provider.totalEarnedCoins,
                                },
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider.value(
                                    value: Provider.of<ProductProvider>(context,
                                        listen: false),
                                    child: const CoinHistoryPage(),
                                  ),
                                ),
                              );
                            },
                            child: _CoinCard(
                              title: 'Total Coin Earned',
                              coinCount: provider.totalEarnedCoins,
                              coinColor: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              MixpanelService.track(
                                "Total coin balance button clicked",
                                properties: {
                                  "timestamp": DateTime.now().toIso8601String(),
                                  "coin_balance": provider.coinBalance,
                                },
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider.value(
                                    value: Provider.of<ProductProvider>(context,
                                        listen: false),
                                    child: const CoinHistoryPage(),
                                  ),
                                ),
                              );
                            },
                            child: _CoinCard(
                              title: 'Total Coin Balance',
                              coinCount: provider.coinBalance,
                              coinColor: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5FF), // soft purple-ish background
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF5C6BFF).withOpacity(0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5C6BFF).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Color(0xFF5C6BFF),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Available Product List",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF3C4FE0),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Browse products available for purchase",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Product cards
                  ...provider.products.asMap().entries.map((entry) {
                    final index = entry.key;
                    final product = entry.value;

                    final imageUrl = product.imageUrl != null &&
                        product.imageUrl!.isNotEmpty
                        ? product.imageUrl!
                        : null;

                    return ProductItem(
                      productName: product.title,
                      redeemPoints: product.coin,
                      balloonAssetPath:
                      imageUrl != null ? imageUrl : 'assets/images/coin.png',
                      isFirst: index == 0,
                      isRedeemed: product.redeemed, // ✅ <-- pass the flag
                      onTap: () {
                        MixpanelService.track("Individual product item clicked", properties: {
                          "timestamp": DateTime.now().toIso8601String(),
                          "product_title": product.title,
                          "product_coin": product.coin,
                          "product_id": product.id ?? "",
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: Provider.of<ProductProvider>(context, listen: false),
                              child: Products(product: product),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CoinCard extends StatelessWidget {
  final String title;
  final int coinCount;
  final Color coinColor;

  const _CoinCard({
    required this.title,
    required this.coinCount,
    required this.coinColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _kPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.monetization_on, color: _kCoinGold, size: 20),
              const SizedBox(width: 4),
              Text(
                coinCount.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: coinColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class ProductItem extends StatelessWidget {
  final String balloonAssetPath;
  final String productName;
  final int redeemPoints;
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isRedeemed; // ✅ NEW

  const ProductItem({
    super.key,
    required this.balloonAssetPath,
    required this.productName,
    required this.redeemPoints,
    this.onTap,
    this.isFirst = false,
    required this.isRedeemed, // ✅ NEW
  });


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: balloonAssetPath.startsWith('http')
                    ? CachedNetworkImage(
                  imageUrl: balloonAssetPath,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Container(
                    height: 160,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 60),
                    ),
                  ),
                )
                    : Image.asset(
                  balloonAssetPath,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF6574F9),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Text(
                  productName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: isRedeemed
                      ? const Text(
                    "Redeemed",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black38,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Redeem With ',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      Image.asset(
                        "assets/images/coin.png",
                        height: 18,
                        width: 18,
                      ),
                      Text(
                        " $redeemPoints",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
