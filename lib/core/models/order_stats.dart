class DashboardStats {
  final int totalOrders;
  final int activeOrders;
  final int completedToday;
  final int cancelledToday;
  final double revenueToday;
  final double revenueThisWeek;
  final double revenueThisMonth;
  final int totalDrivers;
  final int onlineDrivers;
  final int offlineDrivers;
  final int totalRestaurants;
  final int pendingApprovals;
  final int openTickets;
  final List<DailyRevenue> weeklyRevenue;
  final List<OrdersByType> ordersByType;

  const DashboardStats({
    required this.totalOrders,
    required this.activeOrders,
    required this.completedToday,
    required this.cancelledToday,
    required this.revenueToday,
    required this.revenueThisWeek,
    required this.revenueThisMonth,
    required this.totalDrivers,
    required this.onlineDrivers,
    required this.offlineDrivers,
    required this.totalRestaurants,
    required this.pendingApprovals,
    required this.openTickets,
    required this.weeklyRevenue,
    required this.ordersByType,
  });
}

class DailyRevenue {
  final String day;
  final double amount;

  const DailyRevenue({required this.day, required this.amount});
}

class OrdersByType {
  final String type;
  final int count;

  const OrdersByType({required this.type, required this.count});
}
