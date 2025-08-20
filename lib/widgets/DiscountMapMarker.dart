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
    int getDiscountToShow() {
      if (discount.discounts.isEmpty) {
        return 0;
      }

      if (selectedCardTier != null) {
        final specificTier = discount.discounts.firstWhereOrNull((tier) => tier.tier == selectedCardTier);
        return specificTier?.value ?? 0;
      } else {
        final maxVal = discount.discounts.map((tier) => tier.value).reduce((a, b) => a > b ? a : b);
        return maxVal;
      }
    }

    final int discountValue = getDiscountToShow();

    return Container(
      decoration: BoxDecoration(
        color: _getColorForBank(discount.bank),
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
