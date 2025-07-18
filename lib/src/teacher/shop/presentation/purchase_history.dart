import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../provider/provider.dart';
import 'assignment_list.dart';

const _kPurple = Color(0xFF5C6BFF);
const _kLavender = Color(0xFFF5F6FA);
const _kCoinGold = Color(0xFFFFB400);

class PurchaseHistory extends StatefulWidget {
  const PurchaseHistory({super.key});

  @override
  State<PurchaseHistory> createState() => _PurchaseHistoryState();
}

class _PurchaseHistoryState extends State<PurchaseHistory> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ProductProvider>();
      await provider.loadProducts();
      await provider.loadPurchases();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kLavender,
      appBar: AppBar(
        title: const Text('Purchase History', style: TextStyle(color: Colors.black)),
        centerTitle: false,
        backgroundColor: _kLavender,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Stats Buttons with InkWell to navigate
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: Provider.of<ProductProvider>(context, listen: false),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: Provider.of<ProductProvider>(context, listen: false),
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
                const SizedBox(height: 20),

                // Title bar for purchase history
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDBDFFD), Color(0xFFECEEFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Color(0xFF5C6BFF),
                      width: 1,
                      style: BorderStyle.solid, // Flutter doesn't support dashed directly
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.history_edu_rounded,
                        color: Color(0xFF5C6BFF),
                        size: 26,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Purchase History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5C6BFF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Purchase list or empty text
                if (provider.purchases.isEmpty)
                  const Center(child: Text('No purchases found.'))
                else
                  Column(
                    children: provider.purchases.map((p) {
                      return _PurchaseItem(
                        imageUrl: p.imageUrl ?? '',
                        productName: p.productName ?? 'Unknown Product',
                        coins: p.coinsSpent ?? 0,
                        date: p.redeemedAt ?? 'Unknown Date',
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PurchaseItem extends StatelessWidget {
  final String imageUrl;
  final String productName;
  final int coins;
  final String date;

  const _PurchaseItem({
    required this.imageUrl,
    required this.productName,
    required this.coins,
    required this.date,
  });

  Widget _buildImageWidget() {
    if (imageUrl.isEmpty) {
      return _buildPlaceholderIcon();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: 110,
      height: 110,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => _buildErrorIcon(),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.shopping_bag,
        size: 40,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildErrorIcon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 4),
          Text(
            'Image unavailable',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image container with rounded corners
          Container(
            width: 110,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageWidget(),
            ),
          ),
          const SizedBox(width: 12),

          // Product info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    color: _kPurple,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Purchased on: $date',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _kPurple, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Coin spent',
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                      const SizedBox(width: 12),
                      Image.asset('assets/images/coin.png', width: 18, height: 19),
                      const SizedBox(width: 6),
                      Text(
                        coins.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
