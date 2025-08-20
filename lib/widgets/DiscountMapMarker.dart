import 'package:flutter/material.dart';
import '../enums/Bank.dart';
import '../enums/CardTier.dart';
import '../models/discount.dart';
import 'package:collection/collection.dart';

class DiscountMapMarker extends StatelessWidget {
  final Discount discount;
  final CardTier? selectedCardTier;

  const DiscountMapMarker({
    super.key,
    required this.discount,
    this.selectedCardTier,
  });

  Color _getColorForBank(Bank bank) {
    switch (bank) {
      case Bank.itau: return Colors.orange;
      case Bank.scotia: return Colors.red;
      case Bank.brou: return Colors.green;
      case Bank.bbva: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    print("--- 🕵️‍♂️ DEBUG MARCADOR: ${discount.storeName} ---");
    print("Filtro de Tarjeta Recibido: $selectedCardTier");
    // --- FIN DE LOS LOGS ---

    int getDiscountToShow() {
      if (discount.discounts.isEmpty) {
        print("    -> No hay descuentos en la lista.");
        return 0;
      }

      // Log para ver qué descuentos tiene este comercio
      print("    -> Descuentos disponibles: ${discount.discounts.map((t) => '${t.tier.name}:${t.value}%').toList()}");

      if (selectedCardTier != null) {
        print("    -> MODO: Filtro específico. Buscando tier: '${selectedCardTier!.name}'");

        // Usamos 'where' y 'firstOrNull' para encontrar el tier de forma segura
        final specificTier = discount.discounts.firstWhereOrNull((tier) => tier.tier == selectedCardTier);

        if (specificTier != null) {
          print("    -> ÉXITO: Se encontró el tier. Valor: ${specificTier.value}");
        } else {
          print("    -> FALLO: No se encontró un descuento para el tier '${selectedCardTier!.name}'.");
        }
        return specificTier?.value ?? 0;

      } else {
        print("    -> MODO: 'Todas'. Calculando el descuento máximo.");
        final maxVal = discount.discounts.map((tier) => tier.value).reduce((a, b) => a > b ? a : b);
        print("    -> Máximo descuento encontrado: $maxVal");
        return maxVal;
      }
    }

    final int discountValue = getDiscountToShow();
    print("Valor final a mostrar en el marcador: $discountValue");
    print("------------------------------------------\n"); // Separador

    return Container(
      decoration: BoxDecoration(
        color: _getColorForBank(discount.bank),
        // ... (resto del widget sin cambios)
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Center(
        child: Text(
          discountValue > 0 ? "$discountValue%" : "?",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
        ),
      ),
    );
  }
}
