import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solana/solana_pay.dart';

import '../../../l10n/device_locale.dart';
import '../../../l10n/l10n.dart';
import '../../../ui/app_bar.dart';
import '../../../ui/button.dart';
import '../../../ui/colors.dart';
import '../../../ui/theme.dart';
import '../../conversion_rates/widgets/extensions.dart';
import '../../currency/models/amount.dart';
import '../widgets/merchant_logo_icon.dart';

class OTRConfirmationScreen extends StatelessWidget {
  const OTRConfirmationScreen({
    super.key,
    required this.request,
    required this.amount,
    this.message,
  });

  final TransactionRequestInfo request;
  final CryptoAmount amount;
  final String? message;

  void _handleSubmitted(BuildContext context) {
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return CpTheme.black(
      child: Scaffold(
        appBar: const CpAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: MerchantLogoIcon(logoUrl: request.icon),
              ),
              Text(
                request.label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 38),
              Text(
                amount.format(context.locale, maxDecimals: 2),
                style: const TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 42),
              if (message case final message?)
                _Item(
                  title: 'Message',
                  content: message,
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: CpButton(
                  text: context.l10n.pay,
                  minWidth: width,
                  onPressed: () => _handleSubmitted(context),
                  size: CpButtonSize.big,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(
              color: CpColors.darkDividerColor,
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(child: Text(content)),
            ],
          ),
        ),
      );
}

class OTRConfirmationRoute extends GoRouteData {
  const OTRConfirmationRoute(this.$extra);

  final OTRConfirmationParams $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      OTRConfirmationScreen(
        request: $extra.request,
        amount: $extra.amount,
        message: $extra.message,
      );
}

typedef OTRConfirmationParams = ({
  TransactionRequestInfo request,
  CryptoAmount amount,
  String? message,
});
