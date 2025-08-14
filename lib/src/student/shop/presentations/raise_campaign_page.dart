import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../common/helper/color_code.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';
import '../../subject_list/presentation/page/subject_list_page.dart';
import '../presentations/shop_page.dart'; // Import your Shop Page

class RaisedCampaignPage extends StatefulWidget {
  const RaisedCampaignPage({Key? key}) : super(key: key);

  @override
  State<RaisedCampaignPage> createState() => _RaisedCampaignPageState();
}

class _RaisedCampaignPageState extends State<RaisedCampaignPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _body(),
    );
  }

  Widget _body() => Stack(
    children: [
      Lottie.asset(
        "assets/lottie/comic_new.json",
        repeat: true,
        height: double.infinity,
        fit: BoxFit.fill,
      ),
      Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        right: 16,
        child: GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ShopPage()),
            );
          },
          child: const Icon(
            Icons.close,
            size: 30,
            color: Colors.black87,
          ),
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .1),
          const Text(
            "Oops! \nYou have less \ncoins",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ColorCode.buttonColor,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * .3,
            child: Image.asset("assets/images/piggy.png"),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 70),
            child: Text(
              "You don’t have enough Life Coins to purchase this coupon. But don’t worry, keep solving the challenges and earn more coins.",
              style: TextStyle(
                color: Colors.black.withOpacity(.8),
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          InkWell(
            onTap: () {
              MixpanelService.track('Got It Button Clicked on Not Enough Coins Page');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubjectListPage(navName: ""),
                ),
              );
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Container(
              height: MediaQuery.of(context).size.height * .05,
              width: MediaQuery.of(context).size.width * .8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: ColorCode.buttonColor,
              ),
              child: const Center(
                child: Text(
                  "Earn More Coins",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
