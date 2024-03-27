import 'package:espressocash_api/espressocash_api.dart';
import 'package:espressocash_common/espressocash_common.dart';
import 'package:injectable/injectable.dart';

import '../../../../features/blockchain/models/blockchain.dart';
import '../models/incoming_quote.dart';

@lazySingleton
class IncomingQuoteRepository {
  IncomingQuoteRepository({
    required EspressoCashClient ecClient,
  }) : _ecClient = ecClient;

  final EspressoCashClient _ecClient;

  Future<IncomingPaymentQuote> getQuote({
    required CryptoAmount amount,
    required String receiverAddress,
    required Blockchain senderBlockchain,
    required String senderAddress,
    required String? solanaReferenceAddress,
  }) async {
    final quote = await _ecClient.getIncomingDlnQuote(
      IncomingQuoteRequestDto(
        amount: amount.value,
        senderAddress: senderAddress,
        senderBlockchain: senderBlockchain.name,
        receiverAddress: receiverAddress,
        solanaReferenceAddress: solanaReferenceAddress,
      ),
    );

    return IncomingPaymentQuote(
      receiverAmount: CryptoAmount(
        cryptoCurrency: Currency.usdc,
        value: quote.receiverAmount,
      ),
      inputAmount: CryptoAmount(
        cryptoCurrency: Currency.usdc,
        value: quote.inputAmount,
      ),
      fee: CryptoAmount(
        cryptoCurrency: Currency.usdc,
        value: quote.feeInUsdc,
      ),
      tx: quote.tx,
      usdcInfo: quote.usdcInfo,
    );
  }
}
