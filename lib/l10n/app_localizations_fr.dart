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

  @override
  String get secQFirstPet =>
      'Comment s\'appelait votre premier animal de compagnie ?';

  @override
  String get secQBirthCity => 'Dans quelle ville êtes-vous né(e) ?';

  @override
  String get secQPrimarySchool => 'Comment s\'appelait votre école primaire ?';

  @override
  String get secQChildhoodFriend =>
      'Comment s\'appelait votre meilleur ami d\'enfance ?';

  @override
  String get secQFirstJob => 'Où était votre premier emploi ?';

  @override
  String get secQCustom => 'Écrire ma propre question';

  @override
  String get securityQuestionLabel => 'Question de sécurité';

  @override
  String get customQuestionLabel => 'Votre question';

  @override
  String get securityAnswerLabel => 'Réponse';

  @override
  String get securityAnswerHint =>
      'Les majuscules et les accents ne comptent pas.';

  @override
  String get registerSecurityHint =>
      'Vous l\'utiliserez si vous oubliez votre mot de passe.';

  @override
  String get fieldQuestionChoose => 'Choisissez une question';

  @override
  String get fieldQuestionRequired => 'Saisissez votre question';

  @override
  String get fieldAnswerRequired => 'Saisissez votre réponse';

  @override
  String fieldAnswerTooShort(int min) {
    return 'Au moins $min caractères';
  }

  @override
  String get forgotPasswordLink => 'Mot de passe oublié ?';

  @override
  String get forgotTitle => 'Récupérer le mot de passe';

  @override
  String get forgotEmailSubtitle => 'Saisissez l\'e-mail de votre compte.';

  @override
  String get forgotAnswerSubtitle => 'Répondez à votre question de sécurité.';

  @override
  String get forgotNewPasswordSubtitle => 'Créez un nouveau mot de passe.';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get accountNotFound => 'Aucun compte trouvé avec cet e-mail';

  @override
  String get noSecurityQuestion => 'Ce compte n\'a pas de question de sécurité';

  @override
  String get wrongAnswer => 'La réponse est incorrecte';

  @override
  String get securityQuestionMissing =>
      'Configurez une question pour pouvoir récupérer votre mot de passe.';

  @override
  String get securityQuestionSaved => 'Question de sécurité enregistrée';

  @override
  String greetingMorning(String name) {
    return 'Bonjour, $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'Bon après-midi, $name';
  }

  @override
  String greetingNight(String name) {
    return 'Bonsoir, $name';
  }

  @override
  String cutsIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Clôture dans $days jours',
      one: 'Clôture demain',
      zero: 'Clôture aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String recommendationLine(String cut, String due, String days) {
    return '$cut · à payer le $due · $days';
  }

  @override
  String get receiptErrorOffline =>
      'Pas de connexion internet. Saisissez la dépense à la main.';

  @override
  String get receiptErrorTimeout =>
      'L\'IA a mis trop de temps. Réessayez ou saisissez à la main.';

  @override
  String get receiptErrorInvalidKey =>
      'La clé de l\'IA n\'est pas valide. Saisissez la dépense à la main.';

  @override
  String get receiptErrorRateLimited =>
      'L\'IA reçoit trop de demandes. Réessayez dans un moment.';

  @override
  String get receiptErrorUnavailable =>
      'L\'IA n\'est pas disponible pour le moment. Saisissez la dépense à la main.';

  @override
  String get receiptErrorImageTooLarge =>
      'La photo est trop grande. Essayez-en une autre.';

  @override
  String get receiptErrorInvalidResponse =>
      'Nous n\'avons pas pu lire le reçu. Saisissez la dépense à la main.';

  @override
  String get fieldCardAliasRequired => 'Saisissez un nom pour la carte';

  @override
  String get fieldCardBankRequired => 'Saisissez la banque';

  @override
  String get fieldCardLast4Invalid => 'Saisissez les 4 derniers chiffres';

  @override
  String get fieldCardCutDayRange => 'Le jour de clôture va de 1 à 31';

  @override
  String get fieldCardPaymentDaysRange => 'Les jours pour payer vont de 0 à 60';

  @override
  String get fieldCardLimitInvalid => 'Plafond invalide';

  @override
  String get fieldCardDualMustBeDop =>
      'Une carte à double solde est en RD\$ et US\$';

  @override
  String get fieldCardCurrencyInUse =>
      'Cette carte a des mouvements dans cette devise ; vous ne pouvez pas la retirer';

  @override
  String get fieldAmountInvalid => 'Montant invalide';

  @override
  String get fieldNoBalanceInCurrency =>
      'La carte n\'a pas de solde dans cette devise';

  @override
  String get fieldMerchantRequired => 'Saisissez le commerçant';

  @override
  String get fieldConversionInvalid => 'Conversion invalide';

  @override
  String get fieldCategoryRequired => 'Choisissez une catégorie';

  @override
  String get fieldCardRequired => 'Choisissez une carte';

  @override
  String get fieldDateInFuture => 'La date ne peut pas être dans le futur';

  @override
  String get fieldCategoryNameRequired => 'Saisissez un nom';

  @override
  String get fieldCategoryIconInvalid => 'Icône invalide';

  @override
  String get fieldCategoryColorInvalid => 'Couleur invalide';

  @override
  String get fieldCategoryNameTaken => 'Vous avez déjà une catégorie de ce nom';

  @override
  String get fieldCategoryReassignOther => 'Choisissez une autre catégorie';

  @override
  String get catSupermarket => 'Supermarché';

  @override
  String get catFuel => 'Carburant';

  @override
  String get catBarbershop => 'Barbier';

  @override
  String get catSalon => 'Salon de coiffure';

  @override
  String get catBeauty => 'Beauté';

  @override
  String get catHardware => 'Quincaillerie';

  @override
  String get catElectricity => 'Électricité';

  @override
  String get catWater => 'Eau';

  @override
  String get catPhone => 'Téléphone';

  @override
  String get catLiquor => 'Alcool';

  @override
  String get catHealth => 'Santé';

  @override
  String get catRestaurant => 'Restaurant';

  @override
  String get catOther => 'Autres';

  @override
  String get myCards => 'Mes cartes';

  @override
  String get seeAll => 'Voir tout';

  @override
  String get cardsLoadError => 'Impossible de charger vos cartes';

  @override
  String monthSummary(String month) {
    return 'Résumé — $month';
  }

  @override
  String get spentThisMonth => 'Dépensé ce mois-ci';

  @override
  String get totalDebt => 'Dette totale';

  @override
  String debtSplit(String cards, String other) {
    return 'Cartes $cards · Autres dettes $other';
  }

  @override
  String get bestCardToday => 'Meilleure carte aujourd\'hui';

  @override
  String get bestCardEmpty =>
      'Ajoutez une carte pour savoir laquelle utiliser aujourd\'hui.';

  @override
  String get lowCredit => 'Peu de crédit disponible';

  @override
  String get newExpense => 'Nouvelle dépense';

  @override
  String get reports => 'Rapports';

  @override
  String get debts => 'Dettes';

  @override
  String get noCardsYet => 'Vous n\'avez pas encore de carte.';

  @override
  String get add => 'Ajouter';

  @override
  String get noCardsYetTitle => 'Vous n\'avez pas encore de carte';

  @override
  String get addFirstCardHint =>
      'Ajoutez votre première carte pour savoir laquelle utiliser chaque jour.';

  @override
  String cutOn(String date) {
    return 'Clôture $date';
  }

  @override
  String get availableNone => 'Disponible —';

  @override
  String availableAmount(String amount) {
    return 'Disponible $amount';
  }

  @override
  String get dualBalance => 'RD\$ et US\$';

  @override
  String get cardNotFound => 'Carte introuvable';

  @override
  String get registerPayment => 'Enregistrer un paiement';

  @override
  String get fieldAmountPositive => 'Saisissez un montant supérieur à 0';

  @override
  String get amountPaid => 'Montant payé';

  @override
  String payStatementDue(String amount) {
    return 'Payer ce relevé : $amount';
  }

  @override
  String get paymentDate => 'Date du paiement';

  @override
  String get noteOptional => 'Note (facultatif)';

  @override
  String get card => 'Carte';

  @override
  String get filterExpenses => 'Filtrer les dépenses';

  @override
  String get editCard => 'Modifier la carte';

  @override
  String get movements => 'Mouvements';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get filterError => 'Impossible de filtrer les dépenses';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get nextCut => 'Prochaine clôture';

  @override
  String get nextCutDue => 'Date limite de ce relevé';

  @override
  String get payInIfUsedToday =>
      'Si vous l\'utilisez aujourd\'hui, vous payez dans';

  @override
  String daysCountPlain(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
      zero: '0 jour',
    );
    return '$_temp0';
  }

  @override
  String creditInFavor(String currency) {
    return 'Solde créditeur ($currency)';
  }

  @override
  String balanceIn(String currency) {
    return 'Solde ($currency)';
  }

  @override
  String availableOf(String available, String limit) {
    return 'Disponible $available sur $limit';
  }

  @override
  String get dueThisStatement => 'À payer sur ce relevé';

  @override
  String payBefore(String date) {
    return 'À payer avant le $date';
  }

  @override
  String overdueSince(String amount, String date) {
    return 'En retard : $amount depuis le $date';
  }

  @override
  String get noCategory => 'Sans catégorie';

  @override
  String convertedAt(String amount, String rate) {
    return '$amount à $rate';
  }

  @override
  String get deletePaymentTitle => 'Supprimer ce paiement ?';

  @override
  String deletePaymentBody(String amount) {
    return 'Le solde augmentera à nouveau de $amount.';
  }

  @override
  String get payment => 'Paiement';

  @override
  String get noExpensesMatch => 'Aucune dépense ne correspond aux filtres';

  @override
  String get noMovementsYet => 'Aucun mouvement sur cette carte pour le moment';

  @override
  String get tapNewExpenseHint =>
      'Touchez « Nouvelle dépense » pour enregistrer la première.';

  @override
  String get cardScanNothing =>
      'Nous n\'avons pas pu lire la carte ; saisissez les informations à la main';

  @override
  String get scanPurposeCard =>
      'Nous l\'utilisons uniquement pour lire la carte sur votre téléphone. La photo n\'est ni enregistrée ni envoyée, et nous ne gardons que les 4 derniers chiffres.';

  @override
  String get scanPurposeReceipt =>
      'Nous l\'utilisons uniquement pour lire le reçu avec l\'IA. La photo est envoyée une seule fois pour la lire et n\'est pas enregistrée.';

  @override
  String get archiveCardTitle => 'Archiver cette carte ?';

  @override
  String get archiveCardBody =>
      'Elle n\'apparaîtra plus dans vos listes ni dans la recommandation. Ses données sont conservées.';

  @override
  String get archive => 'Archiver';

  @override
  String get newCard => 'Nouvelle carte';

  @override
  String get scanCard => 'Scanner la carte';

  @override
  String get scanCardHint =>
      'Nous lisons la photo sur votre téléphone et ne gardons que les 4 derniers chiffres.';

  @override
  String get cardAliasLabel => 'Nom (ex. Dépenses du mois)';

  @override
  String get detectedByPhoto => 'Détecté sur la photo';

  @override
  String get brand => 'Marque';

  @override
  String get brandOther => 'Autre';

  @override
  String get last4Label => '4 derniers chiffres';

  @override
  String get last4Helper => 'Nous ne stockons jamais le numéro complet';

  @override
  String get fieldCutDay => 'Saisissez un jour de 1 à 31';

  @override
  String get cutDayLabel => 'Jour de clôture';

  @override
  String get cutDayHelper =>
      'Si le mois est plus court, son dernier jour est utilisé';

  @override
  String get fieldPaymentDays => 'Saisissez de 0 à 60 jours';

  @override
  String get paymentDaysLabel => 'Jours pour payer après la clôture';

  @override
  String get currency => 'Devise';

  @override
  String get dualBalanceOption => 'RD\$ et US\$ (double solde)';

  @override
  String get dualBalanceHint =>
      'Chaque dépense reste dans sa devise, avec un plafond par devise.';

  @override
  String get singleCurrencyHint =>
      'Les dépenses dans une autre devise sont converties dans celle-ci.';

  @override
  String get fieldLimitInvalid => 'Montant invalide (ex. 50000 ou 50,000.00)';

  @override
  String get limitDopOptional => 'Plafond en RD\$ (facultatif)';

  @override
  String get creditLimitOptional => 'Plafond de crédit (facultatif)';

  @override
  String get limitUsdOptional => 'Plafond en US\$ (facultatif)';

  @override
  String get color => 'Couleur';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get archiveCard => 'Archiver la carte';

  @override
  String get readingCard => 'Lecture de la carte…';

  @override
  String get bank => 'Banque';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get pickFromGallery => 'Choisir dans la galerie';

  @override
  String get permissionAltGallery =>
      'Vous pouvez l\'activer dans les réglages ou choisir une photo dans la galerie.';

  @override
  String get permissionAltCamera =>
      'Vous pouvez l\'activer dans les réglages ou prendre une photo avec l\'appareil.';

  @override
  String get allowCamera => 'Autorisez l\'accès à l\'appareil photo';

  @override
  String get allowPhotos => 'Autorisez l\'accès à vos photos';

  @override
  String get openSettings => 'Ouvrir les réglages';

  @override
  String get openSettingsHint =>
      'Ouvrez les réglages du téléphone pour l\'autoriser';

  @override
  String get expenseLoadError => 'Impossible de charger la dépense';

  @override
  String get expenseNotFound => 'Dépense introuvable';

  @override
  String get newExpenseTitle => 'Nouvelle dépense';

  @override
  String get editExpense => 'Modifier la dépense';

  @override
  String get addCardFirst =>
      'Ajoutez d\'abord une carte pour enregistrer des dépenses.';

  @override
  String get deleteExpenseTitle => 'Supprimer cette dépense ?';

  @override
  String get deleteExpenseBody =>
      'Elle sera retirée de la carte et des rapports.';

  @override
  String get scanReceipt => 'Scanner le reçu (IA)';

  @override
  String get scanReceiptHint =>
      'L\'IA lit la photo et propose les données ; vous les vérifiez avant d\'enregistrer. La photo n\'est pas conservée.';

  @override
  String get merchant => 'Commerçant';

  @override
  String get category => 'Catégorie';

  @override
  String get archivedCardExpense =>
      'La carte de cette dépense est archivée : vous pouvez la supprimer, mais pas la modifier.';

  @override
  String get expenseCurrency => 'Devise de la dépense';

  @override
  String get amount => 'Montant';

  @override
  String recordedOnCardAs(String amount) {
    return 'Enregistrée sur la carte comme $amount';
  }

  @override
  String get date => 'Date';

  @override
  String get notesOptional => 'Notes (facultatif)';

  @override
  String get saveExpense => 'Enregistrer la dépense';

  @override
  String get deleteExpense => 'Supprimer la dépense';

  @override
  String get readingReceipt => 'Lecture du reçu…';

  @override
  String get aiChip => 'IA';

  @override
  String get rateLoading => 'Recherche du taux du jour…';

  @override
  String get rateOnline =>
      'Taux en ligne du jour. Vous pouvez l\'ajuster à celui de votre banque.';

  @override
  String get rateStale => 'Hors ligne : dernier taux connu. Vérifiez-le.';

  @override
  String get rateUnavailable => 'Impossible d\'obtenir le taux. Saisissez-le.';

  @override
  String get rateIdle => 'Taux utilisé pour la conversion.';

  @override
  String get fieldRateRequired => 'Saisissez le taux (ex. 61.40)';

  @override
  String get rateLabel => 'Taux (RD\$ pour 1 US\$)';

  @override
  String get refreshRate => 'Obtenir le taux du jour';

  @override
  String get allDates => 'Toutes les dates';

  @override
  String get merchantContains => 'Le commerçant contient';

  @override
  String get minAmount => 'Montant minimum';

  @override
  String get maxAmount => 'Montant maximum';

  @override
  String get apply => 'Appliquer';

  @override
  String get newCategory => 'Nouvelle catégorie';

  @override
  String get editCategory => 'Modifier la catégorie';

  @override
  String get noOwnCategories => 'Vous n\'avez pas encore créé de catégories.';

  @override
  String get includedCategories => 'Incluses';

  @override
  String get includedCategoriesHint =>
      'Elles sont fournies avec l\'app et ne peuvent pas être modifiées.';

  @override
  String get categoriesLoadError => 'Impossible de charger les catégories';

  @override
  String get categoryNotFound => 'Catégorie introuvable';

  @override
  String deleteNamedTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get categoryNoExpenses => 'Elle n\'a aucune dépense.';

  @override
  String get categoryNameLabel => 'Nom (ex. Animaux)';

  @override
  String get icon => 'Icône';

  @override
  String colorNumber(int n) {
    return 'Couleur $n';
  }

  @override
  String get createCategory => 'Créer la catégorie';

  @override
  String get deleteCategory => 'Supprimer la catégorie';

  @override
  String categoryHasExpenses(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '« $name » a $count dépenses',
      one: '« $name » a 1 dépense',
    );
    return '$_temp0';
  }

  @override
  String get reassignHint =>
      'Pour la supprimer, choisissez vers quelle catégorie elles passent.';

  @override
  String get moveTo => 'Déplacer vers';

  @override
  String get moveAndDelete => 'Déplacer et supprimer';
}
