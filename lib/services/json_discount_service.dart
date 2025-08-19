// lib/services/json_discount_service.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/discount.dart';

class JsonDiscountService {
  final List<String> _discountFiles = [
    'assets/discounts/itau.json',
    'assets/discounts/scotiabank.json',
    'assets/discounts/brou.json',
    'assets/discounts/bbva.json',
  ];

  Future<List<Discount>> loadAllDiscounts() async {
    final List<Discount> allDiscounts = [];

    for (String filePath in _discountFiles) {
      // Carga el contenido del archivo JSON como un String
      final jsonString = await rootBundle.loadString(filePath);
      // Decodifica el String a una lista de mapas
      final List<dynamic> jsonList = json.decode(jsonString);
      // Convierte cada mapa en un objeto Discount y lo añade a la lista
      allDiscounts.addAll(jsonList.map((jsonItem) => Discount.fromJson(jsonItem)));
    }

    return allDiscounts;
  }
}
