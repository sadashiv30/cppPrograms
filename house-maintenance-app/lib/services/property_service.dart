import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/home_profile.dart';

/// Wraps the Rentcast public property API.
/// Free tier: 500 requests/month — sign up at https://app.rentcast.io
class PropertyService {
  static const _base = 'https://api.rentcast.io/v1';

  /// Looks up property details by address.
  /// Returns null on failure; throws [PropertyServiceException] on API error.
  static Future<HomeProfile> fetchByAddress(
      String address, String apiKey) async {
    if (apiKey.trim().isEmpty) {
      throw PropertyServiceException(
          'No API key set. Add your Rentcast key in Settings → Home Profile.');
    }

    final uri = Uri.parse('$_base/properties').replace(
      queryParameters: {'address': address.trim(), 'limit': '1'},
    );

    late http.Response response;
    try {
      response = await http
          .get(uri, headers: {'X-Api-Key': apiKey.trim()})
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw PropertyServiceException('Network error: $e');
    }

    if (response.statusCode == 401) {
      throw PropertyServiceException(
          'Invalid API key. Check your Rentcast key in Settings.');
    }
    if (response.statusCode == 404) {
      throw PropertyServiceException(
          'Address not found. Try a more specific address (e.g. include city and state).');
    }
    if (response.statusCode == 429) {
      throw PropertyServiceException(
          'API rate limit reached. Free tier allows 500 requests/month.');
    }
    if (response.statusCode != 200) {
      throw PropertyServiceException(
          'API error ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(response.body);

    // Rentcast returns an array
    final List<dynamic> results = body is List ? body : [body];
    if (results.isEmpty) {
      throw PropertyServiceException(
          'No property found for that address.');
    }

    return _parse(results.first as Map<String, dynamic>);
  }

  static HomeProfile _parse(Map<String, dynamic> d) {
    final features = d['features'] as Map<String, dynamic>? ?? {};

    return HomeProfile(
      address: d['addressLine1'] as String? ?? d['formattedAddress'] as String? ?? '',
      city: d['city'] as String? ?? '',
      state: d['state'] as String? ?? '',
      zip: d['zipCode'] as String? ?? '',
      yearBuilt: d['yearBuilt'] as int?,
      bedrooms: d['bedrooms'] as int?,
      bathrooms: (d['bathrooms'] as num?)?.toDouble(),
      sqft: (d['squareFootage'] as num?)?.toDouble(),
      propertyType: d['propertyType'] as String?,
      heatingType: features['heating'] as String?,
      coolingType: features['cooling'] as String?,
      roofType: features['roofType'] as String?,
      foundationType: features['foundationType'] as String?,
      hasPool: _parseBool(features['pool']),
      parkingType: features['parkingType'] as String?,
    );
  }

  static bool? _parseBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is int) return v != 0;
    return null;
  }
}

class PropertyServiceException implements Exception {
  final String message;
  const PropertyServiceException(this.message);
  @override
  String toString() => message;
}
