import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/remote_config_keys.dart';
import '../services/remote_config_service.dart';

part 'remote_config_providers.g.dart';

// ── Service ───────────────────────────────────────────────────────────────────

@riverpod
RemoteConfigService remoteConfigService(RemoteConfigServiceRef ref) =>
    RemoteConfigService();

// ── UI flags ──────────────────────────────────────────────────────────────────

@riverpod
bool enableDarkMode(EnableDarkModeRef ref) => ref
    .watch(remoteConfigServiceProvider)
    .boolConfigValueProvider(RemoteConfigKeys.enableDarkMode);

@riverpod
bool showPremiumBanner(ShowPremiumBannerRef ref) => ref
    .watch(remoteConfigServiceProvider)
    .boolConfigValueProvider(RemoteConfigKeys.showPremiumBanner);

@riverpod
String onboardingVariant(OnboardingVariantRef ref) => ref
    .watch(remoteConfigServiceProvider)
    .stringConfigValueProvider(RemoteConfigKeys.onboardingVariant);

@riverpod
int homeGridColumns(HomeGridColumnsRef ref) => ref
    .watch(remoteConfigServiceProvider)
    .intConfigValueProvider(RemoteConfigKeys.homeGridColumns);

// ── Feature flags ─────────────────────────────────────────────────────────────

@riverpod
bool enableCheckout(EnableCheckoutRef ref) => ref
    .watch(remoteConfigServiceProvider)
    .boolConfigValueProvider(RemoteConfigKeys.enableCheckout);

@riverpod
bool enableNewSearch(EnableNewSearchRef ref) => ref
    .watch(remoteConfigServiceProvider)
    .boolConfigValueProvider(RemoteConfigKeys.enableNewSearch);

@riverpod
bool enableLiveChat(EnableLiveChatRef ref) => ref
    .watch(remoteConfigServiceProvider)
    .boolConfigValueProvider(RemoteConfigKeys.enableLiveChat);

// ── Config values ─────────────────────────────────────────────────────────────

@riverpod
int apiTimeoutSeconds(ApiTimeoutSecondsRef ref) => ref
    .watch(remoteConfigServiceProvider)
    .intConfigValueProvider(RemoteConfigKeys.apiTimeoutSeconds);

@riverpod
int maxCartItems(MaxCartItemsRef ref) => ref
    .watch(remoteConfigServiceProvider)
    .intConfigValueProvider(RemoteConfigKeys.maxCartItems);

@riverpod
String promoCode(PromoCodeRef ref) => ref
    .watch(remoteConfigServiceProvider)
    .stringConfigValueProvider(RemoteConfigKeys.promoCode);

@riverpod
double animationSpeedMultiplier(AnimationSpeedMultiplierRef ref) => ref
    .watch(remoteConfigServiceProvider)
    .doubleConfigValueProvider(RemoteConfigKeys.animationSpeedMultiplier);

// ── Direct string-literal keys (not defined in RemoteConfigKeys) ──────────────
// These test that the scanner detects raw string keys inside @riverpod providers.

@riverpod
bool legacyBannerEnabled(LegacyBannerEnabledRef ref) => ref
    .watch(remoteConfigServiceProvider)
    .boolConfigValueProvider('legacy_banner_enabled');

@riverpod
String appThemeColor(AppThemeColorRef ref) => ref
    .watch(remoteConfigServiceProvider)
    .stringConfigValueProvider('app_theme_color');

@riverpod
String cartBadgeStyle(CartBadgeStyleRef ref) => ref
    .watch(remoteConfigServiceProvider)
    .stringConfigValueProvider('cart_badge_style');

@riverpod
double animationSpeed(AnimationSpeedRef ref) => ref
    .watch(remoteConfigServiceProvider)
    .doubleConfigValueProvider('animation_speed');

// ── Code-only keys (intentionally absent from Firebase) ───────────────────────

@riverpod
bool debugMode(DebugModeRef ref) => ref
    .watch(remoteConfigServiceProvider)
    .boolConfigValueProvider(RemoteConfigKeys.debugMode);

@riverpod
bool experimentalFeatureV2(ExperimentalFeatureV2Ref ref) => ref
    .watch(remoteConfigServiceProvider)
    .boolConfigValueProvider(RemoteConfigKeys.experimentalFeatureV2);
