import 'package:decimal/decimal.dart';
import 'package:dfunc/dfunc.dart';
import 'package:espressocash_common/dart.dart';
import 'package:espressocash_common/flutter.dart';
import 'package:flutter/material.dart';

import '../../../di.dart';
import '../../../l10n/l10n.dart';
import '../../../routing.dart';
import '../../../ui/button.dart';
import '../../../ui/colors.dart';
import '../../../ui/info_icon.dart';
import '../../../ui/value_stream_builder.dart';
import '../../conversion_rates/services/watch_user_fiat_balance.dart';
import '../../ramp/widgets/ramp_buttons.dart';
import '../../tokens/widgets/token_icon.dart';
import '../../wallet_flow/screens/wallet_screen.dart';

class InvestmentHeader extends StatefulWidget {
  const InvestmentHeader({super.key});

  @override
  State<InvestmentHeader> createState() => _InvestmentHeaderState();
}

class _InvestmentHeaderState extends State<InvestmentHeader> {
  bool _showMore = false;

  void _handleInfoPressed() => setState(() => _showMore = !_showMore);

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(color: CpColors.darkBackground),
        child: _HeaderSwitcher(
          first: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Headline(onInfo: _handleInfoPressed),
                    const SizedBox(height: 4),
                    const _Amount(),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
              const _Buttons(),
            ],
          ),
          second: _Info(onClose: _handleInfoPressed),
          showMore: _showMore,
        ),
      );
}

class _Buttons extends StatelessWidget {
  const _Buttons();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xff202020)),
        child: ValueStreamBuilder<bool>(
          create: () =>
              sl<WatchUserFiatBalance>().call().map((it) => it.isZero),
          builder: (context, isZeroAmount) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FittedBox(
                  child: Text(
                    isZeroAmount
                        ? context.l10n.fundYourAccount
                        : context.l10n.investmentHeaderButtonsTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 17,
                      letterSpacing: 0.23,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isZeroAmount) ...[
                      Flexible(
                        child: CpButton(
                          minWidth: 250,
                          size: CpButtonSize.wide,
                          text: context.l10n.sendMoney,
                          onPressed: () => const WalletRoute().go(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const AddCashButton(size: CpButtonSize.wide),
                    if (!isZeroAmount) ...[
                      const SizedBox(width: 8),
                      const CashOutButton(size: CpButtonSize.wide),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
}

class _Info extends StatelessWidget {
  const _Info({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const CircleAvatar(
              maxRadius: 14,
              backgroundColor: CpColors.yellowColor,
              child: CpInfoIcon(iconColor: CpColors.darkBackgroundColor),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                context.l10n.usdcInfo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.10,
                ),
              ),
            ),
            const SizedBox(height: 16),
            CpButton(
              text: context.l10n.close,
              onPressed: onClose,
              minWidth: 250,
              size: CpButtonSize.wide,
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
}

class _Amount extends StatelessWidget {
  const _Amount();

  @override
  Widget build(BuildContext context) => ValueStreamBuilder<Amount>(
        create: () => sl<WatchUserFiatBalance>().call(),
        builder: (context, amount) {
          final formattedAmount = amount.format(
            context.locale,
            roundInteger: amount.isZero,
          );

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FittedBox(
                child: Text(
                  formattedAmount,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ).let((it) => amount.isZero ? it : Flexible(child: it)),
              const SizedBox(width: 8),
              const TokenIcon(token: Token.usdc, size: 30),
            ],
          );
        },
      );
}

class _Headline extends StatelessWidget {
  const _Headline({required this.onInfo});

  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.23,
    );

    return Text.rich(
      TextSpan(
        text: context.l10n.cryptoCashBalance,
        style: baseStyle,
        children: [
          const TextSpan(text: ' ', style: baseStyle),
          WidgetSpan(
            child: GestureDetector(
              onTap: onInfo,
              child: Text.rich(
                TextSpan(
                  text: context.l10n.inUsdc,
                  style: baseStyle.copyWith(color: CpColors.yellowColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on Amount {
  bool get isZero => decimal == Decimal.zero;
}

class _HeaderSwitcher extends StatefulWidget {
  const _HeaderSwitcher({
    required this.first,
    required this.second,
    required this.showMore,
  });

  final Widget first;
  final Widget second;
  final bool showMore;

  @override
  State<_HeaderSwitcher> createState() => _HeaderSwitcherState();
}

class _HeaderSwitcherState extends State<_HeaderSwitcher> {
  double? _firstChildHeight;

  @override
  void didUpdateWidget(covariant _HeaderSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    _firstChildHeight = null;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (_firstChildHeight == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _firstChildHeight = context.size?.height;
              });
            });
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 100),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: !widget.showMore
                ? widget.first
                : SizedBox(
                    key: const ValueKey('second'),
                    height: _firstChildHeight,
                    child: widget.second,
                  ),
          );
        },
      );
}
