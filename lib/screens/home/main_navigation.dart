import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../services/notification_service.dart';
import '../invoices/invoice_list_screen.dart';
import '../maintenance/maintenance_list_screen.dart';
import '../profile/profile_tab.dart';
import 'home_tab.dart';

class MainNavigation extends StatefulWidget {
  final int initialTab;

  const MainNavigation({super.key, this.initialTab = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  Timer? _notificationSyncTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;

    // Đồng bộ thiết bị và tải các thông báo có thể bị lỡ khi offline
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifService = NotificationService();
      notifService.syncDeviceToken();
      notifService.syncOfflineNotifications();
    });

    // Định kỳ kiểm tra thông báo mới từ backend mỗi 30 giây
    _notificationSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      NotificationService().syncOfflineNotifications();
    });
  }

  @override
  void dispose() {
    _notificationSyncTimer?.cancel();
    super.dispose();
  }

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeTab(onSwitchTab: _switchTab),
      const MaintenanceListScreen(),
      const InvoiceListScreen(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _switchTab,
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: AppConstants.primaryLight,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppConstants.primaryColor),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_circle_outlined),
            selectedIcon: Icon(Icons.build_circle_rounded, color: AppConstants.primaryColor),
            label: 'Bảo trì',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: AppConstants.primaryColor),
            label: 'Hóa đơn',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppConstants.primaryColor),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
