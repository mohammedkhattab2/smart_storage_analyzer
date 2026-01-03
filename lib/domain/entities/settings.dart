import 'package:equatable/equatable.dart';

class Settings extends Equatable {
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final bool isPremiumUser;

  const Settings({
    required this.notificationsEnabled,
    required this.darkModeEnabled,
    required this.isPremiumUser,
  });

  Settings copyWith({
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    bool? isPremiumUser,
  }) {
    return Settings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      isPremiumUser: isPremiumUser ?? this.isPremiumUser,
    );
  }

  @override
  List<Object> get props => [
    notificationsEnabled,
    darkModeEnabled,
    isPremiumUser,
  ];
}
