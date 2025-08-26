import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lifelab3/src/student/profile/presentations/pages/profile_page.dart';
import 'package:provider/provider.dart';
import '../../../common/helper/color_code.dart';
import '../../../common/widgets/common_appbar.dart';
import '../../../common/widgets/common_navigator.dart';
import '../../../common/utils/mixpanel_service.dart';
import '../../home/provider/dashboard_provider.dart';
import '../../nav_bar/presentations/pages/nav_bar_page.dart';
import '../model/coupon_list_model.dart';
import '../presentations/raise_campaign_page.dart';
import '../presentations/unlocked_coupon_page.dart';
import '../service/shop_services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({Key? key}) : super(key: key);

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  CouponListModel? couponListModel;
  bool isLoading = true;
  late DateTime _startTime;
  bool budgetExceeded = false; // Add this at the top with other variables
  bool schoolCode = false;
  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getShopData();
    });
    MixpanelService.track('Shop Screen Viewed');
  }

  @override
  void dispose() {
    final duration = DateTime.now().difference(_startTime).inSeconds;
    MixpanelService.track('Shop Screen Time', properties: {
      'duration_seconds': duration,
    });
    super.dispose();
  }

  Future<void> getShopData() async {
    final response = await ShopServices().getCouponList();
    couponListModel = CouponListModel.fromJson(response.data);
    budgetExceeded = couponListModel?.budgetExceeded ?? false; // ← Save the flag
    schoolCode = couponListModel?.schoolCode ?? false;
    isLoading = false;
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: getShopData,
      child: Scaffold(
        appBar: commonAppBar(
          context: context,
          name: "Shop",
          onBack: () => push(context: context, page: const NavBarPage(currentIndex: 0)),
        ),
        body: WillPopScope(
          onWillPop: () async => false,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : couponListModel == null
              ? const Center(child: Text("No data available"))
              : _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: couponListModel!.data!.length,
    itemBuilder: (context, index) {
      final item = couponListModel!.data![index];
      final isRedeemed = item.redeemed ?? false;
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(2, 2),
            )
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: "https://lifeappmedia.blr1.digitaloceanspaces.com/${item.couponMediaId?.url ?? ""}",
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, _) => const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: ColorCode.buttonColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      item.title ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Material(
                      color: Colors.transparent,          // keep the white card visible
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),   // ripple clips to corners
                        onTap: () {
                          if (isRedeemed) {
                            Fluttertoast.showToast(
                              msg: "Already Unlocked",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              backgroundColor: Colors.black87,
                              textColor: Colors.white,
                            );
                          } else {
                            handleRedeem(item);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Image.asset("assets/images/coin.png", height: 20),
                              const SizedBox(width: 6),
                              Text(
                                "${item.coin ?? '0'} Coins",
                                style: const TextStyle(fontSize: 14),
                              ),
                              const Spacer(),
                              Text(
                                isRedeemed ? "Unlocked" : "Unlock",
                                style: TextStyle(
                                  color: isRedeemed ? Colors.grey.shade600 : Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
              ],
              ),
            )
          ],
        ),
      );
    },
  );

  Future<void> handleRedeem(Datum item) async {
    final dashboard = Provider.of<DashboardProvider>(context, listen: false);
    final userCoins = dashboard.dashboardModel?.data?.user?.earnCoins ?? 0;
    final requiredCoins = int.tryParse(item.coin ?? "0") ?? 0;

    if (schoolCode == false) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            elevation: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Update Required',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Oops! We need your school code to process this purchase. Please update it in your profile and try again.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              push(context: context, page: const ProfilePage());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Update Profile'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.deepPurple,
                              side: const BorderSide(color: Colors.deepPurple),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    if (couponListModel?.budgetExceeded == true) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            elevation: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_clock,
                    size: 48,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    textAlign: TextAlign.center,
                    'Purchase limit reached',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Hang tight — you can shop again once it resets!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Okay'),
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    if (requiredCoins > userCoins) {
      MixpanelService.track('Not Enough Coins Page Viewed');
      push(context: context, page: const RaisedCampaignPage());
      return;
    }

    debugPrint('🔄 Redeeming product ID: ${item.id}');
    Response response = await ShopServices().getRedeemCouponData(item.id.toString());
    debugPrint('✅ Redeem API Status: ${response.statusCode}');
    debugPrint('📦 Redeem API Response: ${response.data}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      await getShopData();
      MixpanelService.track('Product Redeemed Successfully');
      push(
        context: context,
        page: UnlockCouponPage(
          url: item.couponMediaId?.url ?? "",
          coin: item.coin ?? "0",
          title: item.title ?? "",
        ),
      );
    }
  }
}
