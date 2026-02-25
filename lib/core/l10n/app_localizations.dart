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

  // ─── Navigation ───────────────────────────────────────────────
  String get overview => _t('Overview', 'نظرة عامة',
      nl: 'Overzicht', fr: 'Aperçu', de: 'Übersicht');
  String get approvals => _t('Approvals', 'الموافقات',
      nl: 'Goedkeuringen', fr: 'Approbations', de: 'Genehmigungen');
  String get drivers => _t('Drivers', 'السائقون',
      nl: 'Chauffeurs', fr: 'Chauffeurs', de: 'Fahrer');
  String get support => _t('Support', 'الدعم',
      nl: 'Ondersteuning', fr: 'Support', de: 'Support');
  String get profile => _t('Profile', 'الملف الشخصي',
      nl: 'Profiel', fr: 'Profil', de: 'Profil');
  String get signOut => _t('Sign out', 'تسجيل الخروج',
      nl: 'Uitloggen', fr: 'Déconnexion', de: 'Abmelden');

  // ─── Sign In ──────────────────────────────────────────────────
  String get adminDashboard => _t('Admin Dashboard', 'لوحة تحكم المشرف',
      nl: 'Beheerdersdashboard', fr: 'Tableau de bord admin', de: 'Admin-Dashboard');
  String get manageDescription => _t(
    'Manage drivers, restaurants, orders, and support from one place.',
    'إدارة السائقين والمطاعم والطلبات والدعم من مكان واحد.',
    nl: 'Beheer chauffeurs, restaurants, bestellingen en ondersteuning vanuit één plek.',
    fr: 'Gérez les chauffeurs, restaurants, commandes et le support depuis un seul endroit.',
    de: 'Verwalten Sie Fahrer, Restaurants, Bestellungen und Support von einem Ort aus.',
  );
  String get welcomeBack => _t('Welcome back', 'مرحبًا بعودتك',
      nl: 'Welkom terug', fr: 'Bon retour', de: 'Willkommen zurück');
  String get enterPhoneToSignIn => _t(
    'Enter your phone number to sign in',
    'أدخل رقم هاتفك لتسجيل الدخول',
    nl: 'Voer uw telefoonnummer in om in te loggen',
    fr: 'Entrez votre numéro de téléphone pour vous connecter',
    de: 'Geben Sie Ihre Telefonnummer ein, um sich anzumelden',
  );
  String get phoneNumber => _t('Phone Number', 'رقم الهاتف',
      nl: 'Telefoonnummer', fr: 'Numéro de téléphone', de: 'Telefonnummer');
  String get sendOtp => _t('Send OTP', 'إرسال رمز التحقق',
      nl: 'OTP verzenden', fr: 'Envoyer OTP', de: 'OTP senden');
  String get enterYourPhone => _t(
    'Enter your phone number',
    'أدخل رقم هاتفك',
    nl: 'Voer uw telefoonnummer in',
    fr: 'Entrez votre numéro de téléphone',
    de: 'Geben Sie Ihre Telefonnummer ein',
  );

  // ─── OTP ──────────────────────────────────────────────────────
  String get verifyOtp => _t('Verify OTP', 'التحقق من الرمز',
      nl: 'OTP verifiëren', fr: 'Vérifier OTP', de: 'OTP verifizieren');
  String enterCodeSentTo(String phone) => _t(
    'Enter the code sent to $phone',
    'أدخل الرمز المرسل إلى $phone',
    nl: 'Voer de code in die is verzonden naar $phone',
    fr: 'Entrez le code envoyé au $phone',
    de: 'Geben Sie den Code ein, der an $phone gesendet wurde',
  );
  String get testOtpLabel => _t('Test OTP: ', 'رمز اختبار: ',
      nl: 'Test OTP: ', fr: 'OTP de test : ', de: 'Test-OTP: ');
  String get otpCode => _t('OTP Code', 'رمز التحقق',
      nl: 'OTP-code', fr: 'Code OTP', de: 'OTP-Code');
  String get enterOtpCode => _t('Enter the OTP code', 'أدخل رمز التحقق',
      nl: 'Voer de OTP-code in', fr: 'Entrez le code OTP', de: 'Geben Sie den OTP-Code ein');
  String get verify => _t('Verify', 'تحقق',
      nl: 'Verifiëren', fr: 'Vérifier', de: 'Verifizieren');
  String get changePhoneNumber => _t(
    'Change phone number',
    'تغيير رقم الهاتف',
    nl: 'Telefoonnummer wijzigen',
    fr: 'Changer le numéro de téléphone',
    de: 'Telefonnummer ändern',
  );

  // ─── Sign Out Dialog ──────────────────────────────────────────
  String get signOutConfirm => _t(
    'Are you sure you want to sign out?',
    'هل أنت متأكد أنك تريد تسجيل الخروج؟',
    nl: 'Weet u zeker dat u wilt uitloggen?',
    fr: 'Êtes-vous sûr de vouloir vous déconnecter ?',
    de: 'Sind Sie sicher, dass Sie sich abmelden möchten?',
  );
  String get cancel => _t('Cancel', 'إلغاء',
      nl: 'Annuleren', fr: 'Annuler', de: 'Abbrechen');

  // ─── Dashboard ────────────────────────────────────────────────
  String get overviewSubtitle => _t(
    "Here's what's happening across your platform today.",
    'إليك ما يحدث عبر منصتك اليوم.',
    nl: 'Dit is wat er vandaag op uw platform gebeurt.',
    fr: "Voici ce qui se passe sur votre plateforme aujourd'hui.",
    de: 'Das passiert heute auf Ihrer Plattform.',
  );
  String get totalOrders => _t('Total Orders', 'إجمالي الطلبات',
      nl: 'Totaal bestellingen', fr: 'Total commandes', de: 'Gesamtbestellungen');
  String get driversOnline => _t('Drivers Online', 'السائقون المتصلون',
      nl: 'Chauffeurs online', fr: 'Chauffeurs en ligne', de: 'Fahrer online');
  String get restaurants => _t('Restaurants', 'المطاعم',
      nl: 'Restaurants', fr: 'Restaurants', de: 'Restaurants');
  String get pendingItems => _t('Pending Items', 'عناصر معلقة',
      nl: 'Openstaande items', fr: 'Éléments en attente', de: 'Ausstehende Elemente');
  String get ordersByStatus => _t('Orders by Status', 'الطلبات حسب الحالة',
      nl: 'Bestellingen op status', fr: 'Commandes par statut', de: 'Bestellungen nach Status');
  String get total => _t('total', 'الإجمالي',
      nl: 'totaal', fr: 'total', de: 'gesamt');
  String get noOrderData => _t('No order data available', 'لا توجد بيانات طلبات',
      nl: 'Geen bestelgegevens beschikbaar', fr: 'Aucune donnée de commande disponible', de: 'Keine Bestelldaten verfügbar');
  String get orders => _t('orders', 'طلبات',
      nl: 'bestellingen', fr: 'commandes', de: 'Bestellungen');
  String get fleetStatus => _t('Fleet Status', 'حالة الأسطول',
      nl: 'Vlootstatus', fr: 'État de la flotte', de: 'Flottenstatus');
  String get driversOnlineLabel => _t('drivers online', 'سائقون متصلون',
      nl: 'chauffeurs online', fr: 'chauffeurs en ligne', de: 'Fahrer online');
  String get totalDrivers => _t('Total drivers', 'إجمالي السائقين',
      nl: 'Totaal chauffeurs', fr: 'Total chauffeurs', de: 'Fahrer gesamt');
  String get online => _t('Online', 'متصل',
      nl: 'Online', fr: 'En ligne', de: 'Online');
  String get offline => _t('Offline', 'غير متصل',
      nl: 'Offline', fr: 'Hors ligne', de: 'Offline');
  String get activeDrivers => _t('Active Drivers', 'السائقون النشطون',
      nl: 'Actieve chauffeurs', fr: 'Chauffeurs actifs', de: 'Aktive Fahrer');
  String get shown => _t('shown', 'معروض',
      nl: 'getoond', fr: 'affiché', de: 'angezeigt');
  String get noDriversAvailable => _t('No drivers available', 'لا يوجد سائقون متاحون',
      nl: 'Geen chauffeurs beschikbaar', fr: 'Aucun chauffeur disponible', de: 'Keine Fahrer verfügbar');
  String get needsAttention => _t('Needs Attention', 'يحتاج انتباه',
      nl: 'Aandacht vereist', fr: 'Nécessite attention', de: 'Erfordert Aufmerksamkeit');
  String get pendingDriverApprovals => _t(
    'Pending driver approvals',
    'موافقات السائقين المعلقة',
    nl: 'Openstaande chauffeursgoedkeuringen',
    fr: 'Approbations de chauffeurs en attente',
    de: 'Ausstehende Fahrergenehmigungen',
  );
  String get pendingRestaurantApprovals => _t(
    'Pending restaurant approvals',
    'موافقات المطاعم المعلقة',
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
  String get retry => _t('Retry', 'إعادة المحاولة',
      nl: 'Opnieuw proberen', fr: 'Réessayer', de: 'Erneut versuchen');
  String get noOrdersData => _t('No orders data', 'لا توجد بيانات طلبات',
      nl: 'Geen bestelgegevens', fr: 'Aucune donnée de commande', de: 'Keine Bestelldaten');
  String activeOfShown(int active, int total) => _t(
    '$active active of $total shown',
    '$active نشط من $total معروض',
    nl: '$active actief van $total getoond',
    fr: '$active actif sur $total affiché',
    de: '$active aktiv von $total angezeigt',
  );
  String get noRestaurantsLoaded => _t(
    'No restaurants loaded',
    'لم يتم تحميل مطاعم',
    nl: 'Geen restaurants geladen',
    fr: 'Aucun restaurant chargé',
    de: 'Keine Restaurants geladen',
  );

  // Dynamic dashboard strings
  String driversCountSummary(int total, int online, int offline) => _t(
    '$total total · $online online',
    '$total الإجمالي · $online متصل',
    nl: '$total totaal · $online online',
    fr: '$total total · $online en ligne',
    de: '$total gesamt · $online online',
  );
  String driversStat(int total, int offline) => _t(
    '$total total · $offline offline',
    '$total الإجمالي · $offline غير متصل',
    nl: '$total totaal · $offline offline',
    fr: '$total total · $offline hors ligne',
    de: '$total gesamt · $offline offline',
  );
  String pendingItemsSub(int drivers, int restaurants) => _t(
    '$drivers drivers · $restaurants restaurants',
    '$drivers سائقين · $restaurants مطاعم',
    nl: '$drivers chauffeurs · $restaurants restaurants',
    fr: '$drivers chauffeurs · $restaurants restaurants',
    de: '$drivers Fahrer · $restaurants Restaurants',
  );

  // ─── Drivers Screen ───────────────────────────────────────────
  String driversScreenSub(int total, int online, int offline) => _t(
    '$total drivers · $online online · $offline offline',
    '$total سائق · $online متصل · $offline غير متصل',
    nl: '$total chauffeurs · $online online · $offline offline',
    fr: '$total chauffeurs · $online en ligne · $offline hors ligne',
    de: '$total Fahrer · $online online · $offline offline',
  );
  String get searchByNameOrPhone => _t(
    'Search by name or phone...',
    'البحث بالاسم أو الهاتف...',
    nl: 'Zoeken op naam of telefoon...',
    fr: 'Rechercher par nom ou téléphone...',
    de: 'Nach Name oder Telefon suchen...',
  );
  String get all => _t('All', 'الكل',
      nl: 'Alle', fr: 'Tous', de: 'Alle');
  String get driver => _t('Driver', 'السائق',
      nl: 'Chauffeur', fr: 'Chauffeur', de: 'Fahrer');
  String get status => _t('Status', 'الحالة',
      nl: 'Status', fr: 'Statut', de: 'Status');
  String get phone => _t('Phone', 'الهاتف',
      nl: 'Telefoon', fr: 'Téléphone', de: 'Telefon');
  String get location => _t('Location', 'الموقع',
      nl: 'Locatie', fr: 'Emplacement', de: 'Standort');
  String get noDriversMatchFilters => _t(
    'No drivers match your filters',
    'لا يوجد سائقون مطابقون للفلاتر',
    nl: 'Geen chauffeurs komen overeen met uw filters',
    fr: 'Aucun chauffeur ne correspond à vos filtres',
    de: 'Keine Fahrer entsprechen Ihren Filtern',
  );
  String get noLocation => _t('No location', 'لا يوجد موقع',
      nl: 'Geen locatie', fr: 'Aucun emplacement', de: 'Kein Standort');
  String get allDriversOffline => _t(
    'All drivers are currently offline',
    'جميع السائقين غير متصلين حالياً',
    nl: 'Alle chauffeurs zijn momenteel offline',
    fr: 'Tous les chauffeurs sont actuellement hors ligne',
    de: 'Alle Fahrer sind derzeit offline',
  );
  String driversOfflineHint(int total) => _t(
    '$total registered drivers — locations appear when drivers go online',
    '$total سائق مسجل — تظهر المواقع عند اتصال السائقين',
    nl: '$total geregistreerde chauffeurs — locaties verschijnen wanneer chauffeurs online gaan',
    fr: '$total chauffeurs enregistrés — les emplacements apparaissent lorsque les chauffeurs se connectent',
    de: '$total registrierte Fahrer — Standorte erscheinen, wenn Fahrer online gehen',
  );
  String get mapView => _t('Map', 'خريطة',
      nl: 'Kaart', fr: 'Carte', de: 'Karte');
  String get listView => _t('List', 'قائمة',
      nl: 'Lijst', fr: 'Liste', de: 'Liste');
  String get noLocationsAvailable => _t(
    'No driver locations available',
    'لا توجد مواقع سائقين متاحة',
    nl: 'Geen chauffeurlocaties beschikbaar',
    fr: 'Aucun emplacement de chauffeur disponible',
    de: 'Keine Fahrerstandorte verfügbar',
  );

  // ─── Approvals Screen ─────────────────────────────────────────
  String applicationsWaitingReview(int count) => _t(
    '$count applications waiting for review',
    '$count طلبات في انتظار المراجعة',
    nl: '$count aanvragen wachten op beoordeling',
    fr: '$count demandes en attente de révision',
    de: '$count Anträge warten auf Überprüfung',
  );
  String get pending => _t('Pending', 'معلق',
      nl: 'In afwachting', fr: 'En attente', de: 'Ausstehend');
  String statusLabel(String s) => _t('Status: $s', 'الحالة: $s',
      nl: 'Status: $s', fr: 'Statut : $s', de: 'Status: $s');
  String get decline => _t('Decline', 'رفض',
      nl: 'Afwijzen', fr: 'Refuser', de: 'Ablehnen');
  String get approve => _t('Approve', 'قبول',
      nl: 'Goedkeuren', fr: 'Approuver', de: 'Genehmigen');
  String get activate => _t('Activate', 'تفعيل',
      nl: 'Activeren', fr: 'Activer', de: 'Aktivieren');
  String get allCaughtUp => _t('All caught up', 'تم الانتهاء من الكل',
      nl: 'Alles bijgewerkt', fr: 'Tout est à jour', de: 'Alles erledigt');
  String get noPendingApplications => _t(
    'No pending applications to review',
    'لا توجد طلبات معلقة للمراجعة',
    nl: 'Geen openstaande aanvragen om te beoordelen',
    fr: 'Aucune demande en attente à examiner',
    de: 'Keine ausstehenden Anträge zur Überprüfung',
  );

  // ─── Support Screen ───────────────────────────────────────────
  String supportSub(int open, int inProgress, int resolved) => _t(
    '$open open · $inProgress in progress · $resolved resolved',
    '$open مفتوح · $inProgress قيد التنفيذ · $resolved تم الحل',
    nl: '$open open · $inProgress in behandeling · $resolved opgelost',
    fr: '$open ouvert · $inProgress en cours · $resolved résolu',
    de: '$open offen · $inProgress in Bearbeitung · $resolved gelöst',
  );
  String get open => _t('Open', 'مفتوح',
      nl: 'Open', fr: 'Ouvert', de: 'Offen');
  String get inProgress => _t('In Progress', 'قيد التنفيذ',
      nl: 'In behandeling', fr: 'En cours', de: 'In Bearbeitung');
  String get resolved => _t('Resolved', 'تم الحل',
      nl: 'Opgelost', fr: 'Résolu', de: 'Gelöst');
  String get closed => _t('Closed', 'مغلق',
      nl: 'Gesloten', fr: 'Fermé', de: 'Geschlossen');
  String get refresh => _t('Refresh', 'تحديث',
      nl: 'Vernieuwen', fr: 'Actualiser', de: 'Aktualisieren');
  String get noTicketsFound => _t('No tickets found', 'لم يتم العثور على تذاكر',
      nl: 'Geen tickets gevonden', fr: 'Aucun ticket trouvé', de: 'Keine Tickets gefunden');
  String get selectATicket => _t('Select a ticket', 'اختر تذكرة',
      nl: 'Selecteer een ticket', fr: 'Sélectionnez un ticket', de: 'Ticket auswählen');
  String get writeReply => _t('Write a reply...', 'اكتب ردًا...',
      nl: 'Schrijf een antwoord...', fr: 'Écrire une réponse...', de: 'Antwort schreiben...');
  String get reply => _t('Reply', 'رد',
      nl: 'Antwoorden', fr: 'Répondre', de: 'Antworten');
  String get markResolved => _t('Mark Resolved', 'تم الحل',
      nl: 'Markeer als opgelost', fr: 'Marquer comme résolu', de: 'Als gelöst markieren');
  String get close => _t('Close', 'إغلاق',
      nl: 'Sluiten', fr: 'Fermer', de: 'Schließen');
  String get low => _t('Low', 'منخفض',
      nl: 'Laag', fr: 'Faible', de: 'Niedrig');
  String get medium => _t('Medium', 'متوسط',
      nl: 'Gemiddeld', fr: 'Moyen', de: 'Mittel');
  String get high => _t('High', 'مرتفع',
      nl: 'Hoog', fr: 'Élevé', de: 'Hoch');
  String get urgent => _t('Urgent', 'عاجل',
      nl: 'Urgent', fr: 'Urgent', de: 'Dringend');
  String failedToSend(String e) => _t(
    'Failed to send: $e',
    'فشل في الإرسال: $e',
    nl: 'Verzenden mislukt: $e',
    fr: "Échec de l'envoi : $e",
    de: 'Senden fehlgeschlagen: $e',
  );
  String failedToUpdate(String e) => _t(
    'Failed to update: $e',
    'فشل في التحديث: $e',
    nl: 'Bijwerken mislukt: $e',
    fr: 'Échec de la mise à jour : $e',
    de: 'Aktualisierung fehlgeschlagen: $e',
  );

  // ─── Profile Screen ───────────────────────────────────────────
  String get settings => _t('Settings', 'الإعدادات',
      nl: 'Instellingen', fr: 'Paramètres', de: 'Einstellungen');
  String get theme => _t('Theme', 'المظهر',
      nl: 'Thema', fr: 'Thème', de: 'Design');
  String get darkMode => _t('Dark', 'داكن',
      nl: 'Donker', fr: 'Sombre', de: 'Dunkel');
  String get lightMode => _t('Light', 'فاتح',
      nl: 'Licht', fr: 'Clair', de: 'Hell');
  String get systemDefault => _t('System', 'النظام',
      nl: 'Systeem', fr: 'Système', de: 'System');
  String get language => _t('Language', 'اللغة',
      nl: 'Taal', fr: 'Langue', de: 'Sprache');
  String get english => _t('English', 'الإنجليزية',
      nl: 'Engels', fr: 'Anglais', de: 'Englisch');
  String get arabic => _t('Arabic', 'العربية',
      nl: 'Arabisch', fr: 'Arabe', de: 'Arabisch');
  String get dutch => _t('Dutch', 'الهولندية',
      nl: 'Nederlands', fr: 'Néerlandais', de: 'Niederländisch');
  String get french => _t('French', 'الفرنسية',
      nl: 'Frans', fr: 'Français', de: 'Französisch');
  String get german => _t('German', 'الألمانية',
      nl: 'Duits', fr: 'Allemand', de: 'Deutsch');

  // ─── Shared ───────────────────────────────────────────────────
  String get connectionError => _t(
    'Connection error. Please try again.',
    'خطأ في الاتصال. يرجى المحاولة مرة أخرى.',
    nl: 'Verbindingsfout. Probeer het opnieuw.',
    fr: 'Erreur de connexion. Veuillez réessayer.',
    de: 'Verbindungsfehler. Bitte versuchen Sie es erneut.',
  );
  String driverApproved(String name) => _t(
    '$name approved',
    'تمت الموافقة على $name',
    nl: '$name goedgekeurd',
    fr: '$name approuvé',
    de: '$name genehmigt',
  );
  String driverRejected(String name) => _t(
    '$name rejected',
    'تم رفض $name',
    nl: '$name afgewezen',
    fr: '$name refusé',
    de: '$name abgelehnt',
  );
  String restaurantActivated(String name) => _t(
    '$name activated',
    'تم تفعيل $name',
    nl: '$name geactiveerd',
    fr: '$name activé',
    de: '$name aktiviert',
  );
  String failed(String e) => _t('Failed: $e', 'فشل: $e',
      nl: 'Mislukt: $e', fr: 'Échec : $e', de: 'Fehlgeschlagen: $e');
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
