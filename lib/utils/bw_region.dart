import 'dart:convert';

import 'package:flutter/services.dart';

/// Baden-Württemberg (BW) region gate for the app.
///
/// Point-in-polygon check against the bundled BW boundary
/// (assets/geojson/baden-wuerttemberg.json). Mirrors the Laravel + web logic
/// so an address outside BW is blocked before submission. The Laravel API also
/// enforces this, so this is a UX convenience (the API is the source of truth).
class BwRegion {
  BwRegion._();

  /// Bounding box of Baden-Württemberg (fast pre-check + map camera bounds).
  static const double minLat = 47.53610229492199;
  static const double minLng = 7.512126922607649;
  static const double maxLat = 49.78755950927729;
  static const double maxLng = 10.505069732666186;
  static const double centerLat = 48.66183090209964;
  static const double centerLng = 9.008598327636918;

  /// Translation key + German fallback for the "outside BW" message.
  static const String outsideKey = 'onlyAvailableInBadenWurttemberg';
  static const String outsideTextDe =
      'Wir sind derzeit nur in Baden-Württemberg verfügbar.';

  static const String _assetPath = 'assets/geojson/baden-wuerttemberg.json';

  /// polygons: list of polygons; each polygon = list of rings; ring = list of [lng, lat].
  static List<List<List<List<double>>>>? _polygons;

  static Future<void> ensureLoaded() async {
    if (_polygons != null) return;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final data = json.decode(raw) as Map<String, dynamic>;
      final features = (data['features'] as List?) ?? [];
      final polys = <List<List<List<double>>>>[];
      for (final f in features) {
        final geom = (f as Map)['geometry'] as Map? ?? {};
        final type = geom['type'];
        final coords = geom['coordinates'] as List? ?? [];
        if (type == 'Polygon') {
          polys.add(_toPolygon(coords));
        } else if (type == 'MultiPolygon') {
          for (final poly in coords) {
            polys.add(_toPolygon(poly as List));
          }
        }
      }
      _polygons = polys;
    } on Object catch (_) {
      _polygons = []; // fail-open if asset missing
    }
  }

  static List<List<List<double>>> _toPolygon(List<dynamic> rings) {
    return rings
        .map<List<List<double>>>((ring) => (ring as List)
            .map<List<double>>((pt) => [
                  (pt[0] as num).toDouble(),
                  (pt[1] as num).toDouble(),
                ])
            .toList())
        .toList();
  }

  static bool isWithinBoundingBox(double lat, double lng) {
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  /// True when (lat,lng) is inside BW. Loads polygons on first use.
  /// Fails open (true) only when boundary data can't be loaded.
  static Future<bool> isWithin(double? lat, double? lng) async {
    if (lat == null || lng == null) return false;
    if (!isWithinBoundingBox(lat, lng)) return false;
    await ensureLoaded();
    final polys = _polygons ?? [];
    if (polys.isEmpty) return true;
    for (final rings in polys) {
      if (rings.isEmpty) continue;
      if (_pointInRing(lat, lng, rings[0])) {
        var inHole = false;
        for (var i = 1; i < rings.length; i++) {
          if (_pointInRing(lat, lng, rings[i])) {
            inHole = true;
            break;
          }
        }
        if (!inHole) return true;
      }
    }
    return false;
  }

  /// ring points are [lng, lat]
  static bool _pointInRing(double lat, double lng, List<List<double>> ring) {
    var inside = false;
    final n = ring.length;
    for (var i = 0, j = n - 1; i < n; j = i++) {
      final xi = ring[i][0];
      final yi = ring[i][1];
      final xj = ring[j][0];
      final yj = ring[j][1];
      final denom = (yj - yi) == 0 ? 1e-12 : (yj - yi);
      final intersect =
          ((yi > lat) != (yj > lat)) && (lng < (xj - xi) * (lat - yi) / denom + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }
}
