import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../state/locale_notifier.dart';
import 'theme.dart';

/// Idiomas suportados, cada nome exibido no próprio idioma para que
/// alguém que não lê o idioma atual ainda encontre o seu.
const _languages = <(Locale, String)>[
  (Locale('pt'), 'Português (Brasil)'),
  (Locale('en'), 'English'),
];

Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const SafeArea(child: _SettingsPanel()),
  );
}

class _SettingsPanel extends ConsumerWidget {
  const _SettingsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(localeProvider);
    // Idioma efetivo (se null, segue o do sistema já resolvido).
    final activeCode =
        selected?.languageCode ?? Localizations.localeOf(context).languageCode;

    return Container(
      decoration: const BoxDecoration(
        color: BoardColors.chassis,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.black45, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: BoardColors.creamDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(l10n.settings.toUpperCase(),
              style: BoardText.wordmark.copyWith(fontSize: 18)),
          const SizedBox(height: 18),
          Text(l10n.language.toUpperCase(), style: BoardText.stencil),
          const SizedBox(height: 10),
          for (final (locale, label) in _languages)
            _LanguageRow(
              label: label,
              selected: locale.languageCode == activeCode,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(locale);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}

/// Linha de idioma com LED indicando a seleção atual.
class _LanguageRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? BoardColors.rec
                    : BoardColors.rec.withValues(alpha: 0.25),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: BoardColors.rec.withValues(alpha: 0.8),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Oswald',
                fontSize: 16,
                letterSpacing: 0.5,
                color: selected ? BoardColors.cream : BoardColors.creamDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
