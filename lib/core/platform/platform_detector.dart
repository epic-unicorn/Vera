import 'package:universal_platform/universal_platform.dart';

/// Thin wrapper around [UniversalPlatform] that provides platform booleans
/// used throughout Vera to conditionally enable features (e.g., Isar, biometrics).
class PlatformDetector {
  const PlatformDetector._();

  /// True when running inside a web browser.
  static bool get isWeb => UniversalPlatform.isWeb;

  /// True when running natively on Android.
  static bool get isAndroid => UniversalPlatform.isAndroid;

  /// True when running natively on iOS.
  static bool get isIOS => UniversalPlatform.isIOS;

  /// True when running on any native mobile device (Android or iOS).
  static bool get isMobile =>
      UniversalPlatform.isAndroid || UniversalPlatform.isIOS;

  /// True when the local encrypted vault is available on this platform.
  /// Requires Isar + flutter_secure_storage native support.
  static bool get isVaultSupported => isMobile;

  /// True when local biometric auth is potentially available.
  /// Actual availability is confirmed at runtime by [local_auth].
  static bool get isBiometricPlatform => isMobile;

  /// True when on-device ML Kit is available (Android / iOS only).
  static bool get isMlKitSupported => isMobile;

  /// True when QR scanning is available (camera required).
  static bool get isQrScanSupported => isMobile;

  /// True when speech-to-text is supported on this platform.
  static bool get isSpeechSupported => isMobile;
}
