import 'package:flutter/material.dart';
import 'package:location/location.dart';


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