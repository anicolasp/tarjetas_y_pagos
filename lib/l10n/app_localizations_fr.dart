// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Tarjetas y Pagos';

  @override
  String get appTagline => 'Vos cartes, dépenses et dettes au même endroit';

  @override
  String get retry => 'Réessayer';

  @override
  String get databaseOpenError => 'Impossible d\'ouvrir la base de données';

  @override
  String get skip => 'Passer';

  @override
  String get next => 'Suivant';

  @override
  String get getStarted => 'Commencer';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get back => 'Retour';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get activate => 'Activer';

  @override
  String get unexpectedError =>
      'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get firstNameLabel => 'Prénom';

  @override
  String get lastNameLabel => 'Nom';

  @override
  String passwordRulesHint(int min) {
    return 'Au moins $min caractères, avec des lettres et des chiffres';
  }

  @override
  String tooManyAttemptsWait(String wait) {
    return 'Trop de tentatives. Patientez $wait.';
  }

  @override
  String get fingerprintUnavailable =>
      'Configurez d\'abord une empreinte dans les réglages du téléphone.';

  @override
  String get fingerprintNotConfirmed => 'L\'empreinte n\'a pas été confirmée.';

  @override
  String get onboardingCardsTitle => 'Vos cartes';

  @override
  String get onboardingCardsBody =>
      'Ajoutez vos cartes de crédit avec une photo. Nous ne gardons que les 4 derniers chiffres.';

  @override
  String get onboardingAiTitle => 'Dépenses avec IA';

  @override
  String get onboardingAiBody =>
      'Prenez le reçu en photo et l\'app remplit la dépense pour vous.';

  @override
  String get onboardingBestCardTitle => 'Meilleure carte aujourd\'hui';

  @override
  String get onboardingBestCardBody =>
      'Nous vous indiquons quelle carte utiliser selon sa date de clôture, pour payer plus tard.';

  @override
  String get onboardingReportsTitle => 'Rapports';

  @override
  String get onboardingReportsBody =>
      'Filtrez par date, carte, catégorie ou commerçant et voyez où va votre argent.';

  @override
  String get loginTitle => 'Se connecter';

  @override
  String get loginSubtitle => 'Connectez-vous pour voir vos cartes et dépenses';

  @override
  String get wrongCredentials => 'E-mail ou mot de passe incorrect';

  @override
  String tooManyAttemptsRetryIn(String wait) {
    return 'Trop de tentatives. Réessayez dans $wait.';
  }

  @override
  String get fingerprintVerifyFailed =>
      'Impossible de vérifier votre empreinte';

  @override
  String loginWithFingerprintAs(String name) {
    return 'Se connecter avec l\'empreinte en tant que $name';
  }

  @override
  String get noAccount => 'Vous n\'avez pas de compte ?';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get registerSubtitle =>
      'Vos données restent uniquement sur ce téléphone';

  @override
  String get confirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get emailAlreadyRegistered => 'Cet e-mail est déjà enregistré';

  @override
  String unlockHello(String name) {
    return 'Bonjour, $name';
  }

  @override
  String get unlockPrompt => 'Utilisez votre empreinte pour vous connecter';

  @override
  String get unlockFailed =>
      'Impossible de vérifier votre empreinte. Réessayez ou utilisez votre mot de passe.';

  @override
  String get unlockBlocked =>
      'Nous n\'avons pas pu vérifier votre empreinte. Connectez-vous avec votre mot de passe.';

  @override
  String get unlockWithFingerprint => 'Déverrouiller avec l\'empreinte';

  @override
  String get usePassword => 'Utiliser le mot de passe';

  @override
  String get loginWithPassword => 'Se connecter avec le mot de passe';

  @override
  String get biometricReasonUnlock =>
      'Confirmez votre identité pour vous connecter';

  @override
  String get biometricReasonEnable =>
      'Confirmez votre empreinte pour l\'activer';

  @override
  String get fieldEmailRequired => 'Saisissez votre e-mail';

  @override
  String get fieldEmailInvalid => 'E-mail invalide';

  @override
  String get fieldPasswordRequired => 'Saisissez votre mot de passe';

  @override
  String fieldPasswordTooShort(int min) {
    return 'Au moins $min caractères';
  }

  @override
  String fieldTooLong(int max) {
    return '$max caractères maximum';
  }

  @override
  String get fieldPasswordLettersDigits =>
      'Doit contenir des lettres et des chiffres';

  @override
  String get fieldConfirmRequired => 'Confirmez votre mot de passe';

  @override
  String get fieldPasswordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get fieldFirstNameRequired => 'Saisissez votre prénom';

  @override
  String get fieldLastNameRequired => 'Saisissez votre nom';

  @override
  String get fieldSamePassword => 'Doit être différent de l\'actuel';

  @override
  String fieldNotifyDaysRange(int min, int max) {
    return 'Saisissez de $min à $max jours';
  }

  @override
  String get profileTitle => 'Mon profil';

  @override
  String get sectionData => 'Informations';

  @override
  String get nameAndSurname => 'Nom et prénom';

  @override
  String get changeEmail => 'Changer d\'e-mail';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get sectionSecurity => 'Sécurité';

  @override
  String get fingerprintLogin => 'Connexion par empreinte';

  @override
  String get fingerprintLoginSubtitle =>
      'Votre empreinte est demandée à l\'ouverture de l\'app.';

  @override
  String get fingerprintEnabled =>
      'C\'est fait : l\'app vous demandera votre empreinte.';

  @override
  String get sectionAppearance => 'Apparence';

  @override
  String get themeLabel => 'Thème';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSystem => 'Système';

  @override
  String get languageLabel => 'Langue';

  @override
  String get sectionPreferences => 'Préférences';

  @override
  String get defaultCurrency => 'Devise par défaut';

  @override
  String get notifyBefore => 'Me prévenir';

  @override
  String get sectionCategories => 'Catégories';

  @override
  String get myCategories => 'Mes catégories';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get logoutConfirmTitle => 'Se déconnecter ?';

  @override
  String get logoutConfirmBody =>
      'Vos données restent enregistrées sur ce téléphone.';

  @override
  String get fewerDays => 'Moins de jours';

  @override
  String get moreDays => 'Plus de jours';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours avant',
      one: '1 jour avant',
    );
    return '$_temp0';
  }

  @override
  String get currentPasswordRequired => 'Saisissez votre mot de passe actuel';

  @override
  String get currentPasswordWrong => 'Le mot de passe actuel est incorrect';

  @override
  String get emailHasAccount => 'Cet e-mail a déjà un compte';

  @override
  String get emailUpdated => 'E-mail mis à jour';

  @override
  String currentEmail(String email) {
    return 'E-mail actuel : $email';
  }

  @override
  String get newEmailLabel => 'Nouvel e-mail';

  @override
  String get currentPasswordLabel => 'Mot de passe actuel';

  @override
  String get newPasswordLabel => 'Nouveau mot de passe';

  @override
  String get confirmNewPasswordLabel => 'Confirmer le nouveau mot de passe';

  @override
  String get passwordUpdated => 'Mot de passe mis à jour';

  @override
  String get setupTitle => 'Configurez votre compte';

  @override
  String stepOf(int step, int total) {
    return 'Étape $step sur $total';
  }

  @override
  String get setupCurrencyTitle => 'Dans quelle devise dépensez-vous le plus ?';

  @override
  String get setupCurrencyBody =>
      'Ce sera la devise proposée en premier pour les nouvelles dépenses et dettes.';

  @override
  String get setupCardTitle => 'Ajoutez votre première carte';

  @override
  String get setupCardBody => 'Nous ne gardons que les 4 derniers chiffres.';

  @override
  String get setupFingerprintTitle => 'Connectez-vous avec votre empreinte';

  @override
  String get setupFingerprintBody =>
      'À l\'ouverture de l\'app, votre empreinte sera demandée au lieu du mot de passe.';

  @override
  String get setupRemindersTitle => 'Rappels';

  @override
  String get setupRemindersBody =>
      'Nous vous prévenons avant la clôture de vos cartes, la date limite de paiement et l\'échéance de vos dettes.';

  @override
  String get addCard => 'Ajouter une carte';

  @override
  String get illDoItLater => 'Plus tard';

  @override
  String get enableReminders => 'Activer les rappels';

  @override
  String get cardAdded => 'Carte ajoutée';

  @override
  String get notificationsDenied =>
      'Sans autorisation, nous ne pourrons pas vous prévenir. Vous pourrez l\'accorder plus tard dans les réglages du téléphone.';
}
