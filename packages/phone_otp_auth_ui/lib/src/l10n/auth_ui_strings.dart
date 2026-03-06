class AuthUiStrings {
  const AuthUiStrings({
    this.phoneSignInTitle = 'Welcome back',
    this.phoneSignInSubtitle = 'Enter your phone number to sign in',
    this.searchCountryHint = 'Search country...',
    this.phoneNumberLabel = 'Phone number',
    this.phoneHintText = '5XXXXXXXX',
    this.enterPhoneError = 'Enter your phone number',
    this.sendOtpLabel = 'Send OTP',
    this.otpVerifyTitle = 'Verify OTP',
    this.otpCodeLabel = 'OTP code',
    this.otpCodeHintText = '------',
    this.enterOtpError = 'Enter the OTP code',
    this.verifyLabel = 'Verify',
    this.changePhoneNumberLabel = 'Change phone number',
    this.testOtpLabel = 'Test OTP:',
    this.enterCodeSentToBuilder,
  });

  final String phoneSignInTitle;
  final String phoneSignInSubtitle;
  final String searchCountryHint;
  final String phoneNumberLabel;
  final String phoneHintText;
  final String enterPhoneError;
  final String sendOtpLabel;
  final String otpVerifyTitle;
  final String otpCodeLabel;
  final String otpCodeHintText;
  final String enterOtpError;
  final String verifyLabel;
  final String changePhoneNumberLabel;
  final String testOtpLabel;
  final String Function(String phone)? enterCodeSentToBuilder;

  String enterCodeSentTo(String phone) {
    return enterCodeSentToBuilder?.call(phone) ??
        'Enter the code sent to $phone';
  }
}
