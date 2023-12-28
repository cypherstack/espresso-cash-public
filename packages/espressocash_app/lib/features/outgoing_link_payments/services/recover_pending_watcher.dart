import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';
import 'package:uuid/uuid.dart';

import '../../../../config.dart';
import '../../../../core/amount.dart';
import '../../../../core/currency.dart';
import '../../../../core/escrow_private_key.dart';
import '../../activities/data/transaction_repository.dart';
import '../../tokens/token.dart';
import '../data/repository.dart';
import '../models/outgoing_link_payment.dart';

@injectable
class RecoverPendingWatcher implements Disposable {
  RecoverPendingWatcher(
    this._client,
    this._repository,
    this._transactionRepository, {
    @factoryParam required Ed25519HDPublicKey userPublicKey,
  }) : _userPublicKey = userPublicKey;

  final SolanaClient _client;
  final TransactionRepository _transactionRepository;
  final OLPRepository _repository;
  final Ed25519HDPublicKey _userPublicKey;

  StreamSubscription<void>? _transactionSubscription;

  void init() {
    _transactionSubscription =
        _transactionRepository.watchAllActivity().listen((transactions) async {
      for (final detail in transactions) {
        final tx = detail.tx;

        // Check if the transaction has interacted with the escrow smart contract
        final accounts = tx.compiledMessage.accountKeys;
        final hasInteractedWithEscrow = accounts.contains(
          Ed25519HDPublicKey.fromBase58(escrowScAddress),
        );

        if (!hasInteractedWithEscrow) continue;

        // Find the escrow address from accounts. It should either be in index 1 or 2.
        // Index 0 is the platforms account, index 1 or 2 should either be the user or the escrow.
        final escrow = accounts
            .getRange(1, 2)
            .where((e) => e != _userPublicKey)
            .firstOrNull;

        if (escrow == null) continue;

        final pendingEscrows = await _pendingEscrows();

        if (pendingEscrows.contains(escrow)) continue;

        final txList = await _client.rpcClient.getTransactionsList(
          escrow,
          limit: 2,
          commitment: Commitment.confirmed,
          encoding: Encoding.jsonParsed,
        );

        if (txList.length < 2) {
          final id = const Uuid().v4();

          final tx = txList.first;

          int amount = 0;

          for (final ix
              in tx.meta?.innerInstructions?.last.instructions ?? []) {
            if (ix is ParsedInstructionSplToken &&
                ix.parsed is ParsedSplTokenTransferInstruction) {
              final parsed = ix.parsed as ParsedSplTokenTransferInstruction;

              amount = int.parse(parsed.info.amount);
            }
          }

          final timestamp = detail.created ?? DateTime.now();

          await _repository.save(
            OutgoingLinkPayment(
              id: id,
              amount: CryptoAmount(
                value: amount,
                cryptoCurrency: const CryptoCurrency(token: Token.usdc),
              ),
              status: OLPStatus.recovered(escrowPubKey: escrow),
              created: timestamp,
              linksGeneratedAt: timestamp,
            ),
          );
        }
      }
    });
  }

  Future<List<EscrowPublicKey>> _pendingEscrows() async {
    final pending = await _repository.watchPending().first;

    final List<EscrowPublicKey> results = [];

    for (final p in pending) {
      final escrow = await p.status.mapOrNull(
        txCreated: (it) async => it.escrow.keyPair.then((v) => v.publicKey),
        txSent: (it) async => it.escrow.keyPair.then((v) => v.publicKey),
        txConfirmed: (it) async => it.escrow.keyPair.then((v) => v.publicKey),
        linkReady: (it) => it.escrow.keyPair.then((v) => v.publicKey),
        cancelTxCreated: (it) async =>
            it.escrow.keyPair.then((v) => v.publicKey),
        cancelTxFailure: (it) async =>
            it.escrow.keyPair.then((v) => v.publicKey),
        cancelTxSent: (it) async => it.escrow.keyPair.then((v) => v.publicKey),
        recovered: (it) async => it.escrowPubKey,
      );

      if (escrow != null) {
        results.add(escrow);
      }
    }

    return results;
  }

  @override
  void onDispose() => _transactionSubscription?.cancel();
}
