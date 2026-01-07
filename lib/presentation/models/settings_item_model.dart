import 'package:flutter/material.dart';

enum SettingsItemType { toggle, navigation, action }

class SettingsItemModel {
  final String id;
  final IconData icon;
  final String title;
  final SettingsItemType type;
  final String? route;
  final Function()? onTap;
  final bool? value;
  final Function(bool)? onToggle;

  const SettingsItemModel({
    required this.id,
    required this.icon,
    required this.title,
    required this.type,
    this.route,
    this.onTap,
    this.value,
    this.onToggle,
  });
}

class SettingsSectionModel {
  final String title;
  final List<SettingsItemModel> items;

  const SettingsSectionModel({required this.title, required this.items});
}
