import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (size.width >= 1100 && desktop != null) {
      return desktop!;
    } else if (size.width >= 650 && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

class ResponsiveSize {
  static double width(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * (percentage / 100);
  }

  static double height(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * (percentage / 100);
  }

  static double fontSize(BuildContext context, double size) {
    final width = MediaQuery.of(context).size.width;
    double scaleFactor = width / 375.0;
    if (scaleFactor < 0.8) scaleFactor = 0.8;
    if (scaleFactor > 1.5) scaleFactor = 1.5;
    return size * scaleFactor;
  }

  static double padding(BuildContext context, double size) {
    if (Responsive.isMobile(context)) {
      return size;
    } else if (Responsive.isTablet(context)) {
      return size * 1.5;
    } else {
      return size * 2;
    }
  }

  static int gridColumns(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return 2;
    } else if (Responsive.isTablet(context)) {
      return 3;
    } else {
      return 4;
    }
  }
}
