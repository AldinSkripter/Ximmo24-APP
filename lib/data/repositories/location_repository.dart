import 'package:dio/dio.dart';
import 'package:ebroker/data/model/google_place_model.dart';
import 'package:ebroker/data/model/place_details_model.dart';
import 'package:ebroker/utils/api.dart';

class GooglePlaceRepository {
  //This will search places from google place api
  //We use this to search location while adding new property
  Future<List<GooglePlaceModel>> serchCities(String text) async {
    try {
      final queryParameters = <String, dynamic>{
        Api.input: text,
      };
      final apiResponse = await Api.get(
        url: Api.getPlaceList,
        useAuthToken: false,
        useBaseUrl: false,
        queryParameters: queryParameters,
      );
      return _buildPlaceModelList(apiResponse);
    } on Exception catch (e) {
      if (e is DioException) {}
      throw ApiException(e.toString());
    }
  }

  ///this will convert normal response to List of models
  ///so we can use it easily in code
  List<GooglePlaceModel> _buildPlaceModelList(
    Map<String, dynamic> apiResponse,
  ) {
    ///loop throuh predictions list,
    ///this will create List of GooglePlaceModel
    try {
      final predictions = apiResponse['data']['predictions'] as List<dynamic>;
      final filteredResult = predictions.map((prediction) {
        final description = prediction['description']?.toString() ?? '';
        final placeId = prediction['place_id']?.toString() ?? '';

        final terms = prediction['terms'] as List<dynamic>;
        final city =
            terms
                .firstWhere(
                  (term) => term['value'] != null,
                  orElse: () => <dynamic, dynamic>{},
                )['value']
                ?.toString() ??
            '';
        final state = terms.length > 1
            ? terms[1]['value']?.toString() ?? ''
            : '';
        final country = terms.length > 2
            ? terms[2]['value']?.toString() ?? ''
            : '';

        return GooglePlaceModel(
          city: city,
          description: description,
          placeId: placeId,
          state: state,
          country: country,
          latitude: '',
          longitude: '',
        );
      }).toList();

      return filteredResult;
    } on Exception catch (_) {
      rethrow;
    }
  }

  ///Fetches place details for a given placeId (forward lookup) or
  ///lat/lng pair (reverse geocoding). Returns a typed [PlaceDetailsModel].
  ///
  ///The backend wraps the response as either:
  ///  - success: `data: { result: {...}, status: "OK" }`
  ///  - empty:   `data: []`
  ///In the empty / malformed case this throws `ApiException('noDataFound')`
  ///so the cubit surfaces it as a failure state instead of silently
  ///emitting a blank model.
  Future<PlaceDetailsModel> getPlaceDetails({
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
        url: Api.getPlaceDetails,
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
      return PlaceDetailsModel.fromMap(Map<String, dynamic>.from(result));
    } on Exception catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }
}
