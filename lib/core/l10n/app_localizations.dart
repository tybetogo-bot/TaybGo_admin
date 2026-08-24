import 'dart:convert';

import 'package:flutter/material.dart';

import '../auth/auth_error_keys.dart';

class AppLocalizations {
  final Locale locale;
  static final Map<String, String> _decodedTextCache = {};

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

  static const errorPhoneAlreadyRegisteredKey =
      AuthErrorKeys.phoneAlreadyRegistered;

  String _t(String en, String ar, {String? nl, String? fr, String? de}) {
    final value = switch (locale.languageCode) {
      'ar' => ar,
      'nl' => nl ?? en,
      'fr' => fr ?? en,
      'de' => de ?? en,
      _ => en,
    };

    return _repairMojibake(value);
  }

  String resolveError(String value) {
    return switch (value) {
      errorPhoneAlreadyRegisteredKey => errorAuthPhoneAlreadyRegistered,
      _ => _repairMojibake(value),
    };
  }

  String resolvePricingError(String value) {
    final repaired = _repairMojibake(value).trim();
    final normalized = repaired.toLowerCase();

    if (normalized.startsWith('non_field_errors:') ||
        normalized.startsWith('__all__:')) {
      final separator = repaired.indexOf(':');
      if (separator >= 0 && separator + 1 < repaired.length) {
        return resolvePricingError(repaired.substring(separator + 1).trim());
      }
    }

    if (normalized.contains('version') &&
        (normalized.contains('already') ||
            normalized.contains('duplicate') ||
            normalized.contains('exist'))) {
      return pricingDuplicateVersion;
    }
    if ((normalized.contains('open-ended') ||
            normalized.contains('open ended')) &&
        normalized.contains('active')) {
      return pricingActiveOpenEndedConflict;
    }
    if (normalized.contains('already exists') && normalized.contains('polic')) {
      return pricingDuplicatePolicy;
    }

    return switch (repaired) {
      'pricing_connection_error' => connectionError,
      'Connection error. Please try again.' => connectionError,
      'pricing_failed_to_load_countries' => failedToLoadCountries,
      'Failed to load countries.' => failedToLoadCountries,
      'pricing_failed_to_load_cities' => failedToLoadCities,
      'Failed to load cities.' => failedToLoadCities,
      _ => repaired,
    };
  }

  String resolvePricingFieldError(String field, String fallback) {
    if (field == 'non_field_errors' || field == '__all__') {
      return resolvePricingError(fallback);
    }
    final translatedFallback = resolvePricingError(fallback);
    if (translatedFallback != fallback) return translatedFallback;

    return switch (field) {
      'name' => pricingNameRequired,
      'scope' => pricingInvalidScope,
      'country' => pricingCountryRequired,
      'city' => pricingCityRequired,
      'order_type' => pricingInvalidOrderType,
      'vehicle_type' => pricingInvalidVehicleType,
      'base_amount' ||
      'base_distance' ||
      'per_km_rate' ||
      'weight_multiplier' ||
      'driver_base_amount' ||
      'driver_base_distance' ||
      'driver_price_per_km' => pricingNonNegativeNumber,
      'average_speed_kmh' => pricingPositiveSpeed,
      'currency' => pricingCurrencyThreeLetters,
      'version' => pricingVersionNonnegative,
      'effective_from' => pricingEffectiveFromRequired,
      'effective_to' => pricingEffectiveToLater,
      _ => translatedFallback,
    };
  }

  String get errorAuthPhoneAlreadyRegistered => _t(
    'This number is already registered.',
    'هذا الرقم مسجل بالفعل.',
    nl: 'Dit nummer is al geregistreerd.',
    fr: 'Ce numéro est déjà enregistré.',
    de: 'Diese Nummer ist bereits registriert.',
  );

  static String _repairMojibake(String value) {
    return _decodedTextCache.putIfAbsent(value, () {
      final repaired = _repairWholeValue(value);
      return _repairEncodableSegments(repaired);
    });
  }

  static String _repairWholeValue(String value) {
    var current = value;

    for (var i = 0; i < 5; i++) {
      final repaired = _decodeWindows1252Utf8(current);
      if (repaired == null || repaired == current) {
        break;
      }
      current = repaired;
    }

    return current;
  }

  static String _repairEncodableSegments(String value) {
    final buffer = StringBuffer();
    final segment = StringBuffer();

    void flushSegment() {
      if (segment.length == 0) {
        return;
      }

      buffer.write(_repairWholeValue(segment.toString()));
      segment.clear();
    }

    for (final rune in value.runes) {
      if (_canEncodeWindows1252Rune(rune)) {
        segment.writeCharCode(rune);
      } else {
        flushSegment();
        buffer.writeCharCode(rune);
      }
    }

    flushSegment();
    return buffer.toString();
  }

  static String? _decodeWindows1252Utf8(String value) {
    try {
      final bytes = _encodeWindows1252(value);
      return utf8.decode(bytes);
    } on FormatException {
      return null;
    } on UnsupportedError {
      return null;
    }
  }

  static List<int> _encodeWindows1252(String value) {
    return value.runes
        .map((rune) {
          if (rune <= 0xff) {
            return rune;
          }

          final byte = _windows1252ReverseMap[rune];
          if (byte != null) {
            return byte;
          }

          throw UnsupportedError(
            'Character not representable in windows-1252: U+${rune.toRadixString(16).padLeft(4, '0')}',
          );
        })
        .toList(growable: false);
  }

  static bool _canEncodeWindows1252Rune(int rune) {
    return rune <= 0xff || _windows1252ReverseMap.containsKey(rune);
  }

  static const Map<int, int> _windows1252ReverseMap = {
    0x20ac: 0x80,
    0x201a: 0x82,
    0x0192: 0x83,
    0x201e: 0x84,
    0x2026: 0x85,
    0x2020: 0x86,
    0x2021: 0x87,
    0x02c6: 0x88,
    0x2030: 0x89,
    0x0160: 0x8a,
    0x2039: 0x8b,
    0x0152: 0x8c,
    0x017d: 0x8e,
    0x2018: 0x91,
    0x2019: 0x92,
    0x201c: 0x93,
    0x201d: 0x94,
    0x2022: 0x95,
    0x2013: 0x96,
    0x2014: 0x97,
    0x02dc: 0x98,
    0x2122: 0x99,
    0x0161: 0x9a,
    0x203a: 0x9b,
    0x0153: 0x9c,
    0x017e: 0x9e,
    0x0178: 0x9f,
  };

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Navigation Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  String get overview => _t(
    'Overview',
    'نظرة عامة',
    nl: 'Overzicht',
    fr: 'Aperçu',
    de: 'Übersicht',
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
  String get driversAndRestaurantsNav => _t(
    'Partners',
    'الشركاء',
    nl: 'Partners',
    fr: 'Partenaires',
    de: 'Partner',
  );
  String get driversAndRestaurantsTitle => _t(
    'Drivers & Restaurants',
    'السائقون والمطاعم',
    nl: 'Chauffeurs & restaurants',
    fr: 'Chauffeurs et restaurants',
    de: 'Fahrer und Restaurants',
  );
  String get managementTitle => _t(
    'Management',
    'الإدارة',
    nl: 'Beheer',
    fr: 'Gestion',
    de: 'Verwaltung',
  );
  String managementSubtitle(int drivers, int restaurants) => _t(
    '$drivers drivers and $restaurants restaurants',
    '$drivers سائق و $restaurants مطعم',
    nl: '$drivers chauffeurs en $restaurants restaurants',
    fr: '$drivers chauffeurs et $restaurants restaurants',
    de: '$drivers Fahrer und $restaurants Restaurants',
  );
  String get addUserTitle => _t(
    'Add user',
    'إضافة مستخدم',
    nl: 'Gebruiker toevoegen',
    fr: 'Ajouter un utilisateur',
    de: 'Benutzer hinzufügen',
  );
  String get addUserAction => addUserTitle;
  String get addUserSubtitle => _t(
    'Create a customer or restaurant login account.',
    'أنشئ حساب دخول لعميل أو مطعم.',
    nl: 'Maak een inlogaccount voor een klant of restaurant.',
    fr: 'Créez un compte de connexion client ou restaurant.',
    de: 'Erstellen Sie ein Anmeldekonto für einen Kunden oder ein Restaurant.',
  );
  String get chooseAccountType => _t(
    'Choose account type',
    'اختر نوع الحساب',
    nl: 'Kies het accounttype',
    fr: 'Choisir le type de compte',
    de: 'Kontotyp auswählen',
  );
  String get chooseAccountTypeDescription => _t(
    'Select how this user will access TaybGo.',
    'حدد كيفية استخدام هذا المستخدم لتطبيق TaybGo.',
    nl: 'Selecteer hoe deze gebruiker TaybGo gebruikt.',
    fr: 'Sélectionnez comment cet utilisateur accédera à TaybGo.',
    de: 'Wählen Sie aus, wie dieser Benutzer auf TaybGo zugreift.',
  );
  String get customerAccount =>
      _t('Customer', 'عميل', nl: 'Klant', fr: 'Client', de: 'Kunde');
  String get customerAccountDescription => _t(
    'For ordering food and using TaybGo services.',
    'لطلب الطعام واستخدام خدمات TaybGo.',
    nl: 'Voor het bestellen van eten en het gebruiken van TaybGo-diensten.',
    fr: 'Pour commander des repas et utiliser les services TaybGo.',
    de: 'Zum Bestellen von Essen und Nutzen der TaybGo-Dienste.',
  );
  String get restaurantAccount => _t(
    'Restaurant',
    'مطعم',
    nl: 'Restaurant',
    fr: 'Restaurant',
    de: 'Restaurant',
  );
  String get restaurantAccountDescription => _t(
    'Creates the seller login used to set up a restaurant.',
    'ينشئ حساب البائع المستخدم لإعداد المطعم.',
    nl: 'Maakt de verkoperslogin waarmee een restaurant wordt ingesteld.',
    fr: 'Crée le compte vendeur utilisé pour configurer un restaurant.',
    de: 'Erstellt das Verkäuferkonto zum Einrichten eines Restaurants.',
  );
  String get accountOnlyNoticeTitle => _t(
    'Account only',
    'الحساب فقط',
    nl: 'Alleen account',
    fr: 'Compte uniquement',
    de: 'Nur Konto',
  );
  String get accountOnlyNotice => _t(
    'This creates login access and the selected role only. It does not create a restaurant or any other profile.',
    'ينشئ هذا الإجراء بيانات الدخول والدور المحدد فقط، ولا ينشئ مطعماً أو أي ملف شخصي آخر.',
    nl: 'Dit maakt alleen inlogtoegang en de gekozen rol aan. Er wordt geen restaurant of ander profiel aangemaakt.',
    fr: 'Cela crée uniquement l’accès et le rôle sélectionné. Aucun restaurant ni autre profil n’est créé.',
    de: 'Dadurch werden nur der Zugang und die ausgewählte Rolle erstellt. Es wird kein Restaurant oder anderes Profil angelegt.',
  );
  String get userDetails => _t(
    'User details',
    'بيانات المستخدم',
    nl: 'Gebruikersgegevens',
    fr: 'Informations utilisateur',
    de: 'Benutzerdaten',
  );
  String get userDetailsDescription => _t(
    'Enter the details the user will use to sign in.',
    'أدخل البيانات التي سيستخدمها المستخدم لتسجيل الدخول.',
    nl: 'Voer de gegevens in waarmee de gebruiker inlogt.',
    fr: 'Saisissez les informations que l’utilisateur utilisera pour se connecter.',
    de: 'Geben Sie die Daten ein, mit denen sich der Benutzer anmeldet.',
  );
  String get password => _t(
    'Password',
    'كلمة المرور',
    nl: 'Wachtwoord',
    fr: 'Mot de passe',
    de: 'Passwort',
  );
  String get passwordHelp => _t(
    'Use at least 8 characters. A stronger password may be required by the server.',
    'استخدم 8 أحرف على الأقل. قد يطلب الخادم كلمة مرور أقوى.',
    nl: 'Gebruik minimaal 8 tekens. De server kan een sterker wachtwoord vereisen.',
    fr: 'Utilisez au moins 8 caractères. Le serveur peut exiger un mot de passe plus fort.',
    de: 'Verwenden Sie mindestens 8 Zeichen. Der Server kann ein stärkeres Passwort verlangen.',
  );
  String get generatePassword => _t(
    'Generate password',
    'إنشاء كلمة مرور',
    nl: 'Wachtwoord genereren',
    fr: 'Générer un mot de passe',
    de: 'Passwort generieren',
  );
  String get copyPassword => _t(
    'Copy password',
    'نسخ كلمة المرور',
    nl: 'Wachtwoord kopiëren',
    fr: 'Copier le mot de passe',
    de: 'Passwort kopieren',
  );
  String get passwordCopied => _t(
    'Password copied.',
    'تم نسخ كلمة المرور.',
    nl: 'Wachtwoord gekopieerd.',
    fr: 'Mot de passe copié.',
    de: 'Passwort kopiert.',
  );
  String get passwordTooShort => _t(
    'Password must contain at least 8 characters.',
    'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل.',
    nl: 'Het wachtwoord moet minimaal 8 tekens bevatten.',
    fr: 'Le mot de passe doit contenir au moins 8 caractères.',
    de: 'Das Passwort muss mindestens 8 Zeichen enthalten.',
  );
  String get passwordTooLong => _t(
    'Password cannot exceed 128 characters.',
    'لا يمكن أن تتجاوز كلمة المرور 128 حرفاً.',
    nl: 'Het wachtwoord mag niet langer zijn dan 128 tekens.',
    fr: 'Le mot de passe ne peut pas dépasser 128 caractères.',
    de: 'Das Passwort darf höchstens 128 Zeichen lang sein.',
  );
  String get resetPassword => _t(
    'Reset password',
    'إعادة تعيين كلمة المرور',
    nl: 'Wachtwoord opnieuw instellen',
    fr: 'Réinitialiser le mot de passe',
    de: 'Passwort zurücksetzen',
  );
  String get resetPasswordDescription => _t(
    'Set a new login password for this account. Existing refresh sessions will be revoked.',
    'عيّن كلمة مرور جديدة لهذا الحساب. سيتم إلغاء جلسات تسجيل الدخول الحالية.',
    nl: 'Stel een nieuw wachtwoord in. Bestaande aanmeldsessies worden ingetrokken.',
    fr: 'Définissez un nouveau mot de passe. Les sessions existantes seront révoquées.',
    de: 'Legen Sie ein neues Passwort fest. Bestehende Sitzungen werden widerrufen.',
  );
  String get newPassword => _t(
    'New password',
    'كلمة المرور الجديدة',
    nl: 'Nieuw wachtwoord',
    fr: 'Nouveau mot de passe',
    de: 'Neues Passwort',
  );
  String get confirmPassword => _t(
    'Confirm password',
    'تأكيد كلمة المرور',
    nl: 'Wachtwoord bevestigen',
    fr: 'Confirmer le mot de passe',
    de: 'Passwort bestätigen',
  );
  String get passwordsDoNotMatch => _t(
    'Passwords do not match.',
    'كلمتا المرور غير متطابقتين.',
    nl: 'De wachtwoorden komen niet overeen.',
    fr: 'Les mots de passe ne correspondent pas.',
    de: 'Die Passwörter stimmen nicht überein.',
  );
  String get showPassword => _t(
    'Show password',
    'إظهار كلمة المرور',
    nl: 'Wachtwoord tonen',
    fr: 'Afficher le mot de passe',
    de: 'Passwort anzeigen',
  );
  String get hidePassword => _t(
    'Hide password',
    'إخفاء كلمة المرور',
    nl: 'Wachtwoord verbergen',
    fr: 'Masquer le mot de passe',
    de: 'Passwort ausblenden',
  );
  String get passwordResetSuccessfully => _t(
    'Password reset successfully.',
    'تمت إعادة تعيين كلمة المرور بنجاح.',
    nl: 'Het wachtwoord is opnieuw ingesteld.',
    fr: 'Le mot de passe a été réinitialisé.',
    de: 'Das Passwort wurde zurückgesetzt.',
  );
  String get selectAccountTypeError => _t(
    'Select Customer or Restaurant.',
    'اختر عميل أو مطعم.',
    nl: 'Selecteer Klant of Restaurant.',
    fr: 'Sélectionnez Client ou Restaurant.',
    de: 'Wählen Sie Kunde oder Restaurant.',
  );
  String get duplicatePhone => _t(
    'An account with this phone number already exists.',
    'يوجد حساب مرتبط برقم الهاتف هذا بالفعل.',
    nl: 'Er bestaat al een account met dit telefoonnummer.',
    fr: 'Un compte avec ce numéro de téléphone existe déjà.',
    de: 'Ein Konto mit dieser Telefonnummer existiert bereits.',
  );
  String get userCreatedSuccessfully => _t(
    'User account created successfully.',
    'تم إنشاء حساب المستخدم بنجاح.',
    nl: 'Gebruikersaccount is aangemaakt.',
    fr: 'Le compte utilisateur a été créé.',
    de: 'Das Benutzerkonto wurde erstellt.',
  );
  String get createDriverTitle => _t(
    'Create driver',
    'إنشاء سائق',
    nl: 'Chauffeur aanmaken',
    fr: 'Créer un chauffeur',
    de: 'Fahrer erstellen',
  );
  String get createDriverAction => _t(
    'Create driver',
    'إنشاء السائق',
    nl: 'Chauffeur aanmaken',
    fr: 'Créer le chauffeur',
    de: 'Fahrer erstellen',
  );
  String get createDriverSubtitle => _t(
    'Add an approved driver account, service preferences, vehicle, and address.',
    'أضف حساب سائق معتمد وخدماته ومركبته وعنوانه.',
    nl: 'Voeg een goedgekeurde chauffeur toe met diensten, voertuig en adres.',
    fr: 'Ajoutez un chauffeur approuvé avec ses services, son véhicule et son adresse.',
    de: 'Erstellen Sie einen genehmigten Fahrer mit Diensten, Fahrzeug und Adresse.',
  );
  String get createRestaurantTitle => _t(
    'Create restaurant',
    'إنشاء مطعم',
    nl: 'Restaurant aanmaken',
    fr: 'Créer un restaurant',
    de: 'Restaurant erstellen',
  );
  String get createRestaurantAction => _t(
    'Create restaurant',
    'إنشاء المطعم',
    nl: 'Restaurant aanmaken',
    fr: 'Créer le restaurant',
    de: 'Restaurant erstellen',
  );
  String get createRestaurantSubtitle => _t(
    'Create the owner account and activate a restaurant in one step.',
    'أنشئ حساب المالك وفعّل المطعم في خطوة واحدة.',
    nl: 'Maak het eigenaarsaccount en activeer het restaurant in één stap.',
    fr: 'Créez le compte propriétaire et activez le restaurant en une étape.',
    de: 'Erstellen Sie das Inhaberkonto und aktivieren Sie das Restaurant in einem Schritt.',
  );
  String get accountDetails => _t(
    'Account details',
    'بيانات الحساب',
    nl: 'Accountgegevens',
    fr: 'Informations du compte',
    de: 'Kontodaten',
  );
  String get accountDetailsDescription => _t(
    'The contact information used for the driver account.',
    'معلومات الاتصال المستخدمة لحساب السائق.',
    nl: 'De contactgegevens voor het chauffeursaccount.',
    fr: 'Les coordonnées utilisées pour le compte chauffeur.',
    de: 'Die Kontaktdaten für das Fahrerkonto.',
  );
  String get ownerAccount => _t(
    'Owner account',
    'حساب المالك',
    nl: 'Eigenaarsaccount',
    fr: 'Compte propriétaire',
    de: 'Inhaberkonto',
  );
  String get ownerAccountDescription => _t(
    'This person will own and manage the restaurant.',
    'سيملك هذا الشخص المطعم ويديره.',
    nl: 'Deze persoon wordt eigenaar en beheerder van het restaurant.',
    fr: 'Cette personne possédera et gérera le restaurant.',
    de: 'Diese Person wird das Restaurant besitzen und verwalten.',
  );
  String get optional => _t(
    'optional',
    'اختياري',
    nl: 'optioneel',
    fr: 'facultatif',
    de: 'optional',
  );
  String get birthdate => _t(
    'Birthdate',
    'تاريخ الميلاد',
    nl: 'Geboortedatum',
    fr: 'Date de naissance',
    de: 'Geburtsdatum',
  );
  String get selectBirthdate => _t(
    'Select a date',
    'اختر تاريخاً',
    nl: 'Selecteer een datum',
    fr: 'Sélectionner une date',
    de: 'Datum auswählen',
  );
  String get addressDetailsDescription => _t(
    'Search Google Places and select the exact address for accurate assignment.',
    'ابحث في أماكن Google واختر العنوان الدقيق لربط الحساب بشكل صحيح.',
    nl: 'Zoek in Google Places en selecteer het exacte adres voor de juiste toewijzing.',
    fr: "Recherchez dans Google Places et sélectionnez l’adresse exacte pour une attribution correcte.",
    de: 'Suchen Sie in Google Places und wählen Sie die genaue Adresse für die richtige Zuordnung.',
  );
  String get searchAddress => _t(
    'Search for an address',
    'ابحث عن عنوان',
    nl: 'Adres zoeken',
    fr: 'Rechercher une adresse',
    de: 'Adresse suchen',
  );
  String get searchAddressHint => _t(
    'Start typing a street, business, or place',
    'ابدأ بكتابة شارع أو نشاط تجاري أو مكان',
    nl: 'Typ een straat, bedrijf of plaats',
    fr: 'Saisissez une rue, un commerce ou un lieu',
    de: 'Straße, Unternehmen oder Ort eingeben',
  );
  String get googlePlacesSearchHelp => _t(
    'Type at least 3 characters, then select a Google suggestion.',
    'اكتب 3 أحرف على الأقل، ثم اختر أحد اقتراحات Google.',
    nl: 'Typ minimaal 3 tekens en selecteer daarna een Google-suggestie.',
    fr: 'Saisissez au moins 3 caractères, puis choisissez une suggestion Google.',
    de: 'Geben Sie mindestens 3 Zeichen ein und wählen Sie dann einen Google-Vorschlag.',
  );
  String get googlePlacesUnavailable => _t(
    'Address search is unavailable. Configure the Google Places API key.',
    'البحث عن العنوان غير متاح. قم بإعداد مفتاح Google Places API.',
    nl: 'Adres zoeken is niet beschikbaar. Configureer de Google Places API-sleutel.',
    fr: 'La recherche d’adresse est indisponible. Configurez la clé API Google Places.',
    de: 'Die Adresssuche ist nicht verfügbar. Konfigurieren Sie den Google Places API-Schlüssel.',
  );
  String get noAddressResults => _t(
    'No matching addresses found.',
    'لم يتم العثور على عناوين مطابقة.',
    nl: 'Geen overeenkomende adressen gevonden.',
    fr: 'Aucune adresse correspondante trouvée.',
    de: 'Keine passende Adresse gefunden.',
  );
  String get addressSelected => _t(
    'Address selected',
    'تم اختيار العنوان',
    nl: 'Adres geselecteerd',
    fr: 'Adresse sélectionnée',
    de: 'Adresse ausgewählt',
  );
  String get selectAddressSuggestion => _t(
    'Select an address from the Google suggestions.',
    'اختر عنواناً من اقتراحات Google.',
    nl: 'Selecteer een adres uit de Google-suggesties.',
    fr: 'Sélectionnez une adresse parmi les suggestions Google.',
    de: 'Wählen Sie eine Adresse aus den Google-Vorschlägen.',
  );
  String get completeAddressRequired => _t(
    'Select a complete address that includes a city and country.',
    'اختر عنواناً كاملاً يتضمن المدينة والدولة.',
    nl: 'Selecteer een volledig adres met plaats en land.',
    fr: 'Sélectionnez une adresse complète comprenant une ville et un pays.',
    de: 'Wählen Sie eine vollständige Adresse mit Stadt und Land.',
  );
  String get googlePlacesSearchError => _t(
    'Could not search Google Places. Check the API access and connection.',
    'تعذر البحث في أماكن Google. تحقق من صلاحية الواجهة والاتصال.',
    nl: 'Google Places kon niet worden doorzocht. Controleer de API-toegang en verbinding.',
    fr: 'Impossible de rechercher dans Google Places. Vérifiez l’accès à l’API et la connexion.',
    de: 'Google Places konnte nicht durchsucht werden. Prüfen Sie API-Zugriff und Verbindung.',
  );
  String get addressLabelHint => _t(
    'e.g. home or office',
    'مثلاً المنزل أو المكتب',
    nl: 'bijv. thuis of kantoor',
    fr: 'p. ex. domicile ou bureau',
    de: 'z. B. Zuhause oder Büro',
  );
  String get restaurantAddressLabelHint => _t(
    'e.g. main branch',
    'مثلاً الفرع الرئيسي',
    nl: 'bijv. hoofdvestiging',
    fr: 'p. ex. établissement principal',
    de: 'z. B. Hauptfiliale',
  );
  String get latitude => _t(
    'Latitude',
    'خط العرض',
    nl: 'Breedtegraad',
    fr: 'Latitude',
    de: 'Breitengrad',
  );
  String get longitude => _t(
    'Longitude',
    'خط الطول',
    nl: 'Lengtegraad',
    fr: 'Longitude',
    de: 'Längengrad',
  );
  String get coordinateHelp => _t(
    'Decimal degrees, up to 6 decimal places.',
    'درجات عشرية، حتى 6 منازل عشرية.',
    nl: 'Decimale graden, maximaal 6 decimalen.',
    fr: 'Degrés décimaux, jusqu’à 6 décimales.',
    de: 'Dezimalgrad mit bis zu 6 Nachkommastellen.',
  );
  String get vehicleDetails => _t(
    'Vehicle details',
    'بيانات المركبة',
    nl: 'Voertuiggegevens',
    fr: 'Informations du véhicule',
    de: 'Fahrzeugdaten',
  );
  String get vehicleDetailsDescription => _t(
    'Choose car or bike. All identifying details are required for cars.',
    'اختر سيارة أو دراجة. جميع بيانات التعريف مطلوبة للسيارات.',
    nl: 'Kies auto of fiets. Alle identificatiegegevens zijn verplicht voor auto’s.',
    fr: 'Choisissez voiture ou vélo. Tous les renseignements sont obligatoires pour les voitures.',
    de: 'Wählen Sie Auto oder Fahrrad. Für Autos sind alle Fahrzeugdaten erforderlich.',
  );
  String get vehiclePlateNumber => _t(
    'Plate number',
    'رقم اللوحة',
    nl: 'Kenteken',
    fr: 'Plaque d’immatriculation',
    de: 'Kennzeichen',
  );
  String get vehicleColor => _t(
    'Vehicle color',
    'لون المركبة',
    nl: 'Voertuigkleur',
    fr: 'Couleur du véhicule',
    de: 'Fahrzeugfarbe',
  );
  String get vehicleMake => _t(
    'Vehicle make',
    'الشركة المصنعة',
    nl: 'Merk',
    fr: 'Marque du véhicule',
    de: 'Fahrzeugmarke',
  );
  String get vehicleModel => _t(
    'Vehicle model',
    'طراز المركبة',
    nl: 'Model',
    fr: 'Modèle du véhicule',
    de: 'Fahrzeugmodell',
  );
  String get vehicleYear => _t(
    'Vehicle year',
    'سنة الصنع',
    nl: 'Bouwjaar',
    fr: 'Année du véhicule',
    de: 'Baujahr',
  );
  String get serviceTypesDescription => _t(
    'Choose at least one type of job this driver can accept.',
    'اختر نوعاً واحداً على الأقل من الطلبات التي يمكن للسائق قبولها.',
    nl: 'Kies minimaal één opdrachttype dat de chauffeur kan aannemen.',
    fr: 'Choisissez au moins un type de course que le chauffeur peut accepter.',
    de: 'Wählen Sie mindestens einen Auftragstyp für den Fahrer.',
  );
  String get optionalDocuments => _t(
    'Driver documents',
    'مستندات السائق',
    nl: 'Chauffeursdocumenten',
    fr: 'Documents du chauffeur',
    de: 'Fahrerdokumente',
  );
  String get optionalDocumentsDescription => _t(
    'Upload each required document to Cloudinary. Only other documents are optional.',
    'ارفع كل مستند مطلوب إلى Cloudinary. المستندات الأخرى فقط اختيارية.',
    nl: 'Upload elk verplicht document naar Cloudinary. Alleen overige documenten zijn optioneel.',
    fr: 'Importez chaque document obligatoire dans Cloudinary. Seuls les autres documents sont facultatifs.',
    de: 'Laden Sie jedes Pflichtdokument zu Cloudinary hoch. Nur weitere Dokumente sind optional.',
  );
  String get uploadFile =>
      _t('Upload', 'رفع', nl: 'Uploaden', fr: 'Importer', de: 'Hochladen');
  String get replaceFile => _t(
    'Replace',
    'استبدال',
    nl: 'Vervangen',
    fr: 'Remplacer',
    de: 'Ersetzen',
  );
  String get uploadingFile => _t(
    'Uploading to Cloudinary…',
    'جارٍ الرفع إلى Cloudinary…',
    nl: 'Uploaden naar Cloudinary…',
    fr: 'Importation vers Cloudinary…',
    de: 'Upload zu Cloudinary…',
  );
  String get uploadFailed => _t(
    'Upload failed. Check the file and try again.',
    'فشل الرفع. تحقق من الملف وحاول مرة أخرى.',
    nl: 'Upload mislukt. Controleer het bestand en probeer opnieuw.',
    fr: 'Échec de l’importation. Vérifiez le fichier et réessayez.',
    de: 'Upload fehlgeschlagen. Prüfen Sie die Datei und versuchen Sie es erneut.',
  );
  String get fileTooLarge => _t(
    'The file must be 10 MB or smaller.',
    'يجب ألا يزيد حجم الملف عن 10 ميغابايت.',
    nl: 'Het bestand mag maximaal 10 MB zijn.',
    fr: 'Le fichier doit faire 10 Mo maximum.',
    de: 'Die Datei darf höchstens 10 MB groß sein.',
  );
  String get documentFileTypesHelp => _t(
    'PDF, JPG, PNG or WEBP · max 10 MB',
    'PDF أو JPG أو PNG أو WEBP · بحد أقصى 10 ميغابايت',
    nl: 'PDF, JPG, PNG of WEBP · max. 10 MB',
    fr: 'PDF, JPG, PNG ou WEBP · 10 Mo max.',
    de: 'PDF, JPG, PNG oder WEBP · max. 10 MB',
  );
  String get imageFileTypesHelp => _t(
    'JPG, PNG or WEBP · max 10 MB',
    'JPG أو PNG أو WEBP · بحد أقصى 10 ميغابايت',
    nl: 'JPG, PNG of WEBP · max. 10 MB',
    fr: 'JPG, PNG ou WEBP · 10 Mo max.',
    de: 'JPG, PNG oder WEBP · max. 10 MB',
  );
  String get documentUrlHelp => _t(
    'Must start with http:// or https://',
    'يجب أن يبدأ بـ http:// أو https://',
    nl: 'Moet beginnen met http:// of https://',
    fr: 'Doit commencer par http:// ou https://',
    de: 'Muss mit http:// oder https:// beginnen',
  );
  String get adminNotes => _t(
    'Admin notes',
    'ملاحظات الإدارة',
    nl: 'Beheerdersnotities',
    fr: 'Notes administrateur',
    de: 'Admin-Notizen',
  );
  String get adminNotesDescription => _t(
    'Internal context about this driver. It is not shown to the driver.',
    'معلومات داخلية عن السائق لا تظهر له.',
    nl: 'Interne context over deze chauffeur; niet zichtbaar voor de chauffeur.',
    fr: 'Contexte interne sur ce chauffeur, non visible par celui-ci.',
    de: 'Interne Hinweise, die dem Fahrer nicht angezeigt werden.',
  );
  String get restaurantProfileDescription => _t(
    'Public restaurant details, contact number, license, and delivery preference.',
    'بيانات المطعم العامة ورقم الاتصال والترخيص وخيار التوصيل.',
    nl: 'Openbare restaurantgegevens, telefoonnummer, vergunning en bezorgvoorkeur.',
    fr: 'Informations publiques, téléphone, licence et préférence de livraison.',
    de: 'Öffentliche Restaurantdaten, Telefonnummer, Lizenz und Lieferoption.',
  );
  String get restaurantName => _t(
    'Restaurant name',
    'اسم المطعم',
    nl: 'Restaurantnaam',
    fr: 'Nom du restaurant',
    de: 'Restaurantname',
  );
  String get restaurantPhone => _t(
    'Restaurant phone',
    'هاتف المطعم',
    nl: 'Telefoon restaurant',
    fr: 'Téléphone du restaurant',
    de: 'Restauranttelefon',
  );
  String get useOwnerPhone => _t(
    'Use owner phone',
    'استخدم هاتف المالك',
    nl: 'Telefoon eigenaar gebruiken',
    fr: 'Utiliser le téléphone du propriétaire',
    de: 'Telefon des Inhabers verwenden',
  );
  String get logoUrl => _t(
    'Restaurant logo',
    'شعار المطعم',
    nl: 'Restaurantlogo',
    fr: 'Logo du restaurant',
    de: 'Restaurantlogo',
  );
  String get registrationLicenseUrl => _t(
    'Registration license',
    'رخصة تسجيل المطعم',
    nl: 'Registratievergunning',
    fr: 'Licence d’enregistrement',
    de: 'Registrierungslizenz',
  );
  String get deliveryEnabled => _t(
    'Platform delivery enabled',
    'تفعيل توصيل المنصة',
    nl: 'Platformbezorging ingeschakeld',
    fr: 'Livraison de la plateforme activée',
    de: 'Plattformlieferung aktiviert',
  );
  String get deliveryEnabledDescription => _t(
    'The restaurant can request TaybGo drivers for its orders.',
    'يمكن للمطعم طلب سائقي TaybGo لتوصيل طلباته.',
    nl: 'Het restaurant kan TaybGo-chauffeurs aanvragen voor bestellingen.',
    fr: 'Le restaurant peut demander des chauffeurs TaybGo pour ses commandes.',
    de: 'Das Restaurant kann TaybGo-Fahrer für Bestellungen anfordern.',
  );
  String get openingHoursDescription => _t(
    'Set local opening hours. Overnight ranges are supported.',
    'حدد ساعات العمل المحلية. يمكن تحديد دوام يمتد بعد منتصف الليل.',
    nl: 'Stel lokale openingstijden in. Nachtelijke tijden worden ondersteund.',
    fr: 'Définissez les horaires locaux. Les plages de nuit sont prises en charge.',
    de: 'Legen Sie lokale Öffnungszeiten fest. Zeiten über Mitternacht werden unterstützt.',
  );
  String get requiredField => _t(
    'This field is required.',
    'هذا الحقل مطلوب.',
    nl: 'Dit veld is verplicht.',
    fr: 'Ce champ est obligatoire.',
    de: 'Dieses Feld ist erforderlich.',
  );
  String get invalidPhone => _t(
    'Enter a valid phone number.',
    'أدخل رقم هاتف صالحاً.',
    nl: 'Voer een geldig telefoonnummer in.',
    fr: 'Saisissez un numéro de téléphone valide.',
    de: 'Geben Sie eine gültige Telefonnummer ein.',
  );
  String get invalidEmail => _t(
    'Enter a valid email address.',
    'أدخل بريداً إلكترونياً صالحاً.',
    nl: 'Voer een geldig e-mailadres in.',
    fr: 'Saisissez une adresse e-mail valide.',
    de: 'Geben Sie eine gültige E-Mail-Adresse ein.',
  );
  String get invalidLatitude => _t(
    'Latitude must be between -90 and 90.',
    'يجب أن يكون خط العرض بين -90 و90.',
    nl: 'Breedtegraad moet tussen -90 en 90 liggen.',
    fr: 'La latitude doit être comprise entre -90 et 90.',
    de: 'Der Breitengrad muss zwischen -90 und 90 liegen.',
  );
  String get invalidLongitude => _t(
    'Longitude must be between -180 and 180.',
    'يجب أن يكون خط الطول بين -180 و180.',
    nl: 'Lengtegraad moet tussen -180 en 180 liggen.',
    fr: 'La longitude doit être comprise entre -180 et 180.',
    de: 'Der Längengrad muss zwischen -180 und 180 liegen.',
  );
  String get invalidVehicleYear => _t(
    'Enter a valid vehicle year.',
    'أدخل سنة صنع صالحة.',
    nl: 'Voer een geldig bouwjaar in.',
    fr: 'Saisissez une année de véhicule valide.',
    de: 'Geben Sie ein gültiges Baujahr ein.',
  );
  String get invalidUrl => _t(
    'Enter a valid HTTP or HTTPS URL.',
    'أدخل رابط HTTP أو HTTPS صالحاً.',
    nl: 'Voer een geldige HTTP- of HTTPS-URL in.',
    fr: 'Saisissez une URL HTTP ou HTTPS valide.',
    de: 'Geben Sie eine gültige HTTP- oder HTTPS-URL ein.',
  );
  String get atLeastOneService => _t(
    'Select at least one service type.',
    'اختر نوع خدمة واحداً على الأقل.',
    nl: 'Selecteer minimaal één servicetype.',
    fr: 'Sélectionnez au moins un type de service.',
    de: 'Wählen Sie mindestens einen Diensttyp.',
  );
  String get openCloseTimesMustDiffer => _t(
    'Opening and closing times must be different.',
    'يجب أن يختلف وقت الفتح عن وقت الإغلاق.',
    nl: 'Openings- en sluitingstijd moeten verschillen.',
    fr: 'Les heures d’ouverture et de fermeture doivent être différentes.',
    de: 'Öffnungs- und Schließzeit müssen unterschiedlich sein.',
  );
  String get driverCreatedSuccessfully => _t(
    'Driver created successfully.',
    'تم إنشاء السائق بنجاح.',
    nl: 'Chauffeur succesvol aangemaakt.',
    fr: 'Chauffeur créé avec succès.',
    de: 'Fahrer erfolgreich erstellt.',
  );
  String get restaurantCreatedSuccessfully => _t(
    'Restaurant created successfully.',
    'تم إنشاء المطعم بنجاح.',
    nl: 'Restaurant succesvol aangemaakt.',
    fr: 'Restaurant créé avec succès.',
    de: 'Restaurant erfolgreich erstellt.',
  );
  String get pricingPolicies => _t(
    'Pricing Policies',
    'سياسات التسعير',
    nl: 'Prijsbeleid',
    fr: 'Politiques tarifaires',
    de: 'Preisrichtlinien',
  );
  String pricingPoliciesSubtitle(int count) => _t(
    '$count pricing policies',
    '$count سياسة تسعير',
    nl: '$count prijsregels',
    fr: '$count politiques tarifaires',
    de: '$count Preisrichtlinien',
  );
  String get pricingPolicyDetails => _t(
    'Policy details',
    'تفاصيل السياسة',
    nl: 'Details van beleid',
    fr: 'Détails de la politique',
    de: 'Richtliniendetails',
  );
  String get pricingModel => _t(
    'Pricing model',
    'نموذج التسعير',
    nl: 'Prijsmodel',
    fr: 'Modèle tarifaire',
    de: 'Preismodell',
  );
  String get driverPayout => _t(
    'Driver payout',
    'مستحقات السائق',
    nl: 'Uitbetaling chauffeur',
    fr: 'Rémunération du chauffeur',
    de: 'Fahrerauszahlung',
  );
  String get validity => _t(
    'Validity',
    'الصلاحية',
    nl: 'Geldigheid',
    fr: 'Validité',
    de: 'Gültigkeit',
  );
  String get createdAt => _t(
    'Created',
    'تاريخ الإنشاء',
    nl: 'Aangemaakt',
    fr: 'Créée',
    de: 'Erstellt',
  );
  String get noEndDate => _t(
    'Open-ended',
    'مفتوحة النهاية',
    nl: 'Zonder einddatum',
    fr: 'Sans date de fin',
    de: 'Ohne Enddatum',
  );
  String get notConfigured => _t(
    'Not configured',
    'غير مُعد',
    nl: 'Niet ingesteld',
    fr: 'Non configuré',
    de: 'Nicht konfiguriert',
  );
  String get activeFilters => _t(
    'active filters',
    'فلاتر نشطة',
    nl: 'actieve filters',
    fr: 'filtres actifs',
    de: 'aktive Filter',
  );
  String get filters =>
      _t('Filters', 'الفلاتر', nl: 'Filters', fr: 'Filtres', de: 'Filter');
  String get filterPolicies => _t(
    'Filter policies by scope, location, and service',
    'تصفية السياسات حسب النطاق والموقع والخدمة',
    nl: 'Beleid filteren op scope, locatie en service',
    fr: 'Filtrer les politiques par périmètre, lieu et service',
    de: 'Richtlinien nach Bereich, Ort und Service filtern',
  );
  String get viewPricingPolicy => _t(
    'View policy details',
    'عرض تفاصيل السياسة',
    nl: 'Beleidsdetails bekijken',
    fr: 'Voir les détails de la politique',
    de: 'Richtliniendetails anzeigen',
  );
  String get addPricingPolicy => _t(
    'Add policy',
    'إضافة سياسة',
    nl: 'Beleid toevoegen',
    fr: 'Ajouter une politique',
    de: 'Richtlinie hinzufügen',
  );
  String get editPricingPolicy => _t(
    'Edit pricing policy',
    'تعديل سياسة التسعير',
    nl: 'Prijsbeleid bewerken',
    fr: 'Modifier la politique tarifaire',
    de: 'Preisrichtlinie bearbeiten',
  );
  String get createPricingPolicy => _t(
    'Create pricing policy',
    'إنشاء سياسة تسعير',
    nl: 'Prijsbeleid aanmaken',
    fr: 'Créer une politique tarifaire',
    de: 'Preisrichtlinie erstellen',
  );
  String pricingPolicyDeleteConfirm(String name) => _t(
    'Delete "$name" permanently? This action cannot be undone.',
    'هل تريد حذف "$name" نهائيًا؟ لا يمكن التراجع عن هذا الإجراء.',
    nl: '"$name" permanent verwijderen? Dit kan niet ongedaan worden gemaakt.',
    fr: 'Supprimer définitivement « $name » ? Cette action est irréversible.',
    de: '"$name" dauerhaft löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
  );
  String get noPricingPolicies => _t(
    'No pricing policies found',
    'لم يتم العثور على سياسات تسعير',
    nl: 'Geen prijsbeleid gevonden',
    fr: 'Aucune politique tarifaire trouvée',
    de: 'Keine Preisrichtlinien gefunden',
  );
  String get searchPricingPolicies => _t(
    'Search pricing policies...',
    'ابحث في سياسات التسعير...',
    nl: 'Prijsbeleid zoeken...',
    fr: 'Rechercher des politiques tarifaires...',
    de: 'Preisrichtlinien suchen...',
  );
  String get allScopes => _t(
    'All scopes',
    'كل النطاقات',
    nl: 'Alle scopes',
    fr: 'Tous les périmètres',
    de: 'Alle Geltungsbereiche',
  );
  String get allCountries => _t(
    'All countries',
    'كل الدول',
    nl: 'Alle landen',
    fr: 'Tous les pays',
    de: 'Alle Länder',
  );
  String get countryFilter => _t(
    'Country filter',
    'فلتر الدولة',
    nl: 'Landenfilter',
    fr: 'Filtre pays',
    de: 'Länderfilter',
  );
  String get countryFilterDescription => _t(
    'Choose which country to view',
    'اختر الدولة التي تريد عرض بياناتها',
    nl: 'Kies het land waarvan u de gegevens wilt bekijken',
    fr: 'Choisissez le pays dont vous voulez voir les données',
    de: 'Wählen Sie das Land aus, dessen Daten Sie sehen möchten',
  );
  String get loadingCountries => _t(
    'Loading countries...',
    'جارٍ تحميل الدول...',
    nl: 'Landen laden...',
    fr: 'Chargement des pays...',
    de: 'Länder werden geladen...',
  );
  String get updatingCountryData => _t(
    'Updating country data...',
    'جارٍ تحديث بيانات الدولة...',
    nl: 'Landgegevens worden bijgewerkt...',
    fr: 'Mise à jour des données du pays...',
    de: 'Länderdaten werden aktualisiert...',
  );
  String get showingAllCountries => _t(
    'Showing all countries',
    'عرض بيانات جميع الدول',
    nl: 'Gegevens van alle landen',
    fr: 'Données de tous les pays',
    de: 'Daten aller Länder',
  );
  String showingCountry(String country) => _t(
    'Showing data for $country',
    'عرض بيانات $country',
    nl: 'Gegevens voor $country',
    fr: 'Données pour $country',
    de: 'Daten für $country',
  );
  String get allOrderTypes => _t(
    'All order types',
    'كل أنواع الطلبات',
    nl: 'Alle besteltypen',
    fr: 'Tous les types de commande',
    de: 'Alle Bestellarten',
  );
  String get selectDate => _t(
    'Select date',
    'اختر التاريخ',
    nl: 'Selecteer datum',
    fr: 'Sélectionner une date',
    de: 'Datum auswählen',
  );
  String get notSet => _t(
    'Not set',
    'غير محدد',
    nl: 'Niet ingesteld',
    fr: 'Non défini',
    de: 'Nicht festgelegt',
  );
  String get correctHighlightedFields => _t(
    'Please correct the highlighted fields.',
    'يرجى تصحيح الحقول المميزة.',
    nl: 'Corrigeer de gemarkeerde velden.',
    fr: 'Veuillez corriger les champs indiqués.',
    de: 'Bitte korrigieren Sie die markierten Felder.',
  );
  String get serverRejectedFields => _t(
    'The server rejected one or more fields.',
    'رفض الخادم حقلًا أو أكثر.',
    nl: 'De server heeft een of meer velden afgewezen.',
    fr: 'Le serveur a rejeté un ou plusieurs champs.',
    de: 'Der Server hat ein oder mehrere Felder abgelehnt.',
  );
  String get pricingActiveOpenEndedConflict => _t(
    'An active, open-ended policy already exists for this target. Edit it or choose a different target.',
    'توجد سياسة نشطة ومفتوحة النهاية لهذا الهدف. عدّلها أو اختر هدفًا مختلفًا.',
    nl: 'Er bestaat al een actief beleid zonder einddatum voor dit doel. Bewerk het of kies een ander doel.',
    fr: 'Une politique active sans date de fin existe déjà pour cette cible. Modifiez-la ou choisissez une autre cible.',
    de: 'Für dieses Ziel gibt es bereits eine aktive Richtlinie ohne Enddatum. Bearbeiten Sie sie oder wählen Sie ein anderes Ziel.',
  );
  String get pricingDuplicateVersion => _t(
    'This version already exists for the selected target. Edit the existing policy or choose a different target.',
    'هذا الإصدار موجود بالفعل للهدف المحدد. عدّل السياسة الحالية أو اختر هدفًا مختلفًا.',
    nl: 'Deze versie bestaat al voor het geselecteerde doel. Bewerk het bestaande beleid of kies een ander doel.',
    fr: 'Cette version existe déjà pour la cible sélectionnée. Modifiez la politique existante ou choisissez une autre cible.',
    de: 'Diese Version existiert bereits für das ausgewählte Ziel. Bearbeiten Sie die vorhandene Richtlinie oder wählen Sie ein anderes Ziel.',
  );
  String get pricingDuplicatePolicy => _t(
    'A policy with these settings already exists. Edit the existing policy instead.',
    'توجد سياسة بهذه الإعدادات بالفعل. عدّل السياسة الحالية بدلًا من ذلك.',
    nl: 'Er bestaat al een beleid met deze instellingen. Bewerk het bestaande beleid.',
    fr: 'Une politique avec ces paramètres existe déjà. Modifiez plutôt la politique existante.',
    de: 'Eine Richtlinie mit diesen Einstellungen existiert bereits. Bearbeiten Sie stattdessen die vorhandene Richtlinie.',
  );
  String get pricingNameRequired => _t(
    'Name is required.',
    'اسم السياسة مطلوب.',
    nl: 'Naam is verplicht.',
    fr: 'Le nom est obligatoire.',
    de: 'Der Name ist erforderlich.',
  );
  String get pricingInvalidScope => _t(
    'Select a valid scope.',
    'اختر نطاقًا صالحًا.',
    nl: 'Selecteer een geldige scope.',
    fr: 'Sélectionnez un périmètre valide.',
    de: 'Wählen Sie einen gültigen Geltungsbereich.',
  );
  String get pricingCountryRequired => _t(
    'Country is required for country policies.',
    'الدولة مطلوبة لسياسات الدول.',
    nl: 'Een land is verplicht voor landbeleid.',
    fr: 'Le pays est obligatoire pour les politiques par pays.',
    de: 'Ein Land ist für Länder-Richtlinien erforderlich.',
  );
  String get pricingCityRequired => _t(
    'City is required for city policies.',
    'المدينة مطلوبة لسياسات المدن.',
    nl: 'Een stad is verplicht voor stadsbeleid.',
    fr: 'La ville est obligatoire pour les politiques par ville.',
    de: 'Eine Stadt ist für Stadt-Richtlinien erforderlich.',
  );
  String get pricingCountryMustBeEmpty => _t(
    'Country must be empty for this scope.',
    'يجب ترك الدولة فارغة لهذا النطاق.',
    nl: 'Het land moet leeg zijn voor deze scope.',
    fr: 'Le pays doit être vide pour ce périmètre.',
    de: 'Das Land muss für diesen Geltungsbereich leer sein.',
  );
  String get pricingCityMustBeEmpty => _t(
    'City must be empty for this scope.',
    'يجب ترك المدينة فارغة لهذا النطاق.',
    nl: 'De stad moet leeg zijn voor deze scope.',
    fr: 'La ville doit être vide pour ce périmètre.',
    de: 'Die Stadt muss für diesen Geltungsbereich leer sein.',
  );
  String get pricingInvalidOrderType => _t(
    'Select a valid order type.',
    'اختر نوع طلب صالحًا.',
    nl: 'Selecteer een geldig besteltype.',
    fr: 'Sélectionnez un type de commande valide.',
    de: 'Wählen Sie eine gültige Bestellart.',
  );
  String get pricingInvalidVehicleType => _t(
    'Select a valid vehicle type.',
    'اختر نوع مركبة صالحًا.',
    nl: 'Selecteer een geldig voertuigtype.',
    fr: 'Sélectionnez un type de véhicule valide.',
    de: 'Wählen Sie einen gültigen Fahrzeugtyp.',
  );
  String get pricingNonNegativeNumber => _t(
    'Enter a number that is zero or greater.',
    'أدخل رقمًا يساوي صفرًا أو أكبر.',
    nl: 'Voer een getal van nul of hoger in.',
    fr: 'Saisissez un nombre supérieur ou égal à zéro.',
    de: 'Geben Sie eine Zahl größer oder gleich null ein.',
  );
  String get pricingPositiveSpeed => _t(
    'Speed must be a positive integer.',
    'يجب أن تكون السرعة عددًا صحيحًا موجبًا.',
    nl: 'Snelheid moet een positief geheel getal zijn.',
    fr: 'La vitesse doit être un entier positif.',
    de: 'Die Geschwindigkeit muss eine positive ganze Zahl sein.',
  );
  String get pricingCurrencyThreeLetters => _t(
    'Currency must be exactly three letters.',
    'يجب أن تتكون العملة من ثلاثة أحرف بالضبط.',
    nl: 'Valuta moet precies drie letters bevatten.',
    fr: 'La devise doit comporter exactement trois lettres.',
    de: 'Die Währung muss genau drei Buchstaben enthalten.',
  );
  String get pricingVersionNonnegative => _t(
    'Version must be a nonnegative integer.',
    'يجب أن يكون الإصدار عددًا صحيحًا غير سالب.',
    nl: 'Versie moet een niet-negatief geheel getal zijn.',
    fr: 'La version doit être un entier non négatif.',
    de: 'Die Version muss eine nicht-negative ganze Zahl sein.',
  );
  String get pricingEffectiveFromRequired => _t(
    'Effective from is required.',
    'تاريخ السريان مطلوب.',
    nl: 'Geldig vanaf is verplicht.',
    fr: 'La date de début est obligatoire.',
    de: 'Gültig ab ist erforderlich.',
  );
  String get pricingEffectiveToLater => _t(
    'Effective to must be later than effective from.',
    'يجب أن يكون تاريخ الانتهاء لاحقًا لتاريخ السريان.',
    nl: 'Geldig tot moet na geldig vanaf liggen.',
    fr: 'La date de fin doit être postérieure à la date de début.',
    de: 'Gültig bis muss nach Gültig ab liegen.',
  );
  String get failedToLoadCountries => _t(
    'Failed to load countries.',
    'تعذر تحميل الدول.',
    nl: 'Landen konden niet worden geladen.',
    fr: 'Échec du chargement des pays.',
    de: 'Länder konnten nicht geladen werden.',
  );
  String get failedToLoadCities => _t(
    'Failed to load cities.',
    'تعذر تحميل المدن.',
    nl: 'Steden konden niet worden geladen.',
    fr: 'Échec du chargement des villes.',
    de: 'Städte konnten nicht geladen werden.',
  );
  String pricingCountryNumber(int id) => _t(
    'Country #$id',
    'الدولة رقم $id',
    nl: 'Land #$id',
    fr: 'Pays n° $id',
    de: 'Land #$id',
  );
  String pricingCityNumber(int id) => _t(
    'City #$id',
    'المدينة رقم $id',
    nl: 'Stad #$id',
    fr: 'Ville n° $id',
    de: 'Stadt #$id',
  );
  String get scope => _t(
    'Scope',
    'النطاق',
    nl: 'Scope',
    fr: 'Périmètre',
    de: 'Geltungsbereich',
  );
  String get globalScope =>
      _t('Global', 'عالمي', nl: 'Globaal', fr: 'Global', de: 'Global');
  String get countryScope =>
      _t('Country', 'دولة', nl: 'Land', fr: 'Pays', de: 'Land');
  String get cityScope =>
      _t('City', 'مدينة', nl: 'Stad', fr: 'Ville', de: 'Stadt');
  String get allVehicles => _t(
    'All vehicles',
    'كل المركبات',
    nl: 'Alle voertuigen',
    fr: 'Tous les véhicules',
    de: 'Alle Fahrzeuge',
  );
  String get allActiveStates => _t(
    'All states',
    'كل الحالات',
    nl: 'Alle statussen',
    fr: 'Tous les états',
    de: 'Alle Zustände',
  );
  String get activeOnly => _t(
    'Active only',
    'النشطة فقط',
    nl: 'Alleen actief',
    fr: 'Actives uniquement',
    de: 'Nur aktive',
  );
  String get inactiveOnly => _t(
    'Inactive only',
    'غير النشطة فقط',
    nl: 'Alleen inactief',
    fr: 'Inactives uniquement',
    de: 'Nur inaktive',
  );
  String get applyFilters => _t(
    'Apply filters',
    'تطبيق الفلاتر',
    nl: 'Filters toepassen',
    fr: 'Appliquer les filtres',
    de: 'Filter anwenden',
  );
  String get save =>
      _t('Save', 'حفظ', nl: 'Opslaan', fr: 'Enregistrer', de: 'Speichern');
  String get create =>
      _t('Create', 'إنشاء', nl: 'Aanmaken', fr: 'Créer', de: 'Erstellen');
  String get delete =>
      _t('Delete', 'حذف', nl: 'Verwijderen', fr: 'Supprimer', de: 'Löschen');
  String get pricingName => _t(
    'Policy name',
    'اسم السياسة',
    nl: 'Naam van beleid',
    fr: 'Nom de la politique',
    de: 'Name der Richtlinie',
  );
  String get baseAmount => _t(
    'Base amount',
    'المبلغ الأساسي',
    nl: 'Basisbedrag',
    fr: 'Montant de base',
    de: 'Grundbetrag',
  );
  String get baseDistance => _t(
    'Base distance (km)',
    'المسافة الأساسية (كم)',
    nl: 'Basisafstand (km)',
    fr: 'Distance de base (km)',
    de: 'Basisdistanz (km)',
  );
  String get perKmRate => _t(
    'Per km rate',
    'السعر لكل كم',
    nl: 'Tarief per km',
    fr: 'Tarif au km',
    de: 'Preis pro km',
  );
  String get weightMultiplier => _t(
    'Weight multiplier',
    'معامل الوزن',
    nl: 'Gewichtsmultiplikator',
    fr: 'Multiplicateur de poids',
    de: 'Gewichtsmultiplikator',
  );
  String get averageSpeed => _t(
    'Average speed (km/h)',
    'السرعة المتوسطة (كم/س)',
    nl: 'Gemiddelde snelheid (km/u)',
    fr: 'Vitesse moyenne (km/h)',
    de: 'Durchschnittsgeschwindigkeit (km/h)',
  );
  String get currency =>
      _t('Currency', 'العملة', nl: 'Valuta', fr: 'Devise', de: 'Währung');
  String get effectiveFrom => _t(
    'Effective from',
    'ساري من',
    nl: 'Geldig vanaf',
    fr: 'Valable à partir du',
    de: 'Gültig ab',
  );
  String get effectiveTo => _t(
    'Effective to',
    'ساري حتى',
    nl: 'Geldig tot',
    fr: "Valable jusqu'au",
    de: 'Gültig bis',
  );
  String get driverBaseAmount => _t(
    'Driver base amount',
    'المبلغ الأساسي للسائق',
    nl: 'Basisbedrag chauffeur',
    fr: 'Montant de base chauffeur',
    de: 'Grundbetrag Fahrer',
  );
  String get driverBaseDistance => _t(
    'Driver base distance',
    'المسافة الأساسية للسائق',
    nl: 'Basisafstand chauffeur',
    fr: 'Distance de base chauffeur',
    de: 'Basisdistanz Fahrer',
  );
  String get driverPricePerKm => _t(
    'Driver price per km',
    'سعر السائق لكل كم',
    nl: 'Chauffeurprijs per km',
    fr: 'Prix chauffeur au km',
    de: 'Fahrerpreis pro km',
  );
  String get policyLocation => _t(
    'Policy location',
    'موقع السياسة',
    nl: 'Locatie van beleid',
    fr: 'Emplacement de la politique',
    de: 'Standort der Richtlinie',
  );
  String get policySaved => _t(
    'Pricing policy saved',
    'تم حفظ سياسة التسعير',
    nl: 'Prijsbeleid opgeslagen',
    fr: 'Politique tarifaire enregistrée',
    de: 'Preisrichtlinie gespeichert',
  );
  String get policyDeleted => _t(
    'Pricing policy deleted',
    'تم حذف سياسة التسعير',
    nl: 'Prijsbeleid verwijderd',
    fr: 'Politique tarifaire supprimée',
    de: 'Preisrichtlinie gelöscht',
  );
  String get selectCountry => _t(
    'Select country',
    'اختر الدولة',
    nl: 'Selecteer land',
    fr: 'Sélectionner un pays',
    de: 'Land auswählen',
  );
  String get selectCity => _t(
    'Select city',
    'اختر المدينة',
    nl: 'Selecteer stad',
    fr: 'Sélectionner une ville',
    de: 'Stadt auswählen',
  );
  String get support =>
      _t('Support', 'الدعم', nl: 'Ondersteuning', fr: 'Support', de: 'Support');
  String get profile =>
      _t('Profile', 'الملف الشخصي', nl: 'Profiel', fr: 'Profil', de: 'Profil');
  String get profileActions => _t(
    'Quick actions',
    'إجراءات سريعة',
    nl: 'Snelle acties',
    fr: 'Actions rapides',
    de: 'Schnellaktionen',
  );
  String get preferences => _t(
    'Preferences',
    'التفضيلات',
    nl: 'Voorkeuren',
    fr: 'Préférences',
    de: 'Präferenzen',
  );
  String get preferencesSubtitle => _t(
    'Theme, language, and display preferences',
    'تفضيلات المظهر واللغة والعرض',
    nl: 'Voorkeuren voor thema, taal en weergave',
    fr: 'Préférences de thème, de langue et d’affichage',
    de: 'Einstellungen für Design, Sprache und Anzeige',
  );
  String get versionControl => _t(
    'Version control',
    'إدارة الإصدارات',
    nl: 'Versiebeheer',
    fr: 'Gestion des versions',
    de: 'Versionsverwaltung',
  );
  String get versionControlSubtitle => _t(
    'Review the current app version and release history',
    'راجع إصدار التطبيق الحالي وسجل الإصدارات',
    nl: 'Bekijk de huidige appversie en releasegeschiedenis',
    fr: 'Consultez la version actuelle et l’historique des sorties',
    de: 'Aktuelle App-Version und Versionsverlauf anzeigen',
  );
  String get currentVersion => _t(
    'Current version',
    'الإصدار الحالي',
    nl: 'Huidige versie',
    fr: 'Version actuelle',
    de: 'Aktuelle Version',
  );
  String get latestRelease =>
      _t('Latest', 'الأحدث', nl: 'Nieuwste', fr: 'Dernière', de: 'Aktuell');
  String get releaseHistory => _t(
    'Release history',
    'سجل الإصدارات',
    nl: 'Releasegeschiedenis',
    fr: 'Historique des sorties',
    de: 'Versionsverlauf',
  );
  String releasedOn(String date) => _t(
    'Released $date',
    'صدر في $date',
    nl: 'Uitgebracht op $date',
    fr: 'Sortie le $date',
    de: 'Veröffentlicht am $date',
  );
  String get release1010Change1 => _t(
    'Added a unified, focused Add User flow for customer and restaurant accounts.',
    'إضافة مسار موحد ومركز لإضافة حسابات العملاء والمطاعم.',
    nl: 'Een uniforme, gerichte gebruikersflow toegevoegd voor klant- en restaurantaccounts.',
    fr: 'Ajout d’un parcours unifié et ciblé pour créer des comptes client et restaurant.',
    de: 'Einen einheitlichen, fokussierten Ablauf zum Hinzufügen von Kunden- und Restaurantkonten hinzugefügt.',
  );
  String get release1010Change2 => _t(
    'Made names mandatory and added secure generated passwords with copy support.',
    'جعل الاسم إلزامياً وإضافة إنشاء كلمات مرور آمنة مع إمكانية النسخ.',
    nl: 'Namen verplicht gemaakt en veilige gegenereerde wachtwoorden met kopieerfunctie toegevoegd.',
    fr: 'Nom rendu obligatoire et ajout de mots de passe sécurisés générés avec copie.',
    de: 'Namen verpflichtend gemacht und sichere generierte Passwörter mit Kopierfunktion hinzugefügt.',
  );
  String get release1010Change3 => _t(
    'Added password changes for drivers and restaurant owners with session revocation.',
    'إضافة تغيير كلمة المرور للسائقين ومالكي المطاعم مع إلغاء الجلسات القائمة.',
    nl: 'Wachtwoordwijzigingen toegevoegd voor chauffeurs en restauranteigenaren met intrekking van sessies.',
    fr: 'Ajout du changement de mot de passe pour chauffeurs et propriétaires avec révocation des sessions.',
    de: 'Passwortänderungen für Fahrer und Restaurantinhaber mit Sitzungswiderruf hinzugefügt.',
  );
  String get release1010Change4 => _t(
    'Added live configuration for OTP or password sign-in and required application updates.',
    'إضافة إعدادات مباشرة لتسجيل الدخول برمز OTP أو كلمة المرور وفرض تحديثات التطبيق.',
    nl: 'Live configuratie toegevoegd voor aanmelden met OTP of wachtwoord en verplichte app-updates.',
    fr: 'Ajout de la configuration dynamique pour la connexion par OTP ou mot de passe et les mises à jour obligatoires.',
    de: 'Live-Konfiguration für OTP- oder Passwortanmeldung und erforderliche App-Updates hinzugefügt.',
  );
  String get release1010Change5 => _t(
    'Added administrator application settings and expanded API and interface regression coverage.',
    'إضافة إعدادات التطبيق للمسؤول وتوسيع اختبارات الانحدار للواجهات وواجهات API.',
    nl: 'Beheerinstellingen voor de app en uitgebreidere regressiedekking voor API en interface toegevoegd.',
    fr: 'Ajout des paramètres administrateur et extension de la couverture de régression API et interface.',
    de: 'Administrator-App-Einstellungen und erweiterte API- und Oberflächen-Regressionstests hinzugefügt.',
  );
  String get release109Change1 => _t(
    'Added complete admin workflows for creating approved drivers and active restaurants.',
    'إضافة مسارات إدارية متكاملة لإنشاء سائقين معتمدين ومطاعم نشطة.',
    nl: 'Volledige beheerworkflows toegevoegd voor goedgekeurde chauffeurs en actieve restaurants.',
    fr: 'Ajout de parcours administrateur complets pour créer des chauffeurs approuvés et des restaurants actifs.',
    de: 'Vollständige Admin-Abläufe zum Erstellen genehmigter Fahrer und aktiver Restaurants hinzugefügt.',
  );
  String get release109Change2 => _t(
    'Added Google Places address search with structured location details and coordinates.',
    'إضافة البحث عن العناوين عبر Google Places مع تفاصيل الموقع والإحداثيات المنظمة.',
    nl: 'Google Places-adreszoekfunctie toegevoegd met gestructureerde locatiegegevens en coördinaten.',
    fr: 'Ajout de la recherche d’adresses Google Places avec détails structurés et coordonnées.',
    de: 'Google-Places-Adresssuche mit strukturierten Standortdaten und Koordinaten hinzugefügt.',
  );
  String get release109Change3 => _t(
    'Added international phone country pickers for driver, owner, and restaurant contacts.',
    'إضافة محددات الدولة الدولية لهواتف السائق والمالك والمطعم.',
    nl: 'Internationale landenkiezers toegevoegd voor telefoonnummers van chauffeur, eigenaar en restaurant.',
    fr: 'Ajout de sélecteurs de pays pour les téléphones du chauffeur, du propriétaire et du restaurant.',
    de: 'Internationale Länderauswahl für Fahrer-, Inhaber- und Restauranttelefonnummern hinzugefügt.',
  );
  String get release109Change4 => _t(
    'Limited vehicles to car and bike, required complete car details, and made taxi car-only.',
    'حصر المركبات في السيارة والدراجة، وإلزام بيانات السيارة الكاملة، وقصر خدمة التاكسي على السيارات.',
    nl: 'Voertuigen beperkt tot auto en fiets, volledige autogegevens verplicht en taxi alleen voor auto’s gemaakt.',
    fr: 'Véhicules limités à voiture et vélo, informations voiture obligatoires et taxi réservé aux voitures.',
    de: 'Fahrzeuge auf Auto und Fahrrad beschränkt, vollständige Autodaten vorgeschrieben und Taxi nur für Autos aktiviert.',
  );
  String get release109Change5 => _t(
    'Added Cloudinary uploads for required driver documents and restaurant assets with robust validation.',
    'إضافة رفع الملفات إلى Cloudinary لمستندات السائق المطلوبة وملفات المطعم مع تحقق شامل.',
    nl: 'Cloudinary-uploads toegevoegd voor verplichte chauffeursdocumenten en restaurantbestanden met grondige validatie.',
    fr: 'Ajout des importations Cloudinary pour les documents chauffeur obligatoires et les fichiers restaurant avec validation complète.',
    de: 'Cloudinary-Uploads für erforderliche Fahrerdokumente und Restaurantdateien mit robuster Validierung hinzugefügt.',
  );
  String get release108Change1 => _t(
    'Added a visible back button to the OTP verification screen.',
    'إضافة زر رجوع واضح إلى شاشة التحقق من رمز OTP.',
    nl: 'Een zichtbare terugknop toegevoegd aan het OTP-verificatiescherm.',
    fr: 'Ajout d’un bouton Retour visible sur l’écran de vérification OTP.',
    de: 'Eine sichtbare Zurück-Schaltfläche zum OTP-Bestätigungsbildschirm hinzugefügt.',
  );
  String get release108Change2 => _t(
    'Fixed Change phone number so it reliably returns administrators to sign-in.',
    'إصلاح خيار تغيير رقم الهاتف للعودة بموثوقية إلى شاشة تسجيل الدخول.',
    nl: 'Telefoonnummer wijzigen hersteld zodat beheerders betrouwbaar terugkeren naar aanmelden.',
    fr: 'Correction de Changer le numéro de téléphone afin de revenir fiablement à la connexion.',
    de: '„Telefonnummer ändern“ korrigiert, sodass Administratoren zuverlässig zur Anmeldung zurückkehren.',
  );
  String get release107Change1 => _t(
    'Redesigned the Partners workspace with a compact app bar, shared search toggle, partner switcher, status cards, and smoother list/map browsing.',
    'إعادة تصميم مساحة الشركاء مع شريط علوي مختصر، ومفتاح بحث مشترك، ومبدّل للشركاء، وبطاقات للحالات، وتصفح أسهل بين القائمة والخريطة.',
    nl: 'De Partner-werkruimte vernieuwd met een compacte appbalk, gedeelde zoekknop, partnerwisselaar, statuskaarten en soepelere lijst- en kaartweergave.',
    fr: 'Espace Partenaires repensé avec une barre d’application compacte, une recherche partagée, un sélecteur de partenaires, des cartes d’état et une navigation liste/carte plus fluide.',
    de: 'Den Partnerbereich mit kompakter App-Leiste, gemeinsamer Suche, Partner-Umschalter, Statuskarten und flüssigerer Listen-/Kartenansicht neu gestaltet.',
  );
  String get release107Change2 => _t(
    'Removed unreliable client-side city inference for drivers and kept driver filtering aligned with API-provided data.',
    'إزالة استنتاج المدينة غير الموثوق محلياً للسائقين وربط تصفية السائقين بالبيانات القادمة من واجهة API.',
    nl: 'Onbetrouwbare lokale stadsschatting voor chauffeurs verwijderd en chauffeursfilters afgestemd op API-gegevens.',
    fr: 'Suppression de l’inférence locale peu fiable de la ville des chauffeurs et alignement des filtres sur les données de l’API.',
    de: 'Unzuverlässige lokale Stadtableitung für Fahrer entfernt und Fahrerfilter an API-Daten ausgerichtet.',
  );
  String get release107Change3 => _t(
    'Added optional driver address support across models, lists, search, profiles, and detail views without replacing live GPS coordinates.',
    'إضافة دعم اختياري لعنوان السائق في النماذج والقوائم والبحث والملفات الشخصية والتفاصيل دون استبدال إحداثيات GPS المباشرة.',
    nl: 'Optionele adressen voor chauffeurs toegevoegd aan modellen, lijsten, zoekopdrachten, profielen en details zonder live GPS-coördinaten te vervangen.',
    fr: 'Ajout de l’adresse facultative du chauffeur dans les modèles, listes, recherches, profils et détails sans remplacer les coordonnées GPS en direct.',
    de: 'Optionale Fahreradressen in Modelle, Listen, Suche, Profile und Details aufgenommen, ohne Live-GPS-Koordinaten zu ersetzen.',
  );
  String get release107Change4 => _t(
    'Refined Orders with an app-bar search action, compact four-column stats, and a tighter filtering layout.',
    'تحسين شاشة الطلبات بإضافة إجراء بحث في الشريط العلوي وإحصاءات مختصرة من أربعة أعمدة وتخطيط تصفية أكثر إحكاماً.',
    nl: 'Bestellingen verfijnd met zoeken vanuit de appbalk, compacte statistieken in vier kolommen en een strakkere filterindeling.',
    fr: 'Écran Commandes amélioré avec recherche dans la barre d’application, statistiques compactes sur quatre colonnes et filtres plus resserrés.',
    de: 'Bestellungen mit Suche in der App-Leiste, kompakten Statistiken in vier Spalten und einer übersichtlicheren Filteranordnung verbessert.',
  );
  String get release107Change5 => _t(
    'Optimized Overview statistics into two-column mobile cards and improved responsive spacing across admin sections.',
    'تحسين إحصاءات النظرة العامة إلى بطاقات من عمودين على الهاتف وتحسين المسافات المتجاوبة في أقسام الإدارة.',
    nl: 'Overzichtsstatistieken geoptimaliseerd naar kaarten met twee kolommen op mobiel en responsieve ruimte in beheersecties verbeterd.',
    fr: 'Statistiques de la vue d’ensemble optimisées en cartes à deux colonnes sur mobile et espacements responsifs améliorés dans les sections d’administration.',
    de: 'Übersichtsstatistiken auf Mobilgeräten als zweispaltige Karten optimiert und responsive Abstände in den Admin-Bereichen verbessert.',
  );
  String get release106Change1 => _t(
    'Aligned dashboard totals and summaries so paginated data no longer shows conflicting numbers.',
    'توحيد إجماليات لوحة التحكم وملخصاتها لمنع تعارض الأرقام الناتج عن البيانات المقسّمة إلى صفحات.',
    nl: 'Dashboardtotalen en samenvattingen op elkaar afgestemd zodat gepagineerde gegevens geen tegenstrijdige aantallen meer tonen.',
    fr: 'Harmonisation des totaux et des résumés du tableau de bord afin d’éviter les chiffres contradictoires liés à la pagination.',
    de: 'Dashboard-Gesamtsummen und Zusammenfassungen angeglichen, damit paginierte Daten keine widersprüchlichen Zahlen mehr anzeigen.',
  );
  String get release106Change2 => _t(
    'Loaded all driver pages before calculating management totals and status counts.',
    'تحميل جميع صفحات السائقين قبل حساب إجماليات الإدارة وأعداد الحالات.',
    nl: 'Alle chauffeurpagina’s geladen voordat beheertotalen en statusaantallen worden berekend.',
    fr: 'Chargement de toutes les pages de chauffeurs avant le calcul des totaux et des statuts de gestion.',
    de: 'Alle Fahrerseiten geladen, bevor Verwaltungs- und Statussummen berechnet werden.',
  );
  String get release106Change3 => _t(
    'Updated release metadata and localized dashboard summaries.',
    'تحديث بيانات الإصدار وملخصات لوحة التحكم المترجمة.',
    nl: 'Releasegegevens en gelokaliseerde dashboardsamenvattingen bijgewerkt.',
    fr: 'Mise à jour des métadonnées de sortie et des résumés localisés du tableau de bord.',
    de: 'Release-Metadaten und lokalisierte Dashboard-Zusammenfassungen aktualisiert.',
  );
  String get release105Change1 => _t(
    'Added pricing policy management with create, edit, detail, and delete workflows.',
    'إضافة إدارة سياسات التسعير مع مسارات الإنشاء والتعديل والتفاصيل والحذف.',
    nl: 'Prijsbeleid toegevoegd met workflows voor aanmaken, bewerken, details en verwijderen.',
    fr: 'Ajout de la gestion des politiques tarifaires avec création, modification, détails et suppression.',
    de: 'Preisrichtlinien mit Workflows zum Erstellen, Bearbeiten, Anzeigen und Löschen hinzugefügt.',
  );
  String get release105Change2 => _t(
    'Added a shared country selector with country-aware data refresh across admin views.',
    'إضافة محدد دول مشترك مع تحديث البيانات حسب الدولة في شاشات الإدارة.',
    nl: 'Een gedeelde landenkiezer toegevoegd met landafhankelijke gegevensvernieuwing in beheerpagina’s.',
    fr: 'Ajout d’un sélecteur de pays partagé avec actualisation des données selon le pays dans les vues d’administration.',
    de: 'Eine gemeinsame Länderauswahl mit länderabhängiger Datenaktualisierung in den Admin-Ansichten hinzugefügt.',
  );
  String get release105Change3 => _t(
    'Expanded dashboard operations and improved localization and profile settings.',
    'توسيع عمليات لوحة التحكم وتحسين الترجمة وإعدادات الملف الشخصي.',
    nl: 'Dashboardfuncties uitgebreid en lokalisatie en profielinstellingen verbeterd.',
    fr: 'Extension des opérations du tableau de bord et amélioration de la localisation et des paramètres du profil.',
    de: 'Dashboard-Funktionen erweitert und Lokalisierung sowie Profileinstellungen verbessert.',
  );
  String get release103Change1 => _t(
    'Hardened OTP authentication and admin session handling.',
    'تعزيز مصادقة رمز التحقق وإدارة جلسة المشرف.',
    nl: 'OTP-authenticatie en beheer van beheerderssessies versterkt.',
    fr: 'Renforcement de l’authentification OTP et de la gestion des sessions administrateur.',
    de: 'OTP-Authentifizierung und Verwaltung von Admin-Sitzungen verbessert.',
  );
  String get release103Change2 => _t(
    'Improved authentication error handling and added regression coverage for request and verification flows.',
    'تحسين معالجة أخطاء المصادقة وإضافة اختبارات لمسارات طلب رمز التحقق والتحقق منه.',
    nl: 'Foutafhandeling voor authenticatie verbeterd en regressietests voor aanvraag- en verificatiestromen toegevoegd.',
    fr: 'Amélioration de la gestion des erreurs d’authentification et ajout de tests de régression pour les flux de demande et de vérification.',
    de: 'Fehlerbehandlung bei der Authentifizierung verbessert und Regressionstests für Anforderungs- und Verifizierungsabläufe hinzugefügt.',
  );
  String get release102Change1 => _t(
    'Scoped OTP request and verification payloads to admin users.',
    'تقييد حمولات طلب رمز التحقق والتحقق منه على مستخدمي الإدارة.',
    nl: 'OTP-aanvragen en verificatiepayloads beperkt tot beheerders.',
    fr: 'Les payloads de demande et de vérification OTP sont désormais réservés aux administrateurs.',
    de: 'OTP-Anfrage- und Verifizierungspayloads auf Admin-Benutzer beschränkt.',
  );
  String get release102Change2 => _t(
    'Added API/auth regression coverage and release metadata.',
    'إضافة اختبارات تراجعية للمصادقة وواجهة API وبيانات الإصدار.',
    nl: 'API- en auth-regressietests en releasegegevens toegevoegd.',
    fr: 'Ajout de tests de régression pour l’API et l’authentification ainsi que des métadonnées de sortie.',
    de: 'API- und Authentifizierungs-Regressionstests sowie Release-Metadaten hinzugefügt.',
  );
  String get release101Change1 => _t(
    'Updated the app version and profile release metadata.',
    'تحديث إصدار التطبيق وبيانات الإصدار في الملف الشخصي.',
    nl: 'Appversie en releasegegevens in het profiel bijgewerkt.',
    fr: 'Mise à jour de la version de l’application et des métadonnées de sortie du profil.',
    de: 'App-Version und Release-Metadaten im Profil aktualisiert.',
  );
  String get release100Change1 => _t(
    'Initial release with authentication, dashboard monitoring, approvals, and support tools.',
    'الإصدار الأول مع المصادقة ومراقبة لوحة التحكم وأدوات الموافقات والدعم.',
    nl: 'Eerste release met authenticatie, dashboardmonitoring, goedkeuringen en ondersteuningstools.',
    fr: 'Version initiale avec authentification, suivi du tableau de bord, approbations et outils de support.',
    de: 'Erste Version mit Authentifizierung, Dashboard-Überwachung, Freigaben und Support-Werkzeugen.',
  );
  String get pricingPoliciesActionSubtitle => _t(
    'Configure delivery pricing rules',
    'إعداد قواعد تسعير التوصيل',
    nl: 'Prijsregels voor bezorging instellen',
    fr: 'Configurer les règles tarifaires de livraison',
    de: 'Preisregeln für Lieferungen konfigurieren',
  );
  String get preferencesActionSubtitle => _t(
    'Theme, language, and display',
    'المظهر واللغة والعرض',
    nl: 'Thema, taal en weergave',
    fr: 'Thème, langue et affichage',
    de: 'Design, Sprache und Anzeige',
  );
  String get supportActionSubtitle => _t(
    'Get help and contact support',
    'الحصول على المساعدة والتواصل مع الدعم',
    nl: 'Hulp en contact met ondersteuning',
    fr: 'Obtenir de l’aide et contacter le support',
    de: 'Hilfe erhalten und Support kontaktieren',
  );
  String get showDetails => _t(
    'Show details',
    'إظهار التفاصيل',
    nl: 'Details tonen',
    fr: 'Afficher les détails',
    de: 'Details anzeigen',
  );
  String get hideDetails => _t(
    'Hide details',
    'إخفاء التفاصيل',
    nl: 'Details verbergen',
    fr: 'Masquer les détails',
    de: 'Details ausblenden',
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
    'إليك ما يحدث على منصتك اليوم.',
    nl: 'Dit is wat er vandaag op uw platform gebeurt.',
    fr: "Voici ce qui se passe sur votre plateforme aujourd'hui.",
    de: 'Das passiert heute auf Ihrer Plattform.',
  );
  String get totalOrders => _t(
    'Total Orders',
    'إجمالي الطلبات',
    nl: 'Totaal aantal bestellingen',
    fr: 'Total des commandes',
    de: 'Bestellungen insgesamt',
  );
  String get driversOnline => _t(
    'Drivers Online',
    'السائقون المتصلون',
    nl: 'Chauffeurs online',
    fr: 'Chauffeurs en ligne',
    de: 'Fahrer online',
  );
  String get restaurants => _t(
    'Restaurants',
    'المطاعم',
    nl: 'Restaurants',
    fr: 'Restaurants',
    de: 'Restaurants',
  );
  String get pendingItems => _t(
    'Pending Items',
    'عناصر معلّقة',
    nl: 'Openstaande items',
    fr: 'Éléments en attente',
    de: 'Ausstehende Elemente',
  );
  String get ordersByStatus => _t(
    'Orders by Status',
    'الطلبات حسب الحالة',
    nl: 'Bestellingen op status',
    fr: 'Commandes par statut',
    de: 'Bestellungen nach Status',
  );
  String get total =>
      _t('total', 'الإجمالي', nl: 'totaal', fr: 'total', de: 'gesamt');
  String get noOrderData => _t(
    'No order data available',
    'لا تتوفر بيانات للطلبات',
    nl: 'Geen bestelgegevens beschikbaar',
    fr: 'Aucune donnée de commande disponible',
    de: 'Keine Bestelldaten verfügbar',
  );
  String get orders => _t(
    'orders',
    'طلبات',
    nl: 'bestellingen',
    fr: 'commandes',
    de: 'Bestellungen',
  );
  String get ordersNav => _t(
    'Orders',
    'الطلبات',
    nl: 'Bestellingen',
    fr: 'Commandes',
    de: 'Bestellungen',
  );
  String get ordersTitle => _t(
    'Orders',
    'الطلبات',
    nl: 'Bestellingen',
    fr: 'Commandes',
    de: 'Bestellingen',
  );
  String ordersSubtitle(int shown, int total) => _t(
    '$shown shown of $total orders',
    '$shown معروض من $total طلب',
    nl: '$shown weergegeven van $total bestellingen',
    fr: '$shown affichées sur $total commandes',
    de: '$shown von $total Bestellungen angezeigt',
  );
  String ordersTotalSummary(int total) => _t(
    '$total total orders',
    'إجمالي الطلبات: $total',
    nl: '$total bestellingen in totaal',
    fr: '$total commandes au total',
    de: '$total Bestellungen insgesamt',
  );
  String get searchOrders => _t(
    'Search orders...',
    'ابحث في الطلبات...',
    nl: 'Bestellingen zoeken...',
    fr: 'Rechercher des commandes...',
    de: 'Bestellungen suchen...',
  );
  String get clear =>
      _t('Clear', 'مسح', nl: 'Wissen', fr: 'Effacer', de: 'Leeren');
  String get orderType => _t(
    'Order type',
    'نوع الطلب',
    nl: 'Besteltype',
    fr: 'Type de commande',
    de: 'Bestelltyp',
  );
  String get allTypes => _t(
    'All types',
    'كل الأنواع',
    nl: 'Alle typen',
    fr: 'Tous les types',
    de: 'Alle Typen',
  );
  String get allOrderStatuses => _t(
    'All statuses',
    'كل الحالات',
    nl: 'Alle statussen',
    fr: 'Tous les statuts',
    de: 'Alle Status',
  );
  String get activeOrders => _t(
    'Active orders',
    'الطلبات النشطة',
    nl: 'Actieve bestellingen',
    fr: 'Commandes actives',
    de: 'Aktive Bestellungen',
  );
  String get visibleAmount => _t(
    'Visible amount',
    'إجمالي المعروض',
    nl: 'Zichtbaar bedrag',
    fr: 'Montant visible',
    de: 'Sichtbarer Betrag',
  );
  String get noOrdersFound => _t(
    'No orders found',
    'لم يتم العثور على طلبات',
    nl: 'Geen bestellingen gevonden',
    fr: 'Aucune commande trouvée',
    de: 'Keine Bestellungen gefunden',
  );
  String get ordersPermissionDeniedSubtitle => _t(
    'Order access is restricted for this account',
    'الوصول إلى الطلبات مقيد لهذا الحساب',
    nl: 'Besteltoegang is beperkt voor dit account',
    fr: "L'accès aux commandes est limité pour ce compte",
    de: 'Der Bestellzugriff ist für dieses Konto eingeschränkt',
  );
  String get ordersPermissionDeniedTitle => _t(
    'Order access is restricted',
    'الوصول إلى الطلبات مقيد',
    nl: 'Besteltoegang is beperkt',
    fr: 'Accès aux commandes limité',
    de: 'Bestellzugriff eingeschränkt',
  );
  String get ordersPermissionDeniedBody => _t(
    'This account can open the admin dashboard, but the API is not granting permission to view admin orders. Grant order access, then retry.',
    'يمكن لهذا الحساب فتح لوحة الإدارة، لكن واجهة API لا تمنحه صلاحية عرض طلبات الإدارة. امنح صلاحية الطلبات ثم أعد المحاولة.',
    nl: 'Dit account kan het beheerdersdashboard openen, maar de API geeft geen toestemming om adminbestellingen te bekijken. Geef besteltoegang en probeer het opnieuw.',
    fr: "Ce compte peut ouvrir le tableau de bord admin, mais l'API ne lui accorde pas l'autorisation de voir les commandes admin. Accordez l'accès aux commandes, puis réessayez.",
    de: 'Dieses Konto kann das Admin-Dashboard öffnen, aber die API erlaubt keinen Zugriff auf Admin-Bestellungen. Gewähren Sie Bestellzugriff und versuchen Sie es erneut.',
  );
  String orderNumber(int id) => _t(
    'Order #$id',
    'طلب #$id',
    nl: 'Bestelling #$id',
    fr: 'Commande n° $id',
    de: 'Bestellung #$id',
  );
  String pageNumber(int page) => _t(
    'Page $page',
    'الصفحة $page',
    nl: 'Pagina $page',
    fr: 'Page $page',
    de: 'Seite $page',
  );
  String get previousPage => _t(
    'Previous page',
    'الصفحة السابقة',
    nl: 'Vorige pagina',
    fr: 'Page précédente',
    de: 'Vorherige Seite',
  );
  String get nextPage => _t(
    'Next page',
    'الصفحة التالية',
    nl: 'Volgende pagina',
    fr: 'Page suivante',
    de: 'Nächste Seite',
  );
  String get orderDetails => _t(
    'Order details',
    'تفاصيل الطلب',
    nl: 'Bestelgegevens',
    fr: 'Détails de la commande',
    de: 'Bestelldetails',
  );
  String get customer =>
      _t('Customer', 'العميل', nl: 'Klant', fr: 'Client', de: 'Kunde');
  String get accepted => _t(
    'Accepted',
    'مقبول',
    nl: 'Geaccepteerd',
    fr: 'Acceptée',
    de: 'Akzeptiert',
  );
  String get searchingForDriver => _t(
    'Searching for driver',
    'جار البحث عن سائق',
    nl: 'Zoeken naar chauffeur',
    fr: 'Recherche de chauffeur',
    de: 'Fahrer wird gesucht',
  );
  String get driverNotificationSent => _t(
    'Driver notified',
    'تم إشعار السائق',
    nl: 'Chauffeur geïnformeerd',
    fr: 'Chauffeur notifié',
    de: 'Fahrer benachrichtigt',
  );
  String get onTheWay => _t(
    'On the way',
    'في الطريق',
    nl: 'Onderweg',
    fr: 'En route',
    de: 'Unterwegs',
  );
  String get delivered => _t(
    'Delivered',
    'تم التسليم',
    nl: 'Bezorgd',
    fr: 'Livrée',
    de: 'Geliefert',
  );
  String get completed => _t(
    'Completed',
    'مكتمل',
    nl: 'Voltooid',
    fr: 'Terminée',
    de: 'Abgeschlossen',
  );
  String get rejected =>
      _t('Rejected', 'مرفوض', nl: 'Afgewezen', fr: 'Rejetée', de: 'Abgelehnt');
  String get expired =>
      _t('Expired', 'منتهي', nl: 'Verlopen', fr: 'Expirée', de: 'Abgelaufen');
  String get cancelled => _t(
    'Cancelled',
    'ملغى',
    nl: 'Geannuleerd',
    fr: 'Annulée',
    de: 'Storniert',
  );
  String get preparing => _t(
    'Preparing',
    'قيد التحضير',
    nl: 'In bereiding',
    fr: 'En préparation',
    de: 'In Zubereitung',
  );
  String get ready =>
      _t('Ready', 'جاهز', nl: 'Klaar', fr: 'Prête', de: 'Bereit');
  String get pickedUp => _t(
    'Picked up',
    'تم الاستلام',
    nl: 'Opgehaald',
    fr: 'Récupérée',
    de: 'Abgeholt',
  );
  String get restaurantDelivered => _t(
    'Restaurant delivered',
    'تم التسليم من المطعم',
    nl: 'Door restaurant bezorgd',
    fr: 'Livrée par le restaurant',
    de: 'Vom Restaurant geliefert',
  );
  String orderStatusLabel(String status) {
    final normalized = status.trim().toUpperCase().replaceAll(
      RegExp(r'[\s-]+'),
      '_',
    );
    return switch (normalized) {
      'PENDING' => pending,
      'SEARCHING_FOR_DRIVER' => searchingForDriver,
      'DRIVER_NOTIFICATION_SENT' => driverNotificationSent,
      'ACCEPTED' => accepted,
      'PREPARING' => preparing,
      'READY' => ready,
      'PICKED_UP' => pickedUp,
      'ON_THE_WAY' => onTheWay,
      'DELIVERED' => delivered,
      'RESTAURANT_DELIVERED' => restaurantDelivered,
      'COMPLETED' => completed,
      'CANCELLED' || 'CANCELED' => cancelled,
      'REJECTED' => rejected,
      'EXPIRED' => expired,
      _ => _titleCaseStatus(normalized),
    };
  }

  String _titleCaseStatus(String value) {
    return value
        .toLowerCase()
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String get cash =>
      _t('Cash', 'نقدا', nl: 'Contant', fr: 'Espèces', de: 'Bar');
  String get card => _t('Card', 'بطاقة', nl: 'Kaart', fr: 'Carte', de: 'Karte');
  String get other =>
      _t('Other', 'أخرى', nl: 'Overig', fr: 'Autre', de: 'Andere');
  String get paid =>
      _t('Paid', 'مدفوع', nl: 'Betaald', fr: 'Payée', de: 'Bezahlt');
  String get unpaid => _t(
    'Unpaid',
    'غير مدفوع',
    nl: 'Onbetaald',
    fr: 'Non payée',
    de: 'Unbezahlt',
  );
  String get route =>
      _t('Route', 'المسار', nl: 'Route', fr: 'Itinéraire', de: 'Route');
  String get people =>
      _t('People', 'الأشخاص', nl: 'Personen', fr: 'Personnes', de: 'Personen');
  String get pricing =>
      _t('Pricing', 'التسعير', nl: 'Prijs', fr: 'Tarification', de: 'Preise');
  String get dispatch => _t(
    'Dispatch',
    'الإرسال',
    nl: 'Dispatch',
    fr: 'Répartition',
    de: 'Disposition',
  );
  String get pickupAddress => _t(
    'Pickup address',
    'عنوان الاستلام',
    nl: 'Ophaaladres',
    fr: 'Adresse de prise en charge',
    de: 'Abholadresse',
  );
  String get dropoffAddress => _t(
    'Dropoff address',
    'عنوان التسليم',
    nl: 'Afleveradres',
    fr: 'Adresse de livraison',
    de: 'Lieferadresse',
  );
  String get assignedDriver => _t(
    'Assigned driver',
    'السائق المعين',
    nl: 'Toegewezen chauffeur',
    fr: 'Chauffeur assigné',
    de: 'Zugewiesener Fahrer',
  );
  String get unassignedDriver => _t(
    'Unassigned driver',
    'لا يوجد سائق معين',
    nl: 'Geen chauffeur toegewezen',
    fr: 'Aucun chauffeur assigné',
    de: 'Kein Fahrer zugewiesen',
  );
  String get unknownCustomer => _t(
    'Unknown customer',
    'عميل غير معروف',
    nl: 'Onbekende klant',
    fr: 'Client inconnu',
    de: 'Unbekannter Kunde',
  );
  String get unknownRestaurant => _t(
    'Unknown restaurant',
    'مطعم غير معروف',
    nl: 'Onbekend restaurant',
    fr: 'Restaurant inconnu',
    de: 'Unbekanntes Restaurant',
  );
  String get deliveryInstructions => _t(
    'Delivery instructions',
    'تعليمات التسليم',
    nl: 'Bezorginstructies',
    fr: 'Instructions de livraison',
    de: 'Lieferhinweise',
  );
  String get noDeliveryInstructions => _t(
    'No delivery instructions',
    'لا توجد تعليمات تسليم',
    nl: 'Geen bezorginstructies',
    fr: 'Aucune instruction de livraison',
    de: 'Keine Lieferhinweise',
  );
  String get subtotal => _t(
    'Subtotal',
    'المجموع الفرعي',
    nl: 'Subtotaal',
    fr: 'Sous-total',
    de: 'Zwischensumme',
  );
  String get deliveryFee => _t(
    'Delivery fee',
    'رسوم التوصيل',
    nl: 'Bezorgkosten',
    fr: 'Frais de livraison',
    de: 'Liefergebühr',
  );
  String get discount =>
      _t('Discount', 'الخصم', nl: 'Korting', fr: 'Remise', de: 'Rabatt');
  String get tip =>
      _t('Tip', 'إكرامية', nl: 'Fooi', fr: 'Pourboire', de: 'Trinkgeld');
  String get coupon =>
      _t('Coupon', 'قسيمة', nl: 'Coupon', fr: 'Coupon', de: 'Coupon');
  String get totalAmount => _t(
    'Total amount',
    'المبلغ الإجمالي',
    nl: 'Totaalbedrag',
    fr: 'Montant total',
    de: 'Gesamtbetrag',
  );
  String get payment =>
      _t('Payment', 'الدفع', nl: 'Betaling', fr: 'Paiement', de: 'Zahlung');
  String get packageDetails => _t(
    'Package details',
    'تفاصيل الطرد',
    nl: 'Pakketgegevens',
    fr: 'Détails du colis',
    de: 'Paketdetails',
  );
  String get packageSize =>
      _t('Size', 'الحجم', nl: 'Grootte', fr: 'Taille', de: 'Größe');
  String get packageWeight =>
      _t('Weight', 'الوزن', nl: 'Gewicht', fr: 'Poids', de: 'Gewicht');
  String get packageContent =>
      _t('Content', 'المحتوى', nl: 'Inhoud', fr: 'Contenu', de: 'Inhalt');
  String get requestedVehicle => _t(
    'Requested vehicle',
    'المركبة المطلوبة',
    nl: 'Gevraagd voertuig',
    fr: 'Véhicule demandé',
    de: 'Gewünschtes Fahrzeug',
  );
  String get requestedDelivery => _t(
    'Requested delivery',
    'التوصيل المطلوب',
    nl: 'Gevraagde bezorging',
    fr: 'Livraison demandée',
    de: 'Gewünschte Lieferung',
  );
  String get carSize => _t(
    'Car size',
    'حجم السيارة',
    nl: 'Autogrootte',
    fr: 'Taille de voiture',
    de: 'Autogröße',
  );
  String get orderItems => _t(
    'Order items',
    'عناصر الطلب',
    nl: 'Bestelitems',
    fr: 'Articles de commande',
    de: 'Bestellpositionen',
  );
  String get noItems => _t(
    'No items',
    'لا توجد عناصر',
    nl: 'Geen items',
    fr: 'Aucun article',
    de: 'Keine Positionen',
  );
  String get unitPrice => _t(
    'Unit price',
    'سعر الوحدة',
    nl: 'Eenheidsprijs',
    fr: 'Prix unitaire',
    de: 'Stückpreis',
  );
  String get orderMode => _t(
    'Order mode',
    'وضع الطلب',
    nl: 'Bestelmodus',
    fr: 'Mode de commande',
    de: 'Bestellmodus',
  );
  String get manual =>
      _t('Manual', 'يدوي', nl: 'Handmatig', fr: 'Manuel', de: 'Manuell');
  String get automatic => _t(
    'Automatic',
    'تلقائي',
    nl: 'Automatisch',
    fr: 'Automatique',
    de: 'Automatisch',
  );
  String get dispatchStarted => _t(
    'Dispatch started',
    'بدأ الإرسال',
    nl: 'Dispatch gestart',
    fr: 'Répartition démarrée',
    de: 'Disposition gestartet',
  );
  String get updatedAt => _t(
    'Updated',
    'تم التحديث',
    nl: 'Bijgewerkt',
    fr: 'Mise à jour',
    de: 'Aktualisiert',
  );
  String get statusHistory => _t(
    'Status history',
    'سجل الحالة',
    nl: 'Statusgeschiedenis',
    fr: 'Historique des statuts',
    de: 'Statusverlauf',
  );
  String get fleetStatus => _t(
    'Fleet Status',
    'حالة الأسطول',
    nl: 'Vlootstatus',
    fr: 'État de la flotte',
    de: 'Flottenstatus',
  );
  String get driversOnlineLabel => _t(
    'drivers online',
    'سائقون متصلون',
    nl: 'chauffeurs online',
    fr: 'chauffeurs en ligne',
    de: 'Fahrer online',
  );
  String get totalDrivers => _t(
    'Total drivers',
    'إجمالي السائقين',
    nl: 'Totaal chauffeurs',
    fr: 'Total chauffeurs',
    de: 'Fahrer gesamt',
  );
  String get online =>
      _t('Online', 'متصل', nl: 'Online', fr: 'En ligne', de: 'Online');
  String get offline =>
      _t('Offline', 'غير متصل', nl: 'Offline', fr: 'Hors ligne', de: 'Offline');
  String get activeDrivers => _t(
    'Active Drivers',
    'السائقون النشطون',
    nl: 'Actieve chauffeurs',
    fr: 'Chauffeurs actifs',
    de: 'Aktive Fahrer',
  );
  String get shown =>
      _t('shown', 'معروض', nl: 'getoond', fr: 'affichés', de: 'angezeigt');
  String get noDriversAvailable => _t(
    'No drivers available',
    'لا يوجد سائقون متاحون',
    nl: 'Geen chauffeurs beschikbaar',
    fr: 'Aucun chauffeur disponible',
    de: 'Keine Fahrer verfügbar',
  );
  String get needsAttention => _t(
    'Needs Attention',
    'يحتاج إلى الانتباه',
    nl: 'Aandacht vereist',
    fr: 'Nécessite votre attention',
    de: 'Erfordert Aufmerksamkeit',
  );
  String get pendingDriverApprovals => _t(
    'Pending driver approvals',
    'طلبات اعتماد السائقين المعلّقة',
    nl: 'Openstaande chauffeursgoedkeuringen',
    fr: 'Approbations de chauffeurs en attente',
    de: 'Ausstehende Fahrergenehmigungen',
  );
  String get pendingRestaurantApprovals => _t(
    'Pending restaurant approvals',
    'طلبات اعتماد المطاعم المعلّقة',
    nl: 'Openstaande restaurantgoedkeuringen',
    fr: 'Approbations de restaurants en attente',
    de: 'Ausstehende Restaurantgenehmigungen',
  );
  String get openSupportTickets => _t(
    'Open support tickets',
    'تذاكر الدعم المفتوحة',
    nl: 'Open supporttickets',
    fr: 'Tickets de support ouverts',
    de: 'Offene Support-Tickets',
  );
  String get retry => _t(
    'Retry',
    'إعادة المحاولة',
    nl: 'Opnieuw proberen',
    fr: 'Réessayer',
    de: 'Erneut versuchen',
  );
  String get noOrdersData => _t(
    'No orders data',
    'لا توجد بيانات للطلبات',
    nl: 'Geen bestelgegevens',
    fr: 'Aucune donnée de commande',
    de: 'Keine Bestelldaten',
  );
  String restaurantsTotalSummary(int total) => _t(
    '$total total restaurants',
    'إجمالي المطاعم: $total',
    nl: '$total restaurants in totaal',
    fr: '$total restaurants au total',
    de: '$total Restaurants insgesamt',
  );
  String get noRestaurantsLoaded => _t(
    'No restaurants loaded',
    'لم يتم تحميل المطاعم',
    nl: 'Geen restaurants geladen',
    fr: 'Aucun restaurant chargé',
    de: 'Keine Restaurants geladen',
  );

  String restaurantsScreenSub(int total, int active, int open) => _t(
    '$total restaurants - $active active - $open open now',
    '$total مطاعم - $active نشط - $open مفتوح الآن',
    nl: '$total restaurants - $active actief - $open nu open',
    fr: '$total restaurants - $active actifs - $open ouverts',
    de: '$total Restaurants - $active aktiv - $open jetzt offen',
  );
  String get restaurant => _t(
    'Restaurant',
    'مطعم',
    nl: 'Restaurant',
    fr: 'Restaurant',
    de: 'Restaurant',
  );
  String get restaurantDetails => _t(
    'Restaurant Details',
    'تفاصيل المطعم',
    nl: 'Restaurantdetails',
    fr: 'Details du restaurant',
    de: 'Restaurantdetails',
  );
  String get restaurantInfo => _t(
    'Restaurant Info',
    'معلومات المطعم',
    nl: 'Restaurantinformatie',
    fr: 'Informations du restaurant',
    de: 'Restaurantinformationen',
  );
  String get searchRestaurants => _t(
    'Search restaurants...',
    'ابحث عن المطاعم...',
    nl: 'Restaurants zoeken...',
    fr: 'Rechercher des restaurants...',
    de: 'Restaurants suchen...',
  );
  String get active =>
      _t('Active', 'نشط', nl: 'Actief', fr: 'Actif', de: 'Aktiv');
  String get inactive =>
      _t('Inactive', 'غير نشط', nl: 'Inactief', fr: 'Inactif', de: 'Inaktiv');
  String get approved => _t(
    'Approved',
    'موافق عليه',
    nl: 'Goedgekeurd',
    fr: 'Approuve',
    de: 'Genehmigt',
  );
  String get openNow => _t(
    'Open now',
    'مفتوح الآن',
    nl: 'Nu open',
    fr: 'Ouvert',
    de: 'Jetzt offen',
  );
  String get closedNow => _t(
    'Closed now',
    'مغلق الآن',
    nl: 'Nu gesloten',
    fr: 'Ferme',
    de: 'Jetzt geschlossen',
  );
  String get allStatuses => _t(
    'All statuses',
    'كل الحالات',
    nl: 'Alle statussen',
    fr: 'Tous les statuts',
    de: 'Alle Status',
  );
  String get allCities => _t(
    'All cities',
    'كل المدن',
    nl: 'Alle steden',
    fr: 'Toutes les villes',
    de: 'Alle Staedte',
  );
  String get openingHours => _t(
    'Opening Hours',
    'ساعات العمل',
    nl: 'Openingstijden',
    fr: 'Horaires',
    de: 'Oeffnungszeiten',
  );
  String get workingHours => _t(
    'Working Hours',
    'ساعات العمل',
    nl: 'Werkuren',
    fr: 'Heures de travail',
    de: 'Arbeitszeiten',
  );
  String get noRestaurantsMatchFilters => _t(
    'No restaurants match your filters',
    'لا توجد مطاعم تطابق الفلاتر',
    nl: 'Geen restaurants passen bij uw filters',
    fr: 'Aucun restaurant ne correspond aux filtres',
    de: 'Keine Restaurants entsprechen den Filtern',
  );
  String get noHoursAvailable => _t(
    'No hours available',
    'لا توجد ساعات عمل',
    nl: 'Geen openingstijden beschikbaar',
    fr: 'Aucun horaire disponible',
    de: 'Keine Zeiten verfuegbar',
  );
  String openUntil(String time) => _t(
    'Open until $time',
    'مفتوح حتى $time',
    nl: 'Open tot $time',
    fr: 'Ouvert jusqu a $time',
    de: 'Offen bis $time',
  );
  String opensTodayAt(String time) => _t(
    'Opens today at $time',
    'يفتح اليوم في $time',
    nl: 'Opent vandaag om $time',
    fr: 'Ouvre aujourd hui a $time',
    de: 'Oeffnet heute um $time',
  );
  String opensDayAt(String day, String time) => _t(
    'Opens $day at $time',
    'يفتح $day في $time',
    nl: 'Opent $day om $time',
    fr: 'Ouvre $day a $time',
    de: 'Oeffnet $day um $time',
  );
  String get ownerUser => _t(
    'Owner user',
    'حساب المالك',
    nl: 'Eigenaar',
    fr: 'Utilisateur proprietaire',
    de: 'Inhaber-Benutzer',
  );
  String get currentHoursStatus => _t(
    'Hours status',
    'حالة الدوام',
    nl: 'Urenstatus',
    fr: 'Statut des horaires',
    de: 'Zeitstatus',
  );
  String get yes => _t('Yes', 'نعم', nl: 'Ja', fr: 'Oui', de: 'Ja');
  String get no => _t('No', 'لا', nl: 'Nee', fr: 'Non', de: 'Nein');
  String get address =>
      _t('Address', 'العنوان', nl: 'Adres', fr: 'Adresse', de: 'Adresse');
  String get label =>
      _t('Label', 'التسمية', nl: 'Label', fr: 'Libelle', de: 'Bezeichnung');
  String get fullAddress => _t(
    'Full address',
    'العنوان الكامل',
    nl: 'Volledig adres',
    fr: 'Adresse complete',
    de: 'Vollstaendige Adresse',
  );
  String get streetName =>
      _t('Street', 'الشارع', nl: 'Straat', fr: 'Rue', de: 'Strasse');
  String get houseNumber => _t(
    'House number',
    'رقم المنزل',
    nl: 'Huisnummer',
    fr: 'Numero',
    de: 'Hausnummer',
  );
  String get city =>
      _t('City', 'المدينة', nl: 'Stad', fr: 'Ville', de: 'Stadt');
  String get postalCode => _t(
    'Postal code',
    'الرمز البريدي',
    nl: 'Postcode',
    fr: 'Code postal',
    de: 'Postleitzahl',
  );
  String get country =>
      _t('Country', 'البلد', nl: 'Land', fr: 'Pays', de: 'Land');
  String get coordinates => _t(
    'Coordinates',
    'الإحداثيات',
    nl: 'Coordinaten',
    fr: 'Coordonnees',
    de: 'Koordinaten',
  );
  String weekdayName(String key) {
    return switch (key) {
      'monday' => _t(
        'Monday',
        'الاثنين',
        nl: 'Maandag',
        fr: 'Lundi',
        de: 'Montag',
      ),
      'tuesday' => _t(
        'Tuesday',
        'الثلاثاء',
        nl: 'Dinsdag',
        fr: 'Mardi',
        de: 'Dienstag',
      ),
      'wednesday' => _t(
        'Wednesday',
        'الأربعاء',
        nl: 'Woensdag',
        fr: 'Mercredi',
        de: 'Mittwoch',
      ),
      'thursday' => _t(
        'Thursday',
        'الخميس',
        nl: 'Donderdag',
        fr: 'Jeudi',
        de: 'Donnerstag',
      ),
      'friday' => _t(
        'Friday',
        'الجمعة',
        nl: 'Vrijdag',
        fr: 'Vendredi',
        de: 'Freitag',
      ),
      'saturday' => _t(
        'Saturday',
        'السبت',
        nl: 'Zaterdag',
        fr: 'Samedi',
        de: 'Samstag',
      ),
      'sunday' => _t(
        'Sunday',
        'الأحد',
        nl: 'Zondag',
        fr: 'Dimanche',
        de: 'Sonntag',
      ),
      _ => key,
    };
  }

  // Dynamic dashboard strings
  String driversCountSummary(int total, int online, int offline) => _t(
    '$total total · $online online',
    '$total إجمالي · $online متصل',
    nl: '$total totaal · $online online',
    fr: '$total au total · $online en ligne',
    de: '$total gesamt · $online online',
  );
  String driversStat(int total, int offline) => _t(
    '$total total · $offline offline',
    '$total إجمالي · $offline غير متصل',
    nl: '$total totaal · $offline offline',
    fr: '$total au total · $offline hors ligne',
    de: '$total gesamt · $offline offline',
  );
  String pendingItemsSub(int drivers, int restaurants) => _t(
    '$drivers drivers · $restaurants restaurants',
    '$drivers سائقون · $restaurants مطاعم',
    nl: '$drivers chauffeurs · $restaurants restaurants',
    fr: '$drivers chauffeurs · $restaurants restaurants',
    de: '$drivers Fahrer · $restaurants Restaurants',
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
    'معلّق',
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
    'تحديث',
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
  String get version => _t(
    'Version',
    'Ã˜Â§Ã™â€žÃ˜Â§Ã™â€žÃ™Â·Ã™â€¦',
    nl: 'Versie',
    fr: 'Version',
    de: 'Version',
  );
  String get releaseDate => _t(
    'Release date',
    'Ã˜ÂªÃ˜Â§Ã™â€žÃ™Â¬Ã™Ë†Ã˜Â±Ã™â€žÃ˜Â§Ã™â€ž',
    nl: 'Releasedatum',
    fr: 'Date de sortie',
    de: 'VerÃƒÆ’Ã…Â¸entlichungsdatum',
  );
  String formatReleaseDate(DateTime date) {
    final month = switch (locale.languageCode) {
      'ar' => const [
        '',
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ][date.month],
      'nl' => const [
        '',
        'januari',
        'februari',
        'maart',
        'april',
        'mei',
        'juni',
        'juli',
        'augustus',
        'september',
        'oktober',
        'november',
        'december',
      ][date.month],
      'fr' => const [
        '',
        'janvier',
        'février',
        'mars',
        'avril',
        'mai',
        'juin',
        'juillet',
        'août',
        'septembre',
        'octobre',
        'novembre',
        'décembre',
      ][date.month],
      'de' => const [
        '',
        'Januar',
        'Februar',
        'März',
        'April',
        'Mai',
        'Juni',
        'Juli',
        'August',
        'September',
        'Oktober',
        'November',
        'Dezember',
      ][date.month],
      _ => const [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ][date.month],
    };

    return switch (locale.languageCode) {
      'en' => '$month ${date.day}, ${date.year}',
      'de' => '${date.day}. $month ${date.year}',
      _ => '${date.day} $month ${date.year}',
    };
  }

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
