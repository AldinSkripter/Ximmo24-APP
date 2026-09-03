import 'package:ebroker/app/app_localization.dart';
import 'package:flutter/cupertino.dart';

extension TranslateString on String {
  String translate(BuildContext context) {
    return (AppLocalization.of(context)!.getTranslatedValues(this) ?? this)
        .trim();
  }

  /// Keeps server-managed text authoritative while preventing blank labels
  /// when a newly added key has not been populated in every language yet.
  String translateWithFallback(
    BuildContext context, {
    required String english,
    required String german,
  }) {
    final translated = translate(context);
    if (translated.isNotEmpty && translated != this) {
      return translated;
    }

    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code == 'de' ? german : english;
  }
}
