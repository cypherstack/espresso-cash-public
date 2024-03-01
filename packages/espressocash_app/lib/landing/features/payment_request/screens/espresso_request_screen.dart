import 'package:flutter/material.dart';
import 'package:solana/solana_pay.dart';

import '../../../core/espresso_desktop.dart';
import '../../../core/espresso_mobile.dart';
import '../../../core/extensions.dart';
import 'request_screen.dart';

class EspressoRequestScreen extends StatelessWidget {
  const EspressoRequestScreen({super.key, required this.request});

  final SolanaPayRequest request;

  @override
  Widget build(BuildContext context) => isMobile
      ? EspressoMobileView(
          actionLink: Uri.parse(request.toUrl()),
          header: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                request.label == null
                    ? 'You have a request of'
                    : '${request.label} is requesting',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.23,
                ),
              ),
              Text(
                '${request.amount ?? 0} USDC',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 45,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          actionButtonText: 'Pay',
        )
      : EspressoDesktopView(
          actionLink: Uri.parse(request.toUrl()),
          title: request.headerTitle,
          subtitle: 'To complete the transaction, follow the steps below.',
        );
}
