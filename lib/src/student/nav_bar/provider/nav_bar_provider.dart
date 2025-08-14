import 'package:flutter/material.dart';

class NavBarProvider extends ChangeNotifier {
  int _unreadNotificationCount = 0;

  int get unreadNotificationCount => _unreadNotificationCount;

  void setUnreadNotificationCount(int count) {
    if (_unreadNotificationCount != count) {
      _unreadNotificationCount = count;
      notifyListeners();
    }
  }
}
