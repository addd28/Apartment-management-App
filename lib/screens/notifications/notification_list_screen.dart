import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_constants.dart';
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
  final ScrollController _scrollController = ScrollController();

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _totalCount = 0;
  int _unreadCount = 0;
  static const int _pageSize = 20;

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
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải thông báo: ')),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thao tác thất bại: ')),
      );
    }
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

    // Navigate to target screen
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
                  subtitle: 'Tất cả các thông báo mới về hóa đơn, bảo trì, lịch chuyển đồ sẽ xuất hiện ở đây.',
                )
              : RefreshIndicator(
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
    );
  }
}