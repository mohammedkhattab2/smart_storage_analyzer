import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double sizeInBytes;
  final int fileCount;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.sizeInBytes,
    required this.fileCount,
  });

  @override
  List<Object?> get props => [id, name, icon, color, sizeInBytes, fileCount];
}
