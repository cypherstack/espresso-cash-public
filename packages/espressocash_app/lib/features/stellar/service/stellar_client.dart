import 'package:espressocash_api/espressocash_api.dart';
import 'package:injectable/injectable.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import '../../accounts/auth_scope.dart';
import '../constants.dart';
import '../models/stellar_wallet.dart';
import '../stellar_module.dart';

@LazySingleton(scope: authScope)
class StellarClient {
  const StellarClient(
    this._ecClient,
    this._stellarWallet,
    @stellar this._sdk,
    @soroban this._sorobanClient,
  );

  final StellarSDK _sdk;
  final SorobanServer _sorobanClient;
  final StellarWallet _stellarWallet;
  final EspressoCashClient _ecClient;

  Future<String> fetchToken({required KeyPair wallet}) {
    const moneygramAuthUrl = '$moneygramBaseUrl/auth';
    final moneygramDomain = Uri.parse(moneygramBaseUrl).host;
    const clientDomain = espressoClientDomain;

    final auth = WebAuth(
      moneygramAuthUrl,
      stellarNetwork,
      moneygramSigningKey,
      moneygramDomain,
    );

    return auth.jwtToken(
      wallet.accountId,
      [wallet],
      clientDomain: clientDomain,
      clientDomainSigningDelegate: (transactionXdr) async => _ecClient
          .signChallenge(
            MoneygramChallengeSignRequestDto(signedTx: transactionXdr),
          )
          .then((e) => e.signedTx),
    );
  }

  Future<double> getXlmBalance(String accountId) async {
    try {
      final account = await _sdk.accounts.account(accountId);
      final nativeAsset = AssetTypeNative();

      for (final balance in account.balances) {
        if (balance.assetType == nativeAsset.type) {
          return double.parse(balance.balance);
        }
      }
    } on Exception {
      return 0.0;
    }

    return 0.0;
  }

  Future<double?> getUsdcBalance(String accountId) async {
    try {
      final account = await _sdk.accounts.account(accountId);

      for (final balance in account.balances) {
        if (balance.assetCode == 'USDC' &&
            balance.assetIssuer == moneygramAssetIssuer) {
          return double.parse(balance.balance);
        }
      }

      return null;
    } on Exception {
      return null;
    }
  }

  Future<OperationResponse?> getPaymentByTxId(String txId) async {
    final operations = await _sdk.operations.forTransaction(txId).execute();

    return operations.records?.firstOrNull;
  }

  Future<bool> hasUsdcTrustline(String accountId, {double? amount}) async {
    try {
      final account = await _sdk.accounts.account(accountId);

      for (final balance in account.balances) {
        if (balance.assetCode == 'USDC' &&
            balance.assetIssuer == moneygramAssetIssuer) {
          if (amount != null) {
            final double currentBalance = double.parse(balance.balance);
            final double limit = double.tryParse(balance.limit ?? '0') ?? 0;

            return (currentBalance + amount) <= limit;
          }

          return true;
        }
      }

      return false;
    } on Exception {
      return false;
    }
  }

  Future<bool> createUsdcTrustline({
    required KeyPair userKeyPair,
    required double limit,
  }) async {
    final accountId = userKeyPair.accountId;
    final account = await _sdk.accounts.account(accountId);

    final usdc = AssetTypeCreditAlphaNum4('USDC', moneygramAssetIssuer);
    final ctob = ChangeTrustOperationBuilder(usdc, limit.toString());

    final transaction = TransactionBuilder(account)
        .addOperation(ctob.build())
        .build()
      ..sign(userKeyPair, stellarNetwork);

    final response = await _sdk.submitTransaction(transaction);

    return response.success;
  }

  Future<String?> submitTransactionFromXdrString(
    String xdr, {
    required KeyPair userKeyPair,
  }) async {
    final transaction = AbstractTransaction.fromEnvelopeXdrString(xdr)
        as Transaction
      ..sign(userKeyPair, stellarNetwork);

    final response = await _sorobanClient.sendTransaction(transaction);

    if (response.status == 'ERROR') {
      throw Exception('error');
    }

    return response.hash;
  }

  Future<GetTransactionResponse?> pollStatus(String transactionId) async {
    String? status = GetTransactionResponse.STATUS_NOT_FOUND;

    GetTransactionResponse? transactionResponse;
    while (status == GetTransactionResponse.STATUS_NOT_FOUND) {
      await Future<void>.delayed(_pollingInterval);

      transactionResponse = await _sorobanClient.getTransaction(transactionId);

      status =
          transactionResponse.status ?? GetTransactionResponse.STATUS_NOT_FOUND;
    }

    return transactionResponse;
  }

  Future<bool> sendUsdc(
    String accountId, {
    required String destinationAddress,
    required String memo,
    required String amount,
  }) async {
    final sourceAccount = await _sdk.accounts.account(accountId);

    final Asset usdcAsset =
        Asset.createNonNativeAsset('USDC', moneygramAssetIssuer);

    final transactionBuilder = TransactionBuilder(sourceAccount)
      ..addOperation(
        PaymentOperationBuilder(
          destinationAddress,
          usdcAsset,
          amount,
        ).build(),
      )
      ..addMemo(Memo.text(memo));

    final transaction = transactionBuilder.build()
      ..sign(_stellarWallet.keyPair, stellarNetwork);

    final response = await _sdk.submitTransaction(transaction);

    return response.success;
  }
}

const _pollingInterval = Duration(seconds: 5);
