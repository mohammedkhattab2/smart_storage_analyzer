import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/domain/entities/statistics.dart';
import 'package:smart_storage_analyzer/data/models/statistics_model.dart';
import 'package:smart_storage_analyzer/presentation/screens/statistics/clean_line_chart.dart';

class CleanLineChartExample extends StatefulWidget {
  const CleanLineChartExample({super.key});

  @override
  State<CleanLineChartExample> createState() => _CleanLineChartExampleState();
}

class _CleanLineChartExampleState extends State<CleanLineChartExample> {
  String _selectedPeriod = 'This Week';
  
  // Generate sample data for different periods
  List<StorageDataPoint> _generateSampleData() {
    final now = DateTime.now();
    final List<StorageDataPoint> data = [];
    final totalSpace = 256.0 * 1024 * 1024 * 1024; // 256 GB in bytes
    
    if (_selectedPeriod == 'This Week') {
      // Generate 7 days of data (Mon to Sun)
      final monday = now.subtract(Duration(days: now.weekday - 1));
      for (int i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));
        final usedGB = 45 + i * 2 + (i.isEven ? 3 : -1);
        final usedSpace = usedGB * 1024.0 * 1024 * 1024; // GB to bytes
        data.add(StorageDataPointModel(
          date: date,
          usedSpace: usedSpace,
          freeSpace: totalSpace - usedSpace,
        ));
      }
    } else if (_selectedPeriod == 'This Month') {
      // Generate 30 days of data
      final startOfMonth = DateTime(now.year, now.month, 1);
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      for (int i = 0; i < daysInMonth; i++) {
        final date = startOfMonth.add(Duration(days: i));
        final usedGB = 50 + i * 0.8 + (i % 3 == 0 ? 5 : -2);
        final usedSpace = usedGB * 1024.0 * 1024 * 1024;
        data.add(StorageDataPointModel(
          date: date,
          usedSpace: usedSpace,
          freeSpace: totalSpace - usedSpace,
        ));
      }
    } else if (_selectedPeriod == 'This Year') {
      // Generate 12 months of data
      for (int i = 0; i < 12; i++) {
        final date = DateTime(now.year, i + 1, 15); // Middle of each month
        final usedGB = 60 + i * 3 + (i % 2 == 0 ? 10 : -5);
        final usedSpace = usedGB * 1024.0 * 1024 * 1024;
        data.add(StorageDataPointModel(
          date: date,
          usedSpace: usedSpace,
          freeSpace: totalSpace - usedSpace,
        ));
      }
    }
    
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Clean Line Chart Example'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha:  0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Period',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildPeriodChip('This Week'),
                      const SizedBox(width: 8),
                      _buildPeriodChip('This Month'),
                      const SizedBox(width: 8),
                      _buildPeriodChip('This Year'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Chart Title
            Text(
              'Storage Usage Trend',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getPeriodDescription(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            
            // Chart
            CleanLineChart(
              dataPoints: _generateSampleData(),
              period: _selectedPeriod,
            ),
            
            const SizedBox(height: 24),
            
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha:  0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha:  0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chart Features',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem('✓ Touch tooltips showing exact GB values'),
                  _buildFeatureItem('✓ Automatic Y-axis scaling based on data range'),
                  _buildFeatureItem('✓ Smooth curved lines with gradient fill'),
                  _buildFeatureItem('✓ Smart label distribution to avoid overlap'),
                  _buildFeatureItem('✓ Responsive design that adapts to screen size'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String period) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedPeriod == period;
    
    return ChoiceChip(
      label: Text(period),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPeriod = period;
          });
        }
      },
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha:  0.3),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
  }

  String _getPeriodDescription() {
    switch (_selectedPeriod) {
      case 'This Week':
        return 'Daily storage usage from Monday to Sunday';
      case 'This Month':
        return 'Weekly breakdown showing 4 weeks of storage usage';
      case 'This Year':
        return 'Monthly storage usage from January to December';
      default:
        return 'Storage usage over time';
    }
  }
}