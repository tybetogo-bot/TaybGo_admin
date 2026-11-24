import 'package:flutter_test/flutter_test.dart';
import 'package:taybgoadmin/core/utils/uuid.dart';

void main() {
  test('generateUuidV4 returns UUID v4 values', () {
    final uuid = generateUuidV4();

    expect(
      uuid,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });
}
