# phone_otp_auth_ui

Reusable Flutter widgets for:

- phone login with country picker
- OTP verification
- country data and country search dialog

## Why this package exists

The current auth screens in this project are not a good direct copy or paste target because
they are coupled to:

- `AuthProvider`
- `GoRouter`
- TaybGo branding assets
- project-specific localization
- project theme helpers

The reusable layer should stay UI-only. Each app should keep its own:

- API client
- auth state management
- routing
- localization
- branding shell

## What is included

- `Country`
- `PhoneNumberValue`
- `CountryPickerDialog`
- `PhoneNumberField`
- `PhoneSignInForm`
- `OtpVerifyForm`
- `AuthUiStrings`

## Recommended usage

Use this package from each app through a local path dependency first:

```yaml
dependencies:
  phone_otp_auth_ui:
    path: packages/phone_otp_auth_ui
```

When you are ready to share it across repositories, move `packages/phone_otp_auth_ui`
to its own repo and consume it via git or a private package registry.

## Integration example

```dart
final authStrings = AuthUiStrings(
  phoneSignInTitle: l.welcomeBack,
  phoneSignInSubtitle: l.enterPhoneToSignIn,
  searchCountryHint: 'Search country...',
  phoneNumberLabel: l.phoneNumber,
  enterPhoneError: l.enterYourPhone,
  sendOtpLabel: l.sendOtp,
  otpVerifyTitle: l.verifyOtp,
  otpCodeLabel: l.otpCode,
  enterOtpError: l.enterOtpCode,
  verifyLabel: l.verify,
  changePhoneNumberLabel: l.changePhoneNumber,
  testOtpLabel: l.testOtpLabel,
  enterCodeSentToBuilder: l.enterCodeSentTo,
);
```

```dart
PhoneSignInForm(
  isLoading: auth.isLoading,
  errorText: auth.error,
  strings: authStrings,
  onSubmit: (value) async {
    final success = await auth.requestOtp(value.fullNumber);
    if (success && context.mounted) {
      context.go('/verify-otp');
    }
  },
)
```

```dart
OtpVerifyForm(
  phone: auth.phone ?? '',
  isLoading: auth.isLoading,
  errorText: auth.error,
  testOtp: auth.testOtp,
  strings: authStrings,
  onSubmit: (code) => auth.verifyOtp(code),
  onChangePhoneNumber: () {
    auth.clearError();
    Navigator.of(context).maybePop();
  },
)
```

## Architecture rule

Do not put `Provider`, `Riverpod`, `Bloc`, `GoRouter`, HTTP, or shared preferences
inside this package. Keep those concerns in the consuming app and pass them through
callbacks and simple data objects.
