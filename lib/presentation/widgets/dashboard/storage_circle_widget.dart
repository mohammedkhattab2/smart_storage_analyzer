import 'dart:io';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/theme/app_color_schemes.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_info.dart';
import 'package:path_provider/path_provider.dart';

class StorageCircleWidget extends StatefulWidget {
  final StorageInfo storageInfo;
  const StorageCircleWidget({super.key, required this.storageInfo});

  @override
  State<StorageCircleWidget> createState() => _StorageCircleWidgetState();
}

class _StorageCircleWidgetState extends State<StorageCircleWidget> {
  double _totalBytes = 0;
  double _availableBytes = 0;
  double _usedBytes = 0;
  bool _isLoading = true;
  bool _usingFallback = false;

  @override
  void initState() {
    super.initState();
    _fetchRealStorageInfo();
  }

  /// Fetches real device storage information
  Future<void> _fetchRealStorageInfo() async {
    try {
      if (Platform.isAndroid) {
        // Get the data directory path (internal storage)
        final Directory? appDir = await getExternalStorageDirectory();
        if (appDir != null) {
          // Get the root path by going up to the storage root
          String path = appDir.path;
          // Extract the root storage path (e.g., /storage/emulated/0)
          final rootPath = path.split('Android')[0];
          
          // Use statfs to get storage info
          final ProcessResult result = await Process.run(
            'df',
            ['-B1', rootPath], // -B1 returns values in bytes
          );
          
          if (result.exitCode == 0) {
            final output = result.stdout.toString();
            final lines = output.split('\n');
            
            // Parse the df output
            for (final line in lines) {
              if (line.contains(rootPath) || line.contains('/data') || line.contains('/storage')) {
                final parts = line.split(RegExp(r'\s+'));
                if (parts.length >= 4) {
                  // df output format: Filesystem, Size, Used, Available, Use%, Mounted
                  final sizeStr = parts[1];
                  final usedStr = parts[2];
                  final availStr = parts[3];
                  
                  // Parse values (they're already in bytes with -B1 flag)
                  _totalBytes = _parseStorageValue(sizeStr);
                  _usedBytes = _parseStorageValue(usedStr);
                  _availableBytes = _parseStorageValue(availStr);
                  
                  // Validate the values
                  if (_totalBytes > 0 && (_usedBytes + _availableBytes).abs() - _totalBytes < _totalBytes * 0.1) {
                    setState(() {
                      _isLoading = false;
                      _usingFallback = false;
                    });
                    return;
                  }
                }
              }
            }
          }
        }
      }
      
      // If we couldn't get real values, use fallback method
      _useFallbackValues();
    } catch (e) {
      debugPrint('Error fetching storage info: $e');
      _useFallbackValues();
    }
  }

  /// Parses storage value from df output
  double _parseStorageValue(String value) {
    try {
      // Remove any non-numeric characters except decimal point
      final cleanValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.parse(cleanValue);
    } catch (e) {
      return 0;
    }
  }

  /// Use fallback values from the passed storageInfo
  void _useFallbackValues() {
    setState(() {
      _totalBytes = widget.storageInfo.totalSpace;
      _usedBytes = widget.storageInfo.usedSpace;
      
      // Ensure consistency: calculate available from total - used
      _availableBytes = _totalBytes - _usedBytes;
      
      // Ensure values are positive
      if (_availableBytes < 0) {
        _availableBytes = 0;
        _usedBytes = _totalBytes;
      }
      
      _isLoading = false;
      _usingFallback = true;
    });
  }

  /// Converts bytes to gigabytes with exactly 1 decimal place maximum
  double _bytesToGB(double bytes) {
    if (bytes <= 0) return 0;
    
    // Convert bytes to GB
    final gb = bytes / (1024 * 1024 * 1024);
    
    // Round to 1 decimal place maximum
    return (gb * 10).roundToDouble() / 10;
  }

  /// Formats GB value to display cleanly (no unnecessary decimals)
  String _formatGB(double gb) {
    if (gb <= 0) return "0";
    
    // Check if it's effectively a whole number
    if ((gb % 1) == 0) {
      // Show as integer: 5.0 → "5"
      return gb.toInt().toString();
    } else {
      // Show with 1 decimal: 5.5 → "5.5"
      return gb.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_isLoading) {
      return Container(
        height: 280,
        margin: const EdgeInsets.symmetric(horizontal: AppSize.paddingSmall),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSize.radiusXLarge),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
      );
    }

    // Convert storage values to GB
    final usedGB = _bytesToGB(_usedBytes);
    final totalGB = _bytesToGB(_totalBytes);
    final availableGB = _bytesToGB(_availableBytes);
    
    // Calculate percentage based on actual values
    // Ensure percentage is between 0 and 1
    final percentage = totalGB > 0 ? (usedGB / totalGB).clamp(0.0, 1.0) : 0.0;
    final percentageInt = (percentage * 100).round();
    final isHighUsage = percentage > 0.8;
    
    // Debug validation
    debugPrint('Storage Info: Used ${_formatGB(usedGB)}GB + Available ${_formatGB(availableGB)}GB = Total ${_formatGB(totalGB)}GB');
    debugPrint('Percentage: $percentageInt% | Using fallback: $_usingFallback');
    
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: AppSize.paddingSmall),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSize.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: .1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background decoration
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: .05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularPercentIndicator(
                radius: 100,
                lineWidth: 14,
                animation: true,
                animationDuration: 1500,
                percent: percentage,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Percentage display
                    Text(
                      '$percentageInt%',
                      style: TextStyle(
                        fontSize: AppSize.fontHuge + 8,
                        fontWeight: FontWeight.w700,
                        color: isHighUsage ? colorScheme.warning : colorScheme.onSurface,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // GB display
                    Text(
                      '${_formatGB(usedGB)} GB',
                      style: TextStyle(
                        fontSize: AppSize.fontLarge,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: isHighUsage ? colorScheme.warning : colorScheme.primary,
                backgroundColor: colorScheme.surface.withValues(alpha: .5),
              ),
              const SizedBox(height: AppSize.paddingLarge),
              // Storage details container
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSize.paddingLarge,
                  vertical: AppSize.paddingSmall + 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(AppSize.radiusLarge),
                ),
                child: Column(
                  children: [
                    // Main storage display
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Used ',
                          style: TextStyle(
                            fontSize: AppSize.fontMedium,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          '${_formatGB(usedGB)} GB',
                          style: TextStyle(
                            fontSize: AppSize.fontLarge,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          ' of ',
                          style: TextStyle(
                            fontSize: AppSize.fontMedium,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          '${_formatGB(totalGB)} GB',
                          style: TextStyle(
                            fontSize: AppSize.fontLarge,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
