import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/services/permission_service.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Permission Manager to handle permission state and persistence
class PermissionManager {
  static final PermissionManager _instance = PermissionManager._internal();
  factory PermissionManager() => _instance;
  PermissionManager._internal();

  final PermissionService _permissionService = PermissionService();
  SharedPreferences? _prefs;
  
  // Keys for storing permission state
  static const String _keyPermissionGranted = 'permission_granted';
  static const String _keyPermissionLastChecked = 'permission_last_checked';
  static const String _keyPermissionDeniedCount = 'permission_denied_count';
  
  // Cache permission state
  bool? _cachedPermissionState;
  DateTime? _lastPermissionCheck;
  
  /// Initialize permission manager
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _loadCachedState();
    } catch (e) {
      Logger.error('Failed to initialize PermissionManager', e);
    }
  }
  
  /// Load cached permission state
  void _loadCachedState() {
    if (_prefs != null) {
      _cachedPermissionState = _prefs!.getBool(_keyPermissionGranted);
      final lastCheckedMillis = _prefs!.getInt(_keyPermissionLastChecked);
      if (lastCheckedMillis != null) {
        _lastPermissionCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckedMillis);
      }
    }
  }
  
  /// Check if permissions are granted with caching
  Future<bool> hasPermission({bool forceCheck = false}) async {
    if (!Platform.isAndroid) return true;
    
    // Use cached state if available and recent (within last 5 minutes)
    if (!forceCheck && 
        _cachedPermissionState != null && 
        _lastPermissionCheck != null &&
        DateTime.now().difference(_lastPermissionCheck!).inMinutes < 5) {
      return _cachedPermissionState!;
    }
    
    // Check actual permission state
    final hasPermission = await _permissionService.hasStoragePermission();
    
    // Update cache
    _cachedPermissionState = hasPermission;
    _lastPermissionCheck = DateTime.now();
    
    // Persist state
    await _savePermissionState(hasPermission);
    
    return hasPermission;
  }
  
  /// Request permission with context
  Future<bool> requestPermission({BuildContext? context}) async {
    if (!Platform.isAndroid) return true;
    
    try {
      final granted = await _permissionService.requestStoragePermission(
        context: context,
      );
      
      // Update cache and persist
      _cachedPermissionState = granted;
      _lastPermissionCheck = DateTime.now();
      await _savePermissionState(granted);
      
      if (!granted) {
        // Increment denied count
        final deniedCount = _prefs?.getInt(_keyPermissionDeniedCount) ?? 0;
        await _prefs?.setInt(_keyPermissionDeniedCount, deniedCount + 1);
      }
      
      return granted;
    } catch (e) {
      Logger.error('Failed to request permission', e);
      return false;
    }
  }
  
  /// Save permission state to persistent storage
  Future<void> _savePermissionState(bool granted) async {
    try {
      await _prefs?.setBool(_keyPermissionGranted, granted);
      await _prefs?.setInt(
        _keyPermissionLastChecked, 
        DateTime.now().millisecondsSinceEpoch
      );
    } catch (e) {
      Logger.error('Failed to save permission state', e);
    }
  }
  
  /// Get number of times permission was denied
  int getPermissionDeniedCount() {
    return _prefs?.getInt(_keyPermissionDeniedCount) ?? 0;
  }
  
  /// Check if we should show permission rationale
  bool shouldShowPermissionRationale() {
    final deniedCount = getPermissionDeniedCount();
    // Show rationale after 2 denials
    return deniedCount >= 2;
  }
  
  /// Clear cached permission state
  Future<void> clearCache() async {
    _cachedPermissionState = null;
    _lastPermissionCheck = null;
    await _prefs?.remove(_keyPermissionGranted);
    await _prefs?.remove(_keyPermissionLastChecked);
  }
  
  /// Reset all permission data (useful for testing)
  Future<void> reset() async {
    await clearCache();
    await _prefs?.remove(_keyPermissionDeniedCount);
  }
}

/// Exception for permission-related errors
class StoragePermissionException implements Exception {
  final String message;
  final bool isPermanentlyDenied;
  
  StoragePermissionException({
    required this.message,
    this.isPermanentlyDenied = false,
  });
  
  @override
  String toString() => 'StoragePermissionException: $message';
}