import 'package:flutter/material.dart';

const Map<String, IconData> categoryIconOptions = {
  'restaurant': Icons.restaurant_outlined,
  'directions_car': Icons.directions_car_outlined,
  'shopping_bag': Icons.shopping_bag_outlined,
  'local_hospital': Icons.local_hospital_outlined,
  'movie': Icons.movie_outlined,
  'receipt_long': Icons.receipt_long_outlined,
  'payments': Icons.payments_outlined,
  'card_giftcard': Icons.card_giftcard_outlined,
  'school': Icons.school_outlined,
  'flight': Icons.flight_outlined,
  'home': Icons.home_outlined,
  'phone_android': Icons.phone_android_outlined,
  'fitness_center': Icons.fitness_center_outlined,
  'more_horiz': Icons.more_horiz_outlined,
};

const List<String> categoryColorOptions = [
  '#EF6C00', '#1E88E5', '#7B61FF', '#2E7D5B',
  '#C62828', '#757575', '#00897B', '#D81B60',
];

IconData iconFromKey(String key) =>
    categoryIconOptions[key] ?? Icons.receipt_long_outlined;

Color colorFromHex(String hex) =>
    Color(int.parse(hex.replaceFirst('#', '0xFF')));