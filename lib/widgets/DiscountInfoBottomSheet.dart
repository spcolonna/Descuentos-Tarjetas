import 'package:flutter/material.dart';
import '../models/discount.dart';

class DiscountInfoBottomSheet extends StatelessWidget {
  final Discount discount;
  const DiscountInfoBottomSheet({super.key, required this.discount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(discount.storeName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(discount.address, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Chip(
            label: Text("${discount.discountPercentage}% OFF con ${discount.bank.name.toUpperCase()}"),
            backgroundColor: Colors.teal.shade100,
          ),
          const SizedBox(height: 8),
          Text(discount.description),
        ],
      ),
    );
  }
}
