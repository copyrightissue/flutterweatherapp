import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RadarMap extends StatefulWidget {
  @override
  _RadarMapState createState() => _RadarMapState();
}

class _RadarMapState extends State<RadarMap> {
  late MapController mapController;
  String? radarLayerUrl;  // Store the radar layer URL here

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    addRadarLayer();
  }
 // this is almost the same as the ionic version
  void addRadarLayer() async {
    try {
      final response = await http.get(Uri.parse('https://api.rainviewer.com/public/weather-maps.json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        //get latest radar data only last frame
        final latestRadarData = data['radar']['past'].last;
        setState(() {
          radarLayerUrl = "${data['host']}${latestRadarData['path']}/512/{z}/{x}/{y}/2/1_1.png";
        });
      }
    } catch (e) {
      print('Failed to fetch radar data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: mapController,
        options: const MapOptions(
          initialCenter: LatLng(46.8721, -113.9940),
          initialZoom: 8,
        ), //mapoptions
        //adding children is no longer layer: or layers: but children:
        children: [
          //tilelayerwidget is now TileLayer and tilelayeroptions depreciated
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ), //tile
          if (radarLayerUrl != null) //  add the radar layer if available
            TileLayer(
              urlTemplate: radarLayerUrl!, // Directly use the radar URL
              additionalOptions: const {
                'opacity': '0.65',
              },
            ), //tile
        ],
      ), //fluttermap
    ); //scaffold
  }
}
