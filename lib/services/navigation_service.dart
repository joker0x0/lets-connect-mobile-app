import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState get navigator => navigatorKey.currentState!;

  static Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigator.pushNamed(routeName, arguments: arguments);
  }

  static Future<dynamic> replaceTo(String routeName, {Object? arguments}) {
    return navigator.pushReplacementNamed(routeName, arguments: arguments);
  }

  static Future<dynamic> navigateToAndClearStack(String routeName, {Object? arguments}) {
    return navigator.pushNamedAndRemoveUntil(
      routeName, 
      (Route<dynamic> route) => false,
      arguments: arguments,
    );
  }

  static void goBack({dynamic result}) {
    return navigator.pop(result);
  }
}