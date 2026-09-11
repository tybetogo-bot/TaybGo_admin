import 'package:flutter_test/flutter_test.dart';
import 'package:taybgoadmin/core/models/admin_order.dart';
import 'package:taybgoadmin/features/support/create_support_ticket_dialog.dart';

void main() {
  test('driver and restaurant presets use profile/user IDs correctly', () {
    final driver = SupportTicketComposerPreset.driver(
      driverId: 17,
      driverName: 'Driver One',
    );
    final restaurant = SupportTicketComposerPreset.restaurant(
      restaurantId: 31,
      recipientUserId: 44,
      restaurantName: 'Restaurant One',
    );

    expect(driver.recipients.single.userId, 17);
    expect(driver.recipients.single.target, {'type': 'DRIVER', 'id': 17});
    expect(restaurant.recipients.single.userId, 44);
    expect(restaurant.recipients.single.target, {
      'type': 'RESTAURANT',
      'id': 31,
    });
  });

  test(
    'order preset maps customer, driver, and deferred restaurant targets',
    () {
      final order = AdminOrder.fromJson({
        'id': 42,
        'order_type': 'FOOD',
        'payment_type': 'CASH',
        'status': 'PENDING',
        'customer': {'id': 11, 'name': 'Customer One', 'phone': '+1'},
        'driver': {'id': 17, 'name': 'Driver One', 'phone': '+2'},
        'restaurant': {'id': 31, 'name': 'Restaurant One', 'phone': '+3'},
        'is_manual': false,
        'is_paid': false,
        'items': [],
      });

      final preset = SupportTicketComposerPreset.order(order);

      expect(preset.orderId, 42);
      expect(preset.orderRestaurantId, 31);
      expect(preset.recipients, hasLength(2));
      expect(preset.recipients[0].userId, 11);
      expect(preset.recipients[0].target, {'type': 'ORDER', 'id': 42});
      expect(preset.recipients[0].relatedOrderId, isNull);
      expect(preset.recipients[1].userId, 17);
      expect(preset.recipients[1].target, {'type': 'DRIVER', 'id': 17});
      expect(preset.recipients[1].relatedOrderId, 42);
    },
  );

  test('general preset has no implicit GENERAL target', () {
    final preset = SupportTicketComposerPreset.general();

    expect(preset.context, SupportTicketComposerContext.general);
    expect(preset.recipients, isEmpty);
  });
}
