class ServiceAvailability {
  const ServiceAvailability({
    this.food = true,
    this.taxi = true,
    this.shipping = true,
  });

  final bool food;
  final bool taxi;
  final bool shipping;

  factory ServiceAvailability.fromJson(Map<String, dynamic> json) {
    return ServiceAvailability(
      food: json['food'] as bool? ?? true,
      taxi: json['taxi'] as bool? ?? true,
      shipping: json['shipping'] as bool? ?? true,
    );
  }

  ServiceAvailability withValue(String service, bool value) {
    return ServiceAvailability(
      food: service == 'food' ? value : food,
      taxi: service == 'taxi' ? value : taxi,
      shipping: service == 'shipping' ? value : shipping,
    );
  }
}
