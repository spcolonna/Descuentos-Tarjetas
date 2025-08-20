class DiscountTier {
  final String cardType;
  final int value;
  final String description;

  DiscountTier({
    required this.cardType,
    required this.value,
    required this.description,
  });

  factory DiscountTier.fromJson(Map<String, dynamic> json) {
    return DiscountTier(
      cardType: json['cardType'] ?? 'Tarjeta',
      value: json['value'] ?? 0,
      description: json['description'] ?? 'Sin descripción.',
    );
  }
}
