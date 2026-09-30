import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_constants.dart';
import '../../models/maintenance_model.dart';
import '../../services/maintenance_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'create_maintenance_screen.dart';
import 'maintenance_detail_screen.dart';

class MaintenanceListScreen extends StatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  State<MaintenanceListScreen> createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends State<MaintenanceListScreen> {
  final _service = MaintenanceService();
  List<MaintenanceRequestModel> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _currentFilter = 'All';

  final List<Map<String, String>> _filters = [
    {'label': 'Tất cả', 'value': 'All'},
    {'label': 'Đang chờ', 'value': 'Pending'},
    {'label': 'Đang xử lý', 'value': 'Processing'},
    {'label': 'Hoàn thành', 'value': 'Completed'},
    {'label': 'Đã đóng', 'value': 'Closed'},
  ];

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
      final list = await _service.getMyRequests(status: _currentFilter);
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

  void _navigateToCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateMaintenanceScreen()),
    );
    if (created == true) {
      _fetchRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Báo Hỏng & Sửa Chữa'),
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
        onPressed: _navigateToCreate,
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Báo hỏng mới', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter Chips Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final isSelected = _currentFilter == f['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(f['label']!),
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppConstants.textPrimary,
                      ),
                      backgroundColor: const Color(0xFFF1F5F9),
                      selectedColor: AppConstants.primaryColor,
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _currentFilter = f['value']!;
                          });
                          _fetchRequests();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Content List
          Expanded(
            child: _isLoading
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
                            icon: Icons.build_circle_outlined,
                            title: 'Chưa có yêu cầu nào',
                            description: _currentFilter == 'All'
                                ? 'Căn hộ của bạn chưa có yêu cầu sửa chữa nào. Nhấn nút bên dưới để gửi yêu cầu trực tiếp tới Kỹ thuật viên (Staff).'
                                : 'Không tìm thấy yêu cầu nào phù hợp với bộ lọc "$_currentFilter".',
                            buttonText: _currentFilter == 'All' ? 'Tạo yêu cầu mới' : null,
                            onButtonPressed: _navigateToCreate,
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchRequests,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                              itemCount: _requests.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, idx) {
                                final req = _requests[idx];
                                return InkWell(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MaintenanceDetailScreen(requestId: req.id),
                                      ),
                                    );
                                    _fetchRequests();
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                      border: Border.all(color: AppConstants.borderColor, width: 0.8),
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
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppConstants.primaryLight,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'P.${req.apartmentNumber ?? req.apartmentId}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppConstants.primaryColor,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                StatusBadge(status: req.priority, fontSize: 11),
                                              ],
                                            ),
                                            StatusBadge(status: req.status, fontSize: 11),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          req.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppConstants.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          req.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13, color: AppConstants.textSecondary),
                                        ),
                                        const Divider(height: 20),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.person_outline, size: 16, color: AppConstants.textSecondary),
                                                const SizedBox(width: 4),
                                                Text(
                                                  req.assignedStaffName ?? 'Chờ tiếp nhận...',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: req.assignedStaffName != null
                                                        ? AppConstants.primaryDark
                                                        : AppConstants.textSecondary,
                                                    fontWeight: req.assignedStaffName != null ? FontWeight.w600 : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              dateFormat.format(req.createdAt),
                                              style: const TextStyle(fontSize: 12, color: AppConstants.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
