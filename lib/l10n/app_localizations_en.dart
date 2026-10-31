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

  @override
  String get secQFirstPet => 'What was the name of your first pet?';

  @override
  String get secQBirthCity => 'In what city were you born?';

  @override
  String get secQPrimarySchool =>
      'What was the name of your elementary school?';

  @override
  String get secQChildhoodFriend =>
      'What was the name of your best childhood friend?';

  @override
  String get secQFirstJob => 'Where was your first job?';

  @override
  String get secQCustom => 'Write my own question';

  @override
  String get securityQuestionLabel => 'Security question';

  @override
  String get customQuestionLabel => 'Your question';

  @override
  String get securityAnswerLabel => 'Answer';

  @override
  String get securityAnswerHint => 'Capitals and accents don\'t matter.';

  @override
  String get registerSecurityHint =>
      'You\'ll use it if you forget your password.';

  @override
  String get fieldQuestionChoose => 'Choose a question';

  @override
  String get fieldQuestionRequired => 'Write your question';

  @override
  String get fieldAnswerRequired => 'Enter your answer';

  @override
  String fieldAnswerTooShort(int min) {
    return 'At least $min characters';
  }

  @override
  String get forgotPasswordLink => 'Forgot your password?';

  @override
  String get forgotTitle => 'Recover password';

  @override
  String get forgotEmailSubtitle => 'Enter your account email.';

  @override
  String get forgotAnswerSubtitle => 'Answer your security question.';

  @override
  String get forgotNewPasswordSubtitle => 'Create a new password.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get accountNotFound => 'We couldn\'t find an account with that email';

  @override
  String get noSecurityQuestion => 'This account has no security question';

  @override
  String get wrongAnswer => 'The answer is wrong';

  @override
  String get securityQuestionMissing =>
      'Set a question so you can recover your password.';

  @override
  String get securityQuestionSaved => 'Security question saved';

  @override
  String greetingMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String greetingNight(String name) {
    return 'Good evening, $name';
  }

  @override
  String cutsIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Closes in $days days',
      one: 'Closes tomorrow',
      zero: 'Closes today',
    );
    return '$_temp0';
  }

  @override
  String recommendationLine(String cut, String due, String days) {
    return '$cut · pay by $due · $days';
  }

  @override
  String get receiptErrorOffline =>
      'No internet connection. Fill in the expense by hand.';

  @override
  String get receiptErrorTimeout =>
      'The AI took too long. Try again or fill it in by hand.';

  @override
  String get receiptErrorInvalidKey =>
      'The AI key is not valid. Fill in the expense by hand.';

  @override
  String get receiptErrorRateLimited =>
      'The AI is getting too many requests. Try again in a while.';

  @override
  String get receiptErrorUnavailable =>
      'The AI is not available now. Fill in the expense by hand.';

  @override
  String get receiptErrorImageTooLarge =>
      'The photo is too large. Try another one.';

  @override
  String get receiptErrorInvalidResponse =>
      'We couldn\'t read the receipt. Fill in the expense by hand.';

  @override
  String get fieldCardAliasRequired => 'Enter a name for the card';

  @override
  String get fieldCardBankRequired => 'Enter the bank';

  @override
  String get fieldCardLast4Invalid => 'Enter the last 4 digits';

  @override
  String get fieldCardCutDayRange => 'The closing day goes from 1 to 31';

  @override
  String get fieldCardPaymentDaysRange => 'Days to pay go from 0 to 60';

  @override
  String get fieldCardLimitInvalid => 'Invalid limit';

  @override
  String get fieldCardDualMustBeDop =>
      'A dual-balance card is RD\\\$ and US\\\$';

  @override
  String get fieldCardCurrencyInUse =>
      'This card has movements in that currency; you cannot remove it';

  @override
  String get fieldAmountInvalid => 'Invalid amount';

  @override
  String get fieldNoBalanceInCurrency =>
      'The card has no balance in that currency';

  @override
  String get fieldMerchantRequired => 'Enter the merchant';

  @override
  String get fieldConversionInvalid => 'Invalid conversion';

  @override
  String get fieldCategoryRequired => 'Choose a category';

  @override
  String get fieldCardRequired => 'Choose a card';

  @override
  String get fieldDateInFuture => 'The date can\'t be in the future';

  @override
  String get fieldCategoryNameRequired => 'Enter a name';

  @override
  String get fieldCategoryIconInvalid => 'Invalid icon';

  @override
  String get fieldCategoryColorInvalid => 'Invalid color';

  @override
  String get fieldCategoryNameTaken => 'You already have a category like that';

  @override
  String get fieldCategoryReassignOther => 'Choose another category';

  @override
  String get catSupermarket => 'Supermarket';

  @override
  String get catFuel => 'Fuel';

  @override
  String get catBarbershop => 'Barbershop';

  @override
  String get catSalon => 'Salon';

  @override
  String get catBeauty => 'Beauty';

  @override
  String get catHardware => 'Hardware store';

  @override
  String get catElectricity => 'Electricity';

  @override
  String get catWater => 'Water';

  @override
  String get catPhone => 'Phone';

  @override
  String get catLiquor => 'Liquor';

  @override
  String get catHealth => 'Health';

  @override
  String get catRestaurant => 'Restaurant';

  @override
  String get catOther => 'Other';

  @override
  String get myCards => 'My cards';

  @override
  String get seeAll => 'See all';

  @override
  String get cardsLoadError => 'Couldn\'t load your cards';

  @override
  String monthSummary(String month) {
    return 'Summary for $month';
  }

  @override
  String get spentThisMonth => 'Spent this month';

  @override
  String get totalDebt => 'Total debt';

  @override
  String debtSplit(String cards, String other) {
    return 'Cards $cards · Other debts $other';
  }

  @override
  String get bestCardToday => 'Best card today';

  @override
  String get bestCardEmpty =>
      'Add a card to see which one is best to use today.';

  @override
  String get lowCredit => 'Low available credit';

  @override
  String get newExpense => 'New expense';

  @override
  String get reports => 'Reports';

  @override
  String get debts => 'Debts';

  @override
  String get noCardsYet => 'You don\'t have any cards yet.';

  @override
  String get add => 'Add';

  @override
  String get noCardsYetTitle => 'You don\'t have any cards yet';

  @override
  String get addFirstCardHint =>
      'Add your first card to see which one is best to use each day.';

  @override
  String cutOn(String date) {
    return 'Closes $date';
  }

  @override
  String get availableNone => 'Available —';

  @override
  String availableAmount(String amount) {
    return 'Available $amount';
  }

  @override
  String get dualBalance => 'RD\\\$ and US\\\$';

  @override
  String get cardNotFound => 'Card not found';

  @override
  String get registerPayment => 'Record payment';

  @override
  String get fieldAmountPositive => 'Enter an amount greater than 0';

  @override
  String get amountPaid => 'Amount paid';

  @override
  String payStatementDue(String amount) {
    return 'Pay this statement: $amount';
  }

  @override
  String get paymentDate => 'Payment date';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get card => 'Card';

  @override
  String get filterExpenses => 'Filter expenses';

  @override
  String get editCard => 'Edit card';

  @override
  String get movements => 'Movements';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get filterError => 'Couldn\'t filter the expenses';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get nextCut => 'Next closing';

  @override
  String get nextCutDue => 'Due date for that statement';

  @override
  String get payInIfUsedToday => 'If you use it today, you pay in';

  @override
  String daysCountPlain(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: '0 days',
    );
    return '$_temp0';
  }

  @override
  String creditInFavor(String currency) {
    return 'Credit balance ($currency)';
  }

  @override
  String balanceIn(String currency) {
    return 'Balance ($currency)';
  }

  @override
  String availableOf(String available, String limit) {
    return 'Available $available of $limit';
  }

  @override
  String get dueThisStatement => 'Due this statement';

  @override
  String payBefore(String date) {
    return 'Pay before $date';
  }

  @override
  String overdueSince(String amount, String date) {
    return 'Overdue: $amount since $date';
  }

  @override
  String get noCategory => 'No category';

  @override
  String convertedAt(String amount, String rate) {
    return '$amount at $rate';
  }

  @override
  String get deletePaymentTitle => 'Delete this payment?';

  @override
  String deletePaymentBody(String amount) {
    return 'The balance will go back up by $amount.';
  }

  @override
  String get payment => 'Payment';

  @override
  String get noExpensesMatch => 'No expenses match the filters';

  @override
  String get noMovementsYet => 'No movements on this card yet';

  @override
  String get tapNewExpenseHint =>
      'Tap \"New expense\" to record the first one.';

  @override
  String get cardScanNothing =>
      'We couldn\'t read the card; fill in the details by hand';

  @override
  String get scanPurposeCard =>
      'We only use it to read the card on your phone. The photo is neither saved nor sent, and we only keep the last 4 digits.';

  @override
  String get scanPurposeReceipt =>
      'We only use it to read the receipt with AI. The photo is sent once to read it and is not saved.';

  @override
  String get archiveCardTitle => 'Archive this card?';

  @override
  String get archiveCardBody =>
      'It will no longer appear in your lists or in the recommendation. Its data is kept.';

  @override
  String get archive => 'Archive';

  @override
  String get newCard => 'New card';

  @override
  String get scanCard => 'Scan card';

  @override
  String get scanCardHint =>
      'We read the photo on your phone and only keep the last 4 digits.';

  @override
  String get cardAliasLabel => 'Name (e.g. Monthly spending)';

  @override
  String get detectedByPhoto => 'Detected from photo';

  @override
  String get brand => 'Brand';

  @override
  String get brandOther => 'Other';

  @override
  String get last4Label => 'Last 4 digits';

  @override
  String get last4Helper => 'We never store the full number';

  @override
  String get fieldCutDay => 'Enter a day from 1 to 31';

  @override
  String get cutDayLabel => 'Closing day';

  @override
  String get cutDayHelper => 'If the month is shorter, its last day is used';

  @override
  String get fieldPaymentDays => 'Enter 0 to 60 days';

  @override
  String get paymentDaysLabel => 'Days to pay after closing';

  @override
  String get currency => 'Currency';

  @override
  String get dualBalanceOption => 'RD\\\$ and US\\\$ (dual balance)';

  @override
  String get dualBalanceHint =>
      'Each expense stays in its currency, with a limit per currency.';

  @override
  String get singleCurrencyHint =>
      'Expenses in another currency are converted to this one.';

  @override
  String get fieldLimitInvalid => 'Invalid amount (e.g. 50000 or 50,000.00)';

  @override
  String get limitDopOptional => 'Limit in RD\\\$ (optional)';

  @override
  String get creditLimitOptional => 'Credit limit (optional)';

  @override
  String get limitUsdOptional => 'Limit in US\\\$ (optional)';

  @override
  String get color => 'Color';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get archiveCard => 'Archive card';

  @override
  String get readingCard => 'Reading the card…';

  @override
  String get bank => 'Bank';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get pickFromGallery => 'Choose from gallery';

  @override
  String get permissionAltGallery =>
      'You can turn it on in settings or choose a photo from the gallery.';

  @override
  String get permissionAltCamera =>
      'You can turn it on in settings or take a photo with the camera.';

  @override
  String get allowCamera => 'Allow camera access';

  @override
  String get allowPhotos => 'Allow access to your photos';

  @override
  String get openSettings => 'Open settings';

  @override
  String get openSettingsHint => 'Open your phone settings to allow it';

  @override
  String get expenseLoadError => 'Couldn\'t load the expense';

  @override
  String get expenseNotFound => 'Expense not found';

  @override
  String get newExpenseTitle => 'New expense';

  @override
  String get editExpense => 'Edit expense';

  @override
  String get addCardFirst => 'Add a card first to record expenses.';

  @override
  String get deleteExpenseTitle => 'Delete this expense?';

  @override
  String get deleteExpenseBody =>
      'It will be removed from the card and the reports.';

  @override
  String get scanReceipt => 'Scan receipt (AI)';

  @override
  String get scanReceiptHint =>
      'The AI reads the photo and suggests the details; you check them before saving. The photo isn\'t kept.';

  @override
  String get merchant => 'Merchant';

  @override
  String get category => 'Category';

  @override
  String get archivedCardExpense =>
      'This expense\'s card is archived: you can delete it, but not edit it.';

  @override
  String get expenseCurrency => 'Expense currency';

  @override
  String get amount => 'Amount';

  @override
  String recordedOnCardAs(String amount) {
    return 'Recorded on the card as $amount';
  }

  @override
  String get date => 'Date';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get saveExpense => 'Save expense';

  @override
  String get deleteExpense => 'Delete expense';

  @override
  String get readingReceipt => 'Reading receipt…';

  @override
  String get aiChip => 'AI';

  @override
  String get rateLoading => 'Looking up today\'s rate…';

  @override
  String get rateOnline =>
      'Today\'s online rate. You can adjust it to your bank\'s.';

  @override
  String get rateStale => 'Offline: last known rate. Check it.';

  @override
  String get rateUnavailable => 'Couldn\'t get the rate. Enter it.';

  @override
  String get rateIdle => 'Rate used for the conversion.';

  @override
  String get fieldRateRequired => 'Enter the rate (e.g. 61.40)';

  @override
  String get rateLabel => 'Rate (RD\$ per US\$ 1)';

  @override
  String get refreshRate => 'Get today\'s rate';

  @override
  String get allDates => 'All dates';

  @override
  String get merchantContains => 'Merchant contains';

  @override
  String get minAmount => 'Minimum amount';

  @override
  String get maxAmount => 'Maximum amount';

  @override
  String get apply => 'Apply';

  @override
  String get newCategory => 'New category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get noOwnCategories => 'You haven\'t created any categories yet.';

  @override
  String get includedCategories => 'Included';

  @override
  String get includedCategoriesHint =>
      'They come with the app and can\'t be changed.';

  @override
  String get categoriesLoadError => 'Couldn\'t load the categories';

  @override
  String get categoryNotFound => 'Category not found';

  @override
  String deleteNamedTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get categoryNoExpenses => 'It has no expenses.';

  @override
  String get categoryNameLabel => 'Name (e.g. Pets)';

  @override
  String get icon => 'Icon';

  @override
  String colorNumber(int n) {
    return 'Color $n';
  }

  @override
  String get createCategory => 'Create category';

  @override
  String get deleteCategory => 'Delete category';

  @override
  String categoryHasExpenses(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '\"$name\" has $count expenses',
      one: '\"$name\" has 1 expense',
    );
    return '$_temp0';
  }

  @override
  String get reassignHint =>
      'To delete it, choose which category they move to.';

  @override
  String get moveTo => 'Move to';

  @override
  String get moveAndDelete => 'Move and delete';
}
