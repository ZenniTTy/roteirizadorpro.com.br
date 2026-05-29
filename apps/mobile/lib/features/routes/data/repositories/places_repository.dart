import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/env/app_env.dart';
import '../../domain/place_autocomplete_prediction.dart';

import '../../domain/place_details.dart';

part 'places_repository.g.dart';

class PlacesRepository {
  PlacesRepository({required this.dio, required this.apiKey});

  final Dio dio;
  final String apiKey;

  Future<List<PlaceAutocompletePrediction>> autocomplete(String query) async {
    if (query.isEmpty) return [];
    if (apiKey.isEmpty) {
      throw Exception(
          'Chave da API do Google Maps ausente. Inicie o app com --dart-define-from-file=.env');
    }

    try {
      final response = await dio.post(
        'https://places.googleapis.com/v1/places:autocomplete',
        options: Options(
          headers: {
            'X-Goog-Api-Key': apiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'input': query,
          'includedRegionCodes': ['br'],
          'languageCode': 'pt-BR',
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) return [];

      if (data.containsKey('error')) {
        final errorMsg = data['error']['message'] ?? 'Unknown error';
        throw Exception('API Error: $errorMsg');
      }

      final suggestions = data['suggestions'] as List?;
      if (suggestions == null) return [];

      return suggestions.map((json) {
        final prediction = json['placePrediction'] as Map<String, dynamic>;
        final structuredFormat =
            prediction['structuredFormat'] as Map<String, dynamic>?;

        return PlaceAutocompletePrediction(
          placeId: prediction['placeId'] as String? ?? '',
          description: prediction['text']?['text'] as String? ?? '',
          mainText: structuredFormat?['mainText']?['text'] as String? ?? '',
          secondaryText:
              structuredFormat?['secondaryText']?['text'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      throw Exception('Falha de conexão com Places API: $e');
    }
  }

  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (apiKey.isEmpty) {
      throw Exception(
          'Chave da API do Google Maps ausente. Inicie o app com --dart-define-from-file=.env');
    }

    try {
      final response = await dio.get(
        'https://places.googleapis.com/v1/places/$placeId',
        queryParameters: {
          'fields': 'location,shortFormattedAddress,formattedAddress',
          'languageCode': 'pt-BR',
        },
        options: Options(
          headers: {
            'X-Goog-Api-Key': apiKey,
          },
        ),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) return null;

      if (data.containsKey('error')) {
        final errorMsg = data['error']['message'] ?? 'Unknown error';
        throw Exception('API Error: $errorMsg');
      }

      final location = data['location'] as Map<String, dynamic>?;
      if (location == null) return null;

      return PlaceDetails(
        lat: (location['latitude'] as num?)?.toDouble() ?? 0.0,
        lng: (location['longitude'] as num?)?.toDouble() ?? 0.0,
        shortFormattedAddress: data['shortFormattedAddress'] as String? ?? '',
        formattedAddress: data['formattedAddress'] as String? ?? '',
      );
    } catch (e) {
      throw Exception('Falha ao buscar detalhes do local: $e');
    }
  }
}

@riverpod
PlacesRepository placesRepository(Ref ref) {
  return PlacesRepository(
    dio: Dio(),
    apiKey: AppEnv.mapsApiKey,
  );
}
