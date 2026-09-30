import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_constants.dart';
import '../../core/storage_service.dart';
import '../../models/apartment_model.dart';
import '../../models/invoice_model.dart';
import '../../models/maintenance_model.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../services/apartment_service.dart';
import '../../services/invoice_service.dart';
import '../../services/maintenance_service.dart';
import '../../services/notification_service.dart';
import '../invoices/invoice_detail_screen.dart';
import '../maintenance/create_maintenance_screen.dart';
import '../maintenance/maintenance_detail_screen.dart';
import '../move_requests/move_request_list_screen.dart';
import '../vehicles/vehicle_list_screen.dart';

class HomeTab extends StatefulWidget {
  final Function(int) onSwitchTab;

  const HomeTab({super.key, required this.onSwitchTab});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _apartmentService = ApartmentService();
  final _maintenanceService = MaintenanceService();
  final _invoiceService = InvoiceService();
  final _notificationService = NotificationService();

  UserModel? _user;
  List<ApartmentModel> _myApartments = [];
  List<MaintenanceRequestModel> _activeMaintenances = [];
  List<InvoiceModel> _unpaidInvoices = [];
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      _user = StorageService.getUser();
      final results = await Future.wait([
        _apartmentService.getMyApartments().catchError((_) => <ApartmentModel>[]),
        _maintenanceService.getMyRequests().catchError((_) => <MaintenanceRequestModel>[]),
        _invoiceService.getMyInvoices(status: 'Pending').catchError((_) => <InvoiceModel>[]),
        _notificationService.getNotifications().catchError((_) => <NotificationModel>[]),
      ]);

      setState(() {
        _myApartments = results[0] as List<ApartmentModel>;
        final allMaintenances = results[1] as List<MaintenanceRequestModel>;
        _activeMaintenances = allMaintenances
            .where((m) => m.isPending || m.isProcessing)
            .toList();
        _unpaidInvoices = results[2] as List<InvoiceModel>;
        _notifications = results[3] as List<NotificationModel>;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _formatVND(double amount) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return fmt.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final primaryApt = _myApartments.isNotEmpty ? _myApartments.first : null;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Greeting
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Xin chào, Cư dân',
                          style: TextStyle(fontSize: 13, color: AppConstants.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _user?.fullName ?? 'Cư dân Chung Cư',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppConstants.primaryColor),
                      onPressed: _loadDashboardData,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Main Apartment Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E5BB0), Color(0xFF0F3670)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryColor.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.home_rounded, size: 14, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  primaryApt?.buildingName ?? 'Tòa Nhà Chung Cư',
                                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Đang sinh sống',
                              style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        primaryApt != null ? 'Căn hộ ${primaryApt.apartmentNumber}' : 'Chưa gán căn hộ',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildAptBadge(Icons.layers_outlined, 'Tầng ${primaryApt?.floorNumber ?? primaryApt?.floorId ?? 1}'),
                          const SizedBox(width: 12),
                          _buildAptBadge(Icons.square_foot_rounded, '${primaryApt?.area ?? 70} m²'),
                          const SizedBox(width: 12),
                          _buildAptBadge(Icons.people_outline_rounded, '${primaryApt?.maxCapacity ?? 4} người'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions (4 Core Resident Features)
                const Text(
                  'Tiện ích cư dân',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildActionCard(
                      icon: Icons.build_circle_rounded,
                      title: 'Báo Hỏng',
                      subtitle: 'Gửi Staff ngay',
                      color: const Color(0xFFEF4444),
                      onTap: () async {
                        final created = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateMaintenanceScreen()),
                        );
                        if (created == true) _loadDashboardData();
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildActionCard(
                      icon: Icons.receipt_long_rounded,
                      title: 'Hóa Đơn',
                      subtitle: 'Xem & đóng tiền',
                      color: const Color(0xFF2563EB),
                      onTap: () => widget.onSwitchTab(2), // Invoices tab
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildActionCard(
                      icon: Icons.two_wheeler_rounded,
                      title: 'Gửi Xe',
                      subtitle: 'Thẻ & biển số',
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VehicleListScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildActionCard(
                      icon: Icons.local_shipping_rounded,
                      title: 'Chuyển Đồ',
                      subtitle: 'Đăng ký ra/vào',
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MoveRequestListScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Unpaid Invoices Alert Banner (if any)
                if (_unpaidInvoices.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bạn có hóa đơn chưa thanh toán',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_unpaidInvoices.first.title}: ${_formatVND(_unpaidInvoices.first.remainingAmount)}',
                                style: const TextStyle(fontSize: 13, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InvoiceDetailScreen(invoiceId: _unpaidInvoices.first.id),
                              ),
                            );
                          },
                          child: const Text('Nộp ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Active Maintenance Request Tracker
                if (_activeMaintenances.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sự cố đang xử lý',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
                      ),
                      TextButton(
                        onPressed: () => widget.onSwitchTab(1), // Maintenance tab
                        child: const Text('Xem tất cả'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                            Text(
                              _activeMaintenances.first.title,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _activeMaintenances.first.isProcessing
                                    ? const Color(0xFFDBEAFE)
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _activeMaintenances.first.isProcessing ? 'Đang sửa chữa' : 'Chờ Kỹ thuật viên',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _activeMaintenances.first.isProcessing
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _activeMaintenances.first.assignedStaffName != null
                              ? 'Kỹ thuật viên phụ trách: ${_activeMaintenances.first.assignedStaffName} (${_activeMaintenances.first.assignedStaffPhone ?? 'Trực tòa'})'
                              : 'Đã gửi trực tiếp tới đội kỹ thuật (Staff). Đang chờ nhận đơn.',
                          style: const TextStyle(fontSize: 13, color: AppConstants.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                            label: const Text('Xem chi tiết tiến độ'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MaintenanceDetailScreen(requestId: _activeMaintenances.first.id),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Building Notifications
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bảng tin chung cư',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
                    ),
                    const Icon(Icons.campaign_outlined, color: AppConstants.primaryColor),
                  ],
                ),
                const SizedBox(height: 12),
                if (_notifications.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppConstants.borderColor),
                    ),
                    child: const Center(
                      child: Text('Chưa có thông báo mới từ Ban Quản Lý.', style: TextStyle(color: AppConstants.textSecondary)),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _notifications.take(4).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final n = _notifications[idx];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppConstants.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  dateFormat.format(n.createdAt),
                                  style: const TextStyle(fontSize: 11, color: AppConstants.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              n.content,
                              style: const TextStyle(fontSize: 13, color: AppConstants.textSecondary, height: 1.4),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAptBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.white)),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppConstants.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: AppConstants.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

