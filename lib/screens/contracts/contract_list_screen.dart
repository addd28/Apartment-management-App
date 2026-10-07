import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_constants.dart';
import '../../models/apartment_model.dart';
import '../../services/apartment_service.dart';
import '../../widgets/empty_state.dart';

class ContractListScreen extends StatefulWidget {
  const ContractListScreen({super.key});

  @override
  State<ContractListScreen> createState() => _ContractListScreenState();
}

class _ContractListScreenState extends State<ContractListScreen> {
  final _apartmentService = ApartmentService();
  List<ContractModel> _contracts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _apartmentService.getMyContracts();
      setState(() {
        _contracts = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatVND(double amount) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return fmt.format(amount);
  }

  void _showDocumentDialog(String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.description_rounded, color: AppConstants.primaryColor),
            SizedBox(width: 8),
            Text('Tài liệu hợp đồng'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tệp hợp đồng lưu trữ trực tuyến của bạn:',
              style: TextStyle(fontSize: 13, color: AppConstants.textSecondary),
            ),
            const SizedBox(height: 8),
            SelectableText(
              url,
              style: const TextStyle(fontSize: 12, color: AppConstants.primaryColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Hợp Đồng Căn Hộ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppConstants.primaryColor),
            onPressed: _loadContracts,
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
                          onPressed: _loadContracts,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : _contracts.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadContracts,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 80),
                          EmptyState(
                            icon: Icons.description_outlined,
                            title: 'Chưa có hợp đồng nào',
                            description: 'Hệ thống chưa tìm thấy hồ sơ hợp đồng thuê hoặc sở hữu liên kết với tài khoản của bạn.',
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadContracts,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _contracts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (ctx, idx) {
                          final c = _contracts[idx];
                          final isActive = c.isActive;

                          return Container(
                            padding: const EdgeInsets.all(18),
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppConstants.primaryLight,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.assignment_rounded,
                                            color: AppConstants.primaryColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'HĐ: ${c.contractNumber}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppConstants.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isActive ? const Color(0xFFD1FAE5) : const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        c.status,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isActive ? AppConstants.secondaryColor : AppConstants.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppConstants.backgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildInfoRow('Căn hộ áp dụng', 'Phòng ${c.apartmentNumber ?? c.apartmentId}'),
                                      const SizedBox(height: 8),
                                      _buildInfoRow('Tiền thuê định kỳ', _formatVND(c.monthlyRent), isHighlight: true),
                                      const SizedBox(height: 8),
                                      _buildInfoRow('Tiền cọc ký quỹ', _formatVND(c.depositAmount)),
                                      const SizedBox(height: 8),
                                      _buildInfoRow('Thời hạn hợp đồng', '${dateFormat.format(c.startDate)} - ${dateFormat.format(c.endDate)}'),
                                      if (c.residentName != null && c.residentName!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        _buildInfoRow('Đại diện thuê', '${c.residentName}${c.residentPhone != null ? ' (${c.residentPhone})' : ''}'),
                                      ],
                                    ],
                                  ),
                                ),
                                if (c.documentUrl != null && c.documentUrl!.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 44),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                                    label: const Text('Xem tệp hợp đồng đính kèm'),
                                    onPressed: () => _showDocumentDialog(c.documentUrl!),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppConstants.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? AppConstants.primaryColor : AppConstants.textPrimary,
          ),
        ),
      ],
    );
  }
}
