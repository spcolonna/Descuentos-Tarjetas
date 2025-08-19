// lib/models/discount.dart

import 'package:latlong2/latlong.dart';

// 1. RE-HABILITAMOS TODOS LOS BANCOS PARA EL FUTURO
enum Bank { itau, scotia, brou, bbva }
// NOTA: Los valores del Excel para categoría eran "Gastronomía".
// Para que coincida, lo ponemos con mayúscula aquí, o lo manejamos en el parser.
// Lo manejaremos en el parser para mayor robustez.
enum CategoryDiscount { gastronomia, indumentaria, supermercado, otro }

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
    // --- INICIO DE LAS CORRECCIONES ---

    final bankString = (json['bank'] as String? ?? 'itau').toLowerCase();
    final bank = Bank.values.firstWhere(
          (b) => b.name == bankString,
      orElse: () => Bank.itau, // Si no lo encuentra, usa 'itau' por defecto
    );

    // Hacemos lo mismo para la categoría
    final categoryString = (json['category'] as String? ?? 'otro').toLowerCase();
    final category = CategoryDiscount.values.firstWhere(
          (c) => c.name == categoryString,
      orElse: () => CategoryDiscount.otro, // Si no lo encuentra, usa 'otro' por defecto
    );

    final pointData = json['point'] as Map<String, dynamic>? ?? {'latitude': 0.0, 'longitude': 0.0};

    // --- FIN DE LAS CORRECCIONES ---

    return Discount(
      id: json['id'],
      storeName: json['storeName'],
      address: json['address'],
      point: LatLng(pointData['latitude'], pointData['longitude']), // Usamos los datos corregidos
      bank: bank,
      category: category,
      discountPercentage: json['discountPercentage'],
      description: json['description'],
    );
  }
}
