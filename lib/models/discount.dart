import 'package:latlong2/latlong.dart';

import '../enums/Bank.dart';
import '../enums/CategoryDiscount.dart';
import 'DiscountTier.dart';

class Discount {
  final String id;
  final String storeName;
  final String address;
  final LatLng point;
  final Bank bank;
  final CategoryDiscount category;
  final List<DiscountTier> discounts;

  Discount({
    required this.id,
    required this.storeName,
    required this.address,
    required this.point,
    required this.bank,
    required this.category,
    required this.discounts,
  });

  factory Discount.fromJson(Map<String, dynamic> json) {
    final bankString = (json['bank'] as String? ?? '').toLowerCase();
    final bank = Bank.values.firstWhere((b) => b.name == bankString, orElse: () => Bank.itau);

    final categoryString = (json['category'] as String? ?? '').toLowerCase();
    CategoryDiscount category;
    if (categoryString == 'gastronomía' || categoryString == 'gastronomia') {
      category = CategoryDiscount.gastronomia;
    } else if (categoryString == 'librerías' || categoryString == 'librerias' || categoryString == 'libreria') {
      category = CategoryDiscount.librerias;
    } else {
      category = CategoryDiscount.otro;
    }

    final pointData = json['point'] as Map<String, dynamic>? ?? {'latitude': 0.0, 'longitude': 0.0};

    // MODIFICADO: Leemos la lista "discounts" del JSON
    var discountList = <DiscountTier>[];
    if (json['discounts'] != null && json['discounts'] is List) {
      // Si existe la lista, la mapeamos creando un objeto DiscountTier por cada item
      discountList = (json['discounts'] as List)
          .map((tierJson) => DiscountTier.fromJson(tierJson))
          .toList();
    }

    return Discount(
      id: json['id'],
      storeName: json['storeName'],
      address: json['address'],
      point: LatLng(pointData['latitude'], pointData['longitude']),
      bank: bank,
      category: category,
      discounts: discountList, // Asignamos la lista de descuentos
    );
  }
}
