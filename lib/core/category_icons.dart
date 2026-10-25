import 'package:flutter/material.dart';

/// Category icon keys (stored in the database) → Material icons. Constant
/// IconData keeps icon tree-shaking working in release builds.
const categoryIcons = <String, IconData>{
  'shopping_cart': Icons.shopping_cart,
  'local_gas_station': Icons.local_gas_station,
  'content_cut': Icons.content_cut,
  'face_retouching_natural': Icons.face_retouching_natural,
  'spa': Icons.spa,
  'hardware': Icons.hardware,
  'bolt': Icons.bolt,
  'water_drop': Icons.water_drop,
  'phone_android': Icons.phone_android,
  'liquor': Icons.liquor,
  'medical_services': Icons.medical_services,
  'restaurant': Icons.restaurant,
  'category': Icons.category,
  'pets': Icons.pets,
  'school': Icons.school,
  'home': Icons.home,
  'directions_car': Icons.directions_car,
  'movie': Icons.movie,
  'flight': Icons.flight,
  'checkroom': Icons.checkroom,
};

IconData categoryIcon(String key) => categoryIcons[key] ?? Icons.category;

/// Colors offered for custom categories (ARGB). Charts lift them to a
/// readable contrast per theme (`readableOn`).
const categoryColors = [
  0xFF2E7D32, // green
  0xFF00897B, // teal
  0xFF0277BD, // blue
  0xFF3949AB, // indigo
  0xFF6A1B9A, // purple
  0xFFAD1457, // pink
  0xFFC62828, // red
  0xFFEF6C00, // orange
  0xFFF9A825, // amber
  0xFF5D4037, // brown
  0xFF546E7A, // blue grey
  0xFF757575, // grey
];
