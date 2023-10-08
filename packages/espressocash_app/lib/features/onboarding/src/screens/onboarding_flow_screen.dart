import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/router_wrapper.dart';
import '../../../../di.dart';
import '../../../../routes.gr.dart';
import '../../../profile/screens/manage_profile_screen.dart';
import '../data/onboarding_repository.dart';
import 'no_email_and_password_screen.dart';
import 'view_recovery_phrase_screen.dart';

@RoutePage()
class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  static const route = OnboardingFlowRoute.new;

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen>
    with RouterWrapper {
  void _handleNoEmailAndPasswordCompleted() =>
      router?.push(ViewRecoveryPhraseScreen.route(onDone: _openProfileScreen));

  void _handleComplete() {
    sl<OnboardingRepository>().hasConfirmedPassphrase = true;
    router?.parent()?.pop();
  }

  void _openProfileScreen() =>
      router?.push(ManageProfileScreen.route(onSubmitted: _handleComplete));

  @override
  PageRouteInfo get initialRoute => sl<OnboardingRepository>()
          .hasConfirmedPassphrase
      ? ManageProfileScreen.route(onSubmitted: _handleComplete) as PageRouteInfo
      : NoEmailAndPasswordScreen.route(
          onDone: _handleNoEmailAndPasswordCompleted,
        );

  @override
  Widget build(BuildContext context) => AutoRouter(key: routerKey);
}