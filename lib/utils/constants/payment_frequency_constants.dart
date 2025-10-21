import '../../localization_manager.dart';

class PaymentFrequencyConstants {
  static const List<String> frequencies = [
    'Per Hour',
    'Per Day',
    'Per Week',
    'bi weekly',
    'Per Month',
  ];

  static Map<String, String> get frequencyLabels {
    return {
      'Per Hour': LocalizationManager.translate('per_hour'),
      'Per Day': LocalizationManager.translate('per_day'),
      'Per Week': LocalizationManager.translate('per_week'),
      'bi weekly': LocalizationManager.translate('bi_weekly'),
      'Per Month': LocalizationManager.translate('per_month'),
    };
  }
}
