enum BillingPeriodMode { single, multiple }

BillingPeriodMode billingPeriodModeFromValue(Object? value) {
  final raw = value?.toString().trim().toLowerCase();
  return switch (raw) {
    'multiple' => BillingPeriodMode.multiple,
    _ => BillingPeriodMode.single,
  };
}
