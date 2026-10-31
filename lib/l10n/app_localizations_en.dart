// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tarjetas y Pagos';

  @override
  String get appTagline => 'Your cards, expenses and debts in one place';

  @override
  String get retry => 'Retry';

  @override
  String get databaseOpenError => 'Couldn\'t open the database';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get back => 'Back';

  @override
  String get notNow => 'Not now';

  @override
  String get activate => 'Turn on';

  @override
  String get unexpectedError => 'Something went wrong. Please try again.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String passwordRulesHint(int min) {
    return 'At least $min characters, with letters and numbers';
  }

  @override
  String tooManyAttemptsWait(String wait) {
    return 'Too many attempts. Wait $wait.';
  }

  @override
  String get fingerprintUnavailable =>
      'Set up a fingerprint in your phone settings first.';

  @override
  String get fingerprintNotConfirmed => 'The fingerprint wasn\'t confirmed.';

  @override
  String get onboardingCardsTitle => 'Your cards';

  @override
  String get onboardingCardsBody =>
      'Add your credit cards with a photo. We only keep the last 4 digits.';

  @override
  String get onboardingAiTitle => 'Expenses with AI';

  @override
  String get onboardingAiBody =>
      'Take a photo of the receipt and the app fills in the expense for you.';

  @override
  String get onboardingBestCardTitle => 'Best card today';

  @override
  String get onboardingBestCardBody =>
      'We tell you which card to use based on its closing date, so you pay later.';

  @override
  String get onboardingReportsTitle => 'Reports';

  @override
  String get onboardingReportsBody =>
      'Filter by date, card, category or merchant and see where your money goes.';

  @override
  String get loginTitle => 'Log in';

  @override
  String get loginSubtitle => 'Log in to see your cards and expenses';

  @override
  String get wrongCredentials => 'Wrong email or password';

  @override
  String tooManyAttemptsRetryIn(String wait) {
    return 'Too many attempts. Try again in $wait.';
  }

  @override
  String get fingerprintVerifyFailed => 'Couldn\'t verify your fingerprint';

  @override
  String loginWithFingerprintAs(String name) {
    return 'Log in with fingerprint as $name';
  }

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get createAccount => 'Create account';

  @override
  String get registerSubtitle => 'Your data is stored only on this phone';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get emailAlreadyRegistered => 'This email is already registered';

  @override
  String unlockHello(String name) {
    return 'Hi, $name';
  }

  @override
  String get unlockPrompt => 'Use your fingerprint to log in';

  @override
  String get unlockFailed =>
      'Couldn\'t verify your fingerprint. Try again or use your password.';

  @override
  String get unlockBlocked =>
      'We couldn\'t verify your fingerprint. Log in with your password.';

  @override
  String get unlockWithFingerprint => 'Unlock with fingerprint';

  @override
  String get usePassword => 'Use password';

  @override
  String get loginWithPassword => 'Log in with password';

  @override
  String get biometricReasonUnlock => 'Confirm your identity to log in';

  @override
  String get biometricReasonEnable => 'Confirm your fingerprint to turn it on';

  @override
  String get fieldEmailRequired => 'Enter your email';

  @override
  String get fieldEmailInvalid => 'Invalid email';

  @override
  String get fieldPasswordRequired => 'Enter your password';

  @override
  String fieldPasswordTooShort(int min) {
    return 'At least $min characters';
  }

  @override
  String fieldTooLong(int max) {
    return 'At most $max characters';
  }

  @override
  String get fieldPasswordLettersDigits => 'Must have letters and numbers';

  @override
  String get fieldConfirmRequired => 'Confirm your password';

  @override
  String get fieldPasswordMismatch => 'Passwords don\'t match';

  @override
  String get fieldFirstNameRequired => 'Enter your first name';

  @override
  String get fieldLastNameRequired => 'Enter your last name';

  @override
  String get fieldSamePassword => 'Must be different from the current one';

  @override
  String fieldNotifyDaysRange(int min, int max) {
    return 'Enter $min to $max days';
  }

  @override
  String get profileTitle => 'My profile';

  @override
  String get sectionData => 'Details';

  @override
  String get nameAndSurname => 'Name';

  @override
  String get changeEmail => 'Change email';

  @override
  String get changePassword => 'Change password';

  @override
  String get sectionSecurity => 'Security';

  @override
  String get fingerprintLogin => 'Log in with fingerprint';

  @override
  String get fingerprintLoginSubtitle =>
      'Your fingerprint is asked when you open the app.';

  @override
  String get fingerprintEnabled =>
      'Done: the app will ask for your fingerprint.';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get languageLabel => 'Language';

  @override
  String get sectionPreferences => 'Preferences';

  @override
  String get defaultCurrency => 'Default currency';

  @override
  String get notifyBefore => 'Remind me';

  @override
  String get sectionCategories => 'Categories';

  @override
  String get myCategories => 'My categories';

  @override
  String get logout => 'Log out';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmBody => 'Your data stays saved on this phone.';

  @override
  String get fewerDays => 'Fewer days';

  @override
  String get moreDays => 'More days';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days before',
      one: '1 day before',
    );
    return '$_temp0';
  }

  @override
  String get currentPasswordRequired => 'Enter your current password';

  @override
  String get currentPasswordWrong => 'The current password is wrong';

  @override
  String get emailHasAccount => 'That email already has an account';

  @override
  String get emailUpdated => 'Email updated';

  @override
  String currentEmail(String email) {
    return 'Current email: $email';
  }

  @override
  String get newEmailLabel => 'New email';

  @override
  String get currentPasswordLabel => 'Current password';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get confirmNewPasswordLabel => 'Confirm new password';

  @override
  String get passwordUpdated => 'Password updated';

  @override
  String get setupTitle => 'Set up your account';

  @override
  String stepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get setupCurrencyTitle => 'Which currency do you spend most in?';

  @override
  String get setupCurrencyBody =>
      'It will be the first currency in new expenses and debts.';

  @override
  String get setupCardTitle => 'Add your first card';

  @override
  String get setupCardBody => 'We only keep the last 4 digits.';

  @override
  String get setupFingerprintTitle => 'Log in with your fingerprint';

  @override
  String get setupFingerprintBody =>
      'When you open the app, your fingerprint will be asked instead of the password.';

  @override
  String get setupRemindersTitle => 'Reminders';

  @override
  String get setupRemindersBody =>
      'We remind you before your cards\' closing date, the payment due date and debts coming due.';

  @override
  String get addCard => 'Add card';

  @override
  String get illDoItLater => 'I\'ll do it later';

  @override
  String get enableReminders => 'Turn on reminders';

  @override
  String get cardAdded => 'Card added';

  @override
  String get notificationsDenied =>
      'Without permission we can\'t remind you. You can allow it later in your phone settings.';
}
