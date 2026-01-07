import 'package:equatable/equatable.dart';

class Settings extends Equatable {
  final bool notificationsEnabled;
  final bool darkModeEnabled;

  const Settings({
    required this.notificationsEnabled,
    required this.darkModeEnabled,
  });

  Settings copyWith({bool? notificationsEnabled, bool? darkModeEnabled}) {
    return Settings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
    );
  }

  @override
  List<Object> get props => [notificationsEnabled, darkModeEnabled];
}
