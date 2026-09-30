import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_constants.dart';
import '../../models/move_request_model.dart';
import '../../services/move_request_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'create_move_request_screen.dart';

class MoveRequestListScreen extends StatefulWidget {
  const MoveRequestListScreen({super.key});

  @override
  State<MoveRequestListScreen> createState() => _MoveRequestListScreenState();
}

class _MoveRequestListScreenState extends State<MoveRequestListScreen> {
  final _service = MoveRequestService();
  List<MoveRequestModel> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getMyMoveRequests();
      setState(() {
        _requests = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCancel(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn đăng ký?'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn đăng ký chuyển đồ này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy đơn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.cancelMoveRequest(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy đơn đăng ký chuyển đồ.')),
      );
      _fetchRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Đăng Ký Chuyển Đồ'),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchRequests,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final registered = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateMoveRequestScreen()),
          );
          if (registered == true) _fetchRequests();
        },
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Đăng ký mới', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      ElevatedButton(onPressed: _fetchRequests, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : _requests.isEmpty
                  ? EmptyState(
                      icon: Icons.local_shipping_outlined,
                      title: 'Chưa có đơn chuyển đồ',
                      description: 'Bạn chưa có lịch chuyển đồ vào hoặc chuyển đồ ra khỏi căn hộ nào.',
                      buttonText: 'Tạo đơn chuyển đồ',
                      onButtonPressed: () async {
                        final registered = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateMoveRequestScreen()),
                        );
                        if (registered == true) _fetchRequests();
                      },
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchRequests,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: _requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, idx) {
                          final req = _requests[idx];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppConstants.borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppConstants.primaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${req.typeLabel} • P.${req.apartmentNumber}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppConstants.primaryColor,
                                        ),
                                      ),
                                    ),
                                    StatusBadge(status: req.status, fontSize: 11),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule_rounded, size: 16, color: AppConstants.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${dateFormat.format(req.scheduledDate)} (${req.startTime} - ${req.endTime})',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  req.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, color: AppConstants.textSecondary),
                                ),
                                if (req.vehicleLicensePlate != null && req.vehicleLicensePlate!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Xe: ${req.vehicleLicensePlate} ${req.driverName != null ? '• TX: ${req.driverName}' : ''}',
                                    style: const TextStyle(fontSize: 12, color: AppConstants.textSecondary),
                                  ),
                                ],
                                if (req.isPending) ...[
                                  const Divider(height: 20),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      icon: const Icon(Icons.cancel_outlined, size: 16, color: AppConstants.dangerColor),
                                      label: const Text('Hủy đơn', style: TextStyle(color: AppConstants.dangerColor)),
                                      onPressed: () => _handleCancel(req.id),
                                    ),
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
}
