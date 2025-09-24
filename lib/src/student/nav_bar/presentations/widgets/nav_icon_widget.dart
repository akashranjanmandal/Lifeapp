import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/color_code.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:provider/provider.dart';

import '../../../home/provider/dashboard_provider.dart';

PersistentBottomNavBarItem navImageIcon(String img, int index, String name,
    {BuildContext? context}) {
  // Safely parse unread notification count as int, fallback to 0
  int unreadCount = 0;
  if (context != null) {
    final countStr = Provider.of<DashboardProvider>(context, listen: true)
            .dashboardModel
            ?.data
            ?.user
            ?.unreadNotificationCount ??
        "0";

    unreadCount = int.tryParse(countStr) ?? 0;
  }

  return PersistentBottomNavBarItem(
    icon: index == 4
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              ImageIcon(
                AssetImage(img),
                size: 30,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -6,
                  top: -3,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          )
        : ImageIcon(
            AssetImage(img),
            size: 30,
          ),
    title: name,
    activeColorPrimary: ColorCode.buttonColor,
    inactiveColorPrimary: const Color(0xffa7a7a7),
    iconSize: 30,
    textStyle: const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 13,
    ),
  );
}
