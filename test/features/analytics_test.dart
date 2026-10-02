import 'package:flutter_test/flutter_test.dart';
import 'package:habito/core/models/domain_models.dart';
// Note: More extensive integration tests for analytics periods can be written here.

void main() {
  group('Analytics Data Model Tests', () {
    test('AnalyticsPeriod enums defined correctly', () {
      expect(AnalyticsPeriod.last7Days.name, 'last7Days');
      expect(AnalyticsPeriod.last30Days.name, 'last30Days');
      expect(AnalyticsPeriod.last90Days.name, 'last90Days');
    });
  });
}
