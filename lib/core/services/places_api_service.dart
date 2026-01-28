import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quick_church/core/config/env_config.dart';

/// Place prediction result from Places API (New).
class PlacePrediction {
  final String placeId;
  final String displayName;
  final String? formattedAddress;

  PlacePrediction({
    required this.placeId,
    required this.displayName,
    this.formattedAddress,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['id'] ?? json['place_id'] ?? '',
      displayName: json['displayName']?['text'] ??
                   json['structuredFormat']?['mainText']?['text'] ??
                   json['description'] ?? '',
      formattedAddress: json['formattedAddress'] ??
                        json['structuredFormat']?['secondaryText']?['text'],
    );
  }
}

/// Service for Google Places API (New) with optimized field masking.
/// Uses the latest Places API endpoints for cost-effective autocomplete.
class PlacesApiService {
  static const String _baseUrl = 'https://places.googleapis.com/v1';
  static const String _autocompleteEndpoint = '$_baseUrl/places:autocomplete';

  final String _apiKey = EnvConfig.googleMapsApiKey;

  Timer? _debounceTimer;

  /// Searches for places with 400ms debounce.
  /// Uses field masking to only request displayName and id (lowest cost tier).
  ///
  /// [query] - The search text
  /// [languageCode] - Optional language code (e.g., 'en', 'fr')
  /// [locationBias] - Optional lat/lng for biasing results
  Future<List<PlacePrediction>> searchPlaces({
    required String query,
    String? languageCode,
    ({double lat, double lng})? locationBias,
  }) async {
    final completer = Completer<List<PlacePrediction>>();

    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // 400ms debounce
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final results = await _performSearch(
          query: query,
          languageCode: languageCode,
          locationBias: locationBias,
        );
        if (!completer.isCompleted) {
          completer.complete(results);
        }
      } catch (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      }
    });

    return completer.future;
  }

  /// Performs the actual API call to Places API (New).
  Future<List<PlacePrediction>> _performSearch({
    required String query,
    String? languageCode,
    ({double lat, double lng})? locationBias,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    // Build request body for Places API (New)
    final requestBody = <String, dynamic>{
      'input': query,
      'includedPrimaryTypes': ['locality', 'administrative_area_level_1', 'country'],
    };

    // Add language code if provided
    if (languageCode != null) {
      requestBody['languageCode'] = languageCode;
    }

    // Add location bias if provided (improves relevance)
    if (locationBias != null) {
      requestBody['locationBias'] = {
        'circle': {
          'center': {
            'latitude': locationBias.lat,
            'longitude': locationBias.lng,
          },
          'radius': 50000.0, // 50km radius
        },
      };
    }

    try {
      final response = await http.post(
        Uri.parse(_autocompleteEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          // Field masking - only request what we need (lowest cost tier)
          'X-Goog-FieldMask': 'suggestions.placePrediction.placeId,suggestions.placePrediction.structuredFormat,suggestions.placePrediction.text',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final suggestions = data['suggestions'] as List<dynamic>? ?? [];

        return suggestions
            .where((s) => s['placePrediction'] != null)
            .map((s) {
              final prediction = s['placePrediction'];
              return PlacePrediction(
                placeId: prediction['placeId'] ?? '',
                displayName: prediction['structuredFormat']?['mainText']?['text'] ??
                            prediction['text']?['text'] ?? '',
                formattedAddress: prediction['structuredFormat']?['secondaryText']?['text'],
              );
            })
            .toList();
      } else {
        // Log error for debugging
        print('Places API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Places API Exception: $e');
      return [];
    }
  }

  /// Cancels any pending debounced search.
  void cancelSearch() {
    _debounceTimer?.cancel();
  }

  /// Disposes the service and cancels any pending operations.
  void dispose() {
    _debounceTimer?.cancel();
  }
}
