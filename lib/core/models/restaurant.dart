enum RestaurantApprovalStatus { pending, approved, rejected }

class Restaurant {
  final String id;
  final String name;
  final String ownerName;
  final String phone;
  final String email;
  final String address;
  final String cuisineType;
  final String? logoUrl;
  final RestaurantApprovalStatus approvalStatus;
  final DateTime submittedAt;
  final String? description;

  const Restaurant({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.cuisineType,
    this.logoUrl,
    required this.approvalStatus,
    required this.submittedAt,
    this.description,
  });
}
