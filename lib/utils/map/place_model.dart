import 'dart:convert';
import 'package:flutter/foundation.dart';

@immutable
class PlaceModel {
  const PlaceModel({
    required this.city,
    required this.description,
    required this.placeId,
    required this.latitude,
    required this.longitude,
    required this.state,
    required this.country,
  });

  factory PlaceModel.fromGooglePrediction(Map<String, dynamic> prediction) {
    final description = prediction['description']?.toString() ?? '';
    final placeId = prediction['place_id']?.toString() ?? '';
    final terms = prediction['terms'] as List<dynamic>? ?? [];

    final city = terms.isNotEmpty && terms[0]['value'] != null
        ? terms[0]['value'].toString()
        : '';
    final state = terms.length > 1 && terms[1]['value'] != null
        ? terms[1]['value'].toString()
        : '';
    final country = terms.length > 2 && terms[2]['value'] != null
        ? terms[2]['value'].toString()
        : '';

    return PlaceModel(
      city: city,
      description: description,
      placeId: placeId,
      state: state,
      country: country,
      latitude: '',
      longitude: '',
    );
  }

  factory PlaceModel.fromOsmPrediction(Map<String, dynamic> prediction) {
    return PlaceModel(
      city: prediction['city']?.toString() ?? '',
      description: prediction['description']?.toString() ?? '',
      placeId: prediction['place_id']?.toString() ?? '',
      state: prediction['state']?.toString() ?? '',
      country: prediction['country']?.toString() ?? '',
      latitude: prediction['lat']?.toString() ?? '',
      longitude: prediction['lng']?.toString() ?? '',
    );
  }

  factory PlaceModel.fromMap(Map<String, dynamic> map) {
    return PlaceModel(
      city: map['name'] as String? ?? map['city'] as String? ?? '',
      description:
          map['desctiption'] as String? ?? map['description'] as String? ?? '',
      placeId: map['placeId'] as String? ?? map['place_id'] as String? ?? '',
      latitude: map['latitude'] as String? ?? map['lat'] as String? ?? '',
      longitude: map['longitude'] as String? ?? map['lng'] as String? ?? '',
      state: map['state'] as String? ?? '',
      country: map['country'] as String? ?? '',
    );
  }
  final String city;
  final String description;
  final String placeId;
  final String latitude;
  final String longitude;
  final String state;
  final String country;

  PlaceModel copyWith({
    String? name,
    String? cityName,
    String? placeId,
    String? latitude,
    String? longitude,
    String? state,
    String? country,
  }) {
    return PlaceModel(
      city: name ?? city,
      state: state ?? this.state,
      country: country ?? this.country,
      description: cityName ?? description,
      placeId: placeId ?? this.placeId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': city,
      'desctiption': description,
      'placeId': placeId,
      'latitude': latitude,
      'longitude': longitude,
      'state': state,
      'country': country,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return '''PlaceModel(city: $city, description: $description, placeId: $placeId, latitude: $latitude, longitude: $longitude, state: $state, country: $country)''';
  }

  @override
  bool operator ==(covariant PlaceModel other) {
    if (identical(this, other)) return true;

    return other.city == city &&
        other.description == description &&
        other.placeId == placeId &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.state == state &&
        other.country == country;
  }

  @override
  int get hashCode {
    return city.hashCode ^
        description.hashCode ^
        placeId.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        state.hashCode ^
        country.hashCode;
  }
}
