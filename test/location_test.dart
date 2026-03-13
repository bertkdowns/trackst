import 'package:flutter_test/flutter_test.dart';
import 'package:trackst/location.dart';

void main() {
  group('calculateDistance', () {
    test('returns 0 for identical coordinates', () {
      final d = calculateDistance(
          targetLatitude, targetLongitude, targetLatitude, targetLongitude);
      expect(d, closeTo(0.0, 0.001));
    });

    test('returns approximate distance for a known offset (~111 m north)', () {
      // 0.001 degrees of latitude ≈ 111 m
      final d = calculateDistance(
          targetLatitude, targetLongitude, targetLatitude + 0.001, targetLongitude);
      expect(d, closeTo(111.0, 5.0));
    });
  });

  group('getProximityIntensity', () {
    test('returns 0 when distance is greater than 200 m', () {
      expect(getProximityIntensity(300), 0);
      expect(getProximityIntensity(201), 0);
    });

    test('returns 1 when distance is between 100 m and 200 m', () {
      expect(getProximityIntensity(200), 1);
      expect(getProximityIntensity(150), 1);
      expect(getProximityIntensity(101), 1);
    });

    test('returns 2 when distance is 100 m or less', () {
      expect(getProximityIntensity(100), 2);
      expect(getProximityIntensity(50), 2);
      expect(getProximityIntensity(0), 2);
    });

    test('divides range into numLevels bands when numLevels is 3', () {
      // With numLevels=3 the 200 m range splits into three ~66.67 m bands.
      expect(getProximityIntensity(250, numLevels: 3), 0); // > 200 m
      expect(getProximityIntensity(180, numLevels: 3), 1); // ≤ 200 m
      expect(getProximityIntensity(100, numLevels: 3), 2); // ≤ 133.33 m
      expect(getProximityIntensity(50,  numLevels: 3), 3); // ≤ 66.67 m
      expect(getProximityIntensity(0,   numLevels: 3), 3);
    });

    test('works with a single level', () {
      expect(getProximityIntensity(201, numLevels: 1), 0);
      expect(getProximityIntensity(200, numLevels: 1), 1);
      expect(getProximityIntensity(0,   numLevels: 1), 1);
    });
  });

  group('calculateBearing', () {
    test('returns ~0 (North) when target is directly north', () {
      final b = calculateBearing(0.0, 0.0, 1.0, 0.0);
      expect(b, closeTo(0.0, 0.5));
    });

    test('returns ~90 (East) when target is directly east', () {
      final b = calculateBearing(0.0, 0.0, 0.0, 1.0);
      expect(b, closeTo(90.0, 0.5));
    });

    test('returns ~180 (South) when target is directly south', () {
      final b = calculateBearing(1.0, 0.0, 0.0, 0.0);
      expect(b, closeTo(180.0, 0.5));
    });

    test('returns ~270 (West) when target is directly west', () {
      final b = calculateBearing(0.0, 1.0, 0.0, 0.0);
      expect(b, closeTo(270.0, 0.5));
    });

    test('returns value in range [0, 360)', () {
      final b = calculateBearing(
          targetLatitude, targetLongitude, targetLatitude + 0.001, targetLongitude + 0.001);
      expect(b, greaterThanOrEqualTo(0.0));
      expect(b, lessThan(360.0));
    });
  });
}
