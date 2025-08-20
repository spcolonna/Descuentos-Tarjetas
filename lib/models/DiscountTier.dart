import '../enums/CardTier.dart';

class DiscountTier {
  final String cardType;
  final int value;
  final CardTier tier;
  final String description;

  DiscountTier({
    required this.cardType,
    required this.value,
    required this.tier,
    required this.description,
  });

  factory DiscountTier.fromJson(Map<String, dynamic> json) {
    final tierString = (json['tier'] as String? ?? 'basic').toLowerCase();
    final tier = CardTier.values.firstWhere(
          (t) => t.name == tierString,
      orElse: () => CardTier.basic,
    );

    return DiscountTier(
      cardType: json['cardType'] ?? 'Tarjeta',
      value: json['value'] ?? 0,
      tier: tier,
      description: json['description'] ?? 'Sin descripción.',
    );
  }
}
