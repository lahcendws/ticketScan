enum PaymentPlatform { android, ios, unsupported }

extension PaymentPlatformLabels on PaymentPlatform {
  String get storeName {
    switch (this) {
      case PaymentPlatform.android:
        return 'Google Play';
      case PaymentPlatform.ios:
        return 'App Store';
      case PaymentPlatform.unsupported:
        return 'plateforme non prise en charge';
    }
  }

  String get verificationValue {
    switch (this) {
      case PaymentPlatform.android:
        return 'android';
      case PaymentPlatform.ios:
        return 'ios';
      case PaymentPlatform.unsupported:
        return 'unsupported';
    }
  }
}

class PaymentPlatformResolver {
  static PaymentPlatform resolve({
    required bool isAndroid,
    required bool isIOS,
  }) {
    if (isAndroid) return PaymentPlatform.android;
    if (isIOS) return PaymentPlatform.ios;
    return PaymentPlatform.unsupported;
  }
}
