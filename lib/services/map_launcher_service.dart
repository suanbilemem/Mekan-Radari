import 'package:url_launcher/url_launcher.dart';

import '../models/place_model.dart';

class MapLauncherService {
  static Future<void> openPlace(PlaceModel place) async {
    final label = Uri.encodeComponent(place.name);
    final geoUri = Uri.parse(
      'geo:${place.lat},${place.lng}?q=${place.lat},${place.lng}($label)',
    );

    try {
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      return;
    } catch (_) {
      // Fall back to the web URL below.
    }

    final webUri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${place.lat},${place.lng}',
    });

    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}
