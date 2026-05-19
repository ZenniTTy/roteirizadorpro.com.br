import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

/// OSM tile usage policy (ADR-0016): every screen that renders OSM tiles must
/// show an always-visible attribution that tappably opens
/// https://www.openstreetmap.org/copyright.
RichAttributionWidget osmAttribution() => RichAttributionWidget(
      alignment: AttributionAlignment.bottomLeft,
      showFlutterMapAttribution: false,
      attributions: [
        TextSourceAttribution(
          'OpenStreetMap contributors',
          onTap: () => launchUrl(
            Uri.parse('https://www.openstreetmap.org/copyright'),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
