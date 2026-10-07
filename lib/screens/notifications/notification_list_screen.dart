import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_constants.dart';
import '../../core/storage_service.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../widgets/empty_state.dart';
import '../invoices/invoice_detail_screen.dart';
import '../invoices/invoice_list_screen.dart';
import '../maintenance/maintenance_detail_screen.dart';
import '../maintenance/maintenance_list_screen.dart';
import '../move_requests/move_request_list_screen.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final _service = NotificationService();
  final _scrollController = ScrollController();

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isOffline = false;
  int _currentPage = 1;
  int _totalCount = 0;
  int _unreadCount = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _notifications.length < _totalCount) {
      _loadMore();
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final res = await _service.getMyNotifications(page: 1, pageSize: _pageSize);
      if (mounted) {
        setState(() {
          _currentPage = 1;
          _notifications = res.items;
          _totalCount = res.totalCount;
          _unreadCount = res.unreadCount;
          _isOffline = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      final cached = StorageService.getCachedNotifications();
      if (cached != null) {
        final cachedRes = NotificationPageResponse.fromJson(cached);
        if (mounted) {
          setState(() {
            _currentPage = 1;
            _notifications = cachedRes.items;
            _totalCount = cachedRes.totalCount;
            _unreadCount = cachedRes.unreadCount;
            _isOffline = true;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể tải thông báo: $e')),
          );
        }
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final res = await _service.getMyNotifications(page: nextPage, pageSize: _pageSize);
      if (mounted) {
        setState(() {
          _currentPage = nextPage;
          _notifications.addAll(res.items);
          _totalCount = res.totalCount;
          _unreadCount = res.unreadCount;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      _loadNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thao tác thất bại: $e')),
      );
    }
  }

  void _showAnnouncementDialog(NotificationModel item) {
    final dateFormat = DateFormat('HH:mm - dd/MM/yyyy');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.campaign_rounded, color: AppConstants.primaryColor, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
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
                  dateFormat.format(item.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppConstants.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              item.body,
              style: const TextStyle(fontSize: 14, color: AppConstants.textPrimary, height: 1.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _handleItemTap(NotificationModel item) async {
    if (!item.isRead) {
      _service.markAsRead(item.id).catchError((_) => false);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == item.id);
        if (index != -1) {
          _notifications[index] = NotificationModel(
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
          if (_unreadCount > 0) _unreadCount--;
        }
      });
    }

    final type = item.type.toUpperCase();
    final refId = item.referenceId;

    if (type.contains('INVOICE') || type.contains('PAYMENT')) {
      if (refId != null && refId > 0) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceId: refId)));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceListScreen()));
      }
    } else if (type.contains('MAINTENANCE')) {
      if (refId != null && refId > 0) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => MaintenanceDetailScreen(requestId: refId)));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceListScreen()));
      }
    } else if (type.contains('MOVING')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MoveRequestListScreen()));
    } else {
      _showAnnouncementDialog(item);
    }
  }

  IconData _getTypeIcon(String type) {
    final t = type.toUpperCase();
    if (t.contains('INVOICE') || t.contains('PAYMENT')) return Icons.receipt_long_rounded;
    if (t.contains('MAINTENANCE')) return Icons.build_circle_rounded;
    if (t.contains('MOVING')) return Icons.local_shipping_rounded;
    return Icons.campaign_rounded;
  }

  Color _getTypeColor(String type) {
    final t = type.toUpperCase();
    if (t.contains('INVOICE') || t.contains('PAYMENT')) return const Color(0xFF2563EB);
    if (t.contains('MAINTENANCE')) return const Color(0xFFD97706);
    if (t.contains('MOVING')) return const Color(0xFF0D9488);
    return AppConstants.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm - dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Đọc hết', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'Chưa có thông báo nào',
                  description: 'Tất cả các thông báo mới về bảng tin chung cư, hóa đơn, bảo trì, lịch chuyển đồ sẽ xuất hiện ở đây.',
                )
              : Column(
                  children: [
                    if (_isOffline)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.cloud_off_rounded, size: 20, color: Color(0xFFB45309)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Bạn đang offline: Đang hiển thị các thông báo đã lưu trước đó. Kéo xuống để tải lại khi có mạng.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      if (idx == _notifications.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final item = _notifications[idx];
                      final iconColor = _getTypeColor(item.type);

                      return InkWell(
                        onTap: () => _handleItemTap(item),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: item.isRead ? Colors.white : const Color(0xFFF0F7FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: item.isRead ? AppConstants.borderColor : AppConstants.primaryColor.withOpacity(0.3),
                              width: item.isRead ? 1 : 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_getTypeIcon(item.type), color: iconColor, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                              color: AppConstants.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (!item.isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(left: 6),
                                            decoration: const BoxDecoration(
                                              color: AppConstants.primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.body,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppConstants.textSecondary,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      dateFormat.format(item.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
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
                ),
              ),
            ],
          ),
    );
  }
}
