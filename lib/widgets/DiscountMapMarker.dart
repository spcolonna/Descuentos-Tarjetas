import 'package:flutter/material.dart';
import '../enums/Bank.dart';
import '../models/discount.dart';

class DiscountMapMarker extends StatelessWidget {
  final Discount discount;
  const DiscountMapMarker({super.key, required this.discount});

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
    int maxDiscount = 0;
    if (discount.discounts.isNotEmpty) {
      maxDiscount = discount.discounts.map((tier) => tier.value).reduce((a, b) => a > b ? a : b);
    }

    return Container(
      decoration: BoxDecoration(
        color: _getColorForBank(discount.bank),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [ // Pequeña sombra para que el marcador resalte más
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Center(
        child: Text(
          maxDiscount > 0 ? "$maxDiscount%" : "?",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
        ),
      ),
    );
  }
}
