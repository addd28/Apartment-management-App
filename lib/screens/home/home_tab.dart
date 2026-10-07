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
import '../contracts/contract_list_screen.dart';
import '../household/household_members_screen.dart';
import '../invoices/invoice_detail_screen.dart';
import '../maintenance/create_maintenance_screen.dart';
import '../maintenance/maintenance_detail_screen.dart';
import '../move_requests/move_request_list_screen.dart';
import '../notifications/notification_list_screen.dart';
import '../utilities/utility_usage_screen.dart';
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
        _invoiceService.getMyInvoices(status: 'Unpaid').catchError((_) => <InvoiceModel>[]),
        _notificationService.getNotifications().catchError((_) => <NotificationModel>[]),
      ]);

      setState(() {
        _myApartments = results[0] as List<ApartmentModel>;
        final allMaintenances = results[1] as List<MaintenanceRequestModel>;
        _activeMaintenances = allMaintenances
            .where((m) => m.isPending || m.isProcessing)
            .toList();
        _unpaidInvoices = (results[2] as List<InvoiceModel>)
            .where((inv) => inv.isUnpaid || (!inv.isPaid && !inv.isCancelled))
            .toList();
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

  void _showAnnouncementDialog(NotificationModel item) {
    if (!item.isRead) {
      _notificationService.markAsRead(item.id).catchError((_) => false);
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == item.id);
        if (idx != -1) {
          _notifications[idx] = NotificationModel(
            id: item.id,
            userId: item.userId,
            title: item.title,
            body: item.body,
            type: item.type,
            referenceId: item.referenceId,
            isRead: true,
            isGlobal: item.isGlobal,
            apartmentId: item.apartmentId,
            apartmentNumber: item.apartmentNumber,
            createdAt: item.createdAt,
          );
        }
      });
    }

    final fullDateFormat = DateFormat('HH:mm - dd/MM/yyyy');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.campaign_rounded, color: AppConstants.primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Ban Quản Lý Chung Cư',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                    ),
                  ),
                  Text(
                    fullDateFormat.format(item.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppConstants.textSecondary),
                  ),
                ],
              ),
              if (item.apartmentNumber != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Gửi đến căn: ${item.apartmentNumber}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0369A1), fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                item.body.isNotEmpty ? item.body : item.content,
                style: const TextStyle(fontSize: 14, color: AppConstants.textPrimary, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationModel item) {
    if (item.type == 'INVOICE' && item.referenceId != null) {
      if (!item.isRead) _notificationService.markAsRead(item.id).catchError((_) => false);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceId: item.referenceId!)),
      ).then((_) => _loadDashboardData());
    } else if (item.type == 'MAINTENANCE' && item.referenceId != null) {
      if (!item.isRead) _notificationService.markAsRead(item.id).catchError((_) => false);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MaintenanceDetailScreen(requestId: item.referenceId!)),
      ).then((_) => _loadDashboardData());
    } else {
      _showAnnouncementDialog(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryApt = _myApartments.isNotEmpty ? _myApartments.first : null;
    final dateFormat = DateFormat('dd/MM/yyyy');

    final announcements = _notifications.where((n) => n.type == 'ANNOUNCEMENT' || n.isGlobal).toList();
    final bulletinItems = (announcements.isNotEmpty ? announcements : _notifications).take(4).toList();

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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.notifications_outlined, color: AppConstants.primaryColor, size: 26),
                              if (_notifications.any((n) => !n.isRead))
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationListScreen()),
                            ).then((_) => _loadDashboardData());
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: AppConstants.primaryColor),
                          onPressed: _loadDashboardData,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Main Apartment Card
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HouseholdMembersScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
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
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Đang sinh sống',
                                    style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
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
                            _buildAptBadge(Icons.people_outline_rounded, '${primaryApt?.maxCapacity ?? 4} người (Xem TV)'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions (6 Full Resident Features)
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildActionCard(
                      icon: Icons.speed_rounded,
                      title: 'Điện & Nước',
                      subtitle: 'Chỉ số tiêu thụ',
                      color: const Color(0xFF0284C7),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UtilityUsageScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildActionCard(
                      icon: Icons.description_rounded,
                      title: 'Hợp Đồng',
                      subtitle: 'Hồ sơ thuê/ở',
                      color: const Color(0xFF0D9488),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ContractListScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Unpaid Invoices Alert Card
                if (_unpaidInvoices.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppConstants.dangerColor),
                            const SizedBox(width: 8),
                            Text(
                              'Bạn có ${_unpaidInvoices.length} hóa đơn chưa thanh toán',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.dangerColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tổng tiền cần nộp: ${_formatVND(_unpaidInvoices.fold(0.0, (acc, item) => acc + item.totalAmount))}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.dangerColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.payment_rounded, size: 16),
                            label: const Text('Thanh toán ngay'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InvoiceDetailScreen(invoiceId: _unpaidInvoices.first.id),
                                ),
                              ).then((_) => _loadDashboardData());
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Active Maintenance Progress
                if (_activeMaintenances.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppConstants.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Đang xử lý sửa chữa: ${_activeMaintenances.first.title}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _activeMaintenances.first.isProcessing
                                    ? const Color(0xFFDBEAFE)
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _activeMaintenances.first.status,
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
                              ? 'Kỹ thuật viên phụ trách: ${_activeMaintenances.first.assignedStaffName} (${_activeMaintenances.first.assignedStaffPhone ?? "Trực tòa"})'
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

                // Building Notifications / Bulletin Board
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.campaign_rounded, color: AppConstants.primaryColor, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Bảng tin chung cư',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: AppConstants.primaryColor),
                      label: const Text('Xem tất cả', style: TextStyle(fontSize: 13, color: AppConstants.primaryColor, fontWeight: FontWeight.w600)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationListScreen()),
                        ).then((_) => _loadDashboardData());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (bulletinItems.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppConstants.borderColor),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.campaign_outlined, size: 36, color: AppConstants.textSecondary),
                        SizedBox(height: 8),
                        Text(
                          'Chưa có thông báo mới từ Ban Quản Lý.',
                          style: TextStyle(color: AppConstants.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bulletinItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final n = bulletinItems[idx];
                      return InkWell(
                        onTap: () => _handleNotificationTap(n),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: !n.isRead ? AppConstants.primaryColor.withOpacity(0.4) : AppConstants.borderColor,
                              width: !n.isRead ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: n.type == 'ANNOUNCEMENT' ? const Color(0xFFEFF6FF) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  n.type == 'ANNOUNCEMENT' ? Icons.campaign_rounded : Icons.notifications_active_rounded,
                                  color: n.type == 'ANNOUNCEMENT' ? AppConstants.primaryColor : const Color(0xFF6B7280),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n.title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: !n.isRead ? FontWeight.bold : FontWeight.w600,
                                              color: AppConstants.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (!n.isRead) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppConstants.primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n.body.isNotEmpty ? n.body : n.content,
                                      style: const TextStyle(fontSize: 12, color: AppConstants.textSecondary, height: 1.4),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          n.apartmentNumber != null ? 'Căn ${n.apartmentNumber}' : 'Toàn chung cư',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF0369A1),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          dateFormat.format(n.createdAt),
                                          style: const TextStyle(fontSize: 11, color: AppConstants.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
