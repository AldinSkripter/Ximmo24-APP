import 'dart:convert';

import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/exports/main_export.dart';

class GMap {
  static Future<List<PropertyModel>> getNearByProperty(
    String city,
    String latitude,
    String longitude,
    String placeId, {
    FilterApply? filter,
  }) async {
    try {
      final filterMap = (filter?.toMap() ?? {})..remove('location');
      final response = await Api.get(
        url: Api.getPropertiesOnMap,
        queryParameters: {
          'city': city,
          'place_id': placeId,
          'latitude': latitude,
          'longitude': longitude,
          if (filterMap.isNotEmpty)
            'filters': base64Encode(utf8.encode(jsonEncode(filterMap))),
        },
        useAuthToken: false,
      );
      // response.mlog('City response');
      if (response['error'] == true) {
        throw ApiException(response['message']?.toString() ?? '');
      }
      final points = (response['data'] as List? ?? []).map((e) {
        return PropertyModel.fromMap(e as Map<String, dynamic>? ?? {});
      }).toList();
      return points;
    } on Exception catch (_) {
      rethrow;
    }
  }
}
