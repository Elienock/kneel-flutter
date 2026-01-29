import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quick_church/core/config/env_config.dart';
import 'package:quick_church/core/utils/kneel_logger.dart';

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

  @override
  String toString() => 'PlacePrediction(placeId: $placeId, displayName: $displayName)';
}

/// Service for Google Places API (New) with optimized field masking.
/// Uses the Autocomplete (New) endpoint for cost-effective city search.
///
/// API Documentation: https://developers.google.com/maps/documentation/places/web-service/place-autocomplete
class PlacesApiService {
  /// Autocomplete (New) endpoint
  static const String _autocompleteEndpoint =
      'https://places.googleapis.com/v1/places:autocomplete';

  final String _apiKey = EnvConfig.googleMapsApiKey;

  Timer? _debounceTimer;

  /// Searches for places with 400ms debounce.
  /// Uses field masking to only request what we need (lowest cost tier).
  ///
  /// [query] - The search text (city name)
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

    // 400ms debounce to prevent excessive API calls
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final results = await _performAutocomplete(
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

  /// Performs the actual API call to Places Autocomplete (New).
  Future<List<PlacePrediction>> _performAutocomplete({
    required String query,
    String? languageCode,
    ({double lat, double lng})? locationBias,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    KneelLogger.log('Searching places for: "$query"', context: 'PlacesAPI');

    // Build request body according to Places API (New) documentation
    // https://developers.google.com/maps/documentation/places/web-service/place-autocomplete
    final requestBody = <String, dynamic>{
      'input': query,
      // Include query predictions for better results
      'includeQueryPredictions': false,
    };

    // Add language code if provided
    if (languageCode != null && languageCode.isNotEmpty) {
      requestBody['languageCode'] = languageCode;
    }

    // Add location bias if provided (improves relevance for nearby cities)
    if (locationBias != null) {
      requestBody['locationBias'] = {
        'circle': {
          'center': {
            'latitude': locationBias.lat,
            'longitude': locationBias.lng,
          },
          'radius': 50000.0, // 50km radius bias
        },
      };
    }

    // Filter to only cities and regions
    requestBody['includedPrimaryTypes'] = [
      'locality',
      'administrative_area_level_1',
      'administrative_area_level_2',
    ];

    // Prepare headers with field mask (Clean Web Request - no Android headers)
    // Field mask specifies which fields to return (affects pricing)
    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': _apiKey,
      'X-Goog-FieldMask':
          'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
    };

    KneelLogger.log('Request URL: $_autocompleteEndpoint', context: 'PlacesAPI');
    KneelLogger.log('Request body: ${jsonEncode(requestBody)}', context: 'PlacesAPI');

    try {
      final response = await http
          .post(
            Uri.parse(_autocompleteEndpoint),
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      KneelLogger.log('Response status: ${response.statusCode}', context: 'PlacesAPI');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        KneelLogger.log('Response data: ${response.body}', context: 'PlacesAPI');

        final suggestions = data['suggestions'] as List<dynamic>? ?? [];
        KneelLogger.log('Found ${suggestions.length} suggestions', context: 'PlacesAPI');

        if (suggestions.isEmpty) {
          KneelLogger.log('No suggestions returned from API', context: 'PlacesAPI');
          return [];
        }

        final results = <PlacePrediction>[];

        for (final suggestion in suggestions) {
          final placePrediction = suggestion['placePrediction'] as Map<String, dynamic>?;
          if (placePrediction == null) continue;

          // Extract placeId
          final placeId = placePrediction['placeId'] as String? ?? '';
          if (placeId.isEmpty) continue;

          // Extract display name from structuredFormat or text
          String displayName = '';
          String? formattedAddress;

          // Try structuredFormat first (preferred)
          final structuredFormat = placePrediction['structuredFormat'] as Map<String, dynamic>?;
          if (structuredFormat != null) {
            final mainText = structuredFormat['mainText'] as Map<String, dynamic>?;
            final secondaryText = structuredFormat['secondaryText'] as Map<String, dynamic>?;

            displayName = mainText?['text'] as String? ?? '';
            formattedAddress = secondaryText?['text'] as String?;
          }

          // Fallback to text field
          if (displayName.isEmpty) {
            final text = placePrediction['text'] as Map<String, dynamic>?;
            displayName = text?['text'] as String? ?? '';
          }

          if (displayName.isEmpty) continue;

          results.add(PlacePrediction(
            placeId: placeId,
            displayName: displayName,
            formattedAddress: formattedAddress,
          ));

          KneelLogger.log('Parsed: $displayName ($placeId)', context: 'PlacesAPI');
        }

        return results;
      } else {
        // Log the FULL error response for debugging
        KneelLogger.error(
          'PlacesAPI',
          'HTTP ${response.statusCode}',
        );

        // For 403 errors, log detailed diagnostic info
        if (response.statusCode == 403) {
          KneelLogger.warn('=== 403 DIAGNOSTIC INFO ===', context: 'PlacesAPI');
          KneelLogger.warn('Clean Web Request (no Android headers)', context: 'PlacesAPI');
          KneelLogger.warn('Response Body:', context: 'PlacesAPI');
          // Pretty print the response body
          try {
            final prettyBody = const JsonEncoder.withIndent('  ')
                .convert(jsonDecode(response.body));
            KneelLogger.warn(prettyBody, context: 'PlacesAPI');
          } catch (_) {
            KneelLogger.warn(response.body, context: 'PlacesAPI');
          }
          KneelLogger.warn('=== END DIAGNOSTIC ===', context: 'PlacesAPI');
        }

        // Parse error details if available
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final error = errorData['error'] as Map<String, dynamic>?;
          if (error != null) {
            final code = error['code'];
            final message = error['message'];
            final status = error['status'];
            KneelLogger.error(
              'PlacesAPI',
              'Google API Error: $status ($code) - $message',
            );
          }
        } catch (_) {
          // Ignore JSON parse errors
        }

        return [];
      }
    } on TimeoutException {
      KneelLogger.error('PlacesAPI', 'Request timed out after 10 seconds');
      return [];
    } catch (e, stackTrace) {
      KneelLogger.error('PlacesAPI', 'Exception: $e\n$stackTrace');
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
