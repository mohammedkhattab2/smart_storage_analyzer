import 'package:equatable/equatable.dart';

class Settings extends Equatable {
  final bool notificationsEnable;
  final bool darkMoodEnable;
  final bool isPremiumUser;

  const Settings({
    required this.notificationsEnable,
    required this.darkMoodEnable,
    required this.isPremiumUser, required bool notificationsEnabled, required bool darkModeEnabled,
  });
  Settings copyWith({
    bool? notificationsEnable,
    bool? darkMoodEnable,
    bool? isPremiumUser,
  }) {
    return Settings(
      notificationsEnable: notificationsEnable ?? this.notificationsEnable,
      darkMoodEnable: darkMoodEnable ?? this.darkMoodEnable,
      isPremiumUser: isPremiumUser ?? this.isPremiumUser, 
      
    );
  }

  @override
  List<Object> get props => [
    notificationsEnable,
    darkMoodEnable,
    isPremiumUser,
  ];
}
