import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'alerte.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Position currentPosition;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    currentPosition = await Geolocator.getCurrentPosition();
    setState(() {});  // Refresh UI with the current position
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Patrouille Map")),
        body: (currentPosition != null) ? FlutterMap(
          options: MapOptions(
            center: LatLng(currentPosition.latitude, currentPosition.longitude),
            zoom: 13.0,
          ),
          layers: [
            TileLayerOptions(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: ['a', 'b', 'c'],
            ),
          ],
        ) : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _showAlertDetailsPopup(List<Alerte> alertes) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Alertes Assignées"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: alertes.map((alerte) => ListTile(
              title: Text(alerte.pseudo),
              subtitle: Text("${alerte.latitude}, ${alerte.longitude} - ${alerte.status}"),
            )).toList(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

}
