import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final TextEditingController _matriculeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  LatLng? currentPosition;
  String? errorMessage;
  List<dynamic>? alertes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showLoginDialog());
    _determinePosition();
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connexion'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _matriculeController,
                  decoration: const InputDecoration(
                    labelText: 'Matricule',
                  ),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Connexion'),
              onPressed: () {
                _login();
              },
            ),
          ],
        );
      },
    );
  }

  void _login() async {
    // Vous pouvez ajouter votre logique d'authentification ici
    print("Matricule: ${_matriculeController.text}");
    print("Password: ${_passwordController.text}");

    final response = await http.post(
      Uri.parse('https://tableau.ourworldtkpl.com/patrouille/login'), // Remplacez par l'URL de votre API
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'matricule': _matriculeController.text,
        'password': _passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      print('Response body: ${response.body}');
      final jsonResponse = jsonDecode(response.body);
      // Afficher le popup des alertes en attente
      setState(() {
        alertes = jsonResponse['alertes'];
      });
    } else if (response.statusCode == 301 || response.statusCode == 302) {
      final redirectedUri = Uri.parse(response.headers['location']!);
      final redirectedResponse = await http.post(
        redirectedUri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'matricule': _matriculeController.text,
          'password': _passwordController.text,
        }),
      );

      if (redirectedResponse.statusCode == 200) {
        print('Response body after redirection: ${redirectedResponse.body}');
        final jsonResponse = jsonDecode(redirectedResponse.body);

        // Afficher le popup des alertes en attente
        setState(() {
          alertes = jsonResponse['alertes'];
        });
      } else {
        _showErrorDialog('Failed to authenticate after redirection.', redirectedResponse.statusCode);
      }
    } else {
      _showErrorDialog('Failed to authenticate.', response.statusCode);
    }

    Navigator.of(context).pop();
  }

  Future<void> _determinePosition() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          errorMessage = 'Permission de localisation refusée';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        errorMessage = 'Les permissions de localisation sont refusées en permanence. Allez dans les paramètres pour les activer.';
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Impossible d\'obtenir la localisation : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Patrouille Map")),
      body: currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : alertes != null ? _showPendingAlerts(alertes!) : FlutterMap(
                  options: MapOptions(
          initialCenter: currentPosition!, // Utiliser la position actuelle comme centre
          initialZoom: 15.0,
                  ),
                  children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 80.0,
                height: 80.0,
                point: currentPosition!,
                child: Container(
                  child: Icon(Icons.location_on, color: Colors.green, size: 40.0),
                ),
              ),
            ],
          ),
                  ],
                ),
    );
  }

  void _showErrorDialog(String errorMessage, int statusCode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Erreur $statusCode'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(errorMessage),
              ],
            ),
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


  Widget _showPendingAlerts(List<dynamic> alerts) {
    return AlertDialog(
      title: Text('Alertes en Attente'),
      content: SingleChildScrollView(
        child: ListBody(
          children: alerts.map((alert) {
            if (alert['status'] == 'pending') {
              return ListTile(
                title: Text('Alerte'),
                subtitle: Text('Date et Heure: ${alert['created_at']}'),
                onTap: () {
                  _showAlertOnMap(alert); // Fermer le popup après avoir cliqué sur une alerte
                },
              );
            } else {
              return Container(); // Ne rien afficher si le statut n'est pas 'pending'
            }
          }).toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Fermer', style: TextStyle(color: Colors.red)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  void _showAlertOnMap(dynamic alert) {
    setState(() {
      currentPosition = LatLng(double.parse(alert['latitude']), double.parse(alert['longitude']));
      alertes = null;
    });
    // Vous pouvez ajouter toute autre logique pour centrer la carte ou afficher un marqueur
  }



}
