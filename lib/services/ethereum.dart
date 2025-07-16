import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter/services.dart';
import 'secure_storage.dart';
import 'dart:convert';

class EthereumService {

  final String _rpcUrl = "https://eth-sepolia.g.alchemy.com/v2/1_debAwqmdVWYsbj_C4Td";
  final SecureStorageService _storageService = SecureStorageService();


  late Web3Client _client;
  late EthPrivateKey _credentials;
  late DeployedContract _contract;

  late ContractFunction _updateLocation;
  late ContractFunction _readLocation;

  EthereumService() {
    _client = Web3Client(_rpcUrl, Client());
  }

  Future<void> init() async {
    final privateKey = await _storageService.getPrivateKey();

    if (privateKey == null) {
      throw Exception("Private key not found. Import wallet first.");
    }
    _credentials = EthPrivateKey.fromHex(privateKey);

    // Load ABI from local asset file
    final abi = await rootBundle.loadString("assets/abi/contract_abi.json");

    final contractAddress =
    EthereumAddress.fromHex("0x51fafAC9c240dF3E9ac9Df8e08151dFf6aAb0B2C");

    _contract = DeployedContract(
      ContractAbi.fromJson(abi, "GPS"),
      contractAddress,
    );

    _updateLocation = _contract.function("updateLocation");
    _readLocation = _contract.function("readLocation");
  }

  // Future<void> sendEncryptedLocation(Uint8List payloadBytes) async {
  //   await _client.sendTransaction(
  //     _credentials,
  //     Transaction.callContract(
  //       contract: _contract,
  //       function: _updateLocation,
  //       parameters: [payloadBytes],
  //     ),
  //     chainId: 11155111, // Sepolia
  //   );
  //
  //
  // }

  Future<Map<String, dynamic>> readEncryptedLocation() async {
    final result = await _client.call(
      contract: _contract,
      function: _readLocation,
      params: [],
    );

    return {
      'payload': result[0] as Uint8List,
      'timestamp': result[1] as BigInt,
    };
  }

  Future<Map<String, dynamic>> sendEncryptedLocation(Uint8List payloadBytes) async {

    final gasEstimate = await estimateGasCost(payloadBytes);
    final estimatedGas = gasEstimate['estimatedGas'];
    final gasPrice = gasEstimate['gasPrice'];
    final gasPriceGwei = gasEstimate['gasPriceGwei'];
    final exchangeRate = gasEstimate['exchangeRate'];

    // Send transaction
    final txHash = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: _updateLocation,
        parameters: [payloadBytes],
        gasPrice: gasPrice,
        maxGas: estimatedGas.toInt(),
      ),
      chainId: 11155111,
    );

    // Wait for receipt
    final receipt = await _waitForReceipt(txHash);
    final actualGasUsed = receipt.gasUsed;
    final actualCostInEth = EtherAmount.inWei(actualGasUsed! * gasPrice.getInWei)
        .getValueInUnit(EtherUnit.ether);
    final actualCostInCAD = actualCostInEth * exchangeRate;

    return {
      'estimatedGas': estimatedGas.toInt(),
      'gasPriceGwei': gasPriceGwei,
      'txHash': txHash,
      'actualGasUsed': actualGasUsed.toInt(),
      'actualCostEth': actualCostInEth,
      'actualCostCAD': actualCostInCAD,
    };
  }

  Future<Map<String, dynamic>> estimateGasCost(Uint8List payloadBytes) async {
    final gasPrice = await _client.getGasPrice();

    final estimatedGas = await _client.estimateGas(
      sender: _credentials.address,
      to: _contract.address,
      data: Transaction.callContract(
        contract: _contract,
        function: _updateLocation,
        parameters: [payloadBytes],
      ).data,
    );

    final gasCostInWei = estimatedGas * gasPrice.getInWei;
    final gasCostInEth = EtherAmount.inWei(gasCostInWei)
        .getValueInUnit(EtherUnit.ether);

    final exchangeRate = await _getEthToCadRate();
    final costInCAD = gasCostInEth * exchangeRate;

    return {
      'estimatedGas': estimatedGas.toInt(),
      'gasPrice': gasPrice,
      'gasPriceGwei': gasPrice.getValueInUnit(EtherUnit.gwei),
      'estimatedCostEth': gasCostInEth,
      'estimatedCostCAD': costInCAD,
      'exchangeRate': exchangeRate,
    };
  }

  Future<double> _getEthToCadRate() async {
    final response = await get(Uri.parse(
      'https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=cad',
    ));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['ethereum']['cad']?.toDouble() ?? 0.0;
    } else {
      throw Exception('Failed to fetch ETH to CAD exchange rate');
    }
  }

  Future<TransactionReceipt> _waitForReceipt(String txHash) async {
    int attempts = 0;
    TransactionReceipt? receipt;

    // Optional: wait for transaction to appear
    while ((await _client.getTransactionByHash(txHash)) == null && attempts < 60) {
      await Future.delayed(Duration(seconds: 2));
      attempts++;
    }

    // Reset counter and check for receipt
    attempts = 0;
    while (receipt == null && attempts < 150) {
      await Future.delayed(Duration(seconds: 2));
      receipt = await _client.getTransactionReceipt(txHash);
      attempts++;
    }

    if (receipt == null) {
      throw Exception("Transaction receipt not found after 5 minutes.");
    }

    return receipt;
  }
}


