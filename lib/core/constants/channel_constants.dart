/// Central configuration for MethodChannel names
class ChannelConstants {
  // Private constructor to prevent instantiation
  ChannelConstants._();

  /// Main method channel for native platform communication
  static const String mainChannel = 'com.smarttools.storageanalyzer/native';

  /// Storage-specific channel (same as main for now, kept for clarity)
  static const String storageChannel = mainChannel;
}
