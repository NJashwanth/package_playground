class RemoteConfigKeys {
  // ── UI flags ──────────────────────────────────────────────────────────────
  static const String enableDarkMode = 'enable_dark_mode';
  static const String showPremiumBanner = 'show_premium_banner';
  static const String onboardingVariant = 'onboarding_variant';
  static const String homeGridColumns = 'home_grid_columns';

  // ── Feature flags ─────────────────────────────────────────────────────────
  static const String enableCheckout = 'enable_checkout';
  static const String enableNewSearch = 'enable_new_search';
  static const String enableLiveChat = 'enable_live_chat';

  // ── Config values ─────────────────────────────────────────────────────────
  static const String apiTimeoutSeconds = 'api_timeout_seconds';
  static const String maxCartItems = 'max_cart_items';
  static const String promoCode = 'promo_code';
  static const String animationSpeedMultiplier = 'animation_speed_multiplier';

  // ── Code-only keys (intentionally absent from Firebase Remote Config) ─────
  // These exist in code but not in the console, so they should trigger the
  // code_only_keys policy when the audit runs.
  static const String debugMode = 'debug_mode';
  static const String experimentalFeatureV2 = 'experimental_feature_v2';
}
