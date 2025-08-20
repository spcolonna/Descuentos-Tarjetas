import 'package:latlong2/latlong.dart';

import '../enums/Bank.dart';
import '../enums/CategoryDiscount.dart';

class Discount {
  final String id;
  final String storeName;
  final String address;
  final LatLng point;
  final Bank bank;
  final CategoryDiscount category;
  final int discountPercentage;
  final String description;

  Discount({
    required this.id,
    required this.storeName,
    required this.address,
    required this.point,
    required this.bank,
    required this.category,
    required this.discountPercentage,
    required this.description,
  });

  // El constructor 'fromJson' es el que "traduce" el JSON a un objeto Discount.
  factory Discount.fromJson(Map<String, dynamic> json) {

    final bankString = (json['bank'] as String? ?? 'itau').toLowerCase();
    final bank = Bank.values.firstWhere(
          (b) => b.name == bankString,
      orElse: () => Bank.itau,
    );

    // Hacemos lo mismo para la categoría
    final categoryString = (json['category'] as String? ?? 'otro').toLowerCase();
    final category = CategoryDiscount.values.firstWhere(
          (c) => c.name == categoryString,
      orElse: () => CategoryDiscount.otro,
    );

    final pointData = json['point'] as Map<String, dynamic>? ?? {'latitude': 0.0, 'longitude': 0.0};

    return Discount(
      id: json['id'],
      storeName: json['storeName'],
      address: json['address'],
      point: LatLng(pointData['latitude'], pointData['longitude']),
      bank: bank,
      category: category,
      discountPercentage: json['discountPercentage'],
      description: json['description'],
    );
  }
}
