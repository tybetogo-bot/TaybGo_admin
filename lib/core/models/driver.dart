enum DriverStatus { online, offline, busy }
enum ApprovalStatus { pending, approved, rejected }

class Driver {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String vehicleType;
  final String vehiclePlate;
  final String? profileImageUrl;
  final DriverStatus status;
  final ApprovalStatus approvalStatus;
  final int totalOrders;
  final int completedOrders;
  final int rejectedOrders;
  final double rating;
  final double earnings;
  final DateTime registeredAt;

  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.vehicleType,
    required this.vehiclePlate,
    this.profileImageUrl,
    required this.status,
    required this.approvalStatus,
    required this.totalOrders,
    required this.completedOrders,
    required this.rejectedOrders,
    required this.rating,
    required this.earnings,
    required this.registeredAt,
  });

  double get acceptanceRate =>
      totalOrders > 0 ? completedOrders / totalOrders * 100 : 0;

  double get rejectionRate =>
      totalOrders > 0 ? rejectedOrders / totalOrders * 100 : 0;
}
