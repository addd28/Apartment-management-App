import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_constants.dart';
import '../../models/maintenance_model.dart';
import '../../services/maintenance_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/status_badge.dart';

class MaintenanceDetailScreen extends StatefulWidget {
  final int requestId;

  const MaintenanceDetailScreen({super.key, required this.requestId});

  @override
  State<MaintenanceDetailScreen> createState() => _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends State<MaintenanceDetailScreen> {
  final _service = MaintenanceService();
  MaintenanceRequestModel? _request;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final req = await _service.getById(widget.requestId);
      setState(() {
        _request = req;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy yêu cầu?'),
        content: const Text('Bạn có chắc chắn muốn hủy yêu cầu bảo trì này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy yêu cầu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.cancelRequest(widget.requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy yêu cầu bảo trì.')),
      );
      _loadDetail();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('HH:mm - dd/MM/yyyy').format(dt);
  }

  String _resolveImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final minio = AppConstants.defaultMinioUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$minio$cleanPath';
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(_request != null ? 'Sự cố #${_request!.id}' : 'Chi Tiết Bảo Trì'),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: AppConstants.dangerColor)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadDetail, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  StatusBadge(status: _request!.status),
                                  StatusBadge(status: _request!.priority),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _request!.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.apartment_rounded, size: 16, color: AppConstants.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Căn hộ: ${_request!.apartmentNumber ?? 'P.${_request!.apartmentId}'}',
                                    style: const TextStyle(fontSize: 13, color: AppConstants.textSecondary),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppConstants.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDateTime(_request!.createdAt),
                                    style: const TextStyle(fontSize: 13, color: AppConstants.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Timeline Section
                        const Text(
                          'Tiến độ xử lý (Direct Workflow)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildTimelineStep(
                                title: 'Gửi yêu cầu bảo trì',
                                subtitle: 'Resident đã gửi thành công lúc ${_formatDateTime(_request!.createdAt)}',
                                isDone: true,
                                isFirst: true,
                              ),
                              _buildTimelineStep(
                                title: 'Kỹ thuật viên tiếp nhận',
                                subtitle: _request!.assignedStaffName != null
                                    ? 'Nhân viên: ${_request!.assignedStaffName} (${_request!.assignedStaffPhone ?? 'Có mặt sớm'})'
                                    : 'Đang trong danh sách chờ Kỹ thuật viên (Staff) tiếp nhận...',
                                isDone: _request!.assignedStaffId != null,
                              ),
                              _buildTimelineStep(
                                title: 'Tiến hành sửa chữa',
                                subtitle: _request!.isProcessing
                                    ? 'Kỹ thuật viên đang kiểm tra & xử lý tại căn hộ'
                                    : (_request!.isCompleted || _request!.isClosed ? 'Đã hoàn tất xử lý' : 'Chưa bắt đầu'),
                                isDone: _request!.isProcessing || _request!.isCompleted || _request!.isClosed,
                              ),
                              _buildTimelineStep(
                                title: 'Nghiệm thu hoàn tất',
                                subtitle: _request!.resolvedAt != null
                                    ? 'Hoàn thành lúc ${_formatDateTime(_request!.resolvedAt)}'
                                    : 'Chờ nghiệm thu',
                                isDone: _request!.isCompleted || _request!.isClosed,
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Description Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mô tả chi tiết',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _request!.description,
                                style: const TextStyle(fontSize: 14, color: AppConstants.textSecondary, height: 1.5),
                              ),
                              if (_request!.resolutionNotes != null && _request!.resolutionNotes!.isNotEmpty) ...[
                                const Divider(height: 24),
                                const Text(
                                  'Ghi chú kết quả nghiệm thu (Staff):',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.secondaryColor),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _request!.resolutionNotes!,
                                  style: const TextStyle(fontSize: 14, color: AppConstants.textPrimary, height: 1.4),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Attachments Section
                        if (_request!.attachments.isNotEmpty) ...[
                          const Text(
                            'Hình ảnh đính kèm',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _request!.attachments.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (ctx, idx) {
                                final att = _request!.attachments[idx];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        _resolveImageUrl(att.filePath),
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 90,
                                          height: 90,
                                          color: const Color(0xFFE2E8F0),
                                          child: const Icon(Icons.broken_image, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      att.isResult ? 'Nghiệm thu' : 'Hiện trường',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: att.isResult ? AppConstants.secondaryColor : AppConstants.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Cancel Request Button (Only if Pending)
                        if (_request!.isPending) ...[
                          CustomButton(
                            text: 'Hủy Yêu Cầu Này',
                            color: AppConstants.dangerColor,
                            isOutlined: true,
                            onPressed: _handleCancel,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isDone,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppConstants.secondaryColor : const Color(0xFFE2E8F0),
              ),
              child: Icon(
                isDone ? Icons.check : Icons.circle,
                size: 14,
                color: isDone ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isDone ? AppConstants.secondaryColor : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDone ? AppConstants.textPrimary : AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDone ? AppConstants.textSecondary : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
