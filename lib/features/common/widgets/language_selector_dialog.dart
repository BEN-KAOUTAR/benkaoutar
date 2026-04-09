import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/localization/translation_extension.dart';

class LanguageSelectorDialog extends StatelessWidget {
  const LanguageSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentLocale = appState.locale.languageCode;

    final languages = [
      {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
      {'code': 'ar', 'name': 'العربية', 'flag': '🇲🇦'},
      {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('select_language'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...languages.map((lang) {
              final isSelected = currentLocale == lang['code'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () {
                    appState.setLocale(Locale(lang['code']!));
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.1) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 16),
                        Text(
                          lang['name']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

void showLanguageSelector(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const LanguageSelectorDialog(),
  );
}
