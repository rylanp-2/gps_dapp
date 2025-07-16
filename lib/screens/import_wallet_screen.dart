import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import '../services/secure_storage.dart';

class ImportWalletScreen extends StatefulWidget {
  const ImportWalletScreen({super.key});

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  final TextEditingController _controller = TextEditingController();
  final SecureStorageService _storage = SecureStorageService();

  String? _walletAddress;
  bool _walletExists = false;

  @override
  void initState() {
    super.initState();
    _loadWalletInfo();
  }

  Future<void> _loadWalletInfo() async {
    final privateKey = await _storage.getPrivateKey();
    if (privateKey != null) {
      final credentials = EthPrivateKey.fromHex(privateKey);
      final address = credentials.address;

      if (!mounted) return;
      setState(() {
        _walletExists = true;
        _walletAddress = address.hexEip55;
      });
    }
  }

  Future<void> _importPrivateKey() async {
    final privateKey = _controller.text.trim().replaceAll('0x', '');

    if (privateKey.length != 64 || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(privateKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid private key format')),
      );
      return;
    }

    await _storage.storePrivateKey(privateKey);
    await _loadWalletInfo();
    _controller.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallet imported successfully')),
    );
  }

  Future<void> _deletePrivateKey() async {
    await _storage.deletePrivateKey();
    if (!mounted) return;

    setState(() {
      _walletExists = false;
      _walletAddress = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallet deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_walletExists) ...[
                const Text(
                  'Wallet is already imported.',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Address:\n$_walletAddress',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _deletePrivateKey,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete Wallet'),
                ),
              ] else ...[
                const Text('Paste your private key:'),
                TextField(
                  controller: _controller,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Private key'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _importPrivateKey,
                  child: const Text('Import Wallet'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
