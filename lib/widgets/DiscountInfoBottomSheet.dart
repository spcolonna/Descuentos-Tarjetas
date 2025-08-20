import 'package:flutter/material.dart';
import '../models/discount.dart';

class DiscountInfoBottomSheet extends StatelessWidget {
  final Discount discount;
  const DiscountInfoBottomSheet({super.key, required this.discount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Encabezado ---
          Text(
            discount.storeName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: Colors.grey[600], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  discount.address,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          // --- Título de la sección de descuentos ---
          Text(
            "Descuentos Disponibles",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // --- Lista dinámica de Descuentos ---
          // Aquí recorremos la lista de descuentos y creamos un widget para cada uno
          ...discount.discounts.map((tier) {
            return Card(
              elevation: 0,
              color: Colors.teal.withOpacity(0.05), // Un color de fondo sutil
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.teal),
                title: Text(tier.cardType, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(tier.description),
                trailing: Chip(
                  label: Text("${tier.value}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  backgroundColor: Colors.teal,
                  side: BorderSide.none,
                ),
              ),
            );
          }).toList(),

          // Mensaje por si un comercio no tiene descuentos detallados
          if (discount.discounts.isEmpty)
            const Text("No hay descuentos detallados para este comercio."),
        ],
      ),
    );
  }
}
