import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/state.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_logo.dart';
import '../widgets/tactile.dart';
import 'home_screen.dart';
import 'legal_screen.dart';
import 'onboarding_screen.dart';

/// Shown on the very first launch, right after the splash screen, and again
/// whenever the legal documents change. It says plainly what the game does
/// with data, links to the Privacy Policy and Terms of Use, and only lets the
/// player continue once they agree.
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  static const String routeName = '/consent';

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _agreed = false;
  bool _saving = false;

  late final TapGestureRecognizer _privacyLink = TapGestureRecognizer()
    ..onTap = () => LegalScreen.open(context, LegalDocument.privacyPolicy);
  late final TapGestureRecognizer _termsLink = TapGestureRecognizer()
    ..onTap = () => LegalScreen.open(context, LegalDocument.termsOfUse);

  @override
  void dispose() {
    _privacyLink.dispose();
    _termsLink.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_agreed || _saving) return;
    setState(() => _saving = true);
    final store = ref.read(onboardingStoreProvider);
    await store.acceptLegal(LegalInfo.version);
    final seenIntro = await store.hasSeenIntro();
    if (!mounted) return;
    // Consent first, then the intro on a first launch, then Home.
    Navigator.of(context).pushReplacementNamed(
      seenIntro ? HomeScreen.routeName : OnboardingScreen.routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final linkStyle = theme.textTheme.bodyMedium!.copyWith(
      color: scheme.primary,
      fontWeight: FontWeight.w800,
      decoration: TextDecoration.underline,
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        children: [
                          const AppLogo(size: 88),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Before you play',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'A quick look at how ${LegalInfo.appName} '
                            'handles your data.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const _Point(
                            icon: Icons.ondemand_video,
                            title: 'Ads keep the game free',
                            body:
                                'We show ads from Google AdMob. Google may use '
                                'your device\'s advertising ID and similar '
                                'info to show and measure ads, which can be '
                                'personalised.',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const _Point(
                            icon: Icons.phone_android,
                            title: 'Your games stay on your phone',
                            body:
                                'No account, no sign-in, no analytics. We do '
                                'not collect your personal info, and your '
                                'scores are never saved or sent anywhere.',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const _Point(
                            icon: Icons.tune,
                            title: 'You are in control',
                            body:
                                'Turn off personalised ads in your phone\'s '
                                'settings any time. You can reread these '
                                'documents in the game\'s Settings.',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Wraps onto two lines when the text is large.
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              TextButton(
                                key: const ValueKey('consent-privacy'),
                                onPressed: () => LegalScreen.open(
                                  context,
                                  LegalDocument.privacyPolicy,
                                ),
                                child: Text('Privacy Policy', style: linkStyle),
                              ),
                              Text('·', style: theme.textTheme.bodyMedium),
                              TextButton(
                                key: const ValueKey('consent-terms'),
                                onPressed: () => LegalScreen.open(
                                  context,
                                  LegalDocument.termsOfUse,
                                ),
                                child: Text('Terms of Use', style: linkStyle),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  MergeSemantics(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      onTap: () => setState(() => _agreed = !_agreed),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              key: const ValueKey('consent-checkbox'),
                              value: _agreed,
                              onChanged: (value) =>
                                  setState(() => _agreed = value ?? false),
                            ),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: theme.textTheme.bodySmall,
                                  children: [
                                    const TextSpan(
                                      text: 'I have read and agree to the ',
                                    ),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: linkStyle.copyWith(
                                        fontSize:
                                            theme.textTheme.bodySmall!.fontSize,
                                      ),
                                      recognizer: _privacyLink,
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Terms of Use',
                                      style: linkStyle.copyWith(
                                        fontSize:
                                            theme.textTheme.bodySmall!.fontSize,
                                      ),
                                      recognizer: _termsLink,
                                    ),
                                    const TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedOpacity(
                      opacity: _agreed ? 1 : 0.45,
                      duration: const Duration(milliseconds: 150),
                      child: ChunkyButton(
                        key: const ValueKey('consent-accept'),
                        label: 'AGREE & CONTINUE',
                        icon: Icons.check_circle,
                        onPressed: _continue,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InsetPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconDisc(
            icon: icon,
            background: scheme.primaryFixed,
            foreground: scheme.onPrimaryFixed,
          ),
          const SizedBox(width: AppSpacing.gutterSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
