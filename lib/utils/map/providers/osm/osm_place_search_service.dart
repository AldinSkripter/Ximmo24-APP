import 'package:ebroker/utils/api.dart';
import 'package:ebroker/utils/map/place_details.dart';
import 'package:ebroker/utils/map/place_model.dart';
import 'package:ebroker/utils/map/place_search_service.dart';

class OsmPlaceSearchService implements PlaceSearchService {
  @override
  Future<List<PlaceModel>> searchCities(String query) async {
    try {
      final queryParameters = <String, dynamic>{
        Api.input: query,
      };
      final apiResponse = await Api.get(
        url: Api.getOsmPlaceList,
        useAuthToken: false,
        useBaseUrl: false,
        queryParameters: queryParameters,
      );

      final predictions =
          apiResponse['data']?['predictions'] as List<dynamic>? ?? [];
      return predictions
          .map(
            (p) => PlaceModel.fromOsmPrediction(
              Map<String, dynamic>.from(p as Map),
            ),
          )
          .toList();
    } on Exception catch (e) {
      throw ApiException(e.toString());
    }
  }

  @override
  Future<PlaceDetails> getPlaceDetails({
    required String latitude,
    required String longitude,
    String? placeId,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        if (placeId != null && placeId.isNotEmpty) 'place_id': placeId,
        Api.latitude: latitude,
        Api.longitude: longitude,
      };
      final response = await Api.get(
        url: Api.getOsmPlaceDetails,
        queryParameters: queryParameters,
        useBaseUrl: false,
        useAuthToken: false,
      );

      final data = response['data'];
      if (data is! Map) {
        throw ApiException('noDataFound');
      }
      final result = data['result'];
      if (result is! Map) {
        throw ApiException('noDataFound');
      }
      return PlaceDetails.fromOsmResult(Map<String, dynamic>.from(result));
    } on Exception catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }
}
