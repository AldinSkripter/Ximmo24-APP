import 'package:ebroker/utils/map/app_map_controller.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';

class OsmMapControllerImpl implements AppMapController {
  OsmMapControllerImpl(this.controller);
  final fm.MapController controller;

  @override
  Future<void> animateTo(LatLng position, {double zoom = 15}) async {
    controller.move(position, zoom);
  }
}
