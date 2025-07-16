import 'package:flutter/material.dart';
import '../services/ethereum.dart';
import '../services/location.dart';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:math';

class SendLocationPage extends StatefulWidget {
  const SendLocationPage({super.key});

  @override
  State<SendLocationPage> createState() => _SendLocationPageState();
}

class _SendLocationPageState extends State<SendLocationPage> {
  final EthereumService _ethService = EthereumService();
  String status = "Initializing...";
  bool loading = false;
  String estimateDisplay = "";
  String costDisplay = "";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _ethService.init();

    // Create random bytes to put in for the gas estimate
    final costEstimate = await _ethService.estimateGasCost(Uint8List.fromList(List.generate(16, (_) => Random().nextInt(256))));
    estimateDisplay = """
      Estimations:
      Gas: ${costEstimate['estimatedGas']} Gas
      Gas price: ${costEstimate['gasPriceGwei'].toStringAsFixed(5)} Gwei
      Cost in ETH: ${costEstimate['estimatedCostEth'].toStringAsFixed(10)} ETH
      Cost in CAD: \$${costEstimate['estimatedCostCAD'].toStringAsFixed(2)} 
    """;
    setState(() => status = "Ready");
  }

  Uint8List encryptCoords(String latLong) {
    final key = encrypt.Key.fromBase64("gNSDGqbQie5bPxHesrU+jg==");
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(latLong, iv: iv);
    return Uint8List.fromList(iv.bytes + encrypted.bytes);
  }

  Future<void> _sendLocation() async {
    setState(() {
      loading = true;
      status = "Encrypting & sending...";
    });

    try {
      final position = await getCurrentLocation(context);
      final latLong = "${position.latitude},${position.longitude}";
      final payload = encryptCoords(latLong);
      final costInfo = await _ethService.sendEncryptedLocation(payload);
      setState(() {
        status = "Location sent!";
        costDisplay = """
          Gas used: ${costInfo['actualGasUsed']} Gas
          Gas price: ${costInfo['gasPriceGwei'].toStringAsFixed(5)} Gwei
          Cost in ETH: ${costInfo['actualCostEth'].toStringAsFixed(10)} ETH
          Cost in CAD: \$${costInfo['actualCostCAD'].toStringAsFixed(2)}
          """;
        loading = false;
      });
    } catch (e) {
      setState(() {
        status = "$e";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Send Location Page")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading) const CircularProgressIndicator(),
            Text(status, style: const TextStyle(fontSize: 18), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendLocation,
              child: const Text("Send Location"),
            ),
            const SizedBox(height: 20),
            Text(estimateDisplay, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 5),
            Text(costDisplay, style: const TextStyle(fontSize: 14, color: Colors.deepPurple), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
