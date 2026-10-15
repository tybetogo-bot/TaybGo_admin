class PromoBanner {
  final int id;
  final int restaurantId;
  final String restaurantName;
  final String title;
  final String description;
  final String imageUrl;
  final String status;
  final bool isActive;
  final int priority;
  final int activeRestaurantPromos;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final DateTime? approvedAt;

  const PromoBanner({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.status,
    required this.isActive,
    required this.priority,
    required this.activeRestaurantPromos,
    this.rejectionReason,
    this.createdAt,
    this.reviewedAt,
    this.approvedAt,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) => PromoBanner(
    id: json['id'] as int,
    restaurantId: json['restaurant'] as int,
    restaurantName: json['restaurant_name'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    imageUrl: json['image_url'] as String? ?? '',
    status: json['status'] as String? ?? 'PENDING',
    isActive: json['is_active'] == true,
    priority: json['priority'] as int? ?? 0,
    activeRestaurantPromos: json['restaurant_active_promos_count'] as int? ?? 0,
    rejectionReason: json['rejection_reason'] as String?,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    reviewedAt: DateTime.tryParse(json['reviewed_at'] as String? ?? ''),
    approvedAt: DateTime.tryParse(json['approved_at'] as String? ?? ''),
  );
}
