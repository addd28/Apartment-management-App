import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../models/utility_usage_model.dart';
import '../../services/utility_service.dart';
import '../../widgets/empty_state.dart';

class UtilityUsageScreen extends StatefulWidget {
  const UtilityUsageScreen({super.key});

  @override
  State<UtilityUsageScreen> createState() => _UtilityUsageScreenState();
}

class _UtilityUsageScreenState extends State<UtilityUsageScreen> {
  final _utilityService = UtilityService();
  List<UtilityUsageModel> _usages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsages();
  }

  Future<void> _loadUsages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _utilityService.getMyUtilityUsages();
      setState(() {
        _usages = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Chỉ số Điện & Nước', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppConstants.primaryColor),
            onPressed: _loadUsages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppConstants.dangerColor, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppConstants.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadUsages,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : _usages.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadUsages,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 80),
                          EmptyState(
                            icon: Icons.speed_rounded,
                            title: 'Chưa có dữ liệu chỉ số',
                            description: 'Ban Quản Lý chưa ghi nhận chỉ số điện hoặc nước định kỳ cho căn hộ của bạn.',
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsages,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _usages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, idx) {
                          final item = _usages[idx];
                          final isElec = item.isElectricity;
                          final iconColor = isElec ? const Color(0xFFF59E0B) : const Color(0xFF0284C7);
                          final bgColor = isElec ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2FE);

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppConstants.borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isElec ? Icons.bolt_rounded : Icons.water_drop_rounded,
                                        color: iconColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.utilityName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppConstants.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Kỳ: Tháng ${item.month}/${item.year}${item.apartmentNumber.isNotEmpty ? ' • Căn hộ ${item.apartmentNumber}' : ''}',
                                            style: const TextStyle(fontSize: 12, color: AppConstants.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppConstants.primaryLight,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Đã chốt',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppConstants.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppConstants.backgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildMetric('Chỉ số đầu', item.oldIndicator.toStringAsFixed(1)),
                                      Container(height: 28, width: 1, color: AppConstants.borderColor),
                                      _buildMetric('Chỉ số cuối', item.newIndicator.toStringAsFixed(1)),
                                      Container(height: 28, width: 1, color: AppConstants.borderColor),
                                      _buildMetric(
                                        'Tiêu thụ',
                                        '${item.usageAmount.toStringAsFixed(1)} ${item.unit}',
                                        isHighlight: true,
                                        color: iconColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildMetric(String label, String value, {bool isHighlight = false, Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppConstants.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 14 : 13,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? (color ?? AppConstants.primaryColor) : AppConstants.textPrimary,
          ),
        ),
      ],
    );
  }
}
