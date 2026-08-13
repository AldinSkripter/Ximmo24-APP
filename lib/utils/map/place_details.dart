import 'package:flutter/foundation.dart';

@immutable
class PlaceDetails {
  const PlaceDetails({
    required this.city,
    required this.state,
    required this.country,
    required this.address,
    this.lat,
    this.lng,
  });

  factory PlaceDetails.fromGoogleResult(Map<String, dynamic> result) {
    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final rawLat = location?['lat'];
    final rawLng = location?['lng'];

    final addressComponents =
        ((result['address_components'] as List?) ?? const <dynamic>[])
            .whereType<Map<dynamic, dynamic>>()
            .toList();

    String getComponent(String type) {
      for (final c in addressComponents) {
        final types =
            (c['types'] as List?)?.map((e) => e.toString()).toList() ?? [];
        if (types.contains(type)) {
          return c['long_name']?.toString() ?? '';
        }
      }
      return '';
    }

    final city = getComponent('locality');
    final state = getComponent('administrative_area_level_1');
    final country = getComponent('country');
    final formattedAddress = result['formatted_address']?.toString() ?? '';

    return PlaceDetails(
      lat: _toDouble(rawLat),
      lng: _toDouble(rawLng),
      city: city,
      state: state,
      country: country,
      address: formattedAddress,
    );
  }

  factory PlaceDetails.fromOsmResult(Map<String, dynamic> result) {
    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final rawLat = location?['lat'];
    final rawLng = location?['lng'];

    return PlaceDetails(
      lat: _toDouble(rawLat),
      lng: _toDouble(rawLng),
      city: result['city']?.toString() ?? '',
      state: result['state']?.toString() ?? '',
      country: result['country']?.toString() ?? '',
      address: result['address']?.toString() ?? '',
    );
  }
  final double? lat;
  final double? lng;
  final String city;
  final String state;
  final String country;
  final String address;

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  String toString() {
    return 'PlaceDetails(lat: $lat, lng: $lng, city: $city, state: $state, country: $country, address: $address)';
  }
}
