import 'dart:math';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:trackst/target_coordinates.dart';
// Target coordinates for the game location

final targetLatitude = getTargetLatitude();
final targetLongitude = getTargetLongitude();

/// Calculates the distance in meters between two geographic coordinates
/// using the Haversine formula.
double calculateDistance(
    double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

/// Calculates the compass bearing in degrees (0–360) from one geographic
/// coordinate to another, where 0/360 is North, 90 is East, etc.
double calculateBearing(
    double lat1, double lon1, double lat2, double lon2) {
  final lat1Rad = lat1 * pi / 180;
  final lat2Rad = lat2 * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final y = sin(dLon) * cos(lat2Rad);
  final x =
      cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLon);
  final bearing = atan2(y, x) * 180 / pi;
  return (bearing + 360) % 360;
}

/// Returns a proximity intensity level based on distance to the target:
///   0 – more than 200 m away (normal)
///   1 – within 200 m (medium)
///   2 – within 100 m (highest)
int getProximityIntensity(double distanceMeters) {
  if (distanceMeters <= 100) return 2;
  if (distanceMeters <= 200) return 1;
  return 0;
}


Future<bool> _waitForService(Location location) async {
  for (int i = 0; i < 5; i++) {
    try {
      if (await location.serviceEnabled()) {
        return true;
      }
    } catch (_) {}

    await Future.delayed(const Duration(seconds: 3));
  }
  return false;
}
/// Requests permissions and returns a stream of location updates.
/// Yields nothing if the service or permission is unavailable.
Stream<LocationData> getLocationStream() async* {
  final location = Location();
  bool serviceEnabled = false;
  await _waitForService(location);
  serviceEnabled = await location.serviceEnabled();

  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) return;
  }

  PermissionStatus permissionGranted = await location.hasPermission();
  if (permissionGranted == PermissionStatus.denied) {
    permissionGranted = await location.requestPermission();
    if (permissionGranted != PermissionStatus.granted) return;
  }

  yield* location.onLocationChanged;
}

Future<LocationData?> getLocationData() async {

  Location location = Location();


  bool serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      return null;
    }
  }

  PermissionStatus permissionGranted = await location.hasPermission();
  if (permissionGranted == PermissionStatus.denied) {
    permissionGranted = await location.requestPermission();
    if (permissionGranted != PermissionStatus.granted) {
      return null;
    }
  }

  LocationData locationData = await location.getLocation();
  return locationData;
}

class LocationTracker extends StatelessWidget {
  const LocationTracker(this.letter, {super.key});


  final String letter;


  @override
  Widget build(BuildContext context) {
    // TODO: Replace Container with widgets.
    return Text("Hello there");
  }
}