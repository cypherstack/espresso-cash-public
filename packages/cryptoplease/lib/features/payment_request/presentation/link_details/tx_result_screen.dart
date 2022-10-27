import 'package:cryptoplease/core/transactions/create_transaction_link.dart';
import 'package:cryptoplease/gen/assets.gen.dart';
import 'package:cryptoplease/l10n/l10n.dart';
import 'package:cryptoplease/ui/app_bar.dart';
import 'package:cryptoplease/ui/colors.dart';
import 'package:cryptoplease/ui/content_padding.dart';
import 'package:cryptoplease/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:solana/solana.dart';
import 'package:url_launcher/url_launcher.dart';

class TxResultScreen extends StatelessWidget {
  const TxResultScreen({
    Key? key,
    required this.signature,
    required this.text,
    required this.icon,
  }) : super(key: key);

  final TransactionId? signature;
  final String text;
  final SvgGenImage icon;

  void _onViewTransaction() {
    final signature = this.signature;
    if (signature == null) return;

    launchUrl(Uri.parse(createTransactionLink(signature)));
  }

  @override
  Widget build(BuildContext context) => CpTheme.dark(
        child: Builder(
          builder: (context) => Scaffold(
            appBar: CpAppBar(),
            body: CpContentPadding(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    icon.svg(height: 50),
                    const SizedBox(height: 16),
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headline4
                          ?.copyWith(fontSize: 32),
                    ),
                    if (signature != null)
                      TextButton(
                        onPressed: _onViewTransaction,
                        child: Text(
                          context.l10n.viewTransaction,
                          style: const TextStyle(color: CpColors.yellowColor),
                        ),
                      ),
                    const SizedBox(height: kToolbarHeight),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
