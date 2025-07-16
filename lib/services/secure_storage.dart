import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> storePrivateKey(String privateKey) async {
    await _storage.write(key: 'wallet_private_key', value: privateKey);
  }

  Future<String?> getPrivateKey() async {
    return await _storage.read(key: 'wallet_private_key');
  }

  Future<void> deletePrivateKey() async {
    await _storage.delete(key: 'wallet_private_key');
  }

  Future<bool> hasPrivateKey() async {
    return (await getPrivateKey()) != null;
  }
}