import 'package:flutter_test/flutter_test.dart';
import 'package:habito/core/models/domain_models.dart';

void main() {
  group('Screen Time Domain Logic Tests', () {
    test('Duration conversion logic', () {
      const duration = Duration(milliseconds: 3661000); // 1h 1m 1s
      expect(duration.inHours, 1);
      expect(duration.inMinutes.remainder(60), 1);
      expect(duration.inSeconds.remainder(60), 1);
    });

    test('Daily date boundaries (Start of Day)', () {
      final now = DateTime(2026, 10, 2, 15, 45, 10);
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      expect(startOfDay.year, 2026);
      expect(startOfDay.month, 10);
      expect(startOfDay.day, 2);
      expect(startOfDay.hour, 0);
      expect(startOfDay.minute, 0);
    });

    test('Sorting AppUsage by duration', () {
      final apps = [
        AppUsage(packageName: 'com.a', appName: 'A', duration: const Duration(minutes: 10)),
        AppUsage(packageName: 'com.b', appName: 'B', duration: const Duration(minutes: 60)),
        AppUsage(packageName: 'com.c', appName: 'C', duration: const Duration(minutes: 5)),
      ];

      apps.sort((a, b) => b.duration.compareTo(a.duration));

      expect(apps[0].appName, 'B');
      expect(apps[1].appName, 'A');
      expect(apps[2].appName, 'C');
    });

    test('Percentage calculation logic', () {
      const totalDuration = Duration(minutes: 100);
      const appDuration = Duration(minutes: 25);
      
      final percentage = totalDuration.inSeconds > 0 
          ? appDuration.inSeconds / totalDuration.inSeconds 
          : 0.0;
          
      expect(percentage, 0.25);
    });
    
    test('Percentage calculation logic (Zero total)', () {
      const totalDuration = Duration(minutes: 0);
      const appDuration = Duration(minutes: 0);
      
      final percentage = totalDuration.inSeconds > 0 
          ? appDuration.inSeconds / totalDuration.inSeconds 
          : 0.0;
          
      expect(percentage, 0.0);
    });
  });
}
