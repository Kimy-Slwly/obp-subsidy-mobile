import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationVerificationResult {
  final double latitude;
  final double longitude;
  final String stationName;
  final String address;
  final double distanceMeters;
  final bool isInsideGeofence;
  final bool isSuccess;
  final String? statusMessage;

  const LocationVerificationResult({
    required this.latitude,
    required this.longitude,
    required this.stationName,
    required this.address,
    required this.distanceMeters,
    required this.isInsideGeofence,
    required this.isSuccess,
    this.statusMessage,
  });
}

class NearestStationResult {
  final String stationName;
  final double distanceKm;
  final bool isFound;
  final String statusText;

  const NearestStationResult({
    required this.stationName,
    required this.distanceKm,
    required this.isFound,
    required this.statusText,
  });
}

class LocationService {
  /// Maximum radius in metres to verify presence at a Shell station
  static const double geofenceRadiusMeters = 250.0;

  /// High-reliability live GPS verification:
  /// 1. Obtains real device coordinates (with 8-second timeout & fallback to last known position)
  /// 2. Dynamically queries OpenStreetMap Overpass API for real Shell petrol stations within 250m
  /// 3. If within 250m of a real Shell station: flags as verified with station name and distance
  /// 4. If NOT at a Shell station: flags as unverified and reverse-geocodes actual driver address
  static Future<LocationVerificationResult> getCurrentVerification() async {
    try {
      // 1. Verify location service is enabled (3s timeout)
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 3), onTimeout: () => false);

      if (!serviceEnabled) {
        debugPrint('[LocationService] Location services disabled on device.');
        return const LocationVerificationResult(
          latitude: 0.0,
          longitude: 0.0,
          stationName: 'Location Services Disabled',
          address: 'Please enable GPS location in your device settings',
          distanceMeters: 0.0,
          isInsideGeofence: false,
          isSuccess: false,
          statusMessage: 'Location services are turned off on your device.',
        );
      }

      // 2. Check and request location permissions cleanly
      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 3), onTimeout: () => LocationPermission.denied);

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 5), onTimeout: () => LocationPermission.denied);
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Location permission denied by user.');
          return const LocationVerificationResult(
            latitude: 0.0,
            longitude: 0.0,
            stationName: 'Permission Denied',
            address: 'Location permission required to verify petrol station',
            distanceMeters: 0.0,
            isInsideGeofence: false,
            isSuccess: false,
            statusMessage: 'Location permission was denied.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Location permission permanently denied.');
        return const LocationVerificationResult(
          latitude: 0.0,
          longitude: 0.0,
          stationName: 'Permission Blocked',
          address: 'Enable location permission in App Settings',
          distanceMeters: 0.0,
          isInsideGeofence: false,
          isSuccess: false,
          statusMessage: 'Location permissions permanently denied. Please enable in Settings.',
        );
      }

      // 3. Acquire real live position with 8-second timeout & fallback to last known position
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (e) {
        debugPrint('[LocationService] getCurrentPosition timed out or failed: $e. Checking last known position.');
        try {
          position = await Geolocator.getLastKnownPosition()
              .timeout(const Duration(seconds: 3), onTimeout: () => null);
        } catch (_) {
          position = null;
        }
      }

      if (position == null) {
        debugPrint('[LocationService] Unable to obtain GPS fix.');
        return const LocationVerificationResult(
          latitude: 0.0,
          longitude: 0.0,
          stationName: 'No GPS Fix',
          address: 'Unable to acquire satellite or network GPS fix',
          distanceMeters: 0.0,
          isInsideGeofence: false,
          isSuccess: false,
          statusMessage: 'GPS fix timed out. Move closer to open sky or enable mobile data.',
        );
      }

      final double liveLat = position.latitude;
      final double liveLng = position.longitude;

      debugPrint('[LocationService] Acquired live coordinates: $liveLat, $liveLng');

      // 4. Dynamically query OpenStreetMap Overpass API for real Shell stations within 250m
      final Map<String, dynamic>? overpassData = await _queryOverpassShellStations(liveLat, liveLng);

      Map<String, dynamic>? nearestShellStation;
      double minDistance = double.infinity;

      if (overpassData != null && overpassData['elements'] is List) {
        final elements = overpassData['elements'] as List;
        for (final el in elements) {
          if (el is! Map<String, dynamic>) continue;

          // Elements can be nodes (lat, lon) or ways with center (center: {lat, lon})
          final double? stationLat = (el['lat'] as num?)?.toDouble() ??
              (el['center']?['lat'] as num?)?.toDouble();
          final double? stationLon = (el['lon'] as num?)?.toDouble() ??
              (el['center']?['lon'] as num?)?.toDouble();

          if (stationLat != null && stationLon != null) {
            final double dist = Geolocator.distanceBetween(
              liveLat,
              liveLng,
              stationLat,
              stationLon,
            );
            if (dist < minDistance) {
              minDistance = dist;
              nearestShellStation = el;
            }
          }
        }
      }

      // 5. Evaluate geofence match (within 250 metres)
      if (nearestShellStation != null && minDistance <= geofenceRadiusMeters) {
        final tags = nearestShellStation['tags'] as Map<String, dynamic>?;
        String stationName = tags?['name'] as String? ?? tags?['brand'] as String? ?? 'Shell Station';
        if (!stationName.toLowerCase().contains('shell')) {
          stationName = 'Shell ($stationName)';
        }

        // Format station address from tags if present, otherwise reverse geocode
        String? stationAddress;
        if (tags != null) {
          final street = tags['addr:street'];
          final city = tags['addr:city'] ?? tags['addr:district'];
          final postcode = tags['addr:postcode'];
          if (street != null && street.toString().trim().isNotEmpty) {
            stationAddress = [street, city, postcode]
                .where((s) => s != null && s.toString().trim().isNotEmpty)
                .join(', ');
          }
        }
        stationAddress ??= await _reverseGeocode(liveLat, liveLng);

        return LocationVerificationResult(
          latitude: liveLat,
          longitude: liveLng,
          stationName: stationName,
          address: stationAddress,
          distanceMeters: minDistance,
          isInsideGeofence: true,
          isSuccess: true,
          statusMessage: 'Verified: Within ${minDistance.toStringAsFixed(0)}m of $stationName',
        );
      }

      // 6. Outside 250m perimeter or no Shell station found:
      // Real driver address is retrieved dynamically via reverse geocoding
      final String realAddress = await _reverseGeocode(liveLat, liveLng);

      return LocationVerificationResult(
        latitude: liveLat,
        longitude: liveLng,
        stationName: 'Not at Shell Station',
        address: realAddress,
        distanceMeters: minDistance.isFinite ? minDistance : 0.0,
        isInsideGeofence: false,
        isSuccess: true,
        statusMessage: minDistance.isFinite
            ? 'Nearest Shell station is ${minDistance.toStringAsFixed(0)}m away (outside 250m geofence).'
            : 'No Shell petrol station detected within 250m of your location.',
      );
    } catch (e) {
      debugPrint('[LocationService] Unexpected verification error: $e');
      return LocationVerificationResult(
        latitude: 0.0,
        longitude: 0.0,
        stationName: 'Location Error',
        address: 'Error during location verification: $e',
        distanceMeters: 0.0,
        isInsideGeofence: false,
        isSuccess: false,
        statusMessage: 'Location verification error: $e',
      );
    }
  }

  /// Finds the nearest real Shell station within [radiusMeters] (default: 5000m / 5 km)
  /// using live GPS and OpenStreetMap Overpass API.
  static Future<NearestStationResult> getNearestShellStation({
    double radiusMeters = 5000.0,
  }) async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 3), onTimeout: () => false);

      if (!serviceEnabled) {
        return const NearestStationResult(
          stationName: 'Location Disabled',
          distanceKm: 0.0,
          isFound: false,
          statusText: 'Enable GPS location',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 3), onTimeout: () => LocationPermission.denied);

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 5), onTimeout: () => LocationPermission.denied);
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          return const NearestStationResult(
            stationName: 'Permission Denied',
            distanceKm: 0.0,
            isFound: false,
            statusText: 'Location permission needed',
          );
        }
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (e) {
        debugPrint('[LocationService] Live GPS timeout: $e. Checking last known position.');
        try {
          position = await Geolocator.getLastKnownPosition()
              .timeout(const Duration(seconds: 3), onTimeout: () => null);
        } catch (_) {
          position = null;
        }
      }

      if (position == null) {
        return const NearestStationResult(
          stationName: 'Searching GPS...',
          distanceKm: 0.0,
          isFound: false,
          statusText: 'GPS fix pending',
        );
      }

      final double liveLat = position.latitude;
      final double liveLng = position.longitude;

      final overpassData = await _queryOverpassShellStations(
        liveLat,
        liveLng,
        radiusMeters: radiusMeters,
      );

      Map<String, dynamic>? closestStation;
      double minDistanceMeters = double.infinity;

      if (overpassData != null && overpassData['elements'] is List) {
        final elements = overpassData['elements'] as List;
        for (final el in elements) {
          if (el is! Map<String, dynamic>) continue;

          final double? stationLat = (el['lat'] as num?)?.toDouble() ??
              (el['center']?['lat'] as num?)?.toDouble();
          final double? stationLon = (el['lon'] as num?)?.toDouble() ??
              (el['center']?['lon'] as num?)?.toDouble();

          if (stationLat != null && stationLon != null) {
            final double dist = Geolocator.distanceBetween(
              liveLat,
              liveLng,
              stationLat,
              stationLon,
            );
            if (dist < minDistanceMeters) {
              minDistanceMeters = dist;
              closestStation = el;
            }
          }
        }
      }

      if (closestStation != null && minDistanceMeters <= radiusMeters) {
        final tags = closestStation['tags'] as Map<String, dynamic>?;
        String stationName = tags?['name'] as String? ?? tags?['brand'] as String? ?? 'Shell Station';
        if (!stationName.toLowerCase().contains('shell')) {
          stationName = 'Shell ($stationName)';
        }

        final double distanceKm = minDistanceMeters / 1000.0;
        final String statusText = distanceKm <= 0.25
            ? '${minDistanceMeters.toStringAsFixed(0)} m • Geofence Ready'
            : '${distanceKm.toStringAsFixed(1)} km • Geofence Ready';

        return NearestStationResult(
          stationName: stationName,
          distanceKm: distanceKm,
          isFound: true,
          statusText: statusText,
        );
      }

      return const NearestStationResult(
        stationName: 'No Shell within 5 km',
        distanceKm: 0.0,
        isFound: false,
        statusText: 'Outside 5 km service area',
      );
    } catch (e) {
      debugPrint('[LocationService] Error searching nearest Shell station: $e');
      return const NearestStationResult(
        stationName: 'GPS Lookup Error',
        distanceKm: 0.0,
        isFound: false,
        statusText: 'Could not fetch pump',
      );
    }
  }

  /// Query OpenStreetMap Overpass API for real Shell stations within [radiusMeters]
  static Future<Map<String, dynamic>?> _queryOverpassShellStations(
    double lat,
    double lng, {
    double radiusMeters = 250.0,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 6);

    try {
      final int radiusInt = radiusMeters.round();
      final query =
          '[out:json][timeout:8];('
          'node["amenity"="fuel"]["name"~"Shell",i](around:$radiusInt,$lat,$lng);'
          'way["amenity"="fuel"]["name"~"Shell",i](around:$radiusInt,$lat,$lng);'
          'node["amenity"="fuel"]["brand"~"Shell",i](around:$radiusInt,$lat,$lng);'
          'way["amenity"="fuel"]["brand"~"Shell",i](around:$radiusInt,$lat,$lng);'
          ');out center;';

      final uri = Uri.parse('https://overpass-api.de/api/interpreter');
      final request = await client.postUrl(uri).timeout(const Duration(seconds: 6));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/x-www-form-urlencoded; charset=utf-8');
      request.headers.set(HttpHeaders.userAgentHeader, 'OBPDriverMobile/1.0 (TargetedFuelSubsidySystem)');

      final postData = 'data=${Uri.encodeQueryComponent(query)}';
      request.add(utf8.encode(postData));

      final response = await request.close().timeout(const Duration(seconds: 6));
      if (response.statusCode == HttpStatus.ok) {
        final responseBody = await response.transform(utf8.decoder).join();
        final dynamic decoded = jsonDecode(responseBody);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } else {
        debugPrint('[LocationService] Overpass API responded with HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[LocationService] Overpass API query error: $e');
    } finally {
      client.close();
    }
    return null;
  }

  /// Reverse geocode coordinates to get real street address (5s timeout)
  static Future<String> _reverseGeocode(double lat, double lng) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 5));
      request.headers.set(HttpHeaders.userAgentHeader, 'OBPDriverMobile/1.0 (TargetedFuelSubsidySystem)');

      final response = await request.close().timeout(const Duration(seconds: 5));
      if (response.statusCode == HttpStatus.ok) {
        final responseBody = await response.transform(utf8.decoder).join();
        final dynamic decoded = jsonDecode(responseBody);

        if (decoded is Map<String, dynamic>) {
          final addressObj = decoded['address'] as Map<String, dynamic>?;
          if (addressObj != null) {
            final road = addressObj['road'] ?? addressObj['pedestrian'] ?? addressObj['highway'];
            final suburb = addressObj['suburb'] ?? addressObj['neighbourhood'] ?? addressObj['village'];
            final city = addressObj['city'] ?? addressObj['town'] ?? addressObj['municipality'];
            final postcode = addressObj['postcode'];
            final state = addressObj['state'];

            final parts = [road, suburb, city, postcode, state]
                .where((p) => p != null && p.toString().trim().isNotEmpty)
                .map((p) => p.toString().trim())
                .toList();

            if (parts.isNotEmpty) {
              return parts.join(', ');
            }
          }

          final displayName = decoded['display_name'] as String?;
          if (displayName != null && displayName.isNotEmpty) {
            return displayName;
          }
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Reverse geocode error: $e');
    } finally {
      client.close();
    }

    return '${lat.toStringAsFixed(5)}° N, ${lng.toStringAsFixed(5)}° E';
  }
}
