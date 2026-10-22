import 'package:flutter/material.dart';

import '../../legal/legal_content.dart';
import '../theme/app_spacing.dart';
import '../widgets/tactile.dart';

export '../../legal/legal_content.dart';

/// Shows one legal document, readable offline.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});

  final LegalDocument document;

  static const String routeName = '/legal';

  /// Opens [document] on top of the current screen.
  static Future<void> open(BuildContext context, LegalDocument document) =>
      Navigator.of(context).pushNamed(routeName, arguments: document);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
                  SizedBox(
                    height: 64,
                    child: Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.arrow_back,
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: AppSpacing.gutterSm),
                        Expanded(
                          child: Text(
                            document.title,
                            key: const ValueKey('legal-title'),
                            style: theme.textTheme.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last updated: ${LegalInfo.effectiveDate}',
                              style: theme.textTheme.labelMedium!.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            SelectableText(
                              'Also online: ${document.url}',
                              key: const ValueKey('legal-url'),
                              style: theme.textTheme.labelMedium!.copyWith(
                                color: scheme.primary,
                              ),
                            ),
                            for (final section in document.sections) ...[
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                section.heading,
                                style: theme.textTheme.titleMedium,
                              ),
                              for (final paragraph in section.paragraphs) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  paragraph,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
