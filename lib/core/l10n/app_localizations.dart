import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('en'),
    Locale('ar'),
    Locale('nl'),
    Locale('fr'),
    Locale('de'),
  ];

  bool get isArabic => locale.languageCode == 'ar';

  String _t(String en, String ar, {String? nl, String? fr, String? de}) {
    switch (locale.languageCode) {
      case 'ar':
        return ar;
      case 'nl':
        return nl ?? en;
      case 'fr':
        return fr ?? en;
      case 'de':
        return de ?? en;
      default:
        return en;
    }
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Navigation Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  String get overview => _t(
    'Overview',
    'Ã™â€ Ã˜Â¸Ã˜Â±Ã˜Â© Ã˜Â¹Ã˜Â§Ã™â€¦Ã˜Â©',
    nl: 'Overzicht',
    fr: 'AperÃƒÂ§u',
    de: 'ÃƒÅ“bersicht',
  );
  String get approvals => _t(
    'Approvals',
    'Ã˜Â§Ã™â€žÃ™â€¦Ã™Ë†Ã˜Â§Ã™ÂÃ™â€šÃ˜Â§Ã˜Âª',
    nl: 'Goedkeuringen',
    fr: 'Approbations',
    de: 'Genehmigungen',
  );
  String get drivers => _t(
    'Drivers',
    'Ã˜Â§Ã™â€žÃ˜Â³Ã˜Â§Ã˜Â¦Ã™â€šÃ™Ë†Ã™â€ ',
    nl: 'Chauffeurs',
    fr: 'Chauffeurs',
    de: 'Fahrer',
  );
  String get support => _t(
    'Support',
    'Ã˜Â§Ã™â€žÃ˜Â¯Ã˜Â¹Ã™â€¦',
    nl: 'Ondersteuning',
    fr: 'Support',
    de: 'Support',
  );
  String get profile => _t(
    'Profile',
    'Ã˜Â§Ã™â€žÃ™â€¦Ã™â€žÃ™Â Ã˜Â§Ã™â€žÃ˜Â´Ã˜Â®Ã˜ÂµÃ™Å ',
    nl: 'Profiel',
    fr: 'Profil',
    de: 'Profil',
  );
  String get signOut => _t(
    'Sign out',
    'Ã˜ÂªÃ˜Â³Ã˜Â¬Ã™Å Ã™â€ž Ã˜Â§Ã™â€žÃ˜Â®Ã˜Â±Ã™Ë†Ã˜Â¬',
    nl: 'Uitloggen',
    fr: 'DÃƒÂ©connexion',
    de: 'Abmelden',
  );

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Sign In Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  String get adminDashboard => _t(
    'Admin Dashboard',
    'Ã™â€žÃ™Ë†Ã˜Â­Ã˜Â© Ã˜ÂªÃ˜Â­Ã™Æ’Ã™â€¦ Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â´Ã˜Â±Ã™Â',
    nl: 'Beheerdersdashboard',
    fr: 'Tableau de bord admin',
    de: 'Admin-Dashboard',
  );
  String get manageDescription => _t(
    'Manage drivers, restaurants, orders, and support from one place.',
    'Ã˜Â¥Ã˜Â¯Ã˜Â§Ã˜Â±Ã˜Â© Ã˜Â§Ã™â€žÃ˜Â³Ã˜Â§Ã˜Â¦Ã™â€šÃ™Å Ã™â€  Ã™Ë†Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â·Ã˜Â§Ã˜Â¹Ã™â€¦ Ã™Ë†Ã˜Â§Ã™â€žÃ˜Â·Ã™â€žÃ˜Â¨Ã˜Â§Ã˜Âª Ã™Ë†Ã˜Â§Ã™â€žÃ˜Â¯Ã˜Â¹Ã™â€¦ Ã™â€¦Ã™â€  Ã™â€¦Ã™Æ’Ã˜Â§Ã™â€  Ã™Ë†Ã˜Â§Ã˜Â­Ã˜Â¯.',
    nl: 'Beheer chauffeurs, restaurants, bestellingen en ondersteuning vanuit ÃƒÂ©ÃƒÂ©n plek.',
    fr: 'GÃƒÂ©rez les chauffeurs, restaurants, commandes et le support depuis un seul endroit.',
    de: 'Verwalten Sie Fahrer, Restaurants, Bestellungen und Support von einem Ort aus.',
  );
  String get welcomeBack => _t(
    'Welcome back',
    'Ã™â€¦Ã˜Â±Ã˜Â­Ã˜Â¨Ã™â€¹Ã˜Â§ Ã˜Â¨Ã˜Â¹Ã™Ë†Ã˜Â¯Ã˜ÂªÃ™Æ’',
    nl: 'Welkom terug',
    fr: 'Bon retour',
    de: 'Willkommen zurÃƒÂ¼ck',
  );
  String get enterPhoneToSignIn => _t(
    'Enter your phone number to sign in',
    'Ã˜Â£Ã˜Â¯Ã˜Â®Ã™â€ž Ã˜Â±Ã™â€šÃ™â€¦ Ã™â€¡Ã˜Â§Ã˜ÂªÃ™ÂÃ™Æ’ Ã™â€žÃ˜ÂªÃ˜Â³Ã˜Â¬Ã™Å Ã™â€ž Ã˜Â§Ã™â€žÃ˜Â¯Ã˜Â®Ã™Ë†Ã™â€ž',
    nl: 'Voer uw telefoonnummer in om in te loggen',
    fr: 'Entrez votre numÃƒÂ©ro de tÃƒÂ©lÃƒÂ©phone pour vous connecter',
    de: 'Geben Sie Ihre Telefonnummer ein, um sich anzumelden',
  );
  String get phoneNumber => _t(
    'Phone Number',
    'Ã˜Â±Ã™â€šÃ™â€¦ Ã˜Â§Ã™â€žÃ™â€¡Ã˜Â§Ã˜ÂªÃ™Â',
    nl: 'Telefoonnummer',
    fr: 'NumÃƒÂ©ro de tÃƒÂ©lÃƒÂ©phone',
    de: 'Telefonnummer',
  );
  String get sendOtp => _t(
    'Send OTP',
    'Ã˜Â¥Ã˜Â±Ã˜Â³Ã˜Â§Ã™â€ž Ã˜Â±Ã™â€¦Ã˜Â² Ã˜Â§Ã™â€žÃ˜ÂªÃ˜Â­Ã™â€šÃ™â€š',
    nl: 'OTP verzenden',
    fr: 'Envoyer OTP',
    de: 'OTP senden',
  );
  String get enterYourPhone => _t(
    'Enter your phone number',
    'Ã˜Â£Ã˜Â¯Ã˜Â®Ã™â€ž Ã˜Â±Ã™â€šÃ™â€¦ Ã™â€¡Ã˜Â§Ã˜ÂªÃ™ÂÃ™Æ’',
    nl: 'Voer uw telefoonnummer in',
    fr: 'Entrez votre numÃƒÂ©ro de tÃƒÂ©lÃƒÂ©phone',
    de: 'Geben Sie Ihre Telefonnummer ein',
  );

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ OTP Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  String get verifyOtp => _t(
    'Verify OTP',
    'Ã˜Â§Ã™â€žÃ˜ÂªÃ˜Â­Ã™â€šÃ™â€š Ã™â€¦Ã™â€  Ã˜Â§Ã™â€žÃ˜Â±Ã™â€¦Ã˜Â²',
    nl: 'OTP verifiÃƒÂ«ren',
    fr: 'VÃƒÂ©rifier OTP',
    de: 'OTP verifizieren',
  );
  String enterCodeSentTo(String phone) => _t(
    'Enter the code sent to $phone',
    'Ã˜Â£Ã˜Â¯Ã˜Â®Ã™â€ž Ã˜Â§Ã™â€žÃ˜Â±Ã™â€¦Ã˜Â² Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â±Ã˜Â³Ã™â€ž Ã˜Â¥Ã™â€žÃ™â€° $phone',
    nl: 'Voer de code in die is verzonden naar $phone',
    fr: 'Entrez le code envoyÃƒÂ© au $phone',
    de: 'Geben Sie den Code ein, der an $phone gesendet wurde',
  );
  String get testOtpLabel => _t(
    'Test OTP: ',
    'Ã˜Â±Ã™â€¦Ã˜Â² Ã˜Â§Ã˜Â®Ã˜ÂªÃ˜Â¨Ã˜Â§Ã˜Â±: ',
    nl: 'Test OTP: ',
    fr: 'OTP de test : ',
    de: 'Test-OTP: ',
  );
  String get otpCode => _t(
    'OTP Code',
    'Ã˜Â±Ã™â€¦Ã˜Â² Ã˜Â§Ã™â€žÃ˜ÂªÃ˜Â­Ã™â€šÃ™â€š',
    nl: 'OTP-code',
    fr: 'Code OTP',
    de: 'OTP-Code',
  );
  String get enterOtpCode => _t(
    'Enter the OTP code',
    'Ã˜Â£Ã˜Â¯Ã˜Â®Ã™â€ž Ã˜Â±Ã™â€¦Ã˜Â² Ã˜Â§Ã™â€žÃ˜ÂªÃ˜Â­Ã™â€šÃ™â€š',
    nl: 'Voer de OTP-code in',
    fr: 'Entrez le code OTP',
    de: 'Geben Sie den OTP-Code ein',
  );
  String get verify => _t(
    'Verify',
    'Ã˜ÂªÃ˜Â­Ã™â€šÃ™â€š',
    nl: 'VerifiÃƒÂ«ren',
    fr: 'VÃƒÂ©rifier',
    de: 'Verifizieren',
  );
  String get changePhoneNumber => _t(
    'Change phone number',
    'Ã˜ÂªÃ˜ÂºÃ™Å Ã™Å Ã˜Â± Ã˜Â±Ã™â€šÃ™â€¦ Ã˜Â§Ã™â€žÃ™â€¡Ã˜Â§Ã˜ÂªÃ™Â',
    nl: 'Telefoonnummer wijzigen',
    fr: 'Changer le numÃƒÂ©ro de tÃƒÂ©lÃƒÂ©phone',
    de: 'Telefonnummer ÃƒÂ¤ndern',
  );

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Sign Out Dialog Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  String get signOutConfirm => _t(
    'Are you sure you want to sign out?',
    'Ã™â€¡Ã™â€ž Ã˜Â£Ã™â€ Ã˜Âª Ã™â€¦Ã˜ÂªÃ˜Â£Ã™Æ’Ã˜Â¯ Ã˜Â£Ã™â€ Ã™Æ’ Ã˜ÂªÃ˜Â±Ã™Å Ã˜Â¯ Ã˜ÂªÃ˜Â³Ã˜Â¬Ã™Å Ã™â€ž Ã˜Â§Ã™â€žÃ˜Â®Ã˜Â±Ã™Ë†Ã˜Â¬Ã˜Å¸',
    nl: 'Weet u zeker dat u wilt uitloggen?',
    fr: 'ÃƒÅ tes-vous sÃƒÂ»r de vouloir vous dÃƒÂ©connecter ?',
    de: 'Sind Sie sicher, dass Sie sich abmelden mÃƒÂ¶chten?',
  );
  String get cancel => _t(
    'Cancel',
    'Ã˜Â¥Ã™â€žÃ˜ÂºÃ˜Â§Ã˜Â¡',
    nl: 'Annuleren',
    fr: 'Annuler',
    de: 'Abbrechen',
  );

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Dashboard Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  String get overviewSubtitle => _t(
    "Here's what's happening across your platform today.",
    'Ã˜Â¥Ã™â€žÃ™Å Ã™Æ’ Ã™â€¦Ã˜Â§ Ã™Å Ã˜Â­Ã˜Â¯Ã˜Â« Ã˜Â¹Ã˜Â¨Ã˜Â± Ã™â€¦Ã™â€ Ã˜ÂµÃ˜ÂªÃ™Æ’ Ã˜Â§Ã™â€žÃ™Å Ã™Ë†Ã™â€¦.',
    nl: 'Dit is wat er vandaag op uw platform gebeurt.',
    fr: "Voici ce qui se passe sur votre plateforme aujourd'hui.",
    de: 'Das passiert heute auf Ihrer Plattform.',
  );
  String get totalOrders => _t(
    'Total Orders',
    'Ã˜Â¥Ã˜Â¬Ã™â€¦Ã˜Â§Ã™â€žÃ™Å  Ã˜Â§Ã™â€žÃ˜Â·Ã™â€žÃ˜Â¨Ã˜Â§Ã˜Âª',
    nl: 'Totaal bestellingen',
    fr: 'Total commandes',
    de: 'Gesamtbestellungen',
  );
  String get driversOnline => _t(
    'Drivers Online',
    'Ã˜Â§Ã™â€žÃ˜Â³Ã˜Â§Ã˜Â¦Ã™â€šÃ™Ë†Ã™â€  Ã˜Â§Ã™â€žÃ™â€¦Ã˜ÂªÃ˜ÂµÃ™â€žÃ™Ë†Ã™â€ ',
    nl: 'Chauffeurs online',
    fr: 'Chauffeurs en ligne',
    de: 'Fahrer online',
  );
  String get restaurants => _t(
    'Restaurants',
    'Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â·Ã˜Â§Ã˜Â¹Ã™â€¦',
    nl: 'Restaurants',
    fr: 'Restaurants',
    de: 'Restaurants',
  );
  String get pendingItems => _t(
    'Pending Items',
    'Ã˜Â¹Ã™â€ Ã˜Â§Ã˜ÂµÃ˜Â± Ã™â€¦Ã˜Â¹Ã™â€žÃ™â€šÃ˜Â©',
    nl: 'Openstaande items',
    fr: 'Ãƒâ€°lÃƒÂ©ments en attente',
    de: 'Ausstehende Elemente',
  );
  String get ordersByStatus => _t(
    'Orders by Status',
    'Ã˜Â§Ã™â€žÃ˜Â·Ã™â€žÃ˜Â¨Ã˜Â§Ã˜Âª Ã˜Â­Ã˜Â³Ã˜Â¨ Ã˜Â§Ã™â€žÃ˜Â­Ã˜Â§Ã™â€žÃ˜Â©',
    nl: 'Bestellingen op status',
    fr: 'Commandes par statut',
    de: 'Bestellungen nach Status',
  );
  String get total => _t(
    'total',
    'Ã˜Â§Ã™â€žÃ˜Â¥Ã˜Â¬Ã™â€¦Ã˜Â§Ã™â€žÃ™Å ',
    nl: 'totaal',
    fr: 'total',
    de: 'gesamt',
  );
  String get noOrderData => _t(
    'No order data available',
    'Ã™â€žÃ˜Â§ Ã˜ÂªÃ™Ë†Ã˜Â¬Ã˜Â¯ Ã˜Â¨Ã™Å Ã˜Â§Ã™â€ Ã˜Â§Ã˜Âª Ã˜Â·Ã™â€žÃ˜Â¨Ã˜Â§Ã˜Âª',
    nl: 'Geen bestelgegevens beschikbaar',
    fr: 'Aucune donnÃƒÂ©e de commande disponible',
    de: 'Keine Bestelldaten verfÃƒÂ¼gbar',
  );
  String get orders => _t(
    'orders',
    'Ã˜Â·Ã™â€žÃ˜Â¨Ã˜Â§Ã˜Âª',
    nl: 'bestellingen',
    fr: 'commandes',
    de: 'Bestellungen',
  );
  String get fleetStatus => _t(
    'Fleet Status',
    'Ã˜Â­Ã˜Â§Ã™â€žÃ˜Â© Ã˜Â§Ã™â€žÃ˜Â£Ã˜Â³Ã˜Â·Ã™Ë†Ã™â€ž',
    nl: 'Vlootstatus',
    fr: 'Ãƒâ€°tat de la flotte',
    de: 'Flottenstatus',
  );
  String get driversOnlineLabel => _t(
    'drivers online',
    'Ã˜Â³Ã˜Â§Ã˜Â¦Ã™â€šÃ™Ë†Ã™â€  Ã™â€¦Ã˜ÂªÃ˜ÂµÃ™â€žÃ™Ë†Ã™â€ ',
    nl: 'chauffeurs online',
    fr: 'chauffeurs en ligne',
    de: 'Fahrer online',
  );
  String get totalDrivers => _t(
    'Total drivers',
    'Ã˜Â¥Ã˜Â¬Ã™â€¦Ã˜Â§Ã™â€žÃ™Å  Ã˜Â§Ã™â€žÃ˜Â³Ã˜Â§Ã˜Â¦Ã™â€šÃ™Å Ã™â€ ',
    nl: 'Totaal chauffeurs',
    fr: 'Total chauffeurs',
    de: 'Fahrer gesamt',
  );
  String get online => _t(
    'Online',
    'Ã™â€¦Ã˜ÂªÃ˜ÂµÃ™â€ž',
    nl: 'Online',
    fr: 'En ligne',
    de: 'Online',
  );
  String get offline => _t(
    'Offline',
    'Ã˜ÂºÃ™Å Ã˜Â± Ã™â€¦Ã˜ÂªÃ˜ÂµÃ™â€ž',
    nl: 'Offline',
    fr: 'Hors ligne',
    de: 'Offline',
  );
  String get activeDrivers => _t(
    'Active Drivers',
    'Ã˜Â§Ã™â€žÃ˜Â³Ã˜Â§Ã˜Â¦Ã™â€šÃ™Ë†Ã™â€  Ã˜Â§Ã™â€žÃ™â€ Ã˜Â´Ã˜Â·Ã™Ë†Ã™â€ ',
    nl: 'Actieve chauffeurs',
    fr: 'Chauffeurs actifs',
    de: 'Aktive Fahrer',
  );
  String get shown => _t(
    'shown',
    'Ã™â€¦Ã˜Â¹Ã˜Â±Ã™Ë†Ã˜Â¶',
    nl: 'getoond',
    fr: 'affichÃƒÂ©',
    de: 'angezeigt',
  );
  String get noDriversAvailable => _t(
    'No drivers available',
    'Ã™â€žÃ˜Â§ Ã™Å Ã™Ë†Ã˜Â¬Ã˜Â¯ Ã˜Â³Ã˜Â§Ã˜Â¦Ã™â€šÃ™Ë†Ã™â€  Ã™â€¦Ã˜ÂªÃ˜Â§Ã˜Â­Ã™Ë†Ã™â€ ',
    nl: 'Geen chauffeurs beschikbaar',
    fr: 'Aucun chauffeur disponible',
    de: 'Keine Fahrer verfÃƒÂ¼gbar',
  );
  String get needsAttention => _t(
    'Needs Attention',
    'Ã™Å Ã˜Â­Ã˜ÂªÃ˜Â§Ã˜Â¬ Ã˜Â§Ã™â€ Ã˜ÂªÃ˜Â¨Ã˜Â§Ã™â€¡',
    nl: 'Aandacht vereist',
    fr: 'NÃƒÂ©cessite attention',
    de: 'Erfordert Aufmerksamkeit',
  );
  String get pendingDriverApprovals => _t(
    'Pending driver approvals',
    'Ã™â€¦Ã™Ë†Ã˜Â§Ã™ÂÃ™â€šÃ˜Â§Ã˜Âª Ã˜Â§Ã™â€žÃ˜Â³Ã˜Â§Ã˜Â¦Ã™â€šÃ™Å Ã™â€  Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â¹Ã™â€žÃ™â€šÃ˜Â©',
    nl: 'Openstaande chauffeursgoedkeuringen',
    fr: 'Approbations de chauffeurs en attente',
    de: 'Ausstehende Fahrergenehmigungen',
  );
  String get pendingRestaurantApprovals => _t(
    'Pending restaurant approvals',
    'Ã™â€¦Ã™Ë†Ã˜Â§Ã™ÂÃ™â€šÃ˜Â§Ã˜Âª Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â·Ã˜Â§Ã˜Â¹Ã™â€¦ Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â¹Ã™â€žÃ™â€šÃ˜Â©',
    nl: 'Openstaande restaurantgoedkeuringen',
    fr: 'Approbations de restaurants en attente',
    de: 'Ausstehende Restaurantgenehmigungen',
  );
  String get openSupportTickets => _t(
    'Open support tickets',
    'Ã˜ÂªÃ˜Â°Ã˜Â§Ã™Æ’Ã˜Â± Ã˜Â§Ã™â€žÃ˜Â¯Ã˜Â¹Ã™â€¦ Ã˜Â§Ã™â€žÃ™â€¦Ã™ÂÃ˜ÂªÃ™Ë†Ã˜Â­Ã˜Â©',
    nl: 'Open supporttickets',
    fr: 'Tickets de support ouverts',
    de: 'Offene Support-Tickets',
  );
  String get retry => _t(
    'Retry',
    'Ã˜Â¥Ã˜Â¹Ã˜Â§Ã˜Â¯Ã˜Â© Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â­Ã˜Â§Ã™Ë†Ã™â€žÃ˜Â©',
    nl: 'Opnieuw proberen',
    fr: 'RÃƒÂ©essayer',
    de: 'Erneut versuchen',
  );
  String get noOrdersData => _t(
    'No orders data',
    'Ã™â€žÃ˜Â§ Ã˜ÂªÃ™Ë†Ã˜Â¬Ã˜Â¯ Ã˜Â¨Ã™Å Ã˜Â§Ã™â€ Ã˜Â§Ã˜Âª Ã˜Â·Ã™â€žÃ˜Â¨Ã˜Â§Ã˜Âª',
    nl: 'Geen bestelgegevens',
    fr: 'Aucune donnÃƒÂ©e de commande',
    de: 'Keine Bestelldaten',
  );
  String activeOfShown(int active, int total) => _t(
    '$active active of $total shown',
    '$active Ã™â€ Ã˜Â´Ã˜Â· Ã™â€¦Ã™â€  $total Ã™â€¦Ã˜Â¹Ã˜Â±Ã™Ë†Ã˜Â¶',
    nl: '$active actief van $total getoond',
    fr: '$active actif sur $total affichÃƒÂ©',
    de: '$active aktiv von $total angezeigt',
  );
  String get noRestaurantsLoaded => _t(
    'No restaurants loaded',
    'Ã™â€žÃ™â€¦ Ã™Å Ã˜ÂªÃ™â€¦ Ã˜ÂªÃ˜Â­Ã™â€¦Ã™Å Ã™â€ž Ã™â€¦Ã˜Â·Ã˜Â§Ã˜Â¹Ã™â€¦',
    nl: 'Geen restaurants geladen',
    fr: 'Aucun restaurant chargÃƒÂ©',
    de: 'Keine Restaurants geladen',
  );

  // Dynamic dashboard strings
  String driversCountSummary(int total, int online, int offline) => _t(
    '$total total Ã‚Â· $online online',
    '$total Ã˜Â§Ã™â€žÃ˜Â¥Ã˜Â¬Ã™â€¦Ã˜Â§Ã™â€žÃ™Å  Ã‚Â· $online Ã™â€¦Ã˜ÂªÃ˜ÂµÃ™â€ž',
    nl: '$total totaal Ã‚Â· $online online',
    fr: '$total total Ã‚Â· $online en ligne',
    de: '$total gesamt Ã‚Â· $online online',
  );
  String driversStat(int total, int offline) => _t(
    '$total total Ã‚Â· $offline offline',
    '$total Ã˜Â§Ã™â€žÃ˜Â¥Ã˜Â¬Ã™â€¦Ã˜Â§Ã™â€žÃ™Å  Ã‚Â· $offline Ã˜ÂºÃ™Å Ã˜Â± Ã™â€¦Ã˜ÂªÃ˜ÂµÃ™â€ž',
    nl: '$total totaal Ã‚Â· $offline offline',
    fr: '$total total Ã‚Â· $offline hors ligne',
    de: '$total gesamt Ã‚Â· $offline offline',
  );
  String pendingItemsSub(int drivers, int restaurants) => _t(
    '$drivers drivers Ã‚Â· $restaurants restaurants',
    '$drivers Ã˜Â³Ã˜Â§Ã˜Â¦Ã™â€šÃ™Å Ã™â€  Ã‚Â· $restaurants Ã™â€¦Ã˜Â·Ã˜Â§Ã˜Â¹Ã™â€¦',
    nl: '$drivers chauffeurs Ã‚Â· $restaurants restaurants',
    fr: '$drivers chauffeurs Ã‚Â· $restaurants restaurants',
    de: '$drivers Fahrer Ã‚Â· $restaurants Restaurants',
  );

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Drivers Screen Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  String driversScreenSub(int total, int online, int offline) => _t(
    '$total drivers - $online online - $offline offline',
    '$total ???? - $online ???? - $offline ??? ????',
    nl: '$total chauffeurs - $online online - $offline offline',
    fr: '$total chauffeurs - $online en ligne - $offline hors ligne',
    de: '$total Fahrer - $online online - $offline offline',
  );
  String driversScreenSubWithSuspended(
    int total,
    int online,
    int offline,
    int suspended,
  ) => _t(
    '$total drivers - $online online - $offline offline - $suspended suspended',
    '$total ???? - $online ???? - $offline ??? ???? - $suspended ?????',
    nl: '$total chauffeurs - $online online - $offline offline - $suspended opgeschort',
    fr: '$total chauffeurs - $online en ligne - $offline hors ligne - $suspended suspendus',
    de: '$total Fahrer - $online online - $offline offline - $suspended gesperrt',
  );
  String get searchByNameOrPhone => _t(
    'Search by name or phone...',
    'Ã˜Â§Ã™â€žÃ˜Â¨Ã˜Â­Ã˜Â« Ã˜Â¨Ã˜Â§Ã™â€žÃ˜Â§Ã˜Â³Ã™â€¦ Ã˜Â£Ã™Ë† Ã˜Â§Ã™â€žÃ™â€¡Ã˜Â§Ã˜ÂªÃ™Â...',
    nl: 'Zoeken op naam of telefoon...',
    fr: 'Rechercher par nom ou tÃƒÂ©lÃƒÂ©phone...',
    de: 'Nach Name oder Telefon suchen...',
  );
  String get all =>
      _t('All', 'Ã˜Â§Ã™â€žÃ™Æ’Ã™â€ž', nl: 'Alle', fr: 'Tous', de: 'Alle');
  String get driver => _t(
    'Driver',
    'Ã˜Â§Ã™â€žÃ˜Â³Ã˜Â§Ã˜Â¦Ã™â€š',
    nl: 'Chauffeur',
    fr: 'Chauffeur',
    de: 'Fahrer',
  );
  String get status => _t(
    'Status',
    'Ã˜Â§Ã™â€žÃ˜Â­Ã˜Â§Ã™â€žÃ˜Â©',
    nl: 'Status',
    fr: 'Statut',
    de: 'Status',
  );
  String get phone => _t(
    'Phone',
    'Ã˜Â§Ã™â€žÃ™â€¡Ã˜Â§Ã˜ÂªÃ™Â',
    nl: 'Telefoon',
    fr: 'TÃƒÂ©lÃƒÂ©phone',
    de: 'Telefon',
  );
  String get location => _t(
    'Location',
    'Ã˜Â§Ã™â€žÃ™â€¦Ã™Ë†Ã™â€šÃ˜Â¹',
    nl: 'Locatie',
    fr: 'Emplacement',
    de: 'Standort',
  );
  String get noDriversMatchFilters => _t(
    'No drivers match your filters',
    'Ã™â€žÃ˜Â§ Ã™Å Ã™Ë†Ã˜Â¬Ã˜Â¯ Ã˜Â³Ã˜Â§Ã˜Â¦Ã™â€šÃ™Ë†Ã™â€  Ã™â€¦Ã˜Â·Ã˜Â§Ã˜Â¨Ã™â€šÃ™Ë†Ã™â€  Ã™â€žÃ™â€žÃ™ÂÃ™â€žÃ˜Â§Ã˜ÂªÃ˜Â±',
    nl: 'Geen chauffeurs komen overeen met uw filters',
    fr: 'Aucun chauffeur ne correspond ÃƒÂ  vos filtres',
    de: 'Keine Fahrer entsprechen Ihren Filtern',
  );
  String get noLocation => _t(
    'No location',
    'Ã™â€žÃ˜Â§ Ã™Å Ã™Ë†Ã˜Â¬Ã˜Â¯ Ã™â€¦Ã™Ë†Ã™â€šÃ˜Â¹',
    nl: 'Geen locatie',
    fr: 'Aucun emplacement',
    de: 'Kein Standort',
  );
  String get allDriversOffline => _t(
    'All drivers are currently offline',
    'Ã˜Â¬Ã™â€¦Ã™Å Ã˜Â¹ Ã˜Â§Ã™â€žÃ˜Â³Ã˜Â§Ã˜Â¦Ã™â€šÃ™Å Ã™â€  Ã˜ÂºÃ™Å Ã˜Â± Ã™â€¦Ã˜ÂªÃ˜ÂµÃ™â€žÃ™Å Ã™â€  Ã˜Â­Ã˜Â§Ã™â€žÃ™Å Ã˜Â§Ã™â€¹',
    nl: 'Alle chauffeurs zijn momenteel offline',
    fr: 'Tous les chauffeurs sont actuellement hors ligne',
    de: 'Alle Fahrer sind derzeit offline',
  );
  String driversOfflineHint(int total) => _t(
    '$total registered drivers - locations appear when drivers go online',
    '$total ???? ???? - ???? ??????? ??? ????? ????????',
    nl: '$total geregistreerde chauffeurs - locaties verschijnen wanneer chauffeurs online gaan',
    fr: '$total chauffeurs enregistr?s - les emplacements apparaissent lorsque les chauffeurs se connectent',
    de: '$total registrierte Fahrer - Standorte erscheinen, wenn Fahrer online gehen',
  );
  String get mapView =>
      _t('Map', 'Ã˜Â®Ã˜Â±Ã™Å Ã˜Â·Ã˜Â©', nl: 'Kaart', fr: 'Carte', de: 'Karte');
  String get listView => _t(
    'List',
    'Ã™â€šÃ˜Â§Ã˜Â¦Ã™â€¦Ã˜Â©',
    nl: 'Lijst',
    fr: 'Liste',
    de: 'Liste',
  );
  String get noLocationsAvailable => _t(
    'No driver locations available',
    'Ã™â€žÃ˜Â§ Ã˜ÂªÃ™Ë†Ã˜Â¬Ã˜Â¯ Ã™â€¦Ã™Ë†Ã˜Â§Ã™â€šÃ˜Â¹ Ã˜Â³Ã˜Â§Ã˜Â¦Ã™â€šÃ™Å Ã™â€  Ã™â€¦Ã˜ÂªÃ˜Â§Ã˜Â­Ã˜Â©',
    nl: 'Geen chauffeurlocaties beschikbaar',
    fr: 'Aucun emplacement de chauffeur disponible',
    de: 'Keine Fahrerstandorte verfÃƒÂ¼gbar',
  );
  String get allRegions => _t(
    'All Regions',
    'Ã˜Â¬Ã™â€¦Ã™Å Ã˜Â¹ Ã˜Â§Ã™â€žÃ™â€¦Ã™â€ Ã˜Â§Ã˜Â·Ã™â€š',
    nl: 'Alle regio\'s',
    fr: 'Toutes les rÃƒÂ©gions',
    de: 'Alle Regionen',
  );
  String get otherRegion => _t(
    'Other',
    'Ã˜Â£Ã˜Â®Ã˜Â±Ã™â€°',
    nl: 'Overig',
    fr: 'Autre',
    de: 'Sonstige',
  );
  String driversInRegion(int count) => _t(
    '$count drivers',
    '$count Ã˜Â³Ã˜Â§Ã˜Â¦Ã™â€šÃ™Å Ã™â€ ',
    nl: '$count chauffeurs',
    fr: '$count chauffeurs',
    de: '$count Fahrer',
  );

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Approvals Screen Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  String applicationsWaitingReview(int count) => _t(
    '$count applications waiting for review',
    '$count Ã˜Â·Ã™â€žÃ˜Â¨Ã˜Â§Ã˜Âª Ã™ÂÃ™Å  Ã˜Â§Ã™â€ Ã˜ÂªÃ˜Â¸Ã˜Â§Ã˜Â± Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â±Ã˜Â§Ã˜Â¬Ã˜Â¹Ã˜Â©',
    nl: '$count aanvragen wachten op beoordeling',
    fr: '$count demandes en attente de rÃƒÂ©vision',
    de: '$count AntrÃƒÂ¤ge warten auf ÃƒÅ“berprÃƒÂ¼fung',
  );
  String get pending => _t(
    'Pending',
    'Ã™â€¦Ã˜Â¹Ã™â€žÃ™â€š',
    nl: 'In afwachting',
    fr: 'En attente',
    de: 'Ausstehend',
  );
  String statusLabel(String s) => _t(
    'Status: $s',
    'Ã˜Â§Ã™â€žÃ˜Â­Ã˜Â§Ã™â€žÃ˜Â©: $s',
    nl: 'Status: $s',
    fr: 'Statut : $s',
    de: 'Status: $s',
  );
  String get decline => _t(
    'Decline',
    'Ã˜Â±Ã™ÂÃ˜Â¶',
    nl: 'Afwijzen',
    fr: 'Refuser',
    de: 'Ablehnen',
  );
  String get approve => _t(
    'Approve',
    'Ã™â€šÃ˜Â¨Ã™Ë†Ã™â€ž',
    nl: 'Goedkeuren',
    fr: 'Approuver',
    de: 'Genehmigen',
  );
  String get activate => _t(
    'Activate',
    'Ã˜ÂªÃ™ÂÃ˜Â¹Ã™Å Ã™â€ž',
    nl: 'Activeren',
    fr: 'Activer',
    de: 'Aktivieren',
  );
  String get suspend => _t(
    'Suspend',
    'ØªØ¹Ù„ÙŠÙ‚',
    nl: 'Opschorten',
    fr: 'Suspendre',
    de: 'Sperren',
  );
  String get suspendDriver => _t(
    'Suspend Driver',
    'ØªØ¹Ù„ÙŠÙ‚ Ø§Ù„Ø³Ø§Ø¦Ù‚',
    nl: 'Chauffeur opschorten',
    fr: 'Suspendre le chauffeur',
    de: 'Fahrer sperren',
  );
  String get activateDriver => _t(
    'Activate Driver',
    'ØªÙØ¹ÙŠÙ„ Ø§Ù„Ø³Ø§Ø¦Ù‚',
    nl: 'Chauffeur activeren',
    fr: 'Activer le chauffeur',
    de: 'Fahrer aktivieren',
  );
  String get suspended => _t(
    'Suspended',
    'Ù…Ø¹Ù„Ù‘Ù‚',
    nl: 'Opgeschort',
    fr: 'Suspendu',
    de: 'Gesperrt',
  );
  String get actions => _t(
    'Actions',
    'Ø¥Ø¬Ø±Ø§Ø¡Ø§Øª',
    nl: 'Acties',
    fr: 'Actions',
    de: 'Aktionen',
  );
  String get allCaughtUp => _t(
    'All caught up',
    'Ã˜ÂªÃ™â€¦ Ã˜Â§Ã™â€žÃ˜Â§Ã™â€ Ã˜ÂªÃ™â€¡Ã˜Â§Ã˜Â¡ Ã™â€¦Ã™â€  Ã˜Â§Ã™â€žÃ™Æ’Ã™â€ž',
    nl: 'Alles bijgewerkt',
    fr: 'Tout est ÃƒÂ  jour',
    de: 'Alles erledigt',
  );
  String get noPendingApplications => _t(
    'No pending applications to review',
    'Ã™â€žÃ˜Â§ Ã˜ÂªÃ™Ë†Ã˜Â¬Ã˜Â¯ Ã˜Â·Ã™â€žÃ˜Â¨Ã˜Â§Ã˜Âª Ã™â€¦Ã˜Â¹Ã™â€žÃ™â€šÃ˜Â© Ã™â€žÃ™â€žÃ™â€¦Ã˜Â±Ã˜Â§Ã˜Â¬Ã˜Â¹Ã˜Â©',
    nl: 'Geen openstaande aanvragen om te beoordelen',
    fr: 'Aucune demande en attente ÃƒÂ  examiner',
    de: 'Keine ausstehenden AntrÃƒÂ¤ge zur ÃƒÅ“berprÃƒÂ¼fung',
  );

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Request Detail Screen Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  String get requestDetails => _t(
    'Request Details',
    'Ã˜ÂªÃ™ÂÃ˜Â§Ã˜ÂµÃ™Å Ã™â€ž Ã˜Â§Ã™â€žÃ˜Â·Ã™â€žÃ˜Â¨',
    nl: 'Aanvraagdetails',
    fr: 'DÃƒÂ©tails de la demande',
    de: 'Anfragedetails',
  );
  String get driverRequest => _t(
    'Driver Request',
    'Ã˜Â·Ã™â€žÃ˜Â¨ Ã˜Â³Ã˜Â§Ã˜Â¦Ã™â€š',
    nl: 'Chauffeursaanvraag',
    fr: 'Demande de chauffeur',
    de: 'Fahreranfrage',
  );
  String get restaurantRequest => _t(
    'Restaurant Request',
    'Ã˜Â·Ã™â€žÃ˜Â¨ Ã™â€¦Ã˜Â·Ã˜Â¹Ã™â€¦',
    nl: 'Restaurantaanvraag',
    fr: 'Demande de restaurant',
    de: 'Restaurantanfrage',
  );
  String get vehicleType => _t(
    'Vehicle Type',
    'Ã™â€ Ã™Ë†Ã˜Â¹ Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â±Ã™Æ’Ã˜Â¨Ã˜Â©',
    nl: 'Voertuigtype',
    fr: 'Type de vÃƒÂ©hicule',
    de: 'Fahrzeugtyp',
  );
  String get serviceTypes => _t(
    'Service Types',
    'Ã˜Â£Ã™â€ Ã™Ë†Ã˜Â§Ã˜Â¹ Ã˜Â§Ã™â€žÃ˜Â®Ã˜Â¯Ã™â€¦Ã˜Â§Ã˜Âª',
    nl: 'Servicetypes',
    fr: 'Types de service',
    de: 'Diensttypen',
  );
  String get food => _t(
    'Food',
    'Ã˜Â·Ã˜Â¹Ã˜Â§Ã™â€¦',
    nl: 'Eten',
    fr: 'Nourriture',
    de: 'Essen',
  );
  String get shipping => _t(
    'Shipping',
    'Ã˜Â´Ã˜Â­Ã™â€ ',
    nl: 'Verzending',
    fr: 'Livraison',
    de: 'Versand',
  );
  String get taxi =>
      _t('Taxi', 'Ã˜ÂªÃ˜Â§Ã™Æ’Ã˜Â³Ã™Å ', nl: 'Taxi', fr: 'Taxi', de: 'Taxi');
  String get documents => _t(
    'Documents',
    'Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â³Ã˜ÂªÃ™â€ Ã˜Â¯Ã˜Â§Ã˜Âª',
    nl: 'Documenten',
    fr: 'Documents',
    de: 'Dokumente',
  );
  String get drivingLicense => _t(
    'Driving License',
    'Ã˜Â±Ã˜Â®Ã˜ÂµÃ˜Â© Ã˜Â§Ã™â€žÃ™â€šÃ™Å Ã˜Â§Ã˜Â¯Ã˜Â©',
    nl: 'Rijbewijs',
    fr: 'Permis de conduire',
    de: 'FÃƒÂ¼hrerschein',
  );
  String get idDocument => _t(
    'ID Document',
    'Ã™Ë†Ã˜Â«Ã™Å Ã™â€šÃ˜Â© Ã˜Â§Ã™â€žÃ™â€¡Ã™Ë†Ã™Å Ã˜Â©',
    nl: 'Identiteitsbewijs',
    fr: "PiÃƒÂ¨ce d'identitÃƒÂ©",
    de: 'Ausweisdokument',
  );
  String get healthInsuranceDocument => _t(
    'Health Insurance Document',
    'Ã™Ë†Ã˜Â«Ã™Å Ã™â€šÃ˜Â© Ã˜Â§Ã™â€žÃ˜ÂªÃ˜Â£Ã™â€¦Ã™Å Ã™â€  Ã˜Â§Ã™â€žÃ˜ÂµÃ˜Â­Ã™Å ',
    nl: 'Zorgverzekeringsdocument',
    fr: "Document d'assurance santÃƒÂ©",
    de: 'Krankenversicherungsdokument',
  );
  String get addressDocument => _t(
    'Address Document',
    'Ã™Ë†Ã˜Â«Ã™Å Ã™â€šÃ˜Â© Ã˜Â§Ã™â€žÃ˜Â¹Ã™â€ Ã™Ë†Ã˜Â§Ã™â€ ',
    nl: 'Adresdocument',
    fr: "Document d'adresse",
    de: 'Adressdokument',
  );
  String get bankDocument => _t(
    'Bank Document',
    'Ã™Ë†Ã˜Â«Ã™Å Ã™â€šÃ˜Â© Ã˜Â§Ã™â€žÃ˜Â¨Ã™â€ Ã™Æ’',
    nl: 'Bankdocument',
    fr: 'Document bancaire',
    de: 'Bankdokument',
  );
  String get otherDocuments => _t(
    'Other Documents',
    'Ã™â€¦Ã˜Â³Ã˜ÂªÃ™â€ Ã˜Â¯Ã˜Â§Ã˜Âª Ã˜Â£Ã˜Â®Ã˜Â±Ã™â€°',
    nl: 'Overige documenten',
    fr: 'Autres documents',
    de: 'Andere Dokumente',
  );
  String get noDocumentsUploaded => _t(
    'No documents uploaded',
    'Ã™â€žÃ™â€¦ Ã™Å Ã˜ÂªÃ™â€¦ Ã˜Â±Ã™ÂÃ˜Â¹ Ã™â€¦Ã˜Â³Ã˜ÂªÃ™â€ Ã˜Â¯Ã˜Â§Ã˜Âª',
    nl: 'Geen documenten geÃƒÂ¼pload',
    fr: 'Aucun document tÃƒÂ©lÃƒÂ©chargÃƒÂ©',
    de: 'Keine Dokumente hochgeladen',
  );
  String get contactInfo => _t(
    'Contact Info',
    'Ã™â€¦Ã˜Â¹Ã™â€žÃ™Ë†Ã™â€¦Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€žÃ˜Â§Ã˜ÂªÃ˜ÂµÃ˜Â§Ã™â€ž',
    nl: 'Contactgegevens',
    fr: 'CoordonnÃƒÂ©es',
    de: 'Kontaktdaten',
  );
  String get submittedDate => _t(
    'Submitted',
    'Ã˜ÂªÃ˜Â§Ã˜Â±Ã™Å Ã˜Â® Ã˜Â§Ã™â€žÃ˜ÂªÃ™â€šÃ˜Â¯Ã™Å Ã™â€¦',
    nl: 'Ingediend',
    fr: 'Soumis',
    de: 'Eingereicht',
  );
  String get registeredDate => _t(
    'Registered',
    'Ã˜ÂªÃ˜Â§Ã˜Â±Ã™Å Ã˜Â® Ã˜Â§Ã™â€žÃ˜ÂªÃ˜Â³Ã˜Â¬Ã™Å Ã™â€ž',
    nl: 'Geregistreerd',
    fr: 'Inscrit',
    de: 'Registriert',
  );
  String get loadingDetails => _t(
    'Loading details...',
    'Ã˜Â¬Ã˜Â§Ã˜Â±Ã™Å  Ã˜ÂªÃ˜Â­Ã™â€¦Ã™Å Ã™â€ž Ã˜Â§Ã™â€žÃ˜ÂªÃ™ÂÃ˜Â§Ã˜ÂµÃ™Å Ã™â€ž...',
    nl: 'Details laden...',
    fr: 'Chargement des dÃƒÂ©tails...',
    de: 'Details werden geladen...',
  );
  String get failedToLoadDetails => _t(
    'Failed to load details',
    'Ã™ÂÃ˜Â´Ã™â€ž Ã˜ÂªÃ˜Â­Ã™â€¦Ã™Å Ã™â€ž Ã˜Â§Ã™â€žÃ˜ÂªÃ™ÂÃ˜Â§Ã˜ÂµÃ™Å Ã™â€ž',
    nl: 'Kan details niet laden',
    fr: 'Ãƒâ€°chec du chargement des dÃƒÂ©tails',
    de: 'Details konnten nicht geladen werden',
  );
  String get notProvided => _t(
    'Not provided',
    'Ã˜ÂºÃ™Å Ã˜Â± Ã™â€¦Ã˜ÂªÃ™Ë†Ã™ÂÃ˜Â±',
    nl: 'Niet opgegeven',
    fr: 'Non fourni',
    de: 'Nicht angegeben',
  );
  String get viewDocument =>
      _t('View', 'Ã˜Â¹Ã˜Â±Ã˜Â¶', nl: 'Bekijken', fr: 'Voir', de: 'Ansehen');
  String get bike => _t(
    'Bike',
    'Ã˜Â¯Ã˜Â±Ã˜Â§Ã˜Â¬Ã˜Â©',
    nl: 'Fiets',
    fr: 'VÃƒÂ©lo',
    de: 'Fahrrad',
  );
  String get motorcycle => _t(
    'Motorcycle',
    'Ã˜Â¯Ã˜Â±Ã˜Â§Ã˜Â¬Ã˜Â© Ã™â€ Ã˜Â§Ã˜Â±Ã™Å Ã˜Â©',
    nl: 'Motor',
    fr: 'Moto',
    de: 'Motorrad',
  );
  String get car =>
      _t('Car', 'Ã˜Â³Ã™Å Ã˜Â§Ã˜Â±Ã˜Â©', nl: 'Auto', fr: 'Voiture', de: 'Auto');
  String get van => _t(
    'Van',
    'Ã™ÂÃ˜Â§Ã™â€ ',
    nl: 'Bestelbus',
    fr: 'Camionnette',
    de: 'Transporter',
  );

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Support Screen Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  String supportSub(int open, int inProgress, int resolved) => _t(
    '$open open Ã‚Â· $inProgress in progress Ã‚Â· $resolved resolved',
    '$open Ã™â€¦Ã™ÂÃ˜ÂªÃ™Ë†Ã˜Â­ Ã‚Â· $inProgress Ã™â€šÃ™Å Ã˜Â¯ Ã˜Â§Ã™â€žÃ˜ÂªÃ™â€ Ã™ÂÃ™Å Ã˜Â° Ã‚Â· $resolved Ã˜ÂªÃ™â€¦ Ã˜Â§Ã™â€žÃ˜Â­Ã™â€ž',
    nl: '$open open Ã‚Â· $inProgress in behandeling Ã‚Â· $resolved opgelost',
    fr: '$open ouvert Ã‚Â· $inProgress en cours Ã‚Â· $resolved rÃƒÂ©solu',
    de: '$open offen Ã‚Â· $inProgress in Bearbeitung Ã‚Â· $resolved gelÃƒÂ¶st',
  );
  String get open => _t(
    'Open',
    'Ã™â€¦Ã™ÂÃ˜ÂªÃ™Ë†Ã˜Â­',
    nl: 'Open',
    fr: 'Ouvert',
    de: 'Offen',
  );
  String get inProgress => _t(
    'In Progress',
    'Ã™â€šÃ™Å Ã˜Â¯ Ã˜Â§Ã™â€žÃ˜ÂªÃ™â€ Ã™ÂÃ™Å Ã˜Â°',
    nl: 'In behandeling',
    fr: 'En cours',
    de: 'In Bearbeitung',
  );
  String get resolved => _t(
    'Resolved',
    'Ã˜ÂªÃ™â€¦ Ã˜Â§Ã™â€žÃ˜Â­Ã™â€ž',
    nl: 'Opgelost',
    fr: 'RÃƒÂ©solu',
    de: 'GelÃƒÂ¶st',
  );
  String get closed => _t(
    'Closed',
    'Ã™â€¦Ã˜ÂºÃ™â€žÃ™â€š',
    nl: 'Gesloten',
    fr: 'FermÃƒÂ©',
    de: 'Geschlossen',
  );
  String get refresh => _t(
    'Refresh',
    'Ã˜ÂªÃ˜Â­Ã˜Â¯Ã™Å Ã˜Â«',
    nl: 'Vernieuwen',
    fr: 'Actualiser',
    de: 'Aktualisieren',
  );
  String get noTicketsFound => _t(
    'No tickets found',
    'Ã™â€žÃ™â€¦ Ã™Å Ã˜ÂªÃ™â€¦ Ã˜Â§Ã™â€žÃ˜Â¹Ã˜Â«Ã™Ë†Ã˜Â± Ã˜Â¹Ã™â€žÃ™â€° Ã˜ÂªÃ˜Â°Ã˜Â§Ã™Æ’Ã˜Â±',
    nl: 'Geen tickets gevonden',
    fr: 'Aucun ticket trouvÃƒÂ©',
    de: 'Keine Tickets gefunden',
  );
  String get selectATicket => _t(
    'Select a ticket',
    'Ã˜Â§Ã˜Â®Ã˜ÂªÃ˜Â± Ã˜ÂªÃ˜Â°Ã™Æ’Ã˜Â±Ã˜Â©',
    nl: 'Selecteer een ticket',
    fr: 'SÃƒÂ©lectionnez un ticket',
    de: 'Ticket auswÃƒÂ¤hlen',
  );
  String get writeReply => _t(
    'Write a reply...',
    'Ã˜Â§Ã™Æ’Ã˜ÂªÃ˜Â¨ Ã˜Â±Ã˜Â¯Ã™â€¹Ã˜Â§...',
    nl: 'Schrijf een antwoord...',
    fr: 'Ãƒâ€°crire une rÃƒÂ©ponse...',
    de: 'Antwort schreiben...',
  );
  String get reply => _t(
    'Reply',
    'Ã˜Â±Ã˜Â¯',
    nl: 'Antwoorden',
    fr: 'RÃƒÂ©pondre',
    de: 'Antworten',
  );
  String get markResolved => _t(
    'Mark Resolved',
    'Ã˜ÂªÃ™â€¦ Ã˜Â§Ã™â€žÃ˜Â­Ã™â€ž',
    nl: 'Markeer als opgelost',
    fr: 'Marquer comme rÃƒÂ©solu',
    de: 'Als gelÃƒÂ¶st markieren',
  );
  String get close => _t(
    'Close',
    'Ã˜Â¥Ã˜ÂºÃ™â€žÃ˜Â§Ã™â€š',
    nl: 'Sluiten',
    fr: 'Fermer',
    de: 'SchlieÃƒÅ¸en',
  );
  String get low => _t(
    'Low',
    'Ã™â€¦Ã™â€ Ã˜Â®Ã™ÂÃ˜Â¶',
    nl: 'Laag',
    fr: 'Faible',
    de: 'Niedrig',
  );
  String get medium => _t(
    'Medium',
    'Ã™â€¦Ã˜ÂªÃ™Ë†Ã˜Â³Ã˜Â·',
    nl: 'Gemiddeld',
    fr: 'Moyen',
    de: 'Mittel',
  );
  String get high => _t(
    'High',
    'Ã™â€¦Ã˜Â±Ã˜ÂªÃ™ÂÃ˜Â¹',
    nl: 'Hoog',
    fr: 'Ãƒâ€°levÃƒÂ©',
    de: 'Hoch',
  );
  String get urgent => _t(
    'Urgent',
    'Ã˜Â¹Ã˜Â§Ã˜Â¬Ã™â€ž',
    nl: 'Urgent',
    fr: 'Urgent',
    de: 'Dringend',
  );
  String failedToSend(String e) => _t(
    'Failed to send: $e',
    'Ã™ÂÃ˜Â´Ã™â€ž Ã™ÂÃ™Å  Ã˜Â§Ã™â€žÃ˜Â¥Ã˜Â±Ã˜Â³Ã˜Â§Ã™â€ž: $e',
    nl: 'Verzenden mislukt: $e',
    fr: "Ãƒâ€°chec de l'envoi : $e",
    de: 'Senden fehlgeschlagen: $e',
  );
  String failedToUpdate(String e) => _t(
    'Failed to update: $e',
    'Ã™ÂÃ˜Â´Ã™â€ž Ã™ÂÃ™Å  Ã˜Â§Ã™â€žÃ˜ÂªÃ˜Â­Ã˜Â¯Ã™Å Ã˜Â«: $e',
    nl: 'Bijwerken mislukt: $e',
    fr: 'Ãƒâ€°chec de la mise ÃƒÂ  jour : $e',
    de: 'Aktualisierung fehlgeschlagen: $e',
  );

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Ticket Detail Screen Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  String get ticketDetails => _t(
    'Ticket Details',
    'Ã˜ÂªÃ™ÂÃ˜Â§Ã˜ÂµÃ™Å Ã™â€ž Ã˜Â§Ã™â€žÃ˜ÂªÃ˜Â°Ã™Æ’Ã˜Â±Ã˜Â©',
    nl: 'Ticketdetails',
    fr: 'DÃƒÂ©tails du ticket',
    de: 'Ticket-Details',
  );
  String get priority => _t(
    'Priority',
    'Ã˜Â§Ã™â€žÃ˜Â£Ã™Ë†Ã™â€žÃ™Ë†Ã™Å Ã˜Â©',
    nl: 'Prioriteit',
    fr: 'PrioritÃƒÂ©',
    de: 'PrioritÃƒÂ¤t',
  );
  String get category => _t(
    'Category',
    'Ã˜Â§Ã™â€žÃ™ÂÃ˜Â¦Ã˜Â©',
    nl: 'Categorie',
    fr: 'CatÃƒÂ©gorie',
    de: 'Kategorie',
  );
  String get requester => _t(
    'Requester',
    'Ã™â€¦Ã™â€šÃ˜Â¯Ã™â€¦ Ã˜Â§Ã™â€žÃ˜Â·Ã™â€žÃ˜Â¨',
    nl: 'Aanvrager',
    fr: 'Demandeur',
    de: 'Anfragender',
  );
  String get created => _t(
    'Created',
    'Ã˜ÂªÃ™â€¦ Ã˜Â§Ã™â€žÃ˜Â¥Ã™â€ Ã˜Â´Ã˜Â§Ã˜Â¡',
    nl: 'Aangemaakt',
    fr: 'CrÃƒÂ©ÃƒÂ©',
    de: 'Erstellt',
  );
  String get lastActivity => _t(
    'Last Activity',
    'Ã˜Â¢Ã˜Â®Ã˜Â± Ã™â€ Ã˜Â´Ã˜Â§Ã˜Â·',
    nl: 'Laatste activiteit',
    fr: 'DerniÃƒÂ¨re activitÃƒÂ©',
    de: 'Letzte AktivitÃƒÂ¤t',
  );
  String get closedAt => _t(
    'Closed',
    'Ã˜ÂªÃ™â€¦ Ã˜Â§Ã™â€žÃ˜Â¥Ã˜ÂºÃ™â€žÃ˜Â§Ã™â€š',
    nl: 'Gesloten',
    fr: 'FermÃƒÂ©',
    de: 'Geschlossen',
  );
  String get conversation => _t(
    'Conversation',
    'Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â­Ã˜Â§Ã˜Â¯Ã˜Â«Ã˜Â©',
    nl: 'Gesprek',
    fr: 'Conversation',
    de: 'Konversation',
  );
  String noMessages(int id) => _t(
    'No messages yet for ticket #$id',
    'Ã™â€žÃ˜Â§ Ã˜ÂªÃ™Ë†Ã˜Â¬Ã˜Â¯ Ã˜Â±Ã˜Â³Ã˜Â§Ã˜Â¦Ã™â€ž Ã˜Â¨Ã˜Â¹Ã˜Â¯ Ã™â€žÃ™â€žÃ˜ÂªÃ˜Â°Ã™Æ’Ã˜Â±Ã˜Â© #$id',
    nl: 'Nog geen berichten voor ticket #$id',
    fr: 'Aucun message pour le ticket #$id',
    de: 'Noch keine Nachrichten fÃƒÂ¼r Ticket #$id',
  );
  String get assignedTo => _t(
    'Assigned To',
    'Ã™â€¦Ã˜Â³Ã™â€ Ã˜Â¯ Ã˜Â¥Ã™â€žÃ™â€°',
    nl: 'Toegewezen aan',
    fr: 'AssignÃƒÂ© ÃƒÂ ',
    de: 'Zugewiesen an',
  );
  String get unassigned => _t(
    'Unassigned',
    'Ã˜ÂºÃ™Å Ã˜Â± Ã™â€¦Ã˜Â³Ã™â€ Ã˜Â¯',
    nl: 'Niet toegewezen',
    fr: 'Non assignÃƒÂ©',
    de: 'Nicht zugewiesen',
  );
  String get relatedOrder => _t(
    'Order',
    'Ã˜Â§Ã™â€žÃ˜Â·Ã™â€žÃ˜Â¨',
    nl: 'Bestelling',
    fr: 'Commande',
    de: 'Bestellung',
  );
  String get relatedRestaurant => _t(
    'Restaurant',
    'Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â·Ã˜Â¹Ã™â€¦',
    nl: 'Restaurant',
    fr: 'Restaurant',
    de: 'Restaurant',
  );
  String get relatedDriver => _t(
    'Driver',
    'Ã˜Â§Ã™â€žÃ˜Â³Ã˜Â§Ã˜Â¦Ã™â€š',
    nl: 'Chauffeur',
    fr: 'Chauffeur',
    de: 'Fahrer',
  );
  String nAttachments(int n) => _t(
    '$n attachment${n == 1 ? '' : 's'}',
    '$n Ã™â€¦Ã˜Â±Ã™ÂÃ™â€š${n == 1 ? '' : 'Ã˜Â§Ã˜Âª'}',
    nl: '$n bijlage${n == 1 ? '' : 'n'}',
    fr: '$n piÃƒÂ¨ce${n == 1 ? '' : 's'} jointe${n == 1 ? '' : 's'}',
    de: '$n Anhang${n == 1 ? '' : 'e'}',
  );

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Profile Screen Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  String get accountInfo => _t(
    'Account',
    'Ã˜Â§Ã™â€žÃ˜Â­Ã˜Â³Ã˜Â§Ã˜Â¨',
    nl: 'Account',
    fr: 'Compte',
    de: 'Konto',
  );
  String get email => _t(
    'Email',
    'Ã˜Â§Ã™â€žÃ˜Â¨Ã˜Â±Ã™Å Ã˜Â¯ Ã˜Â§Ã™â€žÃ˜Â¥Ã™â€žÃ™Æ’Ã˜ÂªÃ˜Â±Ã™Ë†Ã™â€ Ã™Å ',
    nl: 'E-mail',
    fr: 'E-mail',
    de: 'E-Mail',
  );
  String get name =>
      _t('Name', 'Ã˜Â§Ã™â€žÃ˜Â§Ã˜Â³Ã™â€¦', nl: 'Naam', fr: 'Nom', de: 'Name');
  String get roles => _t(
    'Roles',
    'Ã˜Â§Ã™â€žÃ˜Â£Ã˜Â¯Ã™Ë†Ã˜Â§Ã˜Â±',
    nl: 'Rollen',
    fr: 'RÃƒÂ´les',
    de: 'Rollen',
  );
  String get verified => _t(
    'Verified',
    'Ã™â€¦Ã™Ë†Ã˜Â«Ã™â€š',
    nl: 'Geverifieerd',
    fr: 'VÃƒÂ©rifiÃƒÂ©',
    de: 'Verifiziert',
  );
  String get notVerified => _t(
    'Not verified',
    'Ã˜ÂºÃ™Å Ã˜Â± Ã™â€¦Ã™Ë†Ã˜Â«Ã™â€š',
    nl: 'Niet geverifieerd',
    fr: 'Non vÃƒÂ©rifiÃƒÂ©',
    de: 'Nicht verifiziert',
  );
  String get memberSince => _t(
    'Member since',
    'Ã˜Â¹Ã˜Â¶Ã™Ë† Ã™â€¦Ã™â€ Ã˜Â°',
    nl: 'Lid sinds',
    fr: 'Membre depuis',
    de: 'Mitglied seit',
  );
  String get settings => _t(
    'Settings',
    'Ã˜Â§Ã™â€žÃ˜Â¥Ã˜Â¹Ã˜Â¯Ã˜Â§Ã˜Â¯Ã˜Â§Ã˜Âª',
    nl: 'Instellingen',
    fr: 'ParamÃƒÂ¨tres',
    de: 'Einstellungen',
  );
  String get theme => _t(
    'Theme',
    'Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â¸Ã™â€¡Ã˜Â±',
    nl: 'Thema',
    fr: 'ThÃƒÂ¨me',
    de: 'Design',
  );
  String get darkMode =>
      _t('Dark', 'Ã˜Â¯Ã˜Â§Ã™Æ’Ã™â€ ', nl: 'Donker', fr: 'Sombre', de: 'Dunkel');
  String get lightMode =>
      _t('Light', 'Ã™ÂÃ˜Â§Ã˜ÂªÃ˜Â­', nl: 'Licht', fr: 'Clair', de: 'Hell');
  String get systemDefault => _t(
    'System',
    'Ã˜Â§Ã™â€žÃ™â€ Ã˜Â¸Ã˜Â§Ã™â€¦',
    nl: 'Systeem',
    fr: 'SystÃƒÂ¨me',
    de: 'System',
  );
  String get language => _t(
    'Language',
    'Ã˜Â§Ã™â€žÃ™â€žÃ˜ÂºÃ˜Â©',
    nl: 'Taal',
    fr: 'Langue',
    de: 'Sprache',
  );
  String get english => _t(
    'English',
    'Ã˜Â§Ã™â€žÃ˜Â¥Ã™â€ Ã˜Â¬Ã™â€žÃ™Å Ã˜Â²Ã™Å Ã˜Â©',
    nl: 'Engels',
    fr: 'Anglais',
    de: 'Englisch',
  );
  String get arabic => _t(
    'Arabic',
    'Ã˜Â§Ã™â€žÃ˜Â¹Ã˜Â±Ã˜Â¨Ã™Å Ã˜Â©',
    nl: 'Arabisch',
    fr: 'Arabe',
    de: 'Arabisch',
  );
  String get dutch => _t(
    'Dutch',
    'Ã˜Â§Ã™â€žÃ™â€¡Ã™Ë†Ã™â€žÃ™â€ Ã˜Â¯Ã™Å Ã˜Â©',
    nl: 'Nederlands',
    fr: 'NÃƒÂ©erlandais',
    de: 'NiederlÃƒÂ¤ndisch',
  );
  String get french => _t(
    'French',
    'Ã˜Â§Ã™â€žÃ™ÂÃ˜Â±Ã™â€ Ã˜Â³Ã™Å Ã˜Â©',
    nl: 'Frans',
    fr: 'FranÃƒÂ§ais',
    de: 'FranzÃƒÂ¶sisch',
  );
  String get german => _t(
    'German',
    'Ã˜Â§Ã™â€žÃ˜Â£Ã™â€žÃ™â€¦Ã˜Â§Ã™â€ Ã™Å Ã˜Â©',
    nl: 'Duits',
    fr: 'Allemand',
    de: 'Deutsch',
  );

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Shared Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  String get connectionError => _t(
    'Connection error. Please try again.',
    'Ã˜Â®Ã˜Â·Ã˜Â£ Ã™ÂÃ™Å  Ã˜Â§Ã™â€žÃ˜Â§Ã˜ÂªÃ˜ÂµÃ˜Â§Ã™â€ž. Ã™Å Ã˜Â±Ã˜Â¬Ã™â€° Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â­Ã˜Â§Ã™Ë†Ã™â€žÃ˜Â© Ã™â€¦Ã˜Â±Ã˜Â© Ã˜Â£Ã˜Â®Ã˜Â±Ã™â€°.',
    nl: 'Verbindingsfout. Probeer het opnieuw.',
    fr: 'Erreur de connexion. Veuillez rÃƒÂ©essayer.',
    de: 'Verbindungsfehler. Bitte versuchen Sie es erneut.',
  );
  String driverApproved(String name) => _t(
    '$name approved',
    'Ã˜ÂªÃ™â€¦Ã˜Âª Ã˜Â§Ã™â€žÃ™â€¦Ã™Ë†Ã˜Â§Ã™ÂÃ™â€šÃ˜Â© Ã˜Â¹Ã™â€žÃ™â€° $name',
    nl: '$name goedgekeurd',
    fr: '$name approuvÃƒÂ©',
    de: '$name genehmigt',
  );
  String driverRejected(String name) => _t(
    '$name rejected',
    'Ã˜ÂªÃ™â€¦ Ã˜Â±Ã™ÂÃ˜Â¶ $name',
    nl: '$name afgewezen',
    fr: '$name refusÃƒÂ©',
    de: '$name abgelehnt',
  );
  String driverSuspended(String name) => _t(
    '$name suspended',
    'ØªÙ… ØªØ¹Ù„ÙŠÙ‚ $name',
    nl: '$name opgeschort',
    fr: '$name suspendu',
    de: '$name gesperrt',
  );
  String suspendDriverConfirm(String name) => _t(
    'Suspend $name? They will no longer be active on the platform.',
    'Ù‡Ù„ ØªØ±ÙŠØ¯ ØªØ¹Ù„ÙŠÙ‚ $nameØŸ Ù„Ù† ÙŠØ¨Ù‚Ù‰ Ù†Ø´Ø·Ù‹Ø§ Ø¹Ù„Ù‰ Ø§Ù„Ù…Ù†ØµØ©.',
    nl: '$name opschorten? Deze chauffeur is dan niet langer actief op het platform.',
    fr: 'Suspendre $name ? Ce chauffeur ne sera plus actif sur la plateforme.',
    de: '$name sperren? Dieser Fahrer ist dann auf der Plattform nicht mehr aktiv.',
  );
  String driverActivated(String name) => _t(
    '$name activated',
    'ØªÙ… ØªÙØ¹ÙŠÙ„ $name',
    nl: '$name geactiveerd',
    fr: '$name activÃ©',
    de: '$name aktiviert',
  );
  String activateDriverConfirm(String name) => _t(
    'Activate $name again? They will be allowed back on the platform.',
    'Ù‡Ù„ ØªØ±ÙŠØ¯ Ø¥Ø¹Ø§Ø¯Ø© ØªÙØ¹ÙŠÙ„ $nameØŸ Ø³ÙŠØªÙ… Ø§Ù„Ø³Ù…Ø§Ø­ Ù„Ù‡ Ø¨Ø§Ù„Ø¹ÙˆØ¯Ø© Ø¥Ù„Ù‰ Ø§Ù„Ù…Ù†ØµØ©.',
    nl: '$name opnieuw activeren? Deze chauffeur krijgt weer toegang tot het platform.',
    fr: 'RÃ©activer $name ? Ce chauffeur sera de nouveau autorisÃ© sur la plateforme.',
    de: '$name erneut aktivieren? Dieser Fahrer wird wieder auf der Plattform zugelassen.',
  );
  String restaurantActivated(String name) => _t(
    '$name activated',
    'Ã˜ÂªÃ™â€¦ Ã˜ÂªÃ™ÂÃ˜Â¹Ã™Å Ã™â€ž $name',
    nl: '$name geactiveerd',
    fr: '$name activÃƒÂ©',
    de: '$name aktiviert',
  );
  String failed(String e) => _t(
    'Failed: $e',
    'Ã™ÂÃ˜Â´Ã™â€ž: $e',
    nl: 'Mislukt: $e',
    fr: 'Ãƒâ€°chec : $e',
    de: 'Fehlgeschlagen: $e',
  );
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar', 'nl', 'fr', 'de'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
