import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current time. Tests override it to pin "today" for greetings and the
/// billing cycle.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
