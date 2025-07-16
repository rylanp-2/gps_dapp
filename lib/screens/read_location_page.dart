import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../services/ethereum.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';

class ReadLocationPage extends StatefulWidget {
  const ReadLocationPage({super.key});

  @override
  State<ReadLocationPage> createState() => _ReadLocationPageState();
}

class _ReadLocationPageState extends State<ReadLocationPage> {
  final EthereumService _ethService = EthereumService();
  late final MapController _mapController;
  String status = "Initializing...";
  bool loading = false;
  LatLng? _markerPosition;
  String timeDisplay = "";
  String timeAgoDisplay = "";


  void _recenterMap() {
    _mapController.move(_markerPosition!, _mapController.camera.zoom);
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initialize();

  }

  Future<void> _initialize() async {
    await _ethService.init();
    setState(() => status = "Ready");
  }

  Future<void> _readLocation() async {
    setState(() {
      loading = true;
      status = "Reading & decrypting...";
    });

    try {
      final data = await _ethService.readEncryptedLocation();
      final payload = data['payload'] as Uint8List;
      final timestamp = data['timestamp'] as BigInt;
      final iv = encrypt.IV(payload.sublist(0, 16));
      final ciphertext = encrypt.Encrypted(payload.sublist(16));
      final key = encrypt.Key.fromBase64("gNSDGqbQie5bPxHesrU+jg==");
      final encrypter = encrypt.Encrypter(
          encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final decrypted = encrypter.decrypt(ciphertext, iv: iv);
      final parts = decrypted.split(',');

      final lat = double.tryParse(parts[0]);
      final long = double.tryParse(parts[1]);

      if (lat != null && long != null) {
        DateTime date = DateTime.fromMillisecondsSinceEpoch(
            timestamp.toInt() * 1000, isUtc: true).toLocal();
        String formatted = DateFormat('HH:mm:ss  MM/dd/yyyy').format(date);

        DateTime now = DateTime.now();
        Duration difference = now.difference(date);


        String timeAgo = _formatDuration(difference);

        final pos = LatLng(lat, long);
        setState(() {
          _markerPosition = pos;
          status = "${parts[0]}, ${parts[1]}";
          timeDisplay = formatted;
          timeAgoDisplay = "$timeAgo ago";
          loading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(pos, 15.0);
        });

      } else {
        setState(() {
          status = "Invalid coordinates";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        status = "Error: $e";
        loading = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String formatted = "";
    if (duration.inSeconds < 60) {formatted = '${duration.inSeconds} seconds';}
    else if (duration.inMinutes == 1) {formatted =  '1 minute';}
    else if (duration.inMinutes < 60) {formatted =  '${duration.inMinutes} minutes';}
    else if (duration.inHours == 1) {formatted = '1 hour, ${duration.inMinutes - 60} minutes';}
    else if (duration.inHours < 24) {return '${duration.inHours} hours, ${duration.inMinutes - 60*duration.inHours} minutes';}
    else if (duration.inDays == 1) {return '1 day, ${duration.inHours - 24} hours';}
    else {formatted = '${duration.inDays} days, ${duration.inHours - 24*duration.inDays} hours';}
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Read Location Page"),
        centerTitle: true,
      ),
      body: _markerPosition == null
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for the map
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: const Center(
                child: Text(
                  "Read location to enable map view",
                  style: TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (loading) const CircularProgressIndicator(),
            if (!loading)
              Text(
                "$status\n$timeDisplay\n$timeAgoDisplay",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _readLocation,
              icon: const Icon(Icons.location_pin),
              label: const Text("Read Location"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      )
          : Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _markerPosition!,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.gps_dapp',
              ),
              MarkerLayer(
                rotate: false, // prevents marker from rotating with the map
                markers: [
                  Marker(
                    point: _markerPosition!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (loading) const CircularProgressIndicator(),
                    if (!loading)

                      // Box with displayed data
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(230),
                          borderRadius: BorderRadius.circular(8),
                        ),

                        // Text in box
                        child: Text.rich(
                          TextSpan(
                            text: "Coordinates: ",
                            style: const TextStyle(fontSize: 16), // base style
                            children: [
                              TextSpan(
                                text: "$status\n",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: "Timestamp: ",
                                style: const TextStyle(fontSize: 16),
                              ),
                              TextSpan(
                                text: "$timeDisplay\n",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: timeAgoDisplay,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 10),

                    // Refresh Button
                    ElevatedButton.icon(
                      onPressed: _readLocation,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Refresh Location"),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 75),
              child: FloatingActionButton(
                onPressed: _recenterMap,
                child: const Icon(Icons.my_location),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
