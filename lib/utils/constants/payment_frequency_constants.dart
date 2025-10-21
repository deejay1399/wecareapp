import '../../localization_manager.dart';

class PaymentFrequencyConstants {
  static List<String> frequencies = [
    LocalizationManager.translate('per_hour'),
    LocalizationManager.translate('per_day'),
    LocalizationManager.translate('per_week'),
    LocalizationManager.translate('bi_weekly'),
    LocalizationManager.translate('per_month'),
  ];

  static Map<String, String> frequencyLabels = {
    'per_hour': LocalizationManager.translate('per_hour'),
    'per_day': LocalizationManager.translate('per_day'),
    'per_week': LocalizationManager.translate('per_week'),
    'bi_weekly': LocalizationManager.translate('bi_weekly'),
    'per_month': LocalizationManager.translate('per_month'),
  };
}
