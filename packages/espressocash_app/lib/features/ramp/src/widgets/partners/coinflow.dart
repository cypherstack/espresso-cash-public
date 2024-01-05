import 'package:auto_route/auto_route.dart';
import 'package:borsh_annotation/borsh_annotation.dart';
import 'package:dfunc/dfunc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:solana/dto.dart';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

import '../../../../../config.dart';
import '../../../../../core/amount.dart';
import '../../../../../core/currency.dart';
import '../../../../../di.dart';
import '../../../../../ui/web_view_screen.dart';
import '../../../../tokens/token.dart';
import '../../../models/ramp_partner.dart';
import '../../../screens/off_ramp_order_screen.dart';
import '../../../services/off_ramp_order_service.dart';
import '../../models/profile_data.dart';

extension BuildContextExt on BuildContext {
  Future<void> launchCoinflowOffRamp({
    required String address,
    required ProfileData profile,
  }) async {
    final blank = Uri.parse('about:blank');

    bool orderWasCreated = false;
    bool hasLoaded = false;

    Future<void> handleLoaded(InAppWebViewController controller) async {
      if (!hasLoaded) {
        await controller.loadFile(
          assetFilePath: 'assets/coinflow/index.html',
        );

        controller.addJavaScriptHandler(
          handlerName: 'init',
          callback: (args) => {
            'publicKey': address,
            'email': profile.email,
            'cluster': isProd ? 'mainnet' : 'staging',
            'rpcUrl': solanaRpcUrl,
            'token': Token.usdc.address,
          },
        );

        hasLoaded = true;
      }

      controller.addJavaScriptHandler(
        handlerName: 'coinflow',
        callback: (args) async {
          if (orderWasCreated) return null;

          if (args.first is! String) return null;

          const currency = Currency.usdc;

          final encodedTx = args.first as String;
          final tx = encodedTx.let(SignedTx.decode);
          final txData = await sl<SolanaClient>().calculateTxData(
            tx: tx,
            account: Ed25519HDPublicKey.fromBase58(address),
            currency: currency,
          );

          if (txData == null) {
            throw Exception('Failed to calculate tx data');
          }

          await sl<OffRampOrderService>()
              .createFromTx(
            tx: tx,
            slot: txData.slot,
            amount: CryptoAmount(
              value: txData.amount,
              cryptoCurrency: currency,
            ),
            partner: RampPartner.coinflow,
          )
              .then((order) {
            switch (order) {
              case Left<Exception, String>():
                break;
              case Right<Exception, String>(:final value):
                router.replace(OffRampOrderScreen.route(orderId: value));
            }
          });

          orderWasCreated = true;

          return tx.id;
        },
      );
    }

    await router.push(WebViewScreen.route(url: blank, onLoaded: handleLoaded));
  }
}

extension on SolanaClient {
  Future<({BigInt slot, int amount})?> calculateTxData({
    required SignedTx tx,
    required Ed25519HDPublicKey account,
    required CryptoCurrency currency,
  }) async {
    final tokenAddress = await findAssociatedTokenAddress(
      owner: account,
      mint: currency.token.publicKey,
    );

    final simulation = await rpcClient.simulateTransaction(
      tx.encode(),
      commitment: Commitment.confirmed,
      accounts: SimulateTransactionAccounts(
        encoding: Encoding.base64,
        addresses: [tokenAddress.toBase58()],
      ),
    );

    if (simulation.value.err != null) return null;

    final postBalance = simulation.value.accounts?.first.data?.getBalance();
    final preBalance = await rpcClient
        .getAccountInfo(
          tokenAddress.toBase58(),
          commitment: Commitment.confirmed,
          encoding: Encoding.base64,
        )
        .then((e) => e.value?.data?.getBalance());

    if (postBalance == null || preBalance == null) return null;

    return (
      slot: simulation.context.slot,
      amount: preBalance - postBalance,
    );
  }
}

extension on AccountData {
  int? getBalance() {
    try {
      final data = this;
      if (data is! BinaryAccountData) return null;

      final value = BinaryReader(
        Uint8List.fromList(data.data.skip(64).toList()).buffer.asByteData(),
      );

      return value.readU64().toInt();
    } on Object catch (error, stackTrace) {
      Sentry.captureException(error, stackTrace: stackTrace);

      return null;
    }
  }
}
