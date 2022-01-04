import 'package:solana/solana.dart';
import 'package:test/test.dart';

import 'config.dart';

void main() {
  test(
    'accountSubscribe must return account owned by the system program',
    () async {
      const originalLamports = lamportsPerSol;
      final sender = await Ed25519HDKeyPair.random();
      final recipient = await Ed25519HDKeyPair.random();
      final rpcClient = RpcClient(devnetRpcUrl);
      final signature = await rpcClient.requestAirdrop(
        sender.address,
        originalLamports,
      );

      final subscriptionClient =
          await SubscriptionClient.connect(devnetWebsocketUrl);

      final result =
          await subscriptionClient.signatureSubscribe(signature).first;
      expect(result.err, isNull);

      // System program
      final accountStream = subscriptionClient.accountSubscribe(sender.address);

      // Now send some tokens
      await createTestSolanaClient().transferLamports(
        destination: recipient.address,
        commitment: Commitment.confirmed,
        lamports: lamportsPerSol ~/ 2,
        source: sender,
      );

      final account = await accountStream.firstWhere(
        (Account data) => true,
      );

      expect(account.lamports, lessThan(originalLamports));
    },
    timeout: Timeout(Duration(minutes: 1)),
  );
}