import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/provider.dart';
import '../models/model.dart';

const _kPurple = Color(0xFF6574F9);
const _kLavender = Color(0xFFF5F6FA);
const _kCoinGold = Color(0xFFFFB400);
const _kGreenGain = Color(0xFF3DB24B);
const _kRedLoss = Color(0xFFE04444);

class CoinHistoryPage extends StatefulWidget {
  const CoinHistoryPage({super.key});

  @override
  State<CoinHistoryPage> createState() => _CoinHistoryPageState();
}

class _CoinHistoryPageState extends State<CoinHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ProductProvider>();
      await provider.loadCoinTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kLavender,
      appBar: AppBar(
        backgroundColor: _kLavender,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Coin History', style: TextStyle(color: Colors.black)),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          final history = provider.coinTransactions;

          final totalEarned = history.where((tx) => tx.amount > 0).fold<int>(0, (sum, tx) => sum + tx.amount);
          final totalSpent = history.where((tx) => tx.amount < 0).fold<int>(0, (sum, tx) => sum + tx.amount.abs());

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatCard(title: 'Total Coin Earned', value: totalEarned.toString()),
                    const SizedBox(width: 12),
                    _StatCard(title: 'Coin Balance', value: provider.coinBalance.toString()),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F5FF),
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
                            Icons.monetization_on_outlined,
                            color: Color(0xFF5C6BFF),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Track Your Life App Coins",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF3C4FE0),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Monitor your coin earnings and usage",
                              style: TextStyle(
                                fontSize: 10.5,
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
                const SizedBox(height: 16),
                if (history.isEmpty)
                  const Center(child: Text('No coin transactions found.'))
                else
                  ...history.map((tx) => _CoinHistoryTile(transaction: tx)).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(color: _kPurple, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.monetization_on, color: _kCoinGold, size: 20),
                const SizedBox(width: 4),
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinHistoryTile extends StatelessWidget {
  const _CoinHistoryTile({required this.transaction});
  final CoinTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final bool isGain = transaction.amount >= 0;

    // Normalize sourceType for display
    String normalizedSourceType;
    final lowerSourceType = transaction.sourceType.toLowerCase();
    if (lowerSourceType.contains('vision')) {
      normalizedSourceType = 'vision';
    } else if (lowerSourceType.contains('lamission')) {
      normalizedSourceType = 'mission';
    } else if (lowerSourceType.contains('couponredeem')) {
      normalizedSourceType = 'purchased';
    } else {
      normalizedSourceType = transaction.sourceType;
    }

    // Badge color logic based on normalized sourceType
    Color badgeBg;
    Color badgeTextColor;
    switch (normalizedSourceType) {
      case 'mission':
        badgeBg = Colors.blue.shade100;
        badgeTextColor = Colors.blue.shade800;
        break;
      case 'vision':
        badgeBg = Colors.orange.shade100;
        badgeTextColor = Colors.orange.shade800;
        break;
      case 'purchased':
        badgeBg = Colors.green.shade100;
        badgeTextColor = Colors.green.shade800;
        break;
      default:
        badgeBg = Colors.grey.shade300;
        badgeTextColor = Colors.grey.shade700;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kLavender),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(101, 116, 249, 0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isGain ? _kGreenGain.withOpacity(0.1) : _kRedLoss.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isGain ? Icons.arrow_circle_up : Icons.arrow_circle_down,
              color: isGain ? _kGreenGain : _kRedLoss,
              size: 40,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        transaction.sourceTitle,
                        style: const TextStyle(
                          color: _kPurple,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        normalizedSourceType,
                        style: TextStyle(
                          color: badgeTextColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.typeLabel,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${isGain ? '+' : ''}${transaction.amount}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isGain ? _kGreenGain : _kRedLoss,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.monetization_on, color: _kCoinGold, size: 18),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDate(transaction.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Text(
                _formatTime(transaction.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${_twoDigits(dt.month)}-${_twoDigits(dt.day)}';

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = _twoDigits(dt.minute);
    return '$hour:$min $ampm';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
