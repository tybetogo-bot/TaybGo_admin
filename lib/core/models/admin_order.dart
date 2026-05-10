class AdminOrder {
  final int id;
  final String orderType;
  final String paymentType;
  final OrderPerson? customer;
  final String? deliveryInstructions;
  final String status;
  final OrderRestaurantSummary? restaurant;
  final OrderCouponSummary? coupon;
  final String? subtotalAmount;
  final String? discountAmount;
  final String? deliveryFee;
  final String? tip;
  final String? totalAmount;
  final OrderAddress? pickupAddress;
  final OrderAddress? dropoffAddress;
  final String? requestedVehicleType;
  final String? requestedDeliveryType;
  final String? requestedCarSize;
  final ShippingPackageSummary? shippingPackage;
  final OrderPerson? driver;
  final bool isManual;
  final bool isPaid;
  final DateTime? dispatchStartedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<OrderItemSummary> items;

  const AdminOrder({
    required this.id,
    required this.orderType,
    required this.paymentType,
    this.customer,
    this.deliveryInstructions,
    required this.status,
    this.restaurant,
    this.coupon,
    this.subtotalAmount,
    this.discountAmount,
    this.deliveryFee,
    this.tip,
    this.totalAmount,
    this.pickupAddress,
    this.dropoffAddress,
    this.requestedVehicleType,
    this.requestedDeliveryType,
    this.requestedCarSize,
    this.shippingPackage,
    this.driver,
    required this.isManual,
    required this.isPaid,
    this.dispatchStartedAt,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    return AdminOrder(
      id: _intValue(json['id']),
      orderType: _stringValue(json['order_type']).toUpperCase(),
      paymentType: _stringValue(json['payment_type']).toUpperCase(),
      customer: OrderPerson.fromDynamic(json['customer']),
      deliveryInstructions: _nullIfEmpty(json['delivery_instructions']),
      status: _stringValue(json['status']).toUpperCase(),
      restaurant: OrderRestaurantSummary.fromDynamic(json['restaurant']),
      coupon: OrderCouponSummary.fromDynamic(json['coupon']),
      subtotalAmount: _moneyString(json['subtotal_amount']),
      discountAmount: _moneyString(json['discount_amount']),
      deliveryFee: _moneyString(json['delivery_fee']),
      tip: _moneyString(json['tip']),
      totalAmount: _moneyString(json['total_amount']),
      pickupAddress: OrderAddress.fromDynamic(json['pickup_address']),
      dropoffAddress: OrderAddress.fromDynamic(json['dropoff_address']),
      requestedVehicleType: _nullIfEmpty(json['requested_vehicle_type']),
      requestedDeliveryType: _nullIfEmpty(json['requested_delivery_type']),
      requestedCarSize: _nullIfEmpty(json['requested_car_size']),
      shippingPackage: ShippingPackageSummary.fromDynamic(
        json['shipping_package'],
      ),
      driver: OrderPerson.fromDynamic(json['driver']),
      isManual: _boolValue(json['is_manual']) ?? false,
      isPaid: _boolValue(json['is_paid']) ?? false,
      dispatchStartedAt: _dateValue(json['dispatch_started_at']),
      createdAt: _dateValue(json['created_at']),
      updatedAt: _dateValue(json['updated_at']),
      items:
          (json['items'] as List<dynamic>?)
              ?.whereType<Map>()
              .map(
                (item) =>
                    OrderItemSummary.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList() ??
          const [],
    );
  }

  bool get isFood => orderType == 'FOOD';
  bool get isShipping => orderType == 'SHIPPING';
  bool get isTaxi => orderType == 'TAXI';

  double get totalValue => _decimalValue(totalAmount) ?? 0;
}

class OrderPerson {
  final int id;
  final String? email;
  final String name;
  final String phone;
  final bool? isVerified;

  const OrderPerson({
    required this.id,
    this.email,
    required this.name,
    required this.phone,
    this.isVerified,
  });

  static OrderPerson? fromDynamic(dynamic value) {
    final json = _mapValue(value);
    if (json == null) return null;
    return OrderPerson.fromJson(json);
  }

  factory OrderPerson.fromJson(Map<String, dynamic> json) {
    return OrderPerson(
      id: _intValue(json['id']),
      email: _nullIfEmpty(json['email']),
      name: _stringValue(
        json['name'] ?? json['full_name'] ?? json['driver_name'],
      ),
      phone: _stringValue(json['phone'] ?? json['phone_number']),
      isVerified: _boolValue(json['is_verified']),
    );
  }

  String get displayName => name.trim().isEmpty ? '#$id' : name.trim();
}

class OrderRestaurantSummary {
  final int id;
  final String name;
  final String? logo;
  final OrderAddress? address;
  final String phone;
  final String status;
  final DateTime? createdAt;

  const OrderRestaurantSummary({
    required this.id,
    required this.name,
    this.logo,
    this.address,
    required this.phone,
    required this.status,
    this.createdAt,
  });

  static OrderRestaurantSummary? fromDynamic(dynamic value) {
    final json = _mapValue(value);
    if (json == null) return null;
    return OrderRestaurantSummary.fromJson(json);
  }

  factory OrderRestaurantSummary.fromJson(Map<String, dynamic> json) {
    return OrderRestaurantSummary(
      id: _intValue(json['id']),
      name: _stringValue(json['name']),
      logo: _nullIfEmpty(json['logo']),
      address: OrderAddress.fromDynamic(json['address']),
      phone: _stringValue(json['phone']),
      status: _stringValue(json['status']).toUpperCase(),
      createdAt: _dateValue(json['created_at']),
    );
  }
}

class OrderCouponSummary {
  final int id;
  final String title;
  final String code;
  final int percentage;

  const OrderCouponSummary({
    required this.id,
    required this.title,
    required this.code,
    required this.percentage,
  });

  static OrderCouponSummary? fromDynamic(dynamic value) {
    final json = _mapValue(value);
    if (json == null) return null;
    return OrderCouponSummary.fromJson(json);
  }

  factory OrderCouponSummary.fromJson(Map<String, dynamic> json) {
    return OrderCouponSummary(
      id: _intValue(json['id']),
      title: _stringValue(json['title']),
      code: _stringValue(json['code']),
      percentage: _intValue(json['percentage']),
    );
  }

  String get displayName {
    final label = code.isNotEmpty ? code : title;
    if (label.isEmpty) return '#$id';
    return percentage > 0 ? '$label ($percentage%)' : label;
  }
}

class OrderAddress {
  final int id;
  final String label;
  final bool isDefault;
  final String? lat;
  final String? lng;
  final String fullAddress;
  final String? streetName;
  final String? houseNumber;
  final String? city;
  final String? postalCode;
  final String? country;
  final DateTime? createdAt;

  const OrderAddress({
    required this.id,
    required this.label,
    required this.isDefault,
    this.lat,
    this.lng,
    required this.fullAddress,
    this.streetName,
    this.houseNumber,
    this.city,
    this.postalCode,
    this.country,
    this.createdAt,
  });

  static OrderAddress? fromDynamic(dynamic value) {
    final json = _mapValue(value);
    if (json == null) return null;
    return OrderAddress.fromJson(json);
  }

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      id: _intValue(json['id']),
      label: _stringValue(json['label']),
      isDefault: _boolValue(json['is_default']) ?? false,
      lat: _nullIfEmpty(json['lat']),
      lng: _nullIfEmpty(json['lng']),
      fullAddress: _stringValue(json['full_address']),
      streetName: _nullIfEmpty(json['street_name']),
      houseNumber: _nullIfEmpty(json['house_number']),
      city: _nullIfEmpty(json['city']),
      postalCode: _nullIfEmpty(json['postal_code']),
      country: _nullIfEmpty(json['country']),
      createdAt: _dateValue(json['created_at']),
    );
  }

  String get displayLine {
    if (fullAddress.trim().isNotEmpty) return fullAddress.trim();

    final street = [
      streetName,
      houseNumber,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
    final parts = [
      street,
      city,
      postalCode,
      country,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).toList();
    return parts.join(', ');
  }
}

class ShippingPackageSummary {
  final String size;
  final String weightKg;
  final String content;

  const ShippingPackageSummary({
    required this.size,
    required this.weightKg,
    required this.content,
  });

  static ShippingPackageSummary? fromDynamic(dynamic value) {
    final json = _mapValue(value);
    if (json == null) return null;
    return ShippingPackageSummary.fromJson(json);
  }

  factory ShippingPackageSummary.fromJson(Map<String, dynamic> json) {
    return ShippingPackageSummary(
      size: _stringValue(json['size']),
      weightKg: _stringValue(json['weight_kg']),
      content: _stringValue(json['content']),
    );
  }
}

class OrderItemSummary {
  final int id;
  final int item;
  final String itemName;
  final String? itemPrice;
  final int quantity;
  final dynamic customizations;
  final String? pricingSource;
  final double? unitPriceSnapshot;
  final double? originalUnitPriceSnapshot;
  final double? lineTotal;

  const OrderItemSummary({
    required this.id,
    required this.item,
    required this.itemName,
    this.itemPrice,
    required this.quantity,
    this.customizations,
    this.pricingSource,
    this.unitPriceSnapshot,
    this.originalUnitPriceSnapshot,
    this.lineTotal,
  });

  factory OrderItemSummary.fromJson(Map<String, dynamic> json) {
    return OrderItemSummary(
      id: _intValue(json['id']),
      item: _intValue(json['item']),
      itemName: _stringValue(json['item_name']),
      itemPrice: _moneyString(json['item_price']),
      quantity: _intValue(json['quantity']),
      customizations: json['customizations'],
      pricingSource: _nullIfEmpty(json['pricing_source']),
      unitPriceSnapshot: _decimalValue(json['unit_price_snapshot']),
      originalUnitPriceSnapshot: _decimalValue(
        json['original_unit_price_snapshot'],
      ),
      lineTotal: _decimalValue(json['line_total']),
    );
  }
}

class OrderStatusHistory {
  final String status;
  final DateTime? timestamp;

  const OrderStatusHistory({required this.status, this.timestamp});

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      status: _stringValue(json['status']).toUpperCase(),
      timestamp: _dateValue(json['timestamp']),
    );
  }
}

Map<String, dynamic>? _mapValue(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _stringValue(dynamic value) => value?.toString().trim() ?? '';

String? _nullIfEmpty(dynamic value) {
  final text = _stringValue(value);
  return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
}

String? _moneyString(dynamic value) {
  final text = _nullIfEmpty(value);
  if (text == null) return null;
  final parsed = _decimalValue(text);
  if (parsed == null) return text;
  return parsed.toStringAsFixed(2);
}

int _intValue(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool? _boolValue(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().trim().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return null;
}

DateTime? _dateValue(dynamic value) {
  final text = _nullIfEmpty(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}

double? _decimalValue(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
