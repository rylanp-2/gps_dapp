import 'package:flutter/material.dart';
import 'send_location_page.dart';
import 'read_location_page.dart';
import 'import_wallet_screen.dart';
import '../services/secure_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SecureStorageService _storage = SecureStorageService();
  bool _walletConnected = false;

  @override
  void initState() {
    super.initState();
    _checkWalletConnection();
  }

  Future<void> _checkWalletConnection() async {
    final hasKey = await _storage.hasPrivateKey();
    if (!mounted) return;
    setState(() {
      _walletConnected = hasKey;
    });
  }

  Future<void> _navigateToImportWallet(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ImportWalletScreen()),
    );
    _checkWalletConnection(); // Refresh wallet status on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GPS DApp Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _walletConnected
                  ? "Wallet connected ✅"
                  : "Wallet not connected ❌",
              style: TextStyle(
                fontSize: 16,
                color: _walletConnected ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _navigateToImportWallet(context),
              child: const Text("Connect Wallet"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _walletConnected
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SendLocationPage()),
                );
              }
                  : null, // Disabled if wallet not connected
              child: const Text("Send Location"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _walletConnected
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReadLocationPage()),
                );
              }
                  : null,
              child: const Text("Read Location"),
            ),
          ],
        ),
      ),
    );
  }
}
