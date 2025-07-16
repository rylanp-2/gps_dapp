import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';

Future<Position> getCurrentLocation(BuildContext context) async {
  bool serviceEnabled;
  LocationPermission permission;

  // 1. Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Location services are disabled.');
  }

  // 2. Check for permissions
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permissions are denied.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    showLocationPermissionDialog(context);
    throw Exception('Location permissions are permanently denied\nPlease enable them in settings');
  }

  // 3. Adjust accuracy based on permission
  final accuracy = (permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always)
      ? LocationAccuracy.high
      : LocationAccuracy.low;
  final locationSettings = LocationSettings(accuracy: accuracy);

  // 4. Try to get the current location
  try {
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Location request timed out'),
    );

    // Print statement for testing:
    //print(position.accuracy);

    if (position.accuracy < 2000) {
      return position;
    } else {
      showLocationPermissionDialog(context);
      throw Exception('Location too inaccurate.\nPlease update your settings to \'Use precise location\'.');
    }
  } on TimeoutException {
    throw Exception('Failed to get location: Timeout.');
  } on Exception catch (e) {
    throw Exception('Failed to get location: ${e.toString()}');
  }
}


// Turn on precise location dialog
void showLocationPermissionDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Precise Location Required'),
      content: const Text(
        'This app requires precise location access to function properly.\n\n'
            'Please enable "Use precise location" in your device\'s location settings.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            AppSettings.openAppSettings(type: AppSettingsType.location);
          },
          child: const Text('Open Settings'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}